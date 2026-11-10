"""UE4SS for the benchmark: download and check it (tools/Setup-Bench.ps1), put it and the OblvBench mod into the
game's Win64 folder and take it out again (tools/Install-UE4SS.ps1). UE4SS is in the game folder only for
benchmark games; every file and folder the install adds is listed in a manifest, so removal takes out exactly that
(plus what UE4SS itself wrote inside the folders it added) and puts back what was there before."""
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
import urllib.request
import zipfile
from pathlib import Path

from .paths import REPO, to_wine_path

REPO_SLUG = "UE4SS-RE/RE-UE4SS"
TAG = "experimental-latest"
MIN_BUILD = 1181
NAME_RX = re.compile(r"^UE4SS_v3\.0\.1-(\d+)-g[0-9a-f]+\.zip$")
# the build the benchmark mod was tested with upstream (tools/Setup-Bench.ps1)
TESTED = {"build": 1181, "file": "UE4SS_v3.0.1-1181-g83330635.zip",
          "sha256": "b9a166a756605b21058a64cde93bcaab1a855dba3553e5c7e6ce0fa8fdfad7b9", "size": 8748315}
MANIFEST = "ue4ss-manifest.json"
MARKER = "oblvbench-install.json"


def build_of(name):
    m = NAME_RX.match(name)
    return int(m.group(1)) if m else 0


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


# ---------------------------------------------------------------- setup (download + check + unpack)

