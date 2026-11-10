"""bench.py spin --shots: the picture side. Capturing happens in SpinRunner (a short shot lap after every slot);
this module holds what needs no game: heading lists and file names, comparing the saved pictures of each variant with
the base's at the same heading (SSIM with the base-vs-base noise floor, PSNR, share of strongly different pixels, HUD
and overlay masked), the side-by-side pictures and the images.md gallery. Every pair is registered first (the
translation between the two pictures is estimated and only the overlap compared, see imgcmp.align), so a camera that
is a few pixels off does not turn every edge into a difference; the shift found is reported."""
import json
import statistics
from pathlib import Path

from . import detail, imgcmp, scenario, spin

DEFAULT_HEADINGS = [0, 45, 90, 135, 180, 225, 270, 315]       # the eight sector centres
SHOTS_DIR = "shots"
SBS_DIR = "shots/sbs"


def parse_headings(text):
    """'0,45,90' -> [0.0, 45.0, 90.0] (degrees, 0..360, no repeats)."""
    try:
        hs = [float(x) % 360.0 for x in str(text).replace(" ", "").split(",") if x != ""]
    except ValueError:
        raise ValueError(f"--shot-headings expects comma separated degrees, got {text!r}")
    if not hs:
        raise ValueError("--shot-headings is empty")
    if len(set(hs)) != len(hs):
        raise ValueError("--shot-headings has a heading twice")
    return hs


def heading_name(h):
    h = float(h) % 360.0
    return f"{int(h):03d}" if h == int(h) else f"{h:05.1f}".replace(".", "_")


def shot_rel(variant, slot, h):
    """Run-folder relative path of a capture: shots/<variant>/s<slot>/<heading>.png (slot counts from 1)."""
    return f"{SHOTS_DIR}/{variant}/s{slot}/{heading_name(h)}.png"


def all_masks(scn_masks):
    return list(scn_masks or []) + [detail.OVERLAY_MASK]


