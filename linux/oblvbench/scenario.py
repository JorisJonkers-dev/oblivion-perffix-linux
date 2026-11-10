"""Scenarios (bench/scenarios/*.json) and display/quality profiles (bench/profiles.json), read as
tools/BenchBridge.ps1 Get-BenchScenario and tools/Run-Benchmark.ps1 read them."""
import fnmatch
import json
import math
from pathlib import Path

from .paths import REPO

SCENARIO_DIR = REPO / "bench" / "scenarios"
PROFILES_FILE = REPO / "bench" / "profiles.json"


def load_scenario(name, directory=SCENARIO_DIR, _seen=()):
    """A scenario with its "include"s merged in (the including file wins where both define the same thing)."""
    path = Path(directory) / f"{name}.json"
    if not path.exists():
        raise FileNotFoundError(f"no scenario '{name}' ({path})")
    if name in _seen:
        raise ValueError(f"scenario include loop at '{name}'")
    s = json.loads(path.read_text(encoding="utf-8-sig"))
    for key in ("settings", "defaults", "weathers", "places"):
        s.setdefault(key, {})
    for key in ("record", "masks", "scenes"):
        s.setdefault(key, [])
    s.setdefault("name", name)
    for inc in s.get("include", []):
        i = load_scenario(inc, directory, _seen + (name,))
        for key in ("settings", "defaults", "weathers", "places"):
            for k, v in i[key].items():
                s[key].setdefault(k, v)
        s["scenes"] = list(s["scenes"]) + list(i["scenes"])
        s["record"] = list(dict.fromkeys(list(s["record"]) + list(i["record"])))
        if not s["masks"]:
            s["masks"] = i["masks"]
        if "exec" not in s and "exec" in i:
            s["exec"] = i["exec"]
    return s


def list_scenarios(directory=SCENARIO_DIR):
    return sorted(p.stem for p in Path(directory).glob("*.json"))


def scene_tags(scene):
    return [scene.get("type")] + list(scene.get("tags", []))


def select_scenes(scn, patterns=None, tags=None):
    """Scenes by id (wildcards) and/or tag (the type counts as a tag), in scenario order."""
    out = []
    for s in scn["scenes"]:
        if patterns and not any(fnmatch.fnmatchcase(s["id"], p) for p in patterns):
            continue
        if tags and not set(tags) & set(scene_tags(s)):
            continue
        out.append(s)
    return out


def opt(d, key, default=None):
    v = d.get(key) if isinstance(d, dict) else None
    return default if v is None else v


def scene_seconds(scn, s):
    """Rough duration of a scene (Get-SceneSeconds), for the run's time limit."""
    d = scn["defaults"]
    settle = float(opt(s, "settle", opt(d, "settle", 8)))
    t = s.get("type")
    if t == "static":
        return settle + float(opt(s, "measure", opt(d, "measure", 20))) + 6
    if t == "door":
        hold = float(opt(s, "hold", opt(d, "hold", 12)))
        legs = s.get("legs") or [{}, {}]
        total = settle + 6
        for leg in legs:
            total += float(opt(leg, "hold", hold)) + 8 + (settle + 4 if leg.get("at") else 0)
        return total
    if t == "walk":
        return settle + float(opt(s, "measure", opt(d, "measure", 20))) + 8
    if t == "fly":
        p = s.get("path", [])
        length = sum(math.dist(p[i][:3], p[i - 1][:3]) for i in range(1, len(p)))
        return settle + length / float(s["speed"]) + 18
    return 30


# ---------------------------------------------------------------- profiles

QUALITY_OPTIONS = ("ViewDistanceQuality", "ShadowQuality", "GlobalIlluminationQuality", "ReflectionQuality",
                   "PostProcessQuality", "TextureQuality", "EffectsQuality", "FoliageQuality", "ShadingQuality",
                   "ClothQuality")
FSR_SCALE = {0: 100.0, 1: 66.6667, 2: 58.8235, 3: 50.0, 4: 33.3333}


