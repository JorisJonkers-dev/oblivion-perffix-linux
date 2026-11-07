#!/usr/bin/env python3
"""Rank GPU time per pass from a RADV u_trace CSV (MESA_VK_TRACE=ranges, MESA_GPU_TRACES=print_csv).

  utrace_report.py TRACE.csv [--frames A:B] [--internal-res 1506x847] [--output-res 2560x1440]
                             [--names names.json] [--top 25] [--timeline FRAME] [--json OUT]

Input columns: frame,batch,time_ns,event,params  (one line per begin/end tracepoint, GPU timestamps in ns).
Events nest: radv_begin_cmd_buffer > radv_begin_rendering > radv_begin_Draw ... A range's duration is
end - begin; its exclusive time is the duration minus its children, so the exclusive times of one command
buffer sum to its duration (nothing is counted twice).

Tables (all in ms per frame, averaged over the selected frames):
  1. frame summary       traced GPU time, split draw / dispatch / sync / copies / rendering overhead / untraced gaps
  2. render passes       vkCmdBeginRendering ranges grouped by render area + attachment count
  3. pipelines           draws and dispatches grouped by RADV pipeline hash (+ grid for dispatches)
  4. dispatch shapes     compute dispatches grouped by grid size (screen-space shape hints)
  5. timeline (optional) one frame in submission order, consecutive similar events folded into runs

Caveat: every tracepoint inserts a PS+CS partial flush and a cache flush (see radv_utrace_write_timestamp), so
work that normally overlaps runs back to back. Traced ms are inflated and sum to MORE than the real frame time;
read the shares (%) and the ranking, not the absolute numbers. Pass --real-ms to scale to the measured frame time.
"""
import argparse
import collections
import json
import re
import sys

PARAM_RE = re.compile(r"(\w+)=([^,\s]+)")


def parse_params(s):
    return {k: v for k, v in PARAM_RE.findall(s or "")}


def kind_of(name):
    """name without the radv_begin_/radv_end_ prefix -> coarse kind."""
    if name == "cmd_buffer":
        return "cmd_buffer"
    if name == "rendering":
        return "rendering"
    if name == "secondary":
        return "secondary"
    if name.startswith("Draw"):
        return "draw"
    if name.startswith("Dispatch"):
        return "dispatch"
    if name.startswith("TraceRays") or name.startswith("Build") or name.startswith("Copy") and "Acceleration" in name:
        return "rt"
    if name in ("PipelineBarrier2", "WaitEvents2", "SetEvent2", "ResetEvent2"):
        return "sync"
    if name in ("image_transition", "copy_vrs_htile"):
        return "internal"
    if name in ("clear_rendering", "resolve_rendering"):
        return "rendering_internal"
    if name.startswith(("Copy", "Blit", "Resolve", "Clear", "Fill", "Update")) or name.startswith(("compute_copy", "cp_dma")):
        return "copy"
    return "other"


class Node:
    __slots__ = ("name", "kind", "params", "start", "end", "children", "parent")

    def __init__(self, name, params, start, parent):
        self.name = name
        self.kind = kind_of(name)
        self.params = params
        self.start = start
        self.end = start
        self.children = []
        self.parent = parent

    @property
    def dur(self):
        return max(0, self.end - self.start)

    @property
    def excl(self):
        return max(0, self.dur - sum(c.dur for c in self.children))


def last_frame(path):
    """Frame number of the last complete line (reads only the tail of the file)."""
    import os
    with open(path, "rb") as f:
        f.seek(0, os.SEEK_END)
        f.seek(max(0, f.tell() - 65536))
        lines = f.read().decode("ascii", "replace").splitlines()
    for ln in reversed(lines[:-1] if len(lines) > 1 else lines):
        h = ln.split(",", 1)[0]
        if h.isdigit():
            return int(h)
    return 0


def load(path, min_frame=0):
    """-> {frame: [root Node, ...]} (roots are cmd_buffer ranges, in file order)."""
    frames = collections.OrderedDict()
    stacks = {}
    with open(path, newline="") as f:
        next(f, None)  # header
        for line in f:
            parts = line.rstrip("\n").split(",", 4)
            if len(parts) < 4:
                continue
            try:
                frame, batch, t = int(parts[0]), int(parts[1]), int(parts[2])
            except ValueError:
                continue
            if frame < min_frame:
                continue
            ev = parts[3]
            params = parse_params(parts[4]) if len(parts) > 4 else {}
            stack = stacks.setdefault((frame, batch), [])
            if ev.startswith("radv_begin_"):
                name = ev[len("radv_begin_"):]
                n = Node(name, params, t, stack[-1] if stack else None)
                if stack:
                    stack[-1].children.append(n)
                else:
                    frames.setdefault(frame, []).append(n)
                stack.append(n)
            elif ev.startswith("radv_end_"):
                name = ev[len("radv_end_"):]
                # tolerate a missing end: pop to the matching begin
                while stack and stack[-1].name != name:
                    stack.pop()
                if stack:
                    stack[-1].end = t
                    stack.pop()
    return frames


