"""bench.py spin --turn-settle: how long until the picture is complete after the camera turns. The capturing happens in
SpinRunner (a separate turn lap after each slot); this module holds what needs no game: the metrics of one turn's
frame series (luminance, HUD / MangoHud masked), the per-variant summary against base, the contact strips and the
report text.

One turn = a series of (t, picture), t in seconds after the snap. The last TAIL s are the reference picture ("final",
pixel-wise median). Per frame: mad = mean absolute luminance difference to final, big = % of unmasked pixels that
differ from final by more than `diffThresh`, luma = mean luminance.
  settleS  first t from which every later frame has mad <= madMax and big <= bigMax (0 = already complete in the first
           frame); the limits are max(floor, noiseMult x the noise of the tail frames against final), so TAA noise and
           NPC motion do not count as unfinished.
  pops     frame-to-frame jumps (share of pixels changing by more than diffThresh between consecutive frames above
           popMax) at t >= popFrom: each is one more batch of things appearing / lighting changing.
  auc      integral over t of max(0, mad - noise mad): how much was missing and for how long (luminance levels x s);
           aucBig the same for big (% x s).
  luma     mean luminance per frame; lumaSettleS = first t after which it stays within lumaTol of the final one
           (night lighting filling in); lumaDelta = final - first."""
import math
import statistics
from operator import add
from pathlib import Path

from . import imgcmp
from .imgcmp import Pic

DEFAULTS = {"tail": 0.5, "diffThresh": 24, "madFloor": 2.0, "bigFloor": 0.5, "popFloor": 0.3, "noiseMult": 2.0,
            "popFrom": 0.2, "lumaTol": 0.03, "ssimFloor": 0.98, "lowFactor": 8, "lowFloor": 1.0,
            "edgeFloor": 0.5, "edgeStrong": 20.0, "edgeWeak": 8.0, "blobMin": 3, "lumaNoise": 0.3, "lumaMinAmp": 1.5,
            "lumaJump": 2.0, "lumaR2": 0.8}
DEFAULT_HEADINGS = [0, 90, 180, 270]
STRIP_TIMES = (0.0, 0.2, 0.5, 1.0, 2.0)
TURN_DIR = "turn"
FROM_MODES = ("back", "side")


def from_heading(h, mode):
    """Where the camera looks while it waits: straight away from the target ('back') or 90 deg to the left."""
    return (h + 180.0) % 360.0 if mode == "back" else (h - 90.0) % 360.0


def turn_rel(variant, slot, h):
    from . import spinshots
    return f"{TURN_DIR}/{variant}/s{slot}/{spinshots.heading_name(h)}.png"


