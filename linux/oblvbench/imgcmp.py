"""Image comparison for `bench.py spin --shots`: a minimal PNG writer / reader, SSIM, PSNR, the share of pixels that
differ a lot, and the base | variant | difference-heatmap side-by-side picture. Pure stdlib; the pictures are
grayscale (luminance) `detail.Frame`-like objects: .w, .h and .pix (w*h bytes, row by row).

SSIM uses 8x8 box windows (slid `step` pixels at a time) built from running sums, so a 960x540 pair takes well under
a second. Windows that touch a masked rectangle (HUD, MangoHud counter) are left out; PSNR and the big-difference
share skip the masked pixels. Masks are rectangles (x, y, w, h) as fractions of the picture.

register() / align() estimate the translation between two pictures of the same view (normalised cross-correlation,
coarse-to-fine) so that compare_aligned() judges the overlapping region instead of an edge-for-edge mismatch caused by
a camera that is a few pixels off."""
import math
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


def mean_abs_diff(a, b):
    """Mean |a - b| over all pixels (0 = identical): the 'is the picture still' measure of two grabs."""
    _check(a, b)
    return sum(abs(p - q) for p, q in zip(a.pix, b.pix)) / len(a.pix)


# ---------------------------------------------------------------- registration

def _fill_masks(p, masks):
    """A copy of `p` with the masked rectangles set to the picture's mean (a static overlay must not pull the
    correlation towards zero shift)."""
    boxes = [rect_px(m, p.w, p.h) for m in masks or [] if len(m) == 4]
    if not boxes:
        return p
    mean = int(sum(p.pix) / len(p.pix))
    pix = bytearray(p.pix)
    for a, b, c, d in boxes:
        for y in range(c, d):
            pix[y * p.w + a:y * p.w + b] = bytes([mean]) * (b - a)
    return Pic(p.w, p.h, bytes(pix))


