"""Detail arrival: how long after a door / fast travel the textures are sharp.

FPS cannot show it, so the runner grabs the game window every `interval` s after the arrival and measures how sharp
the picture is (variance of the Laplacian of the luminance, HUD and overlay masked). The series says when the picture
stops getting sharper (`detailSettleS`) and how sharp it already was after 1 / 2 / 4 s relative to the end.

Capture: `xdotool search --name 'Oblivion Remastered'` finds the XWayland window, `xwd -id <win> -silent` dumps it,
the XWD is parsed here (stdlib only) and block-averaged down to ~640 px wide on the green channel. Sums over a block
are done on big integers holding 16-bit lanes, which keeps a 2560x1440 frame in the tens of milliseconds."""
import glob
import operator
import shutil
import statistics
import struct
import subprocess
import time
from array import array

TARGET_W = 640
OVERLAY_MASK = (0.0, 0.0, 0.25, 0.15)         # MangoHud's fps counter, top left (x, y, w, h as fractions)
CROP = 0.10                                    # the outer 10 % of every side is ignored (vignette, HUD edges)
SETTLE_TOL = 0.03
FINAL_TAIL_S = 2.0
FADE_FRACTION = 0.9
WINDOW_NAME = "Oblivion Remastered"


class CaptureError(RuntimeError):
    pass


class Frame:
    """A grayscale picture: `pix` is w*h bytes, row by row."""

    def __init__(self, w, h, pix):
        self.w, self.h, self.pix = w, h, pix


# ---------------------------------------------------------------- XWD

def parse_xwd(data, target_w=TARGET_W):
    """A 32 bpp ZPixmap XWD dump -> Frame (green channel, block-averaged to about `target_w` wide)."""
    if len(data) < 100:
        raise CaptureError("XWD too short")
    (hsize, ver, fmt, depth, w, h, xoff, byte_order, unit, bitorder, pad, bpp, bpl, vclass, rmask, gmask, bmask,
     bits_rgb, cmap_entries, ncolors) = struct.unpack(">20I", data[:80])
    if ver != 7:
        raise CaptureError(f"XWD version {ver}, expected 7")
    if bpp != 32 or fmt != 2:
        raise CaptureError(f"XWD {bpp} bpp format {fmt}: only 32 bpp ZPixmap is supported")
    off = hsize + ncolors * 12
    if len(data) < off + bpl * h:
        raise CaptureError("XWD pixel data truncated")
    shift = {0xFF: 0, 0xFF00: 1, 0xFF0000: 2, 0xFF000000: 3}.get(gmask)
    if shift is None:
        raise CaptureError(f"unexpected green mask {gmask:#x}")
    ch = shift if byte_order == 0 else 3 - shift          # byte of the pixel word that holds green
    return _downscale(memoryview(data), off, w, h, bpl, 4, ch, target_w)


