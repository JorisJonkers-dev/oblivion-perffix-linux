"""--warmup auto: wait in the world until the game's start-up PSO precompile is done.

With the fix loaded the end is read from OblivionPerfFix.log (only lines written after this launch count):
    [pso] +54.2 s: shader precompile finished (seen from +9.7 s; ...)
The hook's own start-up line proves the log will say so:
    [pso] SetBatchMode exe+0x... detoured (...)
Without the hook (--fix off, PsoPrecompileFast=0 or no log) the wait is for steady MangoHud frame times (rolling 5 s
p95 within 10% over 10 s); when no frame log can be read either it is a fixed 90 s. Minimum 20 s, cap 240 s."""
import re
import time

MIN_S = 20.0
CAP_S = 240.0
FALLBACK_S = 90.0
WIN_S = 5.0
HOLD_S = 10.0
TOL = 0.10

_TS = r"(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{3})"
DONE_RX = re.compile(r"^" + _TS + r" \[pso\] \+[\d.]+ s: shader precompile finished")
HOOK_RX = re.compile(r"^" + _TS + r" \[pso\] SetBatchMode exe\+0x[0-9A-Fa-f]+ detoured")
DONE_TEXT = "[pso] +<n> s: shader precompile finished"


def parse_warmup(v):
    """'auto' or seconds (>= 0)."""
    if isinstance(v, str) and v.strip().lower() == "auto":
        return "auto"
    s = float(v)
    if s < 0:
        raise ValueError("warm-up seconds must be >= 0")
    return s


def _epoch(ts):
    return time.mktime(time.strptime(ts[:19], "%Y-%m-%d %H:%M:%S")) + float(ts[19:])


def log_state(text, since):
    """(hooked, done_epoch, done_line) from OblivionPerfFix.log text; lines stamped before `since` (an older
    session's) are ignored."""
    hooked, done, line_done = False, None, None
    for line in text.splitlines():
        m = HOOK_RX.match(line)
        if m and _epoch(m.group(1)) >= since:
            hooked = True
            continue
        m = DONE_RX.match(line)
        if m and _epoch(m.group(1)) >= since:
            done, line_done = _epoch(m.group(1)), line.strip()
    return hooked, done, line_done


def frames_stable(elapsed, frametime, win=WIN_S, hold=HOLD_S, tol=TOL):
    """True when the p95 frame time of every `win`-second window ending in the last `hold` seconds (stepped by
    1 s) is within `tol` of the lowest. False when the log is shorter than win + hold."""
    if not elapsed or elapsed[-1] - elapsed[0] < win + hold:
        return False
    end = elapsed[-1]
    p95 = []
    t = end - hold
    while t <= end + 1e-9:
        vals = sorted(f for e, f in zip(elapsed, frametime) if t - win < e <= t)
        if len(vals) < 10:
            return False
        p95.append(vals[min(len(vals) - 1, int(0.95 * len(vals)))])
        t += 1.0
    return max(p95) <= min(p95) * (1 + tol)


def decide(elapsed, hooked, done_line, frames, stable, min_s=MIN_S, cap_s=CAP_S, fallback_s=FALLBACK_S):
    """Reason string to end the warm-up with at `elapsed` seconds, or None to keep waiting. `frames`: whether a
    MangoHud frame log can be read."""
    if elapsed < min_s:
        return None
    if elapsed >= cap_s:
        return f"cap {cap_s:g} s reached" + (" (precompile not finished)" if hooked else " (frame times not stable)" if frames else "")
    if hooked:
        return f"precompile finished: {done_line}" if done_line else None
    if frames:
        return "frame times stable (rolling 5 s p95 within 10% for 10 s)" if stable else None
    return f"no fix log and no frame log: fixed {fallback_s:g} s" if elapsed >= fallback_s else None


def wait_auto(read_log, read_frames, since, wait, now=time.time, min_s=MIN_S, cap_s=CAP_S, fallback_s=FALLBACK_S,
              say=None):
    """Polls every second. read_log() -> OblivionPerfFix.log text or None; read_frames() -> (elapsed, frametime) or
    None; wait(sec) sleeps. Returns {"mode": "auto", "seconds", "reason", "method"}."""
    t0 = now()
    last = 0.0
    while True:
        el = now() - t0
        text = read_log()
        hooked, done, line = log_state(text, since) if text else (False, None, None)
        fr = read_frames() if not hooked else None
        stable = bool(fr) and frames_stable(*fr)
        reason = decide(el, hooked, line, fr is not None, stable, min_s, cap_s, fallback_s)
        if reason:
            method = "pso log" if hooked and line else "frame times" if fr is not None else "fixed"
            return {"mode": "auto", "seconds": round(el, 1), "reason": reason, "method": method}
        if say and el - last >= 30:
            last = el
            say(f"warm-up: {el:.0f} s, waiting for {'the PSO precompile' if hooked else 'stable frame times'}")
        wait(1.0)