def downscale(p, f):
    """Block average by an integer factor (trailing partial blocks dropped)."""
    if f == 1:
        return p
    w, h = p.w // f, p.h // f
    out = bytearray()
    div = f * f
    for by in range(h):
        acc = None
        for y in range(by * f, by * f + f):
            r = p.pix[y * p.w:y * p.w + w * f]
            acc = list(r) if acc is None else list(map(add, acc, r))
        out += bytes(sum(t) // div for t in zip(*(acc[k::f] for k in range(f))))
    return Pic(w, h, bytes(out))


class _Rows:
    """Per row: the pixels plus prefix sums of value and value squared (O(1) window sums)."""

    def __init__(self, p):
        self.w, self.h = p.w, p.h
        self.r = [p.pix[y * p.w:(y + 1) * p.w] for y in range(p.h)]
        self.s = [[0, *accumulate(r)] for r in self.r]
        self.q = [[0, *accumulate(map(mul, r, r))] for r in self.r]


def _ncc(A, B, dx, dy, min_frac=0.5):
    """Normalised cross-correlation of A(x, y) with B(x + dx, y + dy) over the overlap; None if the overlap is
    under `min_frac` of the picture or has no variance."""
    x0, x1 = max(0, -dx), min(A.w, A.w - dx)
    y0, y1 = max(0, -dy), min(A.h, A.h - dy)
    if x1 - x0 < A.w * min_frac or y1 - y0 < A.h * min_frac:
        return None
    sa = sb = saa = sbb = sab = 0
    for y in range(y0, y1):
        ra, rb = A.r[y], B.r[y + dy]
        sa += A.s[y][x1] - A.s[y][x0]
        saa += A.q[y][x1] - A.q[y][x0]
        sb += B.s[y + dy][x1 + dx] - B.s[y + dy][x0 + dx]
        sbb += B.q[y + dy][x1 + dx] - B.q[y + dy][x0 + dx]
        sab += sum(map(mul, ra[x0:x1], rb[x0 + dx:x1 + dx]))
    n = (x1 - x0) * (y1 - y0)
    va = saa - sa * sa / n
    vb = sbb - sb * sb / n
    if va <= 1e-9 or vb <= 1e-9:
        return None
    return (sab - sa * sb / n) / math.sqrt(va * vb)


def _search(A, B, cx, cy, rad):
    """Best (ncc, dx, dy) with |dx - cx|, |dy - cy| <= rad; ties go to the smaller shift."""
    best = None
    cand = sorted(((dx, dy) for dy in range(cy - rad, cy + rad + 1) for dx in range(cx - rad, cx + rad + 1)),
                  key=lambda t: (abs(t[0]) + abs(t[1]), t))
    for dx, dy in cand:
        v = _ncc(A, B, dx, dy)
        if v is not None and (best is None or v > best[0] + 1e-12):
            best = (v, dx, dy)
    return best


def register(a, b, masks=None, search=24):
    """Translation (dx, dy) in pixels such that b(x + dx, y + dy) ~ a(x, y), found by normalised cross-correlation:
    an integer search of +-`search` px on a picture downscaled by 4, refined on the half scale (+-1) and at full scale
    (+-1; each finer level is searched around twice the coarser result, which pins it to within a pixel).
    Masked areas are filled with the mean first. -> dict(dx, dy, ncc, atEdge); ncc None when the pictures have no
    structure (shift 0 then)."""
    _check(a, b)
    a, b = _fill_masks(a, masks), _fill_masks(b, masks)
    if min(a.w, a.h) >= 64:
        levels = [(4, -(-search // 4)), (2, 1), (1, 1)]
    else:
        levels = [(1, search)]
    cx = cy = 0
    best = None
    prev = None
    for f, rad in levels:
        if prev is not None:
            cx, cy = cx * (prev // f), cy * (prev // f)
        best = _search(_Rows(downscale(a, f)), _Rows(downscale(b, f)), cx, cy, rad)
        if best is None:
            return {"dx": 0, "dy": 0, "ncc": None, "atEdge": False}
        cx, cy, prev = best[1], best[2], f
    v, dx, dy = best
    return {"dx": dx, "dy": dy, "ncc": round(v, 5), "atEdge": max(abs(dx), abs(dy)) >= search}


def align(a, b, masks=None, search=24):
    """Registers b to a and crops both to the overlap. -> (a', b', masks', info); info has dx, dy, ncc, atEdge.
    Masks (fractions of a) are re-expressed for the cropped pictures."""
    info = register(a, b, masks, search)
    dx, dy = info["dx"], info["dy"]
    if dx == 0 and dy == 0:
        return a, b, masks, info
    x0, x1 = max(0, -dx), min(a.w, a.w - dx)
    y0, y1 = max(0, -dy), min(a.h, a.h - dy)
    cw, ch = x1 - x0, y1 - y0
    pa = b"".join(a.pix[y * a.w + x0:y * a.w + x1] for y in range(y0, y1))
    pb = b"".join(b.pix[(y + dy) * b.w + x0 + dx:(y + dy) * b.w + x1 + dx] for y in range(y0, y1))
    cm = []
    for m in masks or []:
        if len(m) != 4:
            continue
        mx, my, mw, mh = m
        ax0, ax1 = mx * a.w - x0, (mx + mw) * a.w - x0
        ay0, ay1 = my * a.h - y0, (my + mh) * a.h - y0
        if ax1 <= 0 or ay1 <= 0 or ax0 >= cw or ay0 >= ch:
            continue
        cm.append((ax0 / cw, ay0 / ch, (ax1 - ax0) / cw, (ay1 - ay0) / ch))
    return Pic(cw, ch, pa), Pic(cw, ch, pb), cm, info


def compare_aligned(a, b, masks=None, thresh=24, step=2, search=24):
    """compare() after registration: metrics of the overlapping region plus shift = [dx, dy] and ncc."""
    ca, cb, cm, info = align(a, b, masks, search)
    out = compare(ca, cb, cm, thresh, step)
    out["shift"] = [info["dx"], info["dy"]]
    out["ncc"] = info["ncc"]
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


def masked_pixels(p, masks=None):
    """The unmasked pixels of a picture as one bytes object (same pixels for the same size and masks)."""
    if not masks:
        return bytes(p.pix)
    out = bytearray()
    for y, sg in enumerate(keep_segments(p.w, p.h, masks)):
        row = p.pix[y * p.w:(y + 1) * p.w]
        for x0, x1 in sg:
            out += row[x0:x1]
    return bytes(out)


def hstack(pics, gap=4):
    """Pictures of equal height side by side (dark gap) -> (w, h, pix)."""
    if not pics:
        raise ImageError("no pictures")
    h = pics[0].h
    if any(p.h != h for p in pics):
        raise ImageError("height mismatch")
    sep = bytes([20]) * gap
    rows = []
    for y in range(h):
        rows.append(sep.join(bytes(p.pix[y * p.w:(y + 1) * p.w]) for p in pics))
    return sum(p.w for p in pics) + gap * (len(pics) - 1), h, b"".join(rows)