def _downscale(mv, off, w, h, bpl, bpp, ch, target_w):
    f = max(1, w // target_w)
    ow, oh = w // f, h // f
    n = f * f
    lanes = ow * 2
    out = bytearray(ow * oh)
    zero = bytearray(lanes)
    for oy in range(oh):
        acc = 0
        for dy in range(f):
            base = off + (oy * f + dy) * bpl
            row = mv[base:base + w * bpp]
            for dx in range(f):
                s = row[ch + dx * bpp::f * bpp][:ow]
                b = bytearray(zero)
                b[0:lanes:2] = s
                acc += int.from_bytes(b, "little")
        sums = array("H")
        sums.frombytes(acc.to_bytes(lanes, "little"))
        if sums.itemsize != 2:
            raise CaptureError("unexpected array('H') size")
        out[oy * ow:(oy + 1) * ow] = bytes([v // n for v in sums])
    return Frame(ow, oh, bytes(out))


# ---------------------------------------------------------------- sharpness

def _blocked(w, h, masks):
    """Per row of the analysed region, the x intervals [a, b) that count (HUD / overlay masks cut out)."""
    x0, x1 = int(w * CROP) + 1, int(w * (1 - CROP)) - 1
    y0, y1 = int(h * CROP) + 1, int(h * (1 - CROP)) - 1
    rects = list(masks or [])
    rects.append(OVERLAY_MASK)
    boxes = []
    for m in rects:
        if len(m) != 4:
            continue
        mx, my, mw, mh = m
        boxes.append((int(mx * w) - 1, int((mx + mw) * w) + 1, int(my * h) - 1, int((my + mh) * h) + 1))
    rows = {}
    for y in range(y0, y1):
        cuts = sorted((max(a, x0), min(b, x1)) for a, b, c, d in boxes if c <= y < d and b > x0 and a < x1)
        segs, x = [], x0
        for a, b in cuts:
            if a > x:
                segs.append((x, a))
            x = max(x, b)
        if x < x1:
            segs.append((x, x1))
        rows[y] = segs
    return rows


def _rows(frame):
    w = frame.w
    return [list(frame.pix[y * w:(y + 1) * w]) for y in range(frame.h)]


def sharpness(frame, masks=None):
    """Variance of the 4-neighbour Laplacian of the luminance over the central region, masks excluded
    (rectangles x, y, w, h in fractions of the picture), or None when nothing is left to look at."""
    w, h = frame.w, frame.h
    if w < 16 or h < 16:
        return None
    rows = _blocked(w, h, masks)
    pix = frame.pix
    sub, add, mul = operator.sub, operator.add, operator.mul
    n = s1 = s2 = 0
    for y, segs in rows.items():
        if not segs:
            continue
        up, mid, dn = pix[(y - 1) * w:y * w], pix[y * w:(y + 1) * w], pix[(y + 1) * w:(y + 2) * w]
        lo = min(a for a, _ in segs)
        hi = max(b for _, b in segs)
        c = mid[lo:hi]
        t = list(map(add, map(add, up[lo:hi], dn[lo:hi]), map(add, mid[lo - 1:hi - 1], mid[lo + 1:hi + 1])))
        lap = list(map(sub, map(add, map(add, c, c), map(add, c, c)), t))
        for a, b in segs:
            part = lap[a - lo:b - lo]
            n += len(part)
            s1 += sum(part)
            s2 += sum(map(mul, part, part))
    if n < 100:
        return None
    return s2 / n - (s1 / n) ** 2


def mean_luma(frame):
    """Mean luminance of the whole picture (a sampled average: fade-in and black-frame detection)."""
    px = frame.pix[::7]
    return sum(px) / len(px) if px else 0.0


# ---------------------------------------------------------------- the series

def _median(v):
    return statistics.median(v) if v else None


def analyse(series, tol=SETTLE_TOL, tail=FINAL_TAIL_S):
    """series: [(t, sharpness, mean luminance)] with t in seconds since the capture began (the arrival).
    The fade-in is over at the first sample whose mean luminance reaches 90 % of the final median; times below are
    counted from there. detailSettleS: the first time from which the sharpness stays within `tol` of the median of
    the last `tail` s; detailAt1s/2s/4s: the sharpness at that time relative to that final value."""
    pts = [(t, s, m) for t, s, m in series if s is not None]
    out = {"detailSamples": len(series)}
    if len(pts) < 4:
        return out
    tmax = pts[-1][0]
    tailp = [p for p in pts if p[0] >= tmax - tail] or pts[-1:]
    final_mean = _median([p[2] for p in tailp])
    out["detailFinalMean"] = round(final_mean, 1)
    if final_mean < 2:
        out["detailBlack"] = True                     # the capture saw nothing: no sharpness to speak of
        return out
    origin = 0.0
    for t, s, m in pts:
        if m >= FADE_FRACTION * final_mean:
            origin = t
            break
    out["detailFadeS"] = round(origin, 2)
    pts = [(t - origin, s) for t, s, m in pts if t >= origin]
    tmax -= origin
    final = _median([s for t, s in pts if t >= tmax - tail] or [pts[-1][1]])
    out["detailFinal"] = round(final, 2)
    if not final:
        return out
    settle = None
    for t, s in reversed(pts):
        if abs(s - final) <= tol * final:
            settle = t
        else:
            break
    if settle is not None:
        out["detailSettleS"] = round(settle, 2)
    for sec in (1, 2, 4):
        before = [s for t, s in pts if t <= sec]
        if before and tmax >= sec:
            out[f"detailAt{sec}s"] = round(before[-1] / final, 3)
    return out


# ---------------------------------------------------------------- grabbing

def find_tool(name):
    p = shutil.which(name)
    if p:
        return p
    hits = sorted(glob.glob(f"/nix/store/*-{name}-*/bin/{name}"))
    if name == "xwd":
        hits = hits or sorted(glob.glob("/nix/store/*-xwd-*/bin/xwd"))
    if not hits:
        raise CaptureError(f"{name} not found (nix build nixpkgs#xdotool nixpkgs#xorg.xwd --no-link --print-out-paths)")
    return hits[-1]


class Capturer:
    """Grabs the game window with xwd and returns a downscaled Frame."""

    def __init__(self, name=WINDOW_NAME, target_w=TARGET_W, run=subprocess.run):
        self.name, self.target_w, self.run = name, target_w, run
        self.xdotool = self.xwd = self.win = None
        self.last_ms = None

    def find_window(self):
        if not self.xdotool:
            self.xdotool, self.xwd = find_tool("xdotool"), find_tool("xwd")
        r = self.run([self.xdotool, "search", "--name", self.name], capture_output=True, text=True, timeout=5)
        ids = r.stdout.split()
        if not ids:
            raise CaptureError(f"no window named '{self.name}'")
        return ids[-1]

    def grab(self):
        t0 = time.perf_counter()
        for attempt in (0, 1):
            if not self.win:
                self.win = self.find_window()
            r = self.run([self.xwd, "-id", self.win, "-silent"], capture_output=True, timeout=10)
            if r.returncode == 0 and r.stdout:
                break
            self.win = None                                 # window gone or renamed: look again once
            if attempt:
                raise CaptureError("xwd failed: " + (r.stderr or b"").decode(errors="replace")[:200])
        frame = parse_xwd(r.stdout, self.target_w)
        self.last_ms = (time.perf_counter() - t0) * 1000
        return frame
