"""Where the repo, the game, its Proton prefix and the runtime files are."""
import os
import re
from dataclasses import dataclass, field
from pathlib import Path

APP_ID = 2623190
GAME_PROCESS = "OblivionRemastered-Win64-Shipping"
# The shipping exe as Wine shows it in ps: "S:\...\OblivionRemastered-Win64-Shipping.exe" (or Z:\ on another library).
GAME_PGREP = r"^[A-Z]:.*OblivionRemastered-Win64-Shipping"
DEFAULT_GAME_DIR = "/run/media/ExtraToast/Shared/SteamLibrary/steamapps/common/Oblivion Remastered"
LINUX_DIR = Path(__file__).resolve().parent.parent
REPO = LINUX_DIR.parent


def to_wine_path(p, trailing_slash=True):
    """A Linux path as Wine opens it from inside the game: drive Z: is /, forward slashes (as Install-UE4SS.ps1's
    ConvertTo-LuaPath writes them), with a trailing slash for folders that main.lua appends file names to."""
    s = str(Path(p).resolve()).rstrip("/")
    s = "Z:" + s
    return s + "/" if trailing_slash else s


def _steam_libraries():
    """Library folders from Steam's libraryfolders.vdf (read only)."""
    out = []
    for base in ("~/.local/share/Steam", "~/.steam/steam"):
        vdf = Path(base).expanduser() / "steamapps" / "libraryfolders.vdf"
        try:
            text = vdf.read_text(errors="replace")
        except OSError:
            continue
        out += [Path(m.replace("\\\\", "\\")) for m in re.findall(r'"path"\s+"([^"]+)"', text)]
    return out


def find_game_dir():
    env = os.environ.get("OBLIVION_GAME_DIR")
    if env:
        return Path(env)
    candidates = [Path(DEFAULT_GAME_DIR)] + [lib / "steamapps/common/Oblivion Remastered" for lib in _steam_libraries()]
    for c in candidates:
        if (c / "OblivionRemastered/Binaries/Win64").is_dir():
            return c
    return Path(DEFAULT_GAME_DIR)


@dataclass
class Paths:
    game_dir: Path = field(default_factory=find_game_dir)
    runtime: Path = None
    prefix: Path = None
    env_file: Path = None
    results: Path = None

    def __post_init__(self):
        self.game_dir = Path(self.game_dir)
        if self.runtime is None:
            self.runtime = Path(os.environ.get("OBLV_BENCH_RUNTIME") or REPO / "run")
        if self.prefix is None:
            env = os.environ.get("OBLIVION_PREFIX")
            lib_pfx = self.game_dir.parent.parent / "compatdata" / str(APP_ID) / "pfx"
            self.prefix = Path(env) if env else lib_pfx
        if self.env_file is None:
            cfg = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
            self.env_file = cfg / "oblivion-bench" / "env"
        if self.results is None:
            self.results = LINUX_DIR / "results"

    @property
    def win64(self):
        return self.game_dir / "OblivionRemastered" / "Binaries" / "Win64"

    @property
    def exe(self):
        return self.win64 / f"{GAME_PROCESS}.exe"

    @property
    def fix_ini(self):
        return self.win64 / "OblivionPerfFix.ini"

    @property
    def saved(self):
        env = os.environ.get("OBLIVION_SAVED_DIR")
        if env:
            return Path(env)
        return self.prefix / "drive_c/users/steamuser/Documents/My Games/Oblivion Remastered/Saved"

    @property
    def third_party(self):
        return LINUX_DIR / "third_party"

    @property
    def ue4ss_src(self):
        return Path(os.environ.get("OBLIVION_UE4SS_DIR") or self.third_party / "ue4ss")

    # files shared with the in-game mod (names as in tools/BenchBridge.ps1)
    @property
    def cmd_file(self):
        return self.runtime / "bench-commands.txt"

    @property
    def log_file(self):
        return self.runtime / "bench.log"

    @property
    def heartbeat_file(self):
        return self.runtime / "bench-heartbeat.txt"
