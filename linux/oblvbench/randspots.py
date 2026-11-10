"""Seeded random-spot benchmarking: a pool of every place in bench/scenarios/*.json, and a temporary scenario of N
static scenes drawn from it (same seed + filters = same spots in the same order). The scenes are ordinary static
scenes, so the normal scenario loader and runner take the result unchanged."""
import json
import math
import random
import re
from pathlib import Path

from . import scenario

DEDUPE_UNITS = 500.0
DAY_HOURS = (7, 17)             # inclusive, whole hours: after sunrise, before dusk
SKIP_KEYS = ("include", "name", "description", "places", "scenes")
# tags that say a place only makes sense in flight / is not a stand-on-the-ground spot
UNSAFE_TAGS = ("unsafe", "underwater", "underground")


def world_group(place):
    """Tamriel (the main world and the city worldspaces), Interior (a cell), ShiveringIsles or Oblivion."""
    if place.get("cell"):
        return "Interior"
    w = place.get("world") or ""
    if w == "Tamriel" or w.endswith("World") and w.startswith(("Cheydinhal", "Tamriel")) or w.startswith("IC"):
        return "Tamriel"
    if w.startswith("SE") or w == "SEWorld":
        return "ShiveringIsles"
    if w.startswith(("Oblivion", "Kvatch")):
        return "Oblivion"
    return "Tamriel" if w.endswith("World") else "Oblivion"


def is_unsafe(place, tags):
    return bool(place.get("unsafe") or place.get("hover") or place.get("random") is False
                or set(tags) & set(UNSAFE_TAGS))


def _scene_places(scene):
    """Place names a scene stands on (static/walk 'at', door legs' 'at'); fly paths have raw points, not places."""
    out = []
    if scene.get("at"):
        out.append(scene["at"])
    for leg in scene.get("legs") or []:
        if isinstance(leg, dict) and leg.get("at"):
            out.append(leg["at"])
    return out


def build_pool(directory=scenario.SCENARIO_DIR):
    """Every usable place of every scenario, deduplicated by position (within DEDUPE_UNITS in the same world/cell;
    the first in scenario-name order wins and takes the tags of the ones merged into it)."""
    entries = []
    for name in scenario.list_scenarios(directory):
        try:
            scn = scenario.load_scenario(name, directory)
        except (ValueError, FileNotFoundError, json.JSONDecodeError):
            continue
        tags = {}
        for s in scn["scenes"]:
            if s.get("type") == "fly":
                continue            # path points are not places; only a named place with a heading is a spot
            for p in _scene_places(s):
                tags.setdefault(p, set()).update(t for t in scenario.scene_tags(s) if t and t != "static")
        for pname in sorted(scn["places"]):
            pl = scn["places"][pname]
            pos = pl.get("pos")
            if not (pos and len(pos) >= 3 and pl.get("heading") is not None and (pl.get("world") or pl.get("cell"))):
                continue
            t = set(tags.get(pname, ()))
            if is_unsafe(pl, t):
                continue
            group = world_group(pl)
            t |= {group.lower(), "interior" if group == "Interior" else "exterior"}
            entries.append({"id": f"{name}.{pname}", "scenario": name, "place": pname,
                            "world": pl.get("world"), "cell": pl.get("cell"), "group": group,
                            "pos": [float(c) for c in pos[:3]], "heading": float(pl["heading"]),
                            "pitch": float(pl.get("pitch", 0)), "tags": t,
                            "weathers": dict(scn["weathers"]), "place_def": dict(pl)})
    pool = []
    for e in entries:
        key = e["cell"] or e["world"]
        for k in pool:
            if (k["cell"] or k["world"]) == key and math.dist(k["pos"], e["pos"]) < DEDUPE_UNITS:
                k["tags"] |= e["tags"]
                k.setdefault("merged", []).append(e["id"])
                break
        else:
            pool.append(e)
    for e in pool:
        e["tags"] = sorted(e["tags"])
    return pool


def pool_summary(pool):
    by_tag, by_group = {}, {}
    for e in pool:
        by_group[e["group"]] = by_group.get(e["group"], 0) + 1
        for t in e["tags"]:
            by_tag[t] = by_tag.get(t, 0) + 1
    return by_group, dict(sorted(by_tag.items(), key=lambda kv: (-kv[1], kv[0])))