def _med(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def _mean(v):
    v = [x for x in v if x is not None]
    return sum(v) / len(v) if v else None


REG_MIN_NCC = 0.5          # a registration below this (or at the search limit) is flagged as not trustworthy


def _pair_stats(run_dir, ra, rb, masks, th, step, register=True, search=24):
    """-> (a, b, stats): the two pictures (cropped to their overlap when registered) and compare()'s numbers plus
    shift [dx, dy], ncc and regOk."""
    a = imgcmp.read_gray_png(Path(run_dir) / ra)
    b = imgcmp.read_gray_png(Path(run_dir) / rb)
    if not register:
        return a, b, imgcmp.compare(a, b, masks, th, step)
    ca, cb, cm, info = imgcmp.align(a, b, masks, search)
    st = imgcmp.compare(ca, cb, cm, th, step)
    st["shift"] = [info["dx"], info["dy"]]
    st["ncc"] = info["ncc"]
    st["regOk"] = bool(info["ncc"] is not None and info["ncc"] >= REG_MIN_NCC and not info["atEdge"])
    return ca, cb, st


def _shift_mag(v):
    return max(abs(v["shift"][0]), abs(v["shift"][1])) if v.get("shift") else None


def analyse(run_dir, slots, variants, masks, headings, pairs=2, thresh=24, step=2, gain=4, say=None, src_dir=None,
            register=True, search=24):
    """slots: result slot rows with 'variant' and 'shots' {heading name: rel path}. Compares every non-base variant
    with the first variant. Writes shots/sbs/<variant>/<heading>.png and images.md. Returns
    {'base', 'headings', 'variants': {name: {...}}, 'gallery'}; variant entries hold ssim (mean over headings of the
    per-heading median over the compared slot pairs), noiseFloor (base against its own other slots), drop
    (noiseFloor - ssim, per heading then averaged), psnr, bigPct, dLuma, worst (heading name with the biggest drop)
    shift, regOk and perHeading. Pictures are read from `src_dir` (default run_dir; reshots reads the original run's
    shots and writes into a new folder); `register` False compares as captured."""
    run_dir = Path(run_dir)
    src_dir = Path(src_dir) if src_dir else run_dir
    names = [heading_name(h) for h in headings]
    base = variants[0].name
    by = {}
    for s in slots:
        if s.get("shots"):
            by.setdefault(s["variant"], []).append(s["shots"])
    out = {"base": base, "headings": names, "variants": {}, "pairs": pairs, "step": step, "registered": bool(register),
           "search": search}
    if base not in by:
        out["note"] = "no base captures"
        return out
    bshots = by[base]
    noise = {}
    for hn in names:
        vals = []
        for k in range(min(pairs, len(bshots) - 1)):
            ra, rb = bshots[k].get(hn), bshots[k + 1].get(hn)
            if ra and rb:
                vals.append(_pair_stats(src_dir, ra, rb, masks, thresh, step, register, search)[2])
        noise[hn] = {k: _med([v.get(k) for v in vals]) for k in ("ssim", "psnr", "bigPct")} if vals else None
        if vals and register:
            noise[hn]["shift"] = [v["shift"] for v in vals]
            noise[hn]["regOk"] = sum(1 for v in vals if v["regOk"])
            noise[hn]["pairs"] = len(vals)
    nf = _mean([(noise[h] or {}).get("ssim") for h in names])
    out["variants"][base] = {"name": base, "ssim": None, "noiseFloor": None if nf is None else round(nf, 5),
                             "noisePsnr": _med([(noise[h] or {}).get("psnr") for h in names]),
                             "noiseBigPct": _med([(noise[h] or {}).get("bigPct") for h in names]),
                             "noiseFloorPerHeading": {h: (noise[h] or {}).get("ssim") for h in names},
                             "noiseShifts": {h: (noise[h] or {}).get("shift") for h in names} if register else None,
                             "noiseRegOk": [sum((noise[h] or {}).get("regOk", 0) for h in names),
                                            sum((noise[h] or {}).get("pairs", 0) for h in names)] if register else None}
    for v in variants[1:]:
        vshots = by.get(v.name, [])
        per = {}
        for hn in names:
            res = []
            for k in range(min(pairs, len(bshots), len(vshots))):
                ra, rb = bshots[k].get(hn), vshots[k].get(hn)
                if not (ra and rb):
                    continue
                try:
                    a, b, st = _pair_stats(src_dir, ra, rb, masks, thresh, step, register, search)
                except (imgcmp.ImageError, OSError) as e:
                    if say:
                        say(f"images {v.name} {hn}: {e}")
                    continue
                res.append((st, a, b, ra, rb))
            if not res:
                continue
            res.sort(key=lambda r: r[0]["ssim"] if r[0]["ssim"] is not None else 1.0)
            st, a, b, ra, rb = res[len(res) // 2]               # the median-SSIM pair is the one shown
            sbs = f"{SBS_DIR}/{v.name}/{hn}.png"
            (run_dir / sbs).parent.mkdir(parents=True, exist_ok=True)
            w, h, rgb = imgcmp.side_by_side(a, b, masks, gain)
            imgcmp.write_png(run_dir / sbs, w, h, rgb, 3)
            ssims = [r[0]["ssim"] for r in res]
            nfh = (noise[hn] or {}).get("ssim")
            ss = _med(ssims)
            per[hn] = {"ssim": round(ss, 5), "noiseFloor": nfh, "drop": round((nfh if nfh is not None else 1.0) - ss, 5),
                       "psnr": _med([r[0]["psnr"] for r in res]), "bigPct": _med([r[0]["bigPct"] for r in res]),
                       "dLuma": _med([r[0]["dLuma"] for r in res]), "pairs": len(res), "sideBySide": sbs}
            if register:
                per[hn]["shift"] = st["shift"]                    # of the pair shown
                per[hn]["shifts"] = [r[0]["shift"] for r in res]
                per[hn]["regOk"] = sum(1 for r in res if r[0]["regOk"])
        row = {"name": v.name, "perHeading": per, "headings": len(per)}
        if per:
            row["ssim"] = round(_mean([d["ssim"] for d in per.values()]), 5)
            row["noiseFloor"] = out["variants"][base]["noiseFloor"]
            row["drop"] = round(_mean([d["drop"] for d in per.values()]), 5)
            row["worstDrop"], row["worst"] = max((d["drop"], hn) for hn, d in per.items())
            for k in ("psnr", "bigPct", "dLuma"):
                row[k] = round(_mean([d[k] for d in per.values()]), 3)
            row["noiseFloorKnown"] = nf is not None
        out["variants"][v.name] = row
    out["gallery"] = write_gallery(run_dir, out)
    return out


def write_gallery(run_dir, images):
    base = images["base"]
    lines = ["# Image comparison", "",
             f"Each picture: `{base}` (left) | variant (middle) | amplified difference (right: black = same, red/yellow/"
             f"white = bigger; dark blue = masked HUD / overlay). Grayscale luminance of the game window, captured after "
             f"the camera held the heading for the settle time.", ""]
    nf = images["variants"].get(base, {})
    if nf.get("noiseFloor") is not None:
        lines += [f"Noise floor (`{base}` against its own other slots): SSIM {nf['noiseFloor']:.4f}"
                  f", PSNR {_f(nf.get('noisePsnr'))} dB, {_f(nf.get('noiseBigPct'))} % pixels strongly different. "
                  "A variant is only worse than that floor by what it loses beyond it.", ""]
    if images.get("registered"):
        ok = nf.get("noiseRegOk")
        lines += ["Pairs are registered before comparing: the translation between the two pictures is estimated "
                  f"(normalised cross-correlation, +-{images.get('search', 24)} px) and only the overlap is compared; "
                  "`shift` is dx,dy in pixels of the second picture against the first"
                  + (f" ({ok[0]} of {ok[1]} base-vs-base registrations trustworthy)" if ok and ok[1] else "")
                  + ". `reg` = trustworthy registrations / pairs (not trustworthy = correlation under "
                  f"{REG_MIN_NCC:g} or at the search limit: the pictures show different views).", ""]
    for name, row in images["variants"].items():
        if name == base:
            continue
        lines += [f"## {name}", ""]
        if not row.get("perHeading"):
            lines += ["No pictures compared.", ""]
            continue
        lines += [f"Mean SSIM {row['ssim']:.4f} (floor {_f(row['noiseFloor'], 4)}, drop {row['drop']:+.4f}), "
                  f"PSNR {row['psnr']:.1f} dB, {row['bigPct']:.2f} % pixels strongly different, "
                  f"worst heading {row['worst']}.", "",
                  "| heading | SSIM | floor | drop | PSNR | big diff % | shift | reg |", "|---|---:|---:|---:|---:|---:|---|---:|"]
        for hn, d in row["perHeading"].items():
            sh = d.get("shift")
            lines.append(f"| {hn} | {d['ssim']:.4f} | {_f(d['noiseFloor'], 4)} | {d['drop']:+.4f} | {_f(d['psnr'], 1)} | "
                         f"{_f(d['bigPct'], 2)} | {'-' if sh is None else f'{sh[0]:+d},{sh[1]:+d}'} | "
                         f"{'-' if 'regOk' not in d else str(d['regOk']) + '/' + str(d['pairs'])} |")
        lines.append("")
        for hn, d in row["perHeading"].items():
            lines += [f"### {name} @ {hn}", "", f"![{name} {hn}]({d['sideBySide']})", ""]
    (Path(run_dir) / "images.md").write_text("\n".join(lines))
    return "images.md"


def _f(v, nd=2):
    return "-" if v is None else f"{v:.{nd}f}"


def reshots(src, out, pairs=None, thresh=None, step=2, gain=4, register=True, search=24, thresholds=None, say=print):
    """Re-runs the image comparison of the finished spin run `src` (its shots/ and result.json) into the new folder
    `out`: images.md, shots/sbs, result.json and report.md with fresh SSIM numbers and verdicts. The original is not
    touched; the new result.json still names the shots by their paths inside `src`. Returns the new result."""
    src, out = Path(src), Path(out)
    r = json.loads((src / "result.json").read_text())
    sp, sh = r.get("spin") or {}, (r.get("spin") or {}).get("shots")
    if not sh:
        raise ValueError(f"{src} has no shots (it was not run with --shots)")
    if out.resolve() == src.resolve():
        raise ValueError("reshots writes a new folder, not the original")
    variants = [spin.Variant(v["name"]) for v in sp.get("variantSpecs") or [{"name": x["name"]} for x in r["variants"]]]
    headings = [float(h) for h in sh["headings"]]
    masks = []
    try:
        scn_dir = src if (src / "scenario.json").exists() and r.get("scenario") == "scenario" else scenario.SCENARIO_DIR
        masks = scenario.load_scenario(r["scenario"], scn_dir).get("masks") or []
    except (OSError, ValueError, KeyError) as e:
        say(f"reshots: scenario masks not available ({e}); only the MangoHud overlay is masked")
    th = {**spin.THRESHOLDS, **(sp.get("thresholds") or {}), **{k: v for k, v in (thresholds or {}).items() if v is not None}}
    pairs = pairs or sh.get("pairs", 2)
    thresh = thresh or sh.get("diffThresh", 24)
    out.mkdir(parents=True, exist_ok=True)
    images = analyse(out, r["slots"], variants, all_masks(masks), headings, pairs, thresh, step, gain, say=say,
                     src_dir=src, register=register, search=search)
    r["images"] = images
    sp["thresholds"] = th
    sh.update(pairs=pairs, diffThresh=thresh, register=register, search=search)
    spin.apply_images(r.get("variants") or [], images, th)
    r["reshots"] = {"from": str(src), "register": register, "search": search}
    spin.write_result(out, r)
    return r
