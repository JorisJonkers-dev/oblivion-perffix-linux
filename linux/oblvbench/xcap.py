"""Fast window capture through libX11 (ctypes, stdlib only): XGetImage of just the wanted rectangle of the game window
and a block average in the same pass, instead of `xwd` of the whole window (14.7 MB at 1440p, ~100 ms). Falls back to
detail.Capturer (xwd) when libX11 cannot be loaded or the display cannot be opened.

grab() returns a detail.Frame (luminance = the green channel, like detail.parse_xwd)."""
import ctypes
import ctypes.util
import glob
import os
import subprocess
import time
from array import array

from . import detail

ALL_PLANES = ctypes.c_ulong(~0 & 0xFFFFFFFFFFFFFFFF)
ZPIXMAP = 2


class XImage(ctypes.Structure):
    _fields_ = [("width", ctypes.c_int), ("height", ctypes.c_int), ("xoffset", ctypes.c_int), ("format", ctypes.c_int),
                ("data", ctypes.c_void_p), ("byte_order", ctypes.c_int), ("bitmap_unit", ctypes.c_int),
                ("bitmap_bit_order", ctypes.c_int), ("bitmap_pad", ctypes.c_int), ("depth", ctypes.c_int),
                ("bytes_per_line", ctypes.c_int), ("bits_per_pixel", ctypes.c_int), ("red_mask", ctypes.c_ulong),
                ("green_mask", ctypes.c_ulong), ("blue_mask", ctypes.c_ulong)]


def load_x11():
    cands = [ctypes.util.find_library("X11"), "libX11.so.6"] + sorted(glob.glob("/nix/store/*libx11-*/lib/libX11.so.6"))
    for c in cands:
        if c:
            try:
                return ctypes.CDLL(c)
            except OSError:
                continue
    return None


def crop_rect(w, h, frac):
    """Centre rectangle (x, y, cw, ch) covering `frac` of each side (1.0 = the whole window), even sizes."""
    frac = min(1.0, max(0.1, float(frac)))
    cw, ch = max(16, int(w * frac) // 2 * 2), max(16, int(h * frac) // 2 * 2)
    return (w - cw) // 2, (h - ch) // 2, cw, ch


def downscale_buffer(buf, w, h, bpl, ch_byte, target_w, bpp=4):
    """Block average (green channel) of a w x h 32 bpp buffer to about target_w wide. Same method as detail._downscale."""
    mv = memoryview(buf)
    return detail._downscale(mv, 0, w, h, bpl, bpp, ch_byte, target_w)


class XlibCapturer:
    """detail.Capturer with the same grab() / last_ms, grabbing only the centre `crop` fraction of the window."""

    def __init__(self, name=detail.WINDOW_NAME, target_w=detail.TARGET_W, crop=1.0, run=subprocess.run):
        self.name, self.target_w, self.crop, self.run = name, target_w, crop, run
        self.lib = self.dpy = self.win = None
        self.last_ms = None
        self.fallback = None

    def _open(self):
        lib = load_x11()
        if lib is None:
            raise detail.CaptureError("libX11 not found")
        lib.XOpenDisplay.restype = ctypes.c_void_p
        lib.XOpenDisplay.argtypes = [ctypes.c_char_p]
        lib.XGetImage.restype = ctypes.POINTER(XImage)
        lib.XGetImage.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_int, ctypes.c_uint,
                                  ctypes.c_uint, ctypes.c_ulong, ctypes.c_int]
        lib.XGetGeometry.argtypes = [ctypes.c_void_p, ctypes.c_ulong] + [ctypes.c_void_p] * 7
        lib.XDestroyImage.argtypes = [ctypes.c_void_p]
        lib.XSetErrorHandler.argtypes = [ctypes.c_void_p]
        dpy = lib.XOpenDisplay(os.environ.get("DISPLAY", ":0").encode())
        if not dpy:
            raise detail.CaptureError("cannot open the X display")
        # XGetImage on a vanished window raises an X error that would abort the process: ignore errors instead
        self._handler = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p)(lambda d, e: 0)
        lib.XSetErrorHandler(self._handler)
        self.lib, self.dpy = lib, dpy

    def _find_window(self):
        tool = detail.find_tool("xdotool")
        r = self.run([tool, "search", "--name", self.name], capture_output=True, text=True, timeout=5)
        ids = r.stdout.split()
        if not ids:
            raise detail.CaptureError(f"no window named '{self.name}'")
        return int(ids[-1])

    def _geometry(self):
        lib = self.lib
        root = ctypes.c_ulong()
        w, h, bw, depth = ctypes.c_uint(), ctypes.c_uint(), ctypes.c_uint(), ctypes.c_uint()
        x, y = ctypes.c_int(), ctypes.c_int()
        ok = lib.XGetGeometry(self.dpy, self.win, ctypes.byref(root), ctypes.byref(x), ctypes.byref(y), ctypes.byref(w),
                              ctypes.byref(h), ctypes.byref(bw), ctypes.byref(depth))
        if not ok:
            raise detail.CaptureError("XGetGeometry failed")
        return w.value, h.value

    def grab(self):
        if self.fallback is not None:
            return self.fallback.grab()
        t0 = time.perf_counter()
        try:
            if self.dpy is None:
                self._open()
            for attempt in (0, 1):
                if not self.win:
                    self.win = self._find_window()
                w, h = self._geometry() if self.win else (0, 0)
                x, y, cw, chh = crop_rect(w, h, self.crop)
                img = self.lib.XGetImage(self.dpy, self.win, x, y, cw, chh, ALL_PLANES, ZPIXMAP) if w else None
                if img:
                    break
                self.win = None
                if attempt:
                    raise detail.CaptureError("XGetImage failed")
            im = img.contents
            try:
                if im.bits_per_pixel != 32:
                    raise detail.CaptureError(f"{im.bits_per_pixel} bpp: only 32 bpp is supported")
                shift = {0xFF: 0, 0xFF00: 1, 0xFF0000: 2, 0xFF000000: 3}.get(im.green_mask)
                if shift is None:
                    raise detail.CaptureError(f"unexpected green mask {im.green_mask:#x}")
                chb = shift if im.byte_order == 0 else 3 - shift
                buf = (ctypes.c_char * (im.bytes_per_line * im.height)).from_address(im.data)
                frame = downscale_buffer(buf, im.width, im.height, im.bytes_per_line, chb, self.target_w)
            finally:
                self.lib.XDestroyImage(img)
        except (detail.CaptureError, OSError, AttributeError) as e:
            if self.dpy is None or self.lib is None:
                self.fallback = detail.Capturer(self.name, self.target_w, self.run)    # no libX11 / display: use xwd
                return self.fallback.grab()
            raise
        self.last_ms = (time.perf_counter() - t0) * 1000
        return frame