def load_profiles(path=PROFILES_FILE):
    return {k: v for k, v in json.loads(Path(path).read_text(encoding="utf-8-sig")).items() if not k.startswith("_")}


def is_own(p):
    return bool(p.get("own"))


def profile_res(p, native="2560x1440"):
    if is_own(p):
        return None
    r = p.get("res", "1280x720")
    return native if r == "native" else r


def quality_level(p, name):
    return int(opt(p.get("qualityOptions") or {}, name, p.get("quality", 3)))


def profile_commands(p, part="all", native="2560x1440"):
    """Console commands for one part of a profile ('res', 'quality', 'rt', 'upscaler', 'cvars' or 'all'), as
    Get-ProfileCommands. The upscaler only takes a new quality when the method is applied again, so it is switched
    to another method and back."""
    c = []
    if is_own(p):
        return c
    if part in ("all", "res"):
        mode = {"windowed": "w", "borderless": "wf"}.get(p.get("mode", "windowed"))
        if not mode:
            raise ValueError(f"profile mode must be windowed or borderless, not {p.get('mode')!r}")
        c.append(f"exec r.SetRes {profile_res(p, native)}{mode}")
    if part == "all":
        c += ["cvar Altar.GraphicsOptions.VSync 0", "cvar Altar.GraphicsOptions.FrameRateLimit 0", "cvar t.MaxFPS 0"]
    if part in ("all", "quality"):
        c += [f"cvar Altar.GraphicsOptions.{n} {quality_level(p, n)}" for n in QUALITY_OPTIONS]
    if part in ("all", "rt"):
        rt = int(p.get("rt", 1))
        c.append(f"cvar Altar.GraphicsOptions.EnableHardwareRaytracing {rt}")
        if rt:
            c.append("cvar Altar.GraphicsOptions.HardwareRaytracingMode 3")
    if part in ("all", "upscaler"):
        if p.get("upscaler", "fsr") == "fsr":
            c += [f"cvar Altar.FSR3.Quality {int(p.get('fsrQuality', 3))}",
                  f"cvar Altar.FSR3.FI.Enabled {int(p.get('fg', 0))}",
                  "cvar Altar.UpscalingMethod 0", "cvar Altar.UpscalingMethod 2", "cvar r.FidelityFX.FSR3.Enabled 1"]
        else:
            scale = float(p.get("scale", 100))
            c += ["cvar Altar.FSR3.FI.Enabled 0", f"cvar Altar.GraphicsOptions.ScreenPercentage {scale:g}",
                  "cvar Altar.UpscalingMethod 2", "cvar Altar.UpscalingMethod 0", "cvar r.FidelityFX.FSR3.Enabled 0",
                  f"cvar r.ScreenPercentage {scale:g}"]
    if part in ("all", "cvars"):
        c += [f"cvar {k} {v}" for k, v in (p.get("cvars") or {}).items()]
    return c


def profile_expect(p):
    """cvar -> value the profile should read back as (Get-ProfileExpect, without the window size)."""
    e = {}
    if is_own(p):
        return e
    fsr = p.get("upscaler", "fsr") == "fsr"
    e["r.FidelityFX.FSR3.Enabled"] = int(fsr)
    e["r.ScreenPercentage"] = FSR_SCALE[int(p.get("fsrQuality", 3))] if fsr else float(p.get("scale", 100))
    e["r.FidelityFX.FI.Enabled"] = int(p.get("fg", 0)) if fsr else 0
    e["r.Lumen.HardwareRayTracing"] = int(p.get("rt", 1))
    if int(p.get("rt", 1)):
        e["r.Lumen.HardwareRayTracing.LightingMode"] = 3
    for n in QUALITY_OPTIONS[:-1]:
        e[f"sg.{n}"] = quality_level(p, n)
    return e


def drift_part(name):
    if name.startswith("r.Lumen."):
        return "rt"
    if name.startswith("sg."):
        return "quality"
    return "upscaler"