def walk(node):
    yield node
    for c in node.children:
        yield from walk(c)


def parse_res(s):
    if not s:
        return None
    w, h = s.lower().split("x")
    return int(w), int(h)


def extent_hint(w, h, internal, output):
    """Name a render area by its relation to the scene/output resolution."""
    tags = []
    for label, res in (("internal", internal), ("output", output)):
        if not res:
            continue
        rw, rh = res
        for div in (1, 2, 4, 8, 16, 32):
            if abs(w - rw / div) <= 1.5 * max(1, 1) and abs(h - rh / div) <= 1.5:
                tags.append(label if div == 1 else f"{label}/{div}")
                break
            if abs(w - (rw + div - 1) // div) <= 1 and abs(h - (rh + div - 1) // div) <= 1:
                tags.append(label if div == 1 else f"{label}/{div}")
                break
    if tags:
        return tags[0]
    if w == h and w >= 1024:
        return "square large (shadow map / VSM page pool?)"
    if w == h and w <= 512:
        return "square small (atlas/probe/LUT?)"
    if w >= 8192 or h >= 8192:
        return "huge (page pool / atlas?)"
    return ""


def grid_hint(gx, gy, gz, internal, output):
    """A dispatch grid that covers a screen-sized area with common thread-group sizes -> a hint."""
    for label, res in (("internal", internal), ("output", output)):
        if not res:
            continue
        rw, rh = res
        for div in (1, 2, 4, 8, 16):
            w, h = max(1, rw // div), max(1, rh // div)
            for tg in (4, 8, 16, 32):
                if gx == -(-w // tg) and gy == -(-h // tg):
                    return f"{label}{'' if div == 1 else '/' + str(div)} @{tg}x{tg}"
    return ""


class Agg:
    """Per-frame sums of a key, averaged at the end."""

    def __init__(self):
        self.ns = collections.defaultdict(lambda: collections.defaultdict(int))   # key -> frame -> ns
        self.n = collections.defaultdict(lambda: collections.defaultdict(int))    # key -> frame -> count
        self.meta = {}

    def add(self, key, frame, ns, meta=None):
        self.ns[key][frame] += ns
        self.n[key][frame] += 1
        if meta is not None:
            self.meta.setdefault(key, meta)

    def rows(self, nframes):
        out = []
        for k, per in self.ns.items():
            tot = sum(per.values())
            cnt = sum(self.n[k].values())
            out.append((k, tot / nframes / 1e6, cnt / nframes, (tot / cnt / 1e3) if cnt else 0.0, self.meta.get(k)))
        out.sort(key=lambda r: -r[1])
        return out


def analyse(frames, sel, args):
    internal, output = parse_res(args.internal_res), parse_res(args.output_res)
    names = {}
    if args.names:
        with open(args.names) as f:
            names = {k.lower(): v for k, v in json.load(f).items()}
    for item in args.name or []:
        k, _, v = item.partition("=")
        names[k.lower()] = v

    summary = collections.defaultdict(lambda: collections.defaultdict(int))  # category -> frame -> ns
    rp = Agg()
    pipes = Agg()
    shapes = Agg()
    for fr in sel:
        for root in frames[fr]:
            if root.kind != "cmd_buffer":
                continue
            summary["cmd_buffer total"][fr] += root.dur
            for n in walk(root):
                cat = {"draw": "draws", "dispatch": "dispatches", "sync": "barriers/sync", "copy": "copies/clears",
                       "rt": "ray tracing/AS", "internal": "internal transitions",
                       "rendering_internal": "internal clear/resolve"}.get(n.kind)
                if n.kind == "cmd_buffer":
                    summary["gaps between traced ranges"][fr] += n.excl
                elif n.kind == "rendering":
                    summary["render-pass overhead (inside rendering, outside draws)"][fr] += n.excl
                    w, h, c = n.params.get("width", "?"), n.params.get("height", "?"), n.params.get("colors", "?")
                    draws = [x for x in walk(n) if x.kind == "draw"]
                    hint = extent_hint(int(w), int(h), internal, output) if w != "?" else ""
                    rp.add((w, h, c), fr, n.dur, hint)
                    rp.n[(w, h, c, "draws")][fr] += len(draws)
                elif cat:
                    if n.kind == "internal":
                        if n.parent is not None and n.parent.kind != "sync":
                            summary[cat][fr] += n.dur
                    else:
                        summary[cat][fr] += n.dur
                if n.kind == "draw":
                    p = n.params.get("pipeline", "0x0")
                    pipes.add(("draw", p), fr, n.dur, None)
                elif n.kind == "dispatch":
                    p = n.params.get("pipeline", "0x0")
                    g = (n.params.get("x", "?"), n.params.get("y", "?"), n.params.get("z", "?"))
                    pipes.add(("dispatch", p), fr, n.dur, None)
                    gh = ""
                    if "?" not in g:
                        gh = grid_hint(int(g[0]), int(g[1]), int(g[2]), internal, output)
                    shapes.add((p,) + g, fr, n.dur, gh)
    return summary, rp, pipes, shapes, names


def fmt_pct(x, tot):
    return f"{100 * x / tot:5.1f}%" if tot else "    -"


def timeline(frames, fr, args):
    """Fold the top-level events of one frame into runs; yield (offset_ms, dur_ms, text)."""
    internal, output = parse_res(args.internal_res), parse_res(args.output_res)
    roots = [r for r in frames[fr] if r.kind == "cmd_buffer"]
    if not roots:
        return
    t0 = min(r.start for r in roots)
    runs = []
    for root in roots:
        for c in root.children:
            if c.kind == "rendering":
                w, h = c.params.get("width", "?"), c.params.get("height", "?")
                nd = sum(1 for x in walk(c) if x.kind == "draw")
                hint = extent_hint(int(w), int(h), internal, output) if w != "?" else ""
                sig = ("rendering", w, h, c.params.get("colors", "?"))
                text = f"render {w}x{h} c={sig[3]} {hint}".rstrip()
                runs.append([sig, text, c.start, c.end, 1, nd])
            elif c.kind == "dispatch":
                p = c.params.get("pipeline", "0x0")
                g = f"{c.params.get('x','?')}x{c.params.get('y','?')}x{c.params.get('z','?')}"
                sig = ("dispatch", p, g)
                runs.append([sig, f"dispatch pipe={p} grid={g}", c.start, c.end, 1, 0])
            else:
                sig = (c.kind,)
                runs.append([sig, c.name, c.start, c.end, 1, 0])
    folded = []
    for r in runs:
        if folded and folded[-1][0] == r[0]:
            folded[-1][3] = r[3]
            folded[-1][4] += 1
            folded[-1][5] += r[5]
        else:
            folded.append(r)
    for sig, text, s, e, n, nd in folded:
        extra = f" x{n}" if n > 1 else ""
        if sig[0] == "rendering":
            extra += f"  ({nd} draws)"
        yield (s - t0) / 1e6, (e - s) / 1e6, text + extra


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv")
    ap.add_argument("--last", type=int, default=300, help="read only the last N frames of the file (default 300; 0 = all)")
    ap.add_argument("--frames", help="A:B (inclusive) frame numbers to use; default: all but the first 10%% (min 5)")
    ap.add_argument("--internal-res", default="1506x847", help="scene render resolution (default 2560x1440 at 58.8%%)")
    ap.add_argument("--output-res", default="2560x1440")
    ap.add_argument("--names", help="JSON {\"0x<pipeline hash>\": \"label\"}")
    ap.add_argument("--name", action="append", metavar="0xHASH=LABEL")
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--timeline", type=int, metavar="FRAME", help="also print this frame in submission order")
    ap.add_argument("--min-ms", type=float, default=0.02, help="timeline: hide runs shorter than this")
    ap.add_argument("--real-ms", type=float, help="measured frame time; scales the traced ms to it (shares are unchanged)")
    ap.add_argument("--json", help="write the tables as JSON")
    a = ap.parse_args(argv)

    frames = load(a.csv, max(0, last_frame(a.csv) - a.last) if a.last else 0)
    if not frames:
        raise SystemExit(f"{a.csv}: no trace events (is the driver built with radv-u_trace and MESA_VK_TRACE=ranges set?)")
    allf = list(frames)
    if a.frames:
        lo, _, hi = a.frames.partition(":")
        sel = [f for f in allf if int(lo) <= f <= int(hi or lo)]
    else:
        skip = max(1, len(allf) // 10) if len(allf) > 6 else 0
        sel = allf[skip:]
    if not sel:
        raise SystemExit(f"no frames in range; the file has frames {allf[0]}..{allf[-1]}")
    nf = len(sel)
    summary, rp, pipes, shapes, names = analyse(frames, sel, a)

    total = sum(summary["cmd_buffer total"].values()) / nf
    scale = 1.0
    if a.real_ms and total:
        scale = a.real_ms * 1e6 / total
    print(f"{a.csv}: {len(allf)} frames in file, using {sel[0]}..{sel[-1]} ({nf} frames)"
          + (f", scaled x{scale:.3f} to {a.real_ms} ms" if a.real_ms else ""))

    def ms(ns):
        return ns / nf / 1e6 * scale

    tot_ms = ms(sum(summary["cmd_buffer total"].values()))
    print("\n== 1. frame summary (ms/frame, traced - see caveat in --help) ==")
    print(f"{'category':<58}{'ms':>9}{'share':>8}")
    for cat in ("draws", "dispatches", "barriers/sync", "copies/clears", "ray tracing/AS",
                "render-pass overhead (inside rendering, outside draws)", "internal clear/resolve", "internal transitions",
                "gaps between traced ranges"):
        v = ms(sum(summary[cat].values()))
        if v > 0 or cat in ("draws", "dispatches"):
            print(f"{cat:<58}{v:>9.3f}{fmt_pct(v, tot_ms):>8}")
    print(f"{'cmd_buffer total':<58}{tot_ms:>9.3f}")

    print(f"\n== 2. render passes (vkCmdBeginRendering, grouped by area) top {a.top} ==")
    print(f"{'ms':>8}{'share':>8}{'passes':>8}{'draws':>8}{'avg us':>9}  area / attachments / hint")
    shown = 0
    out_json = {"frames": [sel[0], sel[-1]], "render_passes": [], "pipelines": [], "shapes": [], "summary_ms": {
        c: ms(sum(v.values())) for c, v in summary.items()}}
    for key, ms_, cnt, avg_us, hint in rp.rows(nf):
        if len(key) != 3:
            continue
        draws = sum(rp.n[key + ("draws",)].values()) / nf
        print(f"{ms_ * scale:>8.3f}{fmt_pct(ms_ * scale, tot_ms):>8}{cnt:>8.1f}{draws:>8.0f}{avg_us:>9.1f}  "
              f"{key[0]}x{key[1]} c={key[2]} {hint or ''}")
        out_json["render_passes"].append({"w": key[0], "h": key[1], "colors": key[2], "ms": ms_ * scale,
                                          "passes": cnt, "draws": draws, "hint": hint})
        shown += 1
        if shown >= a.top:
            break

    print(f"\n== 3. pipelines (RADV pipeline hash) top {a.top} ==")
    print(f"{'ms':>8}{'share':>8}{'calls':>8}{'avg us':>9}  type   pipeline            label")
    for i, (key, ms_, cnt, avg_us, _) in enumerate(pipes.rows(nf)):
        if i >= a.top:
            break
        label = names.get(key[1].lower(), "")
        print(f"{ms_ * scale:>8.3f}{fmt_pct(ms_ * scale, tot_ms):>8}{cnt:>8.1f}{avg_us:>9.1f}  {key[0]:<8}{key[1]:<20}{label}")
        out_json["pipelines"].append({"type": key[0], "pipeline": key[1], "ms": ms_ * scale, "calls": cnt, "label": label})

    print(f"\n== 4. dispatch shapes (pipeline, grid) top {a.top} ==")
    print(f"{'ms':>8}{'share':>8}{'calls':>8}{'avg us':>9}  pipeline            grid               hint / label")
    for i, (key, ms_, cnt, avg_us, hint) in enumerate(shapes.rows(nf)):
        if i >= a.top:
            break
        label = names.get(key[0].lower(), "")
        print(f"{ms_ * scale:>8.3f}{fmt_pct(ms_ * scale, tot_ms):>8}{cnt:>8.1f}{avg_us:>9.1f}  {key[0]:<20}"
              f"{key[1]}x{key[2]}x{key[3]:<12}{(label + ' ' + (hint or '')).strip()}")
        out_json["shapes"].append({"pipeline": key[0], "grid": list(key[1:]), "ms": ms_ * scale, "calls": cnt,
                                   "hint": hint, "label": label})

    if a.timeline is not None:
        if a.timeline not in frames:
            raise SystemExit(f"--timeline: frame {a.timeline} not in file")
        print(f"\n== 5. timeline of frame {a.timeline} (offset ms, duration ms) ==")
        for off, dur, text in timeline(frames, a.timeline, a):
            if dur >= a.min_ms:
                print(f"{off:>9.3f} {dur:>8.3f}  {text}")
    if a.json:
        with open(a.json, "w") as f:
            json.dump(out_json, f, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
