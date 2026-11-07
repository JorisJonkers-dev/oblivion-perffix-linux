"""Image comparison for `bench.py spin --shots`: a minimal PNG writer / reader, SSIM, PSNR, the share of pixels that
differ a lot, and the base | variant | difference-heatmap side-by-side picture. Pure stdlib; the pictures are
grayscale (luminance) `detail.Frame`-like objects: .w, .h and .pix (w*h bytes, row by row).

SSIM uses 8x8 box windows (slid `step` pixels at a time) built from running sums, so a 960x540 pair takes well under
a second. Windows that touch a masked rectangle (HUD, MangoHud counter) are left out; PSNR and the big-difference
share skip the masked pixels. Masks are rectangles (x, y, w, h) as fractions of the picture."""
import struct
import zlib
from itertools import accumulate
from operator import add, mul, sub

WIN = 8
C1 = (0.01 * 255) ** 2
C2 = (0.03 * 255) ** 2
PNG_SIG = b"\x89PNG\r\n\x1a\n"


class ImageError(ValueError):
    pass


# ---------------------------------------------------------------- PNG

def _chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def encode_png(w, h, pix, channels=1, level=6):
    """8-bit PNG bytes from `pix` (w*h*channels bytes, row by row); channels 1 = gray, 3 = RGB."""
    if channels not in (1, 3) or len(pix) != w * h * channels:
        raise ImageError("encode_png: bad size / channel count")
    stride = w * channels
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += pix[y * stride:(y + 1) * stride]
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 0 if channels == 1 else 2, 0, 0, 0)
    return PNG_SIG + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(bytes(raw), level)) + _chunk(b"IEND", b"")


def write_png(path, w, h, pix, channels=1):
    with open(path, "wb") as f:
        f.write(encode_png(w, h, pix, channels))


def decode_png(data):
    """-> (w, h, channels, pix) for 8-bit gray / RGB, non-interlaced PNGs (what encode_png writes), any filter."""
    if data[:8] != PNG_SIG:
        raise ImageError("not a PNG")
    pos, idat, hdr = 8, [], None
    while pos + 8 <= len(data):
        n, tag = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if zlib.crc32(tag + body) & 0xFFFFFFFF != struct.unpack(">I", data[pos + 8 + n:pos + 12 + n])[0]:
            raise ImageError(f"bad CRC in {tag!r}")
        if tag == b"IHDR":
            hdr = struct.unpack(">IIBBBBB", body)
        elif tag == b"IDAT":
            idat.append(body)
        elif tag == b"IEND":
            break
        pos += 12 + n
    if not hdr:
        raise ImageError("no IHDR")
    w, h, depth, ctype, _, _, interlace = hdr
    if depth != 8 or ctype not in (0, 2) or interlace:
        raise ImageError("only 8-bit gray / RGB, non-interlaced PNGs are supported")
    ch = 1 if ctype == 0 else 3
    stride = w * ch
    raw = zlib.decompress(b"".join(idat))
    if len(raw) != (stride + 1) * h:
        raise ImageError("PNG data size mismatch")
    out, prev = bytearray(), bytearray(stride)
    for y in range(h):
        ft = raw[y * (stride + 1)]
        row = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        if ft == 2:
            row = bytearray(map(lambda a, b: (a + b) & 255, row, prev))
        elif ft in (1, 3, 4):
            for i in range(stride):
                a = row[i - ch] if i >= ch else 0
                b = prev[i]
                c = prev[i - ch] if i >= ch else 0
                if ft == 1:
                    p = a
                elif ft == 3:
                    p = (a + b) >> 1
                else:
                    pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                    p = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                row[i] = (row[i] + p) & 255
        elif ft != 0:
            raise ImageError(f"bad PNG filter {ft}")
        out += row
        prev = row
    return w, h, ch, bytes(out)


def read_gray_png(path):
    """A PNG file -> Frame-like gray picture (RGB is reduced to its green channel, like the capture)."""
    with open(path, "rb") as f:
        w, h, ch, pix = decode_png(f.read())
    return Pic(w, h, pix if ch == 1 else pix[1::3])