def _csv(v):
    if not v:
        return []
    if isinstance(v, str):
        v = [v]
    return [x.strip() for item in v for x in item.split(",") if x.strip()]


def filter_pool(pool, tags=None, worlds=None):
    """tags: keep spots with any of them; worlds: a group (Tamriel, Interior, ShiveringIsles, Oblivion) or a world/cell
    name. Case-insensitive."""
    tags, worlds = [t.lower() for t in _csv(tags)], [w.lower() for w in _csv(worlds)]
    out = []
    for e in pool:
        if tags and not set(tags) & {t.lower() for t in e["tags"]}:
            continue
        if worlds and not ({e["group"].lower(), (e["world"] or "").lower(), (e["cell"] or "").lower()} & set(worlds)):
            continue
        out.append(e)
    return out


def _weather_ok(name, group):
    """SE* weathers belong to the Shivering Isles, Oblivion* to the Oblivion planes, the rest to Tamriel/interiors."""
    if name.startswith("SE"):
        return group == "ShiveringIsles"
    if name.startswith("Oblivion"):
        return group == "Oblivion"
    return group not in ("ShiveringIsles", "Oblivion")


def draw_spots(pool, n, seed, tags=None, worlds=None, hours="day", weather="Clear"):
    """N spots (fewer if the filtered pool is smaller) as dicts with the pool entry's fields plus hour and weather.
    weather: a name (default Clear), 'any' (any weather of the spot's scenario that suits its world) or a comma list."""
    if hours not in ("day", "any"):
        raise ValueError("--random-hours must be day or any")
    cand = sorted(filter_pool(pool, tags, worlds), key=lambda e: e["id"])
    if not cand:
        raise ValueError("no places match --random-tags/--random-worlds")
    rng = random.Random(f"random-spots:{seed}")
    picked = rng.sample(cand, min(int(n), len(cand)))
    wl = _csv(weather) or ["Clear"]
    out = []
    for e in picked:
        d = dict(e)
        d["hour"] = rng.randint(*DAY_HOURS) if hours == "day" else rng.randint(0, 23)
        names = list(e["weathers"]) if wl == ["any"] else wl
        names = [w for w in names if _weather_ok(w, e["group"])] or ["Clear"]
        d["weather"] = rng.choice(names) if len(names) > 1 else names[0]
        out.append(d)
    return out


def spot_id(i, spot):
    return f"r{i:02d}-{re.sub(r'[^A-Za-z0-9]+', '-', spot['scenario'] + '-' + spot['place']).strip('-')}"


def build_scenario(spots, base, seed, name=None):
    """A scenario of static scenes, one per spot, on top of `base` (a loaded scenario: its settings, defaults, masks,
    profile... are kept, so settle/measure are the scenario's)."""
    scn = {k: v for k, v in base.items() if k not in SKIP_KEYS}
    scn["name"] = name or f"random-seed{seed}-n{len(spots)}"
    scn["description"] = f"{len(spots)} seeded random spots (seed {seed}) drawn from bench/scenarios/*.json"
    scn["weathers"] = dict(base.get("weathers", {}))
    scn["places"], scn["scenes"] = {}, []
    for i, s in enumerate(spots, 1):
        sid = spot_id(i, s)
        scn["places"][sid] = {k: v for k, v in s["place_def"].items()}
        for w, fid in s["weathers"].items():
            scn["weathers"].setdefault(w, fid)
        scn["scenes"].append({
            "id": sid, "type": "static", "at": sid, "hour": s["hour"], "weather": s["weather"],
            "tags": [t for t in s["tags"] if t not in ("static",)],
            "comment": f"{s['scenario']}.{s['place']} ({s['cell'] or s['world']}), hour {s['hour']}, {s['weather']}"})
    return scn


def write_scenario(scn, directory, filename="scenario.json"):
    d = Path(directory)
    d.mkdir(parents=True, exist_ok=True)
    (d / filename).write_text(json.dumps(scn, indent=1))
    return d / filename


def describe(spots):
    lines = []
    for i, s in enumerate(spots, 1):
        x, y, z = s["pos"]
        lines.append(f"  {i:>2}. {s['scenario']}.{s['place']:<26} {s['cell'] or s['world']:<26} "
                     f"({x:.0f},{y:.0f},{z:.0f}) h{s['heading']:.0f}  hour {s['hour']:>2}  {s['weather']:<8} "
                     f"{','.join(s['tags'])}")
    return "\n".join(lines)