def _med(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def down(p, f):
    """Block average by factor f -> Pic (w // f, h // f)."""
    ow, oh = p.w // f, p.h // f
    rows = []
    for y in range(oh):
        acc = None
        for dy in range(f):
            base = (y * f + dy) * p.w
            for dx in range(f):
                part = p.pix[base + dx:base + dx + ow * f:f]
                acc = list(part) if acc is None else list(map(add, acc, part))
        rows.append([v // (f * f) for v in acc])
    return Pic(ow, oh, bytes(v for r in rows for v in r))


def valid_grid(w, h, masks, erode=0):
    """Per pixel of a w x h grid: 1 = not masked (and, with erode, no masked pixel within `erode` px)."""
    v = bytearray(w * h)
    for y, sg in enumerate(imgcmp.keep_segments(w, h, masks)):
        for x0, x1 in sg:
            v[y * w + x0:y * w + x1] = b"\x01" * (x1 - x0)
    for _ in range(erode):
        o = bytearray(w * h)
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                i = y * w + x
                if v[i] and v[i - 1] and v[i + 1] and v[i - w] and v[i + w] and v[i - w - 1] and v[i - w + 1] \
                        and v[i + w - 1] and v[i + w + 1]:
                    o[i] = 1
        v = o
    return v


def sobel(p):
    """|gx| + |gy| / 8 per pixel (about grey levels per pixel across an edge); the 1 px border is 0."""
    w, h, px = p.w, p.h, p.pix
    out = [0.0] * (w * h)
    for y in range(1, h - 1):
        r0, r1, r2 = px[(y - 1) * w:y * w], px[y * w:(y + 1) * w], px[(y + 1) * w:(y + 2) * w]
        a = [r0[x] + 2 * r1[x] + r2[x] for x in range(w)]            # column sums for gx
        gx = [a[x + 1] - a[x - 1] for x in range(1, w - 1)]
        gy = [(r2[x - 1] + 2 * r2[x] + r2[x + 1]) - (r0[x - 1] + 2 * r0[x] + r0[x + 1]) for x in range(1, w - 1)]
        out[y * w + 1:y * w + w - 1] = [(abs(u) + abs(v)) / 8.0 for u, v in zip(gx, gy)]
    return out


def missing_blobs(ref_edges, edges, valid, w, h, strong, weak, min_size):
    """Connected regions (8-neighbour, at least min_size px) of strong reference edges that have no edge at all
    (>= weak, 1 px tolerance) in this frame: detail that is still missing."""
    present = [e >= weak for e in edges]
    near = bytearray(w * h)
    for i, f in enumerate(present):
        if f:
            y, x = divmod(i, w)
            for yy in range(max(0, y - 1), min(h, y + 2)):
                near[yy * w + max(0, x - 1):yy * w + min(w, x + 2)] = b"\x01" * (min(w, x + 2) - max(0, x - 1))
    miss = [bool(valid[i] and ref_edges[i] >= strong and not near[i]) for i in range(w * h)]
    seen, blobs = [False] * (w * h), 0
    for i0 in range(w * h):
        if not miss[i0] or seen[i0]:
            continue
        seen[i0] = True
        stack, n = [i0], 0
        while stack:
            i = stack.pop()
            n += 1
            y, x = divmod(i, w)
            for yy in range(max(0, y - 1), min(h, y + 2)):
                for xx in range(max(0, x - 1), min(w, x + 2)):
                    j = yy * w + xx
                    if miss[j] and not seen[j]:
                        seen[j] = True
                        stack.append(j)
        blobs += n >= min_size
    return blobs


def _first_ok(ok, ts):
    """Time of the first frame from which all later ones are ok (0.0 when all are)."""
    i = len(ok) - 1
    while i > 0 and ok[i - 1]:
        i -= 1
    return 0.0 if i == 0 else ts[i]


def classify_luma(ts, luma, ntail, th):
    """-> (kind, tau s or None, amplitude). kind: flat (change within noise), exponential (monotone and ln|L - final|
    falls linearly: eye adaptation), monotone, stepwise (>= 2 jumps: lighting / shadow pages arriving) or
    non-monotone. tau = exponential fit time constant, else the time the gap to final has shrunk to 37 % (monotone)."""
    fin = statistics.median(luma[-ntail:])
    tail = luma[-ntail:]
    noise = max(th["lumaNoise"], 2 * statistics.pstdev(tail))
    d = [v - fin for v in luma]
    amp = abs(d[0])
    k = len(luma)
    if max(abs(x) for x in d[:k - ntail] or [0]) < max(th["lumaMinAmp"], 3 * noise):
        return "flat", None, round(amp, 2)
    sm = [statistics.median(luma[max(0, i - 1):i + 2]) for i in range(k)]
    sign = 1 if fin - sm[0] >= 0 else -1
    steps = [(sm[i] - sm[i - 1]) * sign for i in range(1, k)]
    fwd = sum(x for x in steps if x > 0)
    back = -sum(x for x in steps if x < 0 and -x > noise)
    jumps = [x for x in (luma[i] - luma[i - 1] for i in range(1, k))
             if abs(x) > max(th["lumaJump"], 3 * noise, 0.25 * amp)]
    mono = back <= 0.15 * max(fwd, 1e-9)
    pts = [(t, math.log(abs(x))) for t, x in zip(ts, d) if abs(x) >= max(3 * noise, 0.3)]
    tau = r2 = None
    if len(pts) >= 3:
        mt = sum(t for t, _ in pts) / len(pts)
        my = sum(y for _, y in pts) / len(pts)
        sxx = sum((t - mt) ** 2 for t, _ in pts)
        sxy = sum((t - mt) * (y - my) for t, y in pts)
        syy = sum((y - my) ** 2 for _, y in pts)
        if sxx > 0 and syy > 0 and sxy < 0:
            tau = -sxx / sxy
            r2 = sxy * sxy / (sxx * syy)
    t37 = next((t for t, x in zip(ts, d) if abs(x) <= 0.37 * abs(d[0])), None) if abs(d[0]) > 0 else None
    if mono and tau is not None and r2 >= th["lumaR2"] and len(jumps) < 2:
        return "exponential", round(tau, 3), round(amp, 2)
    if mono and len(jumps) < 2:
        return "monotone", None if t37 is None else round(t37, 3), round(amp, 2)
    if len(jumps) >= 2:
        return "stepwise", None, round(amp, 2)
    return "non-monotone", None, round(amp, 2)


def analyse_turn(frames, masks=None, th=None):
    """frames: [(t, picture)] ordered by t. -> dict (see the module doc); {'error': ...} with fewer than 4 frames."""
    th = {**DEFAULTS, **(th or {})}
    if len(frames) < 4:
        return {"error": f"only {len(frames)} frames"}
    ts = [t for t, _ in frames]
    px = [imgcmp.masked_pixels(p, masks) for _, p in frames]
    n = len(px[0])
    if not n or any(len(x) != n for x in px):
        return {"error": "no unmasked pixels or frame sizes differ"}
    k = len(frames)
    ntail = max(3, sum(1 for t in ts if t >= ts[-1] - th["tail"]))
    ntail = min(ntail, k - 1)
    tail = slice(k - ntail, k)
    mean_of = lambda arrs: [sum(c) / len(c) for c in zip(*arrs)]
    final = mean_of(px[tail])
    d = th["diffThresh"]
    mult = th["noiseMult"]

    def dist(a, b):
        diff = [abs(x - y) for x, y in zip(a, b)]
        return sum(diff) / n, 100.0 * sum(1 for v in diff if v > d) / n

    mad, big = zip(*(dist(x, final) for x in px))
    luma = [sum(x[::5]) / len(x[::5]) for x in px]
    cons = [(0.0, 0.0)] + [dist(px[i - 1], px[i]) for i in range(1, k)]
    # noise: a tail frame is part of its own reference, so also use the frame-to-frame difference (sqrt(2) x sigma)
    noise_mad = max(statistics.median(mad[tail]), statistics.median(c[0] for c in cons[tail]) / 1.2)
    noise_big = statistics.median(big[tail])
    mad_max = max(th["madFloor"], mult * noise_mad)
    big_max = max(th["bigFloor"], mult * noise_big)
    pop_max = max(th["popFloor"], mult * statistics.median(c[1] for c in cons[tail]))
    settle_mad = _first_ok([mad[i] <= mad_max and big[i] <= big_max for i in range(k)], ts)
    pops = [round(ts[i], 3) for i in range(1, k) if ts[i] >= th["popFrom"] and cons[i][1] > pop_max]
    auc = aucb = 0.0
    for i in range(1, k):
        dt = ts[i] - ts[i - 1]
        auc += dt * (max(0.0, mad[i - 1] - noise_mad) + max(0.0, mad[i] - noise_mad)) / 2
        aucb += dt * (max(0.0, big[i - 1] - noise_big) + max(0.0, big[i] - noise_big)) / 2
    lfin = statistics.median(luma[tail])
    lok = [abs(luma[i] - lfin) <= th["lumaTol"] * max(lfin, 1.0) for i in range(k)]
    kind, tau, amp = classify_luma(ts, luma, ntail, th)

    # ---- total: SSIM against the reference (mean of the tail), half resolution
    half = [down(p, 2) for _, p in frames]
    hw, hh = half[0].w, half[0].h
    ref_h = Pic(hw, hh, bytes(int(round(v)) for v in mean_of([h.pix for h in half[tail]])))
    ss = [imgcmp.ssim(h, ref_h, masks, 1 if hw < 100 else 2) for h in half]
    ss = [1.0 if v is None else v for v in ss]
    noise_ss = statistics.median(ss[tail])
    ss_min = max(0.5, min(th["ssimFloor"], 1 - mult * (1 - noise_ss)))
    settle = _first_ok([v >= ss_min for v in ss], ts)

    # ---- lighting: heavily blurred (1/8 scale) difference to the reference
    f8 = max(2, th["lowFactor"])
    low = [down(p, f8) for _, p in frames]
    lv = valid_grid(low[0].w, low[0].h, masks)
    lidx = [i for i, v in enumerate(lv) if v] or list(range(low[0].w * low[0].h))
    lref = mean_of([[l.pix[i] for i in lidx] for l in low[tail]])
    lmad = [sum(abs(l.pix[i] - r) for i, r in zip(lidx, lref)) / len(lidx) for l in low]
    lnoise = max(statistics.median(lmad[tail]), 0.0)
    lmax = max(th["lowFloor"], mult * lnoise)
    settle_light = _first_ok([v <= lmax for v in lmad], ts)

    # ---- pop-in: edge maps (Sobel) of the half-resolution frames, difference and missing regions
    ev = valid_grid(hw, hh, masks, erode=1)
    eidx = [i for i, v in enumerate(ev) if v] or list(range(hw * hh))
    edges = [sobel(h) for h in half]
    eref = mean_of(edges[tail])
    emad = [sum(abs(e[i] - eref[i]) for i in eidx) / len(eidx) for e in edges]
    enoise = statistics.median(emad[tail])
    emax = max(th["edgeFloor"], mult * enoise)
    blobs = [missing_blobs(eref, e, ev, hw, hh, th["edgeStrong"], th["edgeWeak"], th["blobMin"]) for e in edges]
    bmax = max(blobs[tail])
    settle_pop = _first_ok([emad[i] <= emax and blobs[i] <= bmax for i in range(k)], ts)
    r3 = lambda v: [round(x, 3) for x in v]
    return {"frames": k, "tailFrames": ntail, "settleS": round(settle, 3), "settleMadS": round(settle_mad, 3),
            "lightSettleS": round(settle_light, 3), "popSettleS": round(settle_pop, 3),
            "ssimFirst": round(ss[0], 4), "ssimMin": round(ss_min, 4), "noiseSsim": round(noise_ss, 4),
            "blobsFirst": blobs[0], "blobsMax": max(blobs), "blobsFinalNoise": bmax,
            "pops": len(pops), "popTimes": pops,
            "auc": round(auc, 4), "aucBig": round(aucb, 4), "noiseMad": round(noise_mad, 3),
            "noiseBig": round(noise_big, 3), "madMax": round(mad_max, 3), "bigMax": round(big_max, 3),
            "popMax": round(pop_max, 3), "noiseLow": round(lnoise, 3), "noiseEdge": round(enoise, 3),
            "lumaFirst": round(luma[0], 2), "lumaFinal": round(lfin, 2),
            "lumaDelta": round(lfin - luma[0], 2), "lumaSettleS": round(_first_ok(lok, ts), 3),
            "lumaKind": kind, "lumaTauS": tau, "lumaAmp": amp,
            "t": r3(ts), "mad": r3(mad), "big": r3(big), "luma": r3(luma), "ssim": [round(v, 4) for v in ss],
            "lowMad": r3(lmad), "edgeMad": r3(emad), "blobs": blobs}


def strip_indices(ts, times=STRIP_TIMES):
    """Frame indices nearest to each wanted time (repeats dropped) plus the last frame (the 'final' look)."""
    idx = []
    for want in times:
        i = min(range(len(ts)), key=lambda j: abs(ts[j] - want))
        if i not in idx:
            idx.append(i)
    if len(ts) - 1 not in idx:
        idx.append(len(ts) - 1)
    return idx


def write_strip(path, frames, times=STRIP_TIMES):
    """Contact strip of a turn: frames nearest t = 0, 0.2, 0.5, 1, 2 s and the last one, left to right."""
    idx = strip_indices([t for t, _ in frames], times)
    w, h, pix = imgcmp.hstack([frames[i][1] for i in idx])
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    imgcmp.write_png(path, w, h, pix)
    return [round(frames[i][0], 2) for i in idx]


# ---------------------------------------------------------------- per variant

KEYS = (("settleS", "settle s (SSIM)", "{:.2f}"), ("lightSettleS", "lighting settle s", "{:.2f}"),
        ("popSettleS", "pop-in settle s", "{:.2f}"), ("auc", "AUC", "{:.2f}"), ("pops", "pops", "{:.1f}"),
        ("blobsFirst", "missing regions at t=0", "{:.1f}"), ("lumaSettleS", "luma settle s", "{:.2f}"),
        ("lumaDelta", "luma change", "{:+.1f}"))
TIME_KEYS = ("settleS", "lightSettleS", "popSettleS", "lumaSettleS")


def summarise(slots, variants, interval=0.1):
    """slots: result slot rows with 'variant' and 'turns' [analyse_turn dicts + 'heading']. -> {'base', 'variants':
    [row]}: per variant the median over all its turns of every KEYS metric, 'slotSpread' (max - min of the per-slot
    medians), 'delta' / 'quiet' against the first variant (quiet = within the larger spread of the two, or one capture
    interval for the times) and the base's noise reference."""
    base = variants[0].name
    rows = []
    for v in variants:
        sl = [s for s in slots if s["variant"] == v.name and s.get("turns")]
        turns = [t for s in sl for t in s["turns"] if "error" not in t]
        row = {"name": v.name, "slots": len(sl), "turns": len(turns), "failed": sum(len(s["turns"]) for s in sl) - len(turns)}
        spread = {}
        for key, _, _ in KEYS:
            row[key] = _med([t[key] for t in turns])
            per = [_med([t[key] for t in s["turns"] if "error" not in t]) for s in sl]
            per = [x for x in per if x is not None]
            spread[key] = max(per) - min(per) if len(per) > 1 else None
        row["slotSpread"] = spread
        kinds = [t["lumaKind"] for t in turns]
        row["lumaKind"] = max(set(kinds), key=kinds.count) if kinds else None
        row["lumaKinds"] = {kd: kinds.count(kd) for kd in sorted(set(kinds))}
        row["lumaTauS"] = _med([t["lumaTauS"] for t in turns if t.get("lumaTauS") is not None])
        row["noiseMad"] = _med([t["noiseMad"] for t in turns])
        row["noiseBig"] = _med([t["noiseBig"] for t in turns])
        row["noiseLow"] = _med([t["noiseLow"] for t in turns])
        row["noiseEdge"] = _med([t["noiseEdge"] for t in turns])
        rows.append(row)
    if rows:
        b = rows[0]
        for row in rows[1:]:
            row["delta"], row["quiet"] = {}, {}
            for key, _, _ in KEYS:
                if row[key] is None or b[key] is None:
                    continue
                dlt = row[key] - b[key]
                tol = max(row["slotSpread"][key] or 0.0, b["slotSpread"][key] or 0.0,
                          interval if key in TIME_KEYS else 0.0)
                row["delta"][key] = round(dlt, 4)
                row["quiet"][key] = abs(dlt) <= tol
    return {"base": base, "variants": rows, "interval": interval}


def _f(fmt, v):
    return "-" if v is None else fmt.format(v)


def report_lines(ts, cfg):
    """Markdown lines of the 'Turn settle' section. cfg = result['spin']['turnSettle']."""
    rows = ts["variants"]
    if not rows:
        return []
    out = ["", "## Turn settle: time until the picture is complete after a turn", "",
           f"{cfg['turns']} snap turn(s) per slot to heading(s) {', '.join(f'{h:g}' for h in cfg['headings'])} "
           f"(camera waited {cfg['hold']:g} s looking {'away from' if cfg['from'] == 'back' else 'to the left of'} the target), "
           f"window captured every {cfg['interval']:g} s for {cfg['secs']:g} s; achieved capture every "
           f"{_f('{:.2f}', cfg.get('achievedInterval'))} s ({_f('{:.0f}', cfg.get('grabMs'))} ms per grab). Median over the "
           "variant's turns; `~` = change within the slot-to-slot spread (or one capture interval).", "",
           "| variant | turns | " + " | ".join(lbl for _, lbl, _ in KEYS) + " |",
           "|---|---:|" + "---:|" * len(KEYS)]
    for i, r in enumerate(rows):
        cells = []
        for key, _, fmt in KEYS:
            c = _f(fmt, r.get(key))
            if i and key in (r.get("delta") or {}):
                c += f" ({r['delta'][key]:+.2f}{'~' if r['quiet'][key] else ''})"
            cells.append(c)
        out.append(f"| {r['name']} | {r['turns']}" + (f" ({r['failed']} failed)" if r.get("failed") else "") + " | "
                    + " | ".join(cells) + " |")
    out += ["", "Luminance curve and noise reference:", "", "| variant | curve | time constant s | noise: mad / big % / lowpass / edge |",
            "|---|---|---:|---|"]
    for r in rows:
        kinds = ", ".join(f"{n} {k}" for k, n in (r.get("lumaKinds") or {}).items())
        out.append(f"| {r['name']} | {kinds or '-'} | {_f('{:.2f}', r.get('lumaTauS'))} | {_f('{:.2f}', r.get('noiseMad'))} / "
                   f"{_f('{:.2f}', r.get('noiseBig'))} / {_f('{:.2f}', r.get('noiseLow'))} / {_f('{:.2f}', r.get('noiseEdge'))} |")
    out += ["", "Reference = mean of the last 0.5 s. settle (total) = first time from which SSIM to the reference stays above "
            "max(0.5, min(0.98, 1 - 2 x (1 - tail SSIM noise))); lighting settle = same for the difference of 1/8-scale "
            "(heavily blurred) frames, Lumen / exposure / fog convergence; pop-in settle = first time from which the Sobel edge-map "
            "difference is within 2 x noise and no strong reference edge region (>= 3 px) is missing, late objects / geometry / "
            "texture detail; missing regions at t=0 = such regions in the first frame. Luminance curve: exponential = monotone "
            "with a linear ln|L - final| fit (R2 >= 0.8; time constant of the fit: eye adaptation), monotone (time constant = "
            "time to 37 % of the gap), stepwise = two or more jumps (lighting / shadow pages), non-monotone, flat. The "
            "mean-abs-difference settle is kept per turn as settleMadS; pops = "
            "frame-to-frame jumps after 0.2 s above max(0.3 %, 2 x noise) strongly different pixels; AUC = integral of "
            "the difference to the final picture above the noise, over the capture. HUD / MangoHud masked. Frame strips "
            "(t = 0, 0.2, 0.5, 1, 2 s, final): [images.md](images.md#turn-settle).", ""]
    return out


def write_gallery(run_dir, slots):
    """Appends the '## Turn settle' section to images.md (created when --shots did not)."""
    run_dir = Path(run_dir)
    lines = ["", "<a id=\"turn-settle\"></a>", "## Turn settle", "",
             "Frames of every turn at t = 0, 0.2, 0.5, 1, 2 s after the snap (nearest captured) and the last one, left to "
             "right. Luminance only.", ""]
    for s in slots:
        for t in s.get("turns") or []:
            if t.get("strip"):
                lines += [f"### {s['variant']} slot {s.get('slot')} @ {t['heading']:g}: settle "
                          f"{_f('{:.2f}', t.get('settleS'))} s, pops {t.get('pops')}, AUC {_f('{:.2f}', t.get('auc'))}", "",
                          f"![{s['variant']} {t['heading']:g}]({t['strip']})", ""]
    f = run_dir / "images.md"
    head = "" if f.exists() and f.read_text() else "# Image comparison\n"
    with open(f, "a") as fh:
        fh.write(head + "\n".join(lines))
    return "images.md"