class Pic:
    def __init__(self, w, h, pix):
        self.w, self.h, self.pix = w, h, pix


# ---------------------------------------------------------------- masks

def rect_px(rect, w, h):
    mx, my, mw, mh = rect
    return (max(0, int(mx * w)), min(w, int((mx + mw) * w) + 1), max(0, int(my * h)), min(h, int((my + mh) * h) + 1))


def _merge(iv):
    out = []
    for a, b in sorted(iv):
        if out and a <= out[-1][1]:
            out[-1][1] = max(out[-1][1], b)
        else:
            out.append([a, b])
    return out


def keep_segments(w, h, masks):
    """Per pixel row, the x intervals [a, b) that are NOT masked."""
    boxes = [rect_px(m, w, h) for m in masks or [] if len(m) == 4]
    rows = []
    for y in range(h):
        cut = _merge([(a, b) for a, b, c, d in boxes if c <= y < d])
        segs, x = [], 0
        for a, b in cut:
            if a > x:
                segs.append((x, a))
            x = b
        if x < w:
            segs.append((x, w))
        rows.append(segs)
    return rows


def _window_valid(w, h, masks, step, win=WIN):
    """Per window row, a bytes of 1/0 per window column: 0 when the window overlaps a masked rectangle."""
    boxes = [rect_px(m, w, h) for m in masks or [] if len(m) == 4]
    nx = (w - win) // step + 1
    ny = (h - win) // step + 1
    rows = []
    for j in range(ny):
        y = j * step
        bad = _merge([(a - win + 1, b) for a, b, c, d in boxes if c < y + win and y < d])
        v = bytearray(b"\x01" * nx)
        for a, b in bad:
            i0 = max(0, -(-a // step))
            i1 = min(nx, -(-b // step))
            if i1 > i0:
                v[i0:i1] = bytes(i1 - i0)
        rows.append(bytes(v))
    return rows


# ---------------------------------------------------------------- metrics

def _row_windows(rows, step, win=WIN):
    """For each picture row (a sequence of numbers) the sums over `win` consecutive pixels, every `step` pixels."""
    for r in rows:
        ps = [0]
        ps.extend(accumulate(r))
        yield list(map(sub, ps[win::step], ps[::step]))


def _vertical(rowsums, step, win=WIN):
    """Sums of `win` consecutive horizontal-window rows, every `step` rows (running sum)."""
    buf, acc, n = [], None, 0
    for r in rowsums:
        buf.append(r)
        acc = r if acc is None else list(map(add, acc, r))
        if len(buf) > win:
            acc = list(map(sub, acc, buf.pop(0)))
        if len(buf) == win:
            if n % step == 0:
                yield acc
            n += 1


def _check(a, b):
    if (a.w, a.h) != (b.w, b.h):
        raise ImageError(f"size mismatch {a.w}x{a.h} vs {b.w}x{b.h}")
    if a.w < WIN * 2 or a.h < WIN * 2:
        raise ImageError("picture too small")


def _rows(p):
    return [p.pix[y * p.w:(y + 1) * p.w] for y in range(p.h)]


def ssim(a, b, masks=None, step=2):
    """Mean SSIM of two gray pictures over 8x8 windows (masked ones skipped); None if no window is left."""
    _check(a, b)
    ra, rb = _rows(a), _rows(b)
    n = WIN * WIN
    sx = _vertical(_row_windows(ra, step), step)
    sy = _vertical(_row_windows(rb, step), step)
    sxx = _vertical(_row_windows((list(map(mul, r, r)) for r in ra), step), step)
    syy = _vertical(_row_windows((list(map(mul, r, r)) for r in rb), step), step)
    sxy = _vertical(_row_windows((list(map(mul, p, q)) for p, q in zip(ra, rb)), step), step)
    valid = _window_valid(a.w, a.h, masks, step)
    total = cnt = 0
    for vx, vy, vxx, vyy, vxy, ok in zip(sx, sy, sxx, syy, sxy, valid):
        s = c = 0.0
        for X, Y, XX, YY, XY, g in zip(vx, vy, vxx, vyy, vxy, ok):
            if not g:
                continue
            mx, my = X / n, Y / n
            cx = XX / n - mx * mx
            cy = YY / n - my * my
            cxy = XY / n - mx * my
            s += ((2 * mx * my + C1) * (2 * cxy + C2)) / ((mx * mx + my * my + C1) * (cx + cy + C2))
            c += 1
        total += s
        cnt += c
    return total / cnt if cnt else None


def diff_stats(a, b, masks=None, thresh=24):
    """-> dict(psnr dB (99 if identical), bigPct % of unmasked pixels differing by more than `thresh`,
    dLuma mean(b) - mean(a)) over the unmasked pixels."""
    _check(a, b)
    segs = keep_segments(a.w, a.h, masks)
    se = big = n = sa = sb = 0
    for y, sg in enumerate(segs):
        ra, rb = a.pix[y * a.w:(y + 1) * a.w], b.pix[y * a.w:(y + 1) * a.w]
        for x0, x1 in sg:
            pa, pb = ra[x0:x1], rb[x0:x1]
            d = list(map(sub, pa, pb))
            se += sum(map(mul, d, d))
            big += sum(1 for v in d if v > thresh or v < -thresh)
            sa += sum(pa)
            sb += sum(pb)
            n += x1 - x0
    if not n:
        return {"psnr": None, "bigPct": None, "dLuma": None}
    mse = se / n
    import math
    return {"psnr": 99.0 if mse == 0 else round(10 * math.log10(255 * 255 / mse), 2),
            "bigPct": round(100.0 * big / n, 3), "dLuma": round((sb - sa) / n, 2)}


def compare(a, b, masks=None, thresh=24, step=2):
    out = diff_stats(a, b, masks, thresh)
    s = ssim(a, b, masks, step)
    out["ssim"] = None if s is None else round(s, 5)
    return out


# ---------------------------------------------------------------- pictures

def _lut():
    r = bytes(min(255, v * 3) for v in range(256))
    g = bytes(max(0, min(255, (v - 85) * 3)) for v in range(256))
    b = bytes(max(0, min(255, (v - 170) * 3)) for v in range(256))
    return r, g, b


def gray_to_rgb(row):
    out = bytearray(len(row) * 3)
    out[0::3] = out[1::3] = out[2::3] = row
    return out


def side_by_side(a, b, masks=None, gain=4, gap=4):
    """base | variant | amplified |difference| heatmap (black -> red -> yellow -> white; masked areas dark blue),
    as (w, h, rgb bytes)."""
    _check(a, b)
    lr, lg, lb = _lut()
    segs = keep_segments(a.w, a.h, masks)
    w = a.w * 3 + gap * 2
    out = bytearray()
    sep = bytes([40, 40, 40]) * gap
    for y in range(a.h):
        ra, rb = a.pix[y * a.w:(y + 1) * a.w], b.pix[y * a.w:(y + 1) * a.w]
        d = bytes(min(255, abs(p - q) * gain) for p, q in zip(ra, rb))
        heat = bytearray(a.w * 3)
        heat[0::3], heat[1::3], heat[2::3] = d.translate(lr), d.translate(lg), d.translate(lb)
        x = 0
        for s0, s1 in segs[y] + [(a.w, a.w)]:
            if s0 > x:
                heat[x * 3:s0 * 3] = bytes([0, 0, 90]) * (s0 - x)
            x = s1
        out += gray_to_rgb(ra) + sep + gray_to_rgb(rb) + sep + heat
    return w, a.h, bytes(out)


def median_pic(pics):
    """Pixel-wise median (mean of the middle two for an even count) of equally sized pictures."""
    if not pics:
        raise ImageError("no pictures")
    if len(pics) == 1:
        return pics[0]
    for p in pics[1:]:
        if (p.w, p.h) != (pics[0].w, pics[0].h):
            raise ImageError("size mismatch")
    k = len(pics)
    srt = [sorted(t) for t in zip(*(p.pix for p in pics))]
    pix = bytes(t[k // 2] if k % 2 else (t[k // 2 - 1] + t[k // 2]) // 2 for t in srt)
    return Pic(pics[0].w, pics[0].h, pix)