def release_assets():
    """The experimental-latest release's assets (gh api, else the public API)."""
    try:
        r = subprocess.run(["gh", "api", f"repos/{REPO_SLUG}/releases/tags/{TAG}"], capture_output=True, text=True,
                           timeout=60)
        if r.returncode == 0:
            return json.loads(r.stdout)["assets"]
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError):
        pass
    req = urllib.request.Request(f"https://api.github.com/repos/{REPO_SLUG}/releases/tags/{TAG}",
                                 headers={"User-Agent": "OblivionPerfFix-linux-bench"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)["assets"]


def pick_asset(assets, min_build=MIN_BUILD):
    """The newest official UE4SS_v3.0.1-<build>-g<commit>.zip of build >= min_build (never zDEV-)."""
    ok = [a for a in assets if build_of(a.get("name", "")) >= min_build]
    return max(ok, key=lambda a: build_of(a["name"])) if ok else None


def expected_sha(asset):
    """SHA-256 GitHub lists for the asset ("digest": "sha256:..."), else the pinned hash of the tested zip."""
    m = re.match(r"^sha256:([0-9a-fA-F]{64})$", str(asset.get("digest") or ""))
    if m:
        return m.group(1).lower(), "GitHub's asset digest"
    if asset.get("name") == TESTED["file"]:
        return TESTED["sha256"], "the upstream pinned hash"
    return None, None


def safe_extract(zip_path, dest):
    """Unpacks a zip, refusing entries that would land outside dest."""
    dest = Path(dest).resolve()
    with zipfile.ZipFile(zip_path) as z:
        for info in z.infolist():
            target = (dest / info.filename).resolve()
            if target != dest and dest not in target.parents:
                raise ValueError(f"unsafe path in zip: {info.filename}")
        z.extractall(dest)


def setup(third_party, zip_path=None, update=False, allow_unverified=False, say=print):
    """Gets UE4SS into <third_party>/ue4ss. Returns the unpacked folder."""
    third_party = Path(third_party)
    third_party.mkdir(parents=True, exist_ok=True)
    dest = third_party / "ue4ss"
    mark = dest / "oblvbench-build.txt"
    have = mark.read_text().splitlines()[0].strip() if mark.exists() else None
    if have and not update and not zip_path:
        say(f"ok    already unpacked ({have})")
        return dest
    if zip_path:
        zp = Path(zip_path)
        if build_of(zp.name) < MIN_BUILD and not allow_unverified:
            raise RuntimeError(f"{zp.name} is not an official build {MIN_BUILD} or newer (--allow-unverified accepts it)")
        sha = sha256_file(zp)
        source = f"local file {zp}"
    else:
        try:
            asset = pick_asset(release_assets())
        except Exception as e:     # API unreachable: try the tested build's address
            say(f"GitHub's release list not readable ({e}); trying the tested build's address")
            asset = {"name": TESTED["file"], "size": TESTED["size"], "digest": f"sha256:{TESTED['sha256']}",
                     "browser_download_url": f"https://github.com/{REPO_SLUG}/releases/download/{TAG}/{TESTED['file']}"}
        if not asset:
            raise RuntimeError(f"release {TAG} of {REPO_SLUG} has no UE4SS zip of build {MIN_BUILD} or newer")
        url = asset["browser_download_url"]
        if not url.startswith("https://github.com/"):
            raise RuntimeError(f"unexpected download address {url}")
        want, how = expected_sha(asset)
        if not want and not allow_unverified:
            raise RuntimeError(f"no SHA-256 known for {asset['name']} (--allow-unverified downloads it anyway)")
        zp = third_party / asset["name"]
        if zp.exists() and want and sha256_file(zp) == want:
            say(f"ok    {zp.name} already downloaded (SHA-256 matches {how})")
        else:
            tmp = zp.with_name(zp.name + ".download")
            say(f"get   {url} ({asset.get('size', 0) / 2**20:.1f} MB)")
            req = urllib.request.Request(url, headers={"User-Agent": "OblivionPerfFix-linux-bench"})
            with urllib.request.urlopen(req, timeout=300) as resp, open(tmp, "wb") as f:
                shutil.copyfileobj(resp, f)
            got = sha256_file(tmp)
            if want and got != want:
                tmp.unlink()
                raise RuntimeError(f"{asset['name']} has SHA-256 {got}, but {how} is {want} (deleted)")
            os.replace(tmp, zp)
            say(f"ok    {zp.name} downloaded" + (f", SHA-256 matches {how}" if want else ", NOT verified"))
        sha = sha256_file(zp)
        source = f"https://github.com/{REPO_SLUG}/releases/tag/{TAG}"
    build = zp.stem
    tested = "tested build" if sha == TESTED["sha256"] else "newer than tested"
    if have == build and not update:
        say(f"ok    {build} already unpacked")
        return dest
    if dest.exists():
        old = dest.with_name(f"ue4ss.replaced-{time.strftime('%Y%m%d-%H%M%S')}")
        dest.rename(old)
        say(f"moved the previous copy ({have}) to {old}")
    safe_extract(zp, dest)
    if not (dest / "dwmapi.dll").exists() or not (dest / "ue4ss" / "UE4SS.dll").exists():
        raise RuntimeError(f"{zp.name} does not have dwmapi.dll and ue4ss/UE4SS.dll at its top")
    mark.write_text(f"{build}\nsha256={sha}\ntested={tested}\nsource={source}\n")
    say(f"ok    unpacked {build} ({tested}; SHA-256 {sha})")
    return dest


# ---------------------------------------------------------------- install / remove in the game folder

def _insert_mod_line(text, mod):
    """mods.txt with "<mod> : 1" above the built-in Keybinds entry (which must stay last), once."""
    nl = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    if any(re.match(r"^\s*%s\s*:" % re.escape(mod), l) for l in lines):
        return text
    i = next((n for n, l in enumerate(lines) if "Built-in keybinds" in l), len(lines))
    lines.insert(i, f"{mod} : 1")
    return nl.join(lines) + nl


class Installer:
    def __init__(self, win64, runtime, source, project=REPO, game_running=lambda: False, say=print):
        self.win64 = Path(win64)
        self.runtime = Path(runtime)
        self.source = Path(source)
        self.project = Path(project)
        self.game_running = game_running
        self.say = say
        self.manifest_path = self.runtime / MANIFEST

    @property
    def dll(self):
        return self.win64 / "dwmapi.dll"

    @property
    def dir(self):
        return self.win64 / "ue4ss"

    def manifest(self):
        try:
            return json.loads(self.manifest_path.read_text())
        except (OSError, ValueError):
            return None

    def status(self):
        m = self.manifest()
        if m:
            return f"installed by bench.py ({m.get('build')}, {m.get('installed')}) in {self.win64}"
        if self.dll.exists() or self.dir.exists():
            return f"a UE4SS that bench.py did not install is in {self.win64}"
        return f"not installed in {self.win64}"

    def _copy(self, src, dst, m):
        """Copies a file or tree, recording what it creates (relative to Win64)."""
        if src.is_dir():
            if not dst.exists():
                dst.mkdir()
                m["dirs"].append(str(dst.relative_to(self.win64)))
            for child in sorted(src.iterdir()):
                self._copy(child, dst / child.name, m)
        else:
            new = not dst.exists()
            shutil.copy2(src, dst)
            rel = str(dst.relative_to(self.win64))
            if new and rel not in m["files"]:
                m["files"].append(rel)

    def _save(self, m):
        self.runtime.mkdir(parents=True, exist_ok=True)
        self.manifest_path.write_text(json.dumps(m, indent=1))

    def deploy_mods(self, m, runtime_dir=None):
        """The repo's mods/ue4ss/* into ue4ss/Mods, main.lua with the project and runtime folders as Wine paths."""
        mods_dir = self.dir / "Mods"
        if not mods_dir.is_dir():
            raise RuntimeError(f"UE4SS not installed at {self.dir}")
        runtime_dir = runtime_dir or self.runtime
        for mod in sorted(p for p in (self.project / "mods" / "ue4ss").iterdir() if p.is_dir()):
            dest = mods_dir / mod.name
            self._copy(mod, dest, m)
            boot = dest / "Scripts" / "main.lua"
            if boot.exists():
                lua = boot.read_text(encoding="utf-8")
                lua = lua.replace("@PROJECT@", to_wine_path(self.project)).replace("@RUNTIME@", to_wine_path(runtime_dir))
                boot.write_text(lua, encoding="utf-8")
            enabled = dest / "enabled.txt"
            if not enabled.exists():
                enabled.write_text("")
                m["files"].append(str(enabled.relative_to(self.win64)))
            txt = mods_dir / "mods.txt"
            if txt.exists():
                raw = txt.read_bytes().decode("utf-8", errors="surrogateescape")
                txt.write_bytes(_insert_mod_line(raw, mod.name).encode("utf-8", errors="surrogateescape"))
            self.say(f"deployed mod {mod.name}")

    def install(self):
        if self.game_running():
            raise RuntimeError("close the game first")
        if not (self.source / "dwmapi.dll").exists() or not (self.source / "ue4ss" / "UE4SS.dll").exists():
            raise RuntimeError(f"UE4SS not unpacked at {self.source} (run: bench.py setup)")
        mark = self.source / "oblvbench-build.txt"
        build = mark.read_text().splitlines()[0].strip() if mark.exists() else self.source.name
        old = self.manifest()
        if old:
            if old.get("build") == build and (self.dir / "UE4SS.dll").exists():
                self.deploy_mods(old)            # already in place: refresh the mod
                self._save(old)
                self.say(self.status())
                return
            self.remove()
        m = {"build": build, "installed": time.strftime("%Y-%m-%dT%H:%M:%S"), "win64": str(self.win64),
             "files": [], "dirs": [], "backups": {}}
        self._save(m)                            # before the first copy: a failed install can still be removed
        if self.dir.exists():
            backup = self.win64 / "ue4ss.pre-oblvbench"
            if backup.exists():
                raise RuntimeError(f"{self.dir} is not ours and {backup} exists already: sort it out by hand")
            self.dir.rename(backup)
            m["backups"]["ue4ss"] = backup.name
            self.say(f"kept the UE4SS that was there as {backup} (put back on removal)")
        if self.dll.exists():
            backup = self.win64 / "dwmapi.dll.pre-ue4ss"
            if backup.exists():
                raise RuntimeError(f"{self.dll} exists and so does {backup}: sort it out by hand")
            self.dll.rename(backup)
            m["backups"]["dwmapi.dll"] = backup.name
            self.say(f"existing dwmapi.dll kept as {backup}")
        self._save(m)
        try:
            self._copy(self.source / "dwmapi.dll", self.dll, m)
            self._copy(self.source / "ue4ss", self.dir, m)
            marker = self.dir / MARKER
            marker.write_text(json.dumps({"build": build, "source": str(self.source), "by": "linux/bench.py"}))
            m["files"].append(str(marker.relative_to(self.win64)))
            self.deploy_mods(m)
        finally:
            self._save(m)
        self.say(f"UE4SS enabled in {self.win64} ({build}); its log: {self.dir / 'UE4SS.log'}")

    def save_logs(self):
        keep = self.runtime / "ue4ss-logs"
        stamp = time.strftime("%Y%m%d-%H%M%S")
        if not self.dir.is_dir():
            return
        for f in self.dir.iterdir():
            if f.is_file() and (f.name == "UE4SS.log" or f.suffix == ".dmp"):
                keep.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, keep / f"{stamp}-{f.name}")
        logs = sorted(keep.glob("*-UE4SS.log"), reverse=True) if keep.exists() else []
        for old in logs[20:]:
            old.unlink()

    def remove(self):
        if self.game_running():
            raise RuntimeError("close the game first (UE4SS is loaded in it)")
        m = self.manifest()
        if not m:
            self.say(f"nothing to remove: no manifest ({self.status()})")
            return
        self.save_logs()
        for rel in m["files"]:
            p = self.win64 / rel
            if p.is_file() or p.is_symlink():
                p.unlink()
        extra = 0
        for rel in sorted(m["dirs"], key=lambda r: r.count("/"), reverse=True):
            d = self.win64 / rel
            if not d.is_dir():
                continue
            for child in d.iterdir():            # written by UE4SS or the mod at run time, inside our folder
                extra += 1
                shutil.rmtree(child) if child.is_dir() and not child.is_symlink() else child.unlink()
            d.rmdir()
        for name, backup in m.get("backups", {}).items():
            src, dst = self.win64 / backup, self.win64 / name
            if src.exists() and not dst.exists():
                src.rename(dst)
                self.say(f"put back the {name} that was there before")
        self.manifest_path.unlink()
        self.say(f"UE4SS removed from {self.win64}" + (f" ({extra} file(s) it wrote at run time removed too)" if extra else ""))
