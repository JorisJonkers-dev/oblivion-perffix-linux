// ShaderScreenAfterDriverChange (game bug, on by default): the game's own "Shaders preloading" screen comes
// back at start-up after the graphics driver or card changed.
//
// The problem. A new graphics driver throws away the driver's compiled shaders. On the very first launch the game waits
// for its pipeline precompile behind a start-up screen ("Shaders preloading: 0-100 %", "Compiling shaders to optimize
// performance during gameplay."), but it decides that only once: at start-up (exe+0x44E1290 in build 19115871) it sets
// the start-up movie player's first-launch flag (+0x89) to "the Save_Settings save does not exist"
// (UGameplayStatics::DoesSaveGameExist, called at exe+0x44E12C4), and the movie player's set-up (exe+0x44E8350) adds the
// ShaderLoadingScreenMovie and its precompile callbacks only while that flag is set. After the first launch the settings
// save exists, so after a driver update the precompile runs in the background into play instead (with a cold driver
// cache ~3 minutes on the test PC, ~35 hitches a minute in the first flight: docs/research.md). Players rename
// Save_Settings.sav to get the screen back, which also resets every setting.
//
// The fix. That one call goes through a wrapper. It calls the game's DoesSaveGameExist, then compares the graphics card
// the game runs on (DXGI: vendor, device, the UMD (user-mode driver) version; the hardware adapter with the most dedicated
// video memory, as in memory_monitor.cpp) with the one recorded in OblivionPerfFix-gpu.txt next to the DLL. If the record
// exists and differs, the wrapper answers "no settings save" to this one caller only, so the game takes its own
// first-launch path: the shader screen, with the game's own pace and timeout. Settings are loaded as always (the game's
// other DoesSaveGameExist callers are untouched). The new card and driver are recorded once the precompile has finished
// (PsoPrecompileFast sees its end; a start-up closed behind the screen shows it again next time). No record yet (the first
// launch with the switch on): it is written and nothing else happens. Delete the file to record again.
// It cannot loop: before the screen is taken, a second line "shown N <card>" is written to the record (that write is also
// the check that the file can be written: if it fails, start-up stays the game's, since the screen would otherwise come
// back at every start). The line goes when the new card is recorded. If the screen was already shown twice for this card
// and driver without being recorded (each start-up closed behind it, or the precompile's end never seen), the card is
// recorded at once and start-up stays the game's.
//
// Under Wine/Proton (ShaderScreenLinuxFingerprint, on): DXGI's driver version there is a constant (35.0.65535.65535), so a
// Mesa or vkd3d-proton update would not be seen and the game would then compile everything in the background. The recorded
// first line therefore also carries what the Linux side lets a Windows process read: "<card> | wine=<version> proton=<dir name>
// <build> vkd3d=<d3d12core.dll content hash> icd=<hash of each Vulkan ICD's library (file name, size, time), the count and the Mesa
// version from a path like mesa-26.2.6>". Any difference in that line is a driver change. A third line "caches <vkd3d bytes> <mesa bytes>"
// (the vkd3d-proton pipeline cache files and Mesa's shader cache directory, measured at each start-up and after the
// precompile) means a wiped cache: a cache that fell under half of its recorded size (recorded at least 1 MB) shows the screen
// like a driver change. A record from before this (no " | " part, same card) is just extended, no screen. Windows: unchanged.
//
// What changes. After a driver or card change, start-up waits on the game's shader screen until its precompile is done
// (minutes with a cold driver cache), as on the game's first launch, instead of compiling during play. Nothing else.
#include "common.h"

#include <dxgi1_4.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

namespace opf {
namespace {

using ExistsFn = bool (*)(const void* slotName, int32_t userIndex);  // (const FString&, int32)

// lea rdx,[L"Save_Settings"]; lea rcx,[rsp+20h]; call FString(const TCHAR*); xor edx,edx; lea rcx,[rsp+20h];
// call DoesSaveGameExist; mov rcx,[rsp+20h]; test al,al; sete al; mov [rdi+89h],al
constexpr const char* kCallSite =
    "48 8D 15 ?? ?? ?? ?? 48 8D 4C 24 20 E8 ?? ?? ?? ?? 33 D2 48 8D 4C 24 20 E8 ?? ?? ?? ?? 48 8B 4C 24 20 84 C0 0F 94 C0 "
    "88 87 89 00 00 00";
constexpr size_t kNameLea = 0, kExistsCall = 24;
// DoesSaveGameExist: mov [rsp+8],rbx; push rdi; sub rsp,20h; mov edi,edx; mov rbx,rcx; call IPlatformFeaturesModule::Get;
// mov rcx,rax; mov r8,[rax]; call [r8+40h] (GetSaveGameSystem); test rax,rax; je; cmp dword [rbx+8],0; mov r8,[rax];
// mov r9,[r8+10h] (DoesSaveGameExist)
constexpr const char* kExistsEntry =
    "48 89 5C 24 08 57 48 83 EC 20 8B FA 48 8B D9 E8 ?? ?? ?? ?? 48 8B C8 4C 8B 00 41 FF 50 40 48 85 C0 74 ?? 83 7B 08 00 "
    "4C 8B 00 4D 8B 48 10";
constexpr wchar_t kSlot[] = L"Save_Settings";

uint8_t* g_call = nullptr;
uint8_t* g_stub = nullptr;
uint8_t* g_target = nullptr;  // the game's DoesSaveGameExist
ExistsFn g_original = nullptr;
std::wstring g_recordPath;
bool (*g_testGpu)(char*, size_t) = nullptr;
bool (*g_testLinux)(char*, size_t, uint64_t*, uint64_t*) = nullptr;  // self-test: the Linux-side tokens and cache sizes
bool g_linuxFp = true;     // ShaderScreenLinuxFingerprint
int g_decision = -1;  // -1 not asked yet, 0 game's answer, 1 first-launch path taken
int g_shownUnrecorded = 0;  // the "shown N" count written at this start-up (-1: the record could not be written)
constexpr size_t kFp = 640;   // the recorded fingerprint line
char g_pending[kFp] = "";  // the new card and driver, recorded once the precompile has finished (PsoPrecompileFast sees it)

struct Caches {
    bool have = false;
    uint64_t vkd3d = 0, mesa = 0;
};
Caches g_cachesNow;        // measured at this start-up (written with the record)

// "vendor device subsys rev driver" of the hardware adapter with the most dedicated video memory.
bool CurrentGpu(char* out, size_t size)
{
    if (g_testGpu) return g_testGpu(out, size);
    HMODULE dxgi = GetModuleHandleW(L"dxgi.dll");
    if (!dxgi) dxgi = LoadLibraryExW(L"dxgi.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if (!dxgi) return false;
    auto create = reinterpret_cast<HRESULT(WINAPI*)(REFIID, void**)>(GetProcAddress(dxgi, "CreateDXGIFactory1"));
    IDXGIFactory1* factory = nullptr;
    if (!create || FAILED(create(IID_PPV_ARGS(&factory))) || !factory) return false;
    bool found = false;
    SIZE_T best = 0;
    IDXGIAdapter1* a = nullptr;
    for (UINT i = 0; factory->EnumAdapters1(i, &a) != DXGI_ERROR_NOT_FOUND; ++i) {
        DXGI_ADAPTER_DESC1 desc{};
        LARGE_INTEGER umd{};
        if (SUCCEEDED(a->GetDesc1(&desc)) && !(desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE) && desc.DedicatedVideoMemory > best &&
            SUCCEEDED(a->CheckInterfaceSupport(__uuidof(IDXGIDevice), &umd))) {
            best = desc.DedicatedVideoMemory;
            snprintf(out, size, "%04X %04X %08X %02X %u.%u.%u.%u", desc.VendorId, desc.DeviceId, desc.SubSysId, desc.Revision,
                     static_cast<unsigned>(HIWORD(umd.HighPart)), static_cast<unsigned>(LOWORD(umd.HighPart)),
                     static_cast<unsigned>(HIWORD(umd.LowPart)), static_cast<unsigned>(LOWORD(umd.LowPart)));
            found = true;
        }
        a->Release();
    }
    factory->Release();
    return found;
}

// ---- Linux side, read from inside Wine (the Z: drive is the Linux root; the Linux environment is the process's) ----

std::string EnvA(const char* name)
{
    char buf[2048];
    const DWORD n = GetEnvironmentVariableA(name, buf, sizeof buf);
    return n && n < sizeof buf ? std::string(buf, n) : std::string();
}

std::wstring UnixToWin(const std::string& p)
{
    std::wstring w;
    if (!p.empty() && p[0] == '/') w = L"Z:";
    for (char c : p) w += c == '/' ? L'\\' : static_cast<wchar_t>(static_cast<unsigned char>(c));
    return w;
}

std::vector<std::string> Split(const std::string& s, char sep)
{
    std::vector<std::string> out;
    size_t at = 0;
    while (at <= s.size()) {
        const size_t e = s.find(sep, at);
        const size_t end = e == std::string::npos ? s.size() : e;
        if (end > at) out.push_back(s.substr(at, end - at));
        if (e == std::string::npos) break;
        at = e + 1;
    }
    return out;
}

bool StatFile(const std::wstring& path, uint64_t* size, uint64_t* mtimeSec)
{
    WIN32_FILE_ATTRIBUTE_DATA d{};
    if (!GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &d) || (d.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) return false;
    *size = (static_cast<uint64_t>(d.nFileSizeHigh) << 32) | d.nFileSizeLow;
    const uint64_t ft = (static_cast<uint64_t>(d.ftLastWriteTime.dwHighDateTime) << 32) | d.ftLastWriteTime.dwLowDateTime;
    *mtimeSec = ft / 10000000ull;
    return true;
}

bool ReadHead(const std::wstring& path, std::string* out, size_t cap)
{
    HANDLE h = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) return false;
    out->resize(cap);
    DWORD got = 0;
    const bool ok = ReadFile(h, out->data(), static_cast<DWORD>(cap), &got, nullptr) != 0;
    CloseHandle(h);
    out->resize(ok ? got : 0);
    return ok;
}

// FNV-1a over the whole file (at most 48 MB): the content identity of vkd3d-proton's DLL, whatever its time stamp.
bool HashFile(const std::wstring& path, uint64_t* hash)
{
    HANDLE h = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) return false;
    std::vector<uint8_t> buf(1u << 20);
    uint64_t hv = 1469598103934665603ull, total = 0;
    for (;;) {
        DWORD got = 0;
        if (!ReadFile(h, buf.data(), static_cast<DWORD>(buf.size()), &got, nullptr)) { CloseHandle(h); return false; }
        if (!got) break;
        for (DWORD i = 0; i < got; ++i) hv = (hv ^ buf[i]) * 1099511628211ull;
        total += got;
        if (total > (48u << 20)) break;
    }
    CloseHandle(h);
    *hash = hv;
    return true;
}

// "mesa-26.2.6" in a path (Nix store paths): the version, or "".
std::string MesaVersionInPath(const std::string& path)
{
    const size_t at = path.find("mesa-");
    if (at == std::string::npos) return "";
    size_t i = at + 5, e = i;
    while (e < path.size() && (isdigit(static_cast<unsigned char>(path[e])) || path[e] == '.')) ++e;
    while (e > i && path[e - 1] == '.') --e;
    return e > i ? path.substr(i, e - i) : "";
}

std::string BaseName(const std::string& p)
{
    const size_t s = p.find_last_of('/');
    return s == std::string::npos ? p : p.substr(s + 1);
}

// The Vulkan ICD files Wine's loader would see: VK_DRIVER_FILES / VK_ICD_FILENAMES, else the standard directories.
std::vector<std::string> IcdFiles()
{
    std::vector<std::string> files, dirs;
    for (const char* var : {"VK_DRIVER_FILES", "VK_ICD_FILENAMES", "VK_ADD_DRIVER_FILES"})
        for (const std::string& e : Split(EnvA(var), ':')) {
            if (e.size() > 5 && e.compare(e.size() - 5, 5, ".json") == 0) files.push_back(e);
            else dirs.push_back(e);
        }
    if (files.empty() && dirs.empty()) {
        for (const char* d : {"/run/opengl-driver/share/vulkan/icd.d", "/usr/share/vulkan/icd.d", "/etc/vulkan/icd.d",
                              "/usr/local/share/vulkan/icd.d"})
            dirs.push_back(d);
        for (const std::string& x : Split(EnvA("XDG_DATA_DIRS"), ':')) dirs.push_back(x + "/vulkan/icd.d");
        const std::string home = EnvA("HOME");
        if (!home.empty()) dirs.push_back(home + "/.local/share/vulkan/icd.d");
    }
    for (const std::string& d : dirs) {
        WIN32_FIND_DATAW fd;
        HANDLE h = FindFirstFileW((UnixToWin(d) + L"\\*.json").c_str(), &fd);
        if (h == INVALID_HANDLE_VALUE) continue;
        do {
            std::string name;
            for (const wchar_t* c = fd.cFileName; *c; ++c) name += *c < 128 ? static_cast<char>(*c) : '?';
            if (name.find("i686") == std::string::npos && name.find("_32") == std::string::npos) files.push_back(d + "/" + name);
        } while (FindNextFileW(h, &fd));
        FindClose(h);
    }
    // each once
    std::vector<std::string> unique;
    for (const std::string& f : files) {
        bool dup = false;
        for (const std::string& u : unique) dup = dup || u == f;
        if (!dup) unique.push_back(f);
    }
    return unique;
}

// "name:size:mtime[:mesa=ver]" of one ICD's driver library (its JSON's "library_path").
std::string IcdToken(const std::string& jsonPath)
{
    std::string json;
    if (!ReadHead(UnixToWin(jsonPath), &json, 16384)) return "";
    const size_t k = json.find("\"library_path\"");
    if (k == std::string::npos) return "";
    const size_t q1 = json.find('"', json.find(':', k) + 1);
    const size_t q2 = q1 == std::string::npos ? q1 : json.find('"', q1 + 1);
    if (q2 == std::string::npos) return "";
    const std::string lib = json.substr(q1 + 1, q2 - q1 - 1);
    std::vector<std::string> cands;
    if (!lib.empty() && lib[0] == '/') cands.push_back(lib);
    else {
        const size_t s = jsonPath.find_last_of('/');
        if (lib.find('/') != std::string::npos && s != std::string::npos) cands.push_back(jsonPath.substr(0, s + 1) + lib);
        for (const char* d : {"/run/opengl-driver/lib", "/usr/lib/x86_64-linux-gnu", "/usr/lib64", "/usr/lib", "/lib/x86_64-linux-gnu"})
            cands.push_back(std::string(d) + "/" + lib);
    }
    uint64_t size = 0, mt = 0;
    std::string used = cands.empty() ? lib : cands[0];
    for (const std::string& c : cands)
        if (StatFile(UnixToWin(c), &size, &mt)) { used = c; break; }
    char buf[256];
    const std::string ver = MesaVersionInPath(used);
    snprintf(buf, sizeof buf, "%s:%llu:%llu%s%s", BaseName(used).c_str(), static_cast<unsigned long long>(size),
             static_cast<unsigned long long>(mt), ver.empty() ? "" : ":mesa=", ver.c_str());
    return buf;
}

// The Proton in use: PROTON_VERSION, else the path segment naming it in the environment's paths, with its "version" file.
std::string ProtonToken()
{
    const std::string pv = EnvA("PROTON_VERSION");
    if (!pv.empty()) return pv;
    for (const char* var : {"WINEDLLPATH", "PATH", "LD_LIBRARY_PATH", "STEAM_COMPAT_TOOL_PATHS", "PROTONPATH", "WINELOADER"})
        for (const std::string& dir : Split(EnvA(var), ':')) {
            const std::vector<std::string> segs = Split(dir, '/');
            std::string root;
            for (const std::string& seg : segs) {
                root += "/" + seg;
                std::string low = seg;
                for (char& c : low) c = static_cast<char>(tolower(static_cast<unsigned char>(c)));
                if (low.find("proton") == std::string::npos || low == "proton") continue;
                std::string version;
                ReadHead(UnixToWin(root + "/version"), &version, 128);
                const size_t eol = version.find_first_of("\r\n");
                if (eol != std::string::npos) version.resize(eol);
                for (char& c : version) if (c == ' ' || c == '|') c = '_';
                std::string name = seg;
                for (char& c : name) if (c == ' ' || c == '|') c = '_';
                return version.empty() ? name : name + "/" + version;
            }
        }
    return "";
}

// vkd3d-proton: the content hash of the d3d12core.dll / d3d12.dll the game has loaded (Proton copies or links its own into the prefix).
std::string Vkd3dToken()
{
    std::string out;
    for (const wchar_t* mod : {L"d3d12core.dll", L"d3d12.dll"}) {
        // the module if the game has loaded it, else the prefix's system folder (the check runs early at start-up)
        HMODULE m = GetModuleHandleW(mod);
        wchar_t path[MAX_PATH];
        if (!m || !GetModuleFileNameW(m, path, MAX_PATH)) {
            if (!GetSystemDirectoryW(path, MAX_PATH)) continue;
            wcscat_s(path, L"\\");
            wcscat_s(path, mod);
        }
        uint64_t hash = 0, size = 0, mt = 0;
        if (!HashFile(path, &hash) || !StatFile(path, &size, &mt)) continue;
        char buf[80];
        snprintf(buf, sizeof buf, "%s%016llx.%llu", out.empty() ? "" : "+", static_cast<unsigned long long>(hash),
                 static_cast<unsigned long long>(size));
        out += buf;
    }
    return out;
}

// Bytes of the files under a directory (Windows path). onlyCacheNames: only vkd3d-proton's cache files. Bounded: depth, entries, time.
uint64_t DirBytes(const std::wstring& dir, int depth, bool onlyCacheNames, ULONGLONG deadline, int* budget)
{
    WIN32_FIND_DATAW fd;
    HANDLE h = FindFirstFileW((dir + L"\\*").c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return 0;
    uint64_t sum = 0;
    do {
        if (--*budget <= 0 || GetTickCount64() > deadline) break;
        if (fd.cFileName[0] == L'.' && (!fd.cFileName[1] || (fd.cFileName[1] == L'.' && !fd.cFileName[2]))) continue;
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            if (depth > 0) sum += DirBytes(dir + L"\\" + fd.cFileName, depth - 1, onlyCacheNames, deadline, budget);
            continue;
        }
        if (onlyCacheNames) {
            std::wstring n = fd.cFileName;
            for (wchar_t& c : n) c = static_cast<wchar_t>(towlower(c));
            const bool cache = n.find(L"vkd3d") != std::wstring::npos && n.find(L".cache") != std::wstring::npos;
            if (!cache) continue;
        }
        sum += (static_cast<uint64_t>(fd.nFileSizeHigh) << 32) | fd.nFileSizeLow;
    } while (FindNextFileW(h, &fd));
    FindClose(h);
    return sum;
}

void AddUnique(std::vector<std::wstring>* v, const std::wstring& w)
{
    if (w.empty()) return;
    for (const std::wstring& e : *v)
        if (_wcsicmp(e.c_str(), w.c_str()) == 0) return;
    v->push_back(w);
}

// The vkd3d-proton pipeline cache files and Mesa's shader cache: their sizes (a wiped cache reads as a large drop).
Caches MeasureCaches()
{
    Caches c;
    c.have = true;
    const ULONGLONG deadline = GetTickCount64() + 500;
    int budget = 40000;
    std::vector<std::wstring> vk, mesa;
    AddUnique(&vk, UnixToWin(EnvA("VKD3D_SHADER_CACHE_PATH")));
    AddUnique(&vk, UnixToWin(EnvA("STEAM_COMPAT_SHADER_PATH")));
    wchar_t exe[MAX_PATH];
    if (GetModuleFileNameW(nullptr, exe, MAX_PATH)) {
        std::wstring e = exe;
        const size_t s = e.find_last_of(L'\\');
        if (s != std::wstring::npos) AddUnique(&vk, e.substr(0, s));
    }
    wchar_t cwd[MAX_PATH];
    if (GetCurrentDirectoryW(MAX_PATH, cwd)) AddUnique(&vk, cwd);
    AddUnique(&mesa, UnixToWin(EnvA("MESA_SHADER_CACHE_DIR")));
    AddUnique(&mesa, UnixToWin(EnvA("MESA_GLSL_CACHE_DIR")));
    const std::string xdg = EnvA("XDG_CACHE_HOME"), home = EnvA("HOME");
    if (!xdg.empty()) AddUnique(&mesa, UnixToWin(xdg + "/mesa_shader_cache"));
    else if (!home.empty()) AddUnique(&mesa, UnixToWin(home + "/.cache/mesa_shader_cache"));
    for (const std::wstring& d : vk) c.vkd3d += DirBytes(d, 2, true, deadline, &budget);
    for (const std::wstring& d : mesa) c.mesa += DirBytes(d, 3, false, deadline, &budget);
    return c;
}

// Everything the Linux side of the fingerprint adds; false off Wine (or switched off).
bool LinuxProbe(char* tokens, size_t size, Caches* caches)
{
    if (!g_linuxFp) return false;
    if (g_testLinux) {
        uint64_t v = 0, m = 0;
        if (!g_testLinux(tokens, size, &v, &m)) return false;
        *caches = {true, v, m};
        return true;
    }
    if (!IsWine()) return false;
    std::string wine;
    if (HMODULE ntdll = GetModuleHandleW(L"ntdll.dll")) {
        using VerFn = const char*(CDECL*)();
        if (auto f = reinterpret_cast<VerFn>(GetProcAddress(ntdll, "wine_get_version"))) wine = f();
    }
    // every ICD library's name/size/time (/Mesa version): the record keeps a hash and the Mesa versions, the log the list
    std::string icd, mesaVers;
    int icdCount = 0;
    uint64_t icdHash = 1469598103934665603ull;
    for (const std::string& f : IcdFiles()) {
        const std::string t = IcdToken(f);
        if (t.empty()) continue;
        icd += (icd.empty() ? "" : ",") + t;
        ++icdCount;
        for (char c : t) icdHash = (icdHash ^ static_cast<uint8_t>(c)) * 1099511628211ull;
        const size_t m = t.find(":mesa=");
        if (m != std::string::npos) {
            const std::string v = t.substr(m + 6);
            if (("+" + mesaVers + "+").find("+" + v + "+") == std::string::npos) mesaVers += (mesaVers.empty() ? "" : "+") + v;
        }
    }
    static bool listed = false;
    if (!listed) {
        listed = true;
        Log("[shaderscreen] Vulkan driver libraries: %s", icd.empty() ? "none found" : icd.c_str());
    }
    char icdTok[160] = "?";
    if (icdCount) snprintf(icdTok, sizeof icdTok, "%016llx.%d%s%s", static_cast<unsigned long long>(icdHash), icdCount, mesaVers.empty() ? "" : "/mesa=", mesaVers.c_str());
    std::string proton = ProtonToken(), vk = Vkd3dToken();
    for (char& c : wine) if (c == ' ' || c == '|') c = '_';
    snprintf(tokens, size, "wine=%s proton=%s vkd3d=%s icd=%s", wine.empty() ? "?" : wine.c_str(), proton.empty() ? "?" : proton.c_str(),
             vk.empty() ? "?" : vk.c_str(), icdTok);
    *caches = MeasureCaches();
    return true;
}

struct Record {
    char gpu[kFp] = "";
    int shown = 0;
    char shownGpu[kFp] = "";
    Caches caches;
};

// The record: first line (card and driver [| Linux side]), optional "shown N <same>", optional "caches <vkd3d> <mesa>".
bool ReadRecord(Record* r)
{
    FILE* f = nullptr;
    if (_wfopen_s(&f, g_recordPath.c_str(), L"rb") != 0 || !f) return false;
    char buf[2048];
    const size_t n = fread(buf, 1, sizeof buf - 1, f);
    fclose(f);
    buf[n] = 0;
    size_t eol = strcspn(buf, "\r\n");
    const size_t len = eol < sizeof r->gpu - 1 ? eol : sizeof r->gpu - 1;
    memcpy(r->gpu, buf, len);
    r->gpu[len] = 0;
    for (size_t i = len; i > 0 && r->gpu[i - 1] == ' '; --i) r->gpu[i - 1] = 0;
    for (const char* line = buf + eol; *line;) {
        while (*line == '\r' || *line == '\n') ++line;
        const size_t e = strcspn(line, "\r\n");
        if (strncmp(line, "shown ", 6) == 0) {
            char* end = nullptr;
            const long cnt = strtol(line + 6, &end, 10);
            if (cnt > 0 && end && *end == ' ') {
                r->shown = static_cast<int>(cnt);
                const size_t l = e - static_cast<size_t>(end + 1 - line);
                memcpy(r->shownGpu, end + 1, l < sizeof r->shownGpu - 1 ? l : sizeof r->shownGpu - 1);
                r->shownGpu[l < sizeof r->shownGpu - 1 ? l : sizeof r->shownGpu - 1] = 0;
            }
        } else if (strncmp(line, "caches ", 7) == 0) {
            unsigned long long v = 0, m = 0;
            if (sscanf_s(line + 7, "%llu %llu", &v, &m) == 2) r->caches = {true, v, m};
        }
        line += e;
    }
    return r->gpu[0] != 0;
}

// The record, with shownCount > 0 the "shown N <card>" line, and the caches line (when measured / kept).
bool WriteRecord(const char* gpu, int shownCount = 0, const char* shownGpu = nullptr, const Caches* caches = nullptr)
{
    FILE* f = nullptr;
    if (_wfopen_s(&f, g_recordPath.c_str(), L"wb") != 0 || !f) return false;
    bool ok = fprintf(f, "%s\r\n", gpu) > 0;
    if (ok && shownCount > 0 && shownGpu) ok = fprintf(f, "shown %d %s\r\n", shownCount, shownGpu) > 0;
    if (ok && caches && caches->have)
        ok = fprintf(f, "caches %llu %llu\r\n", static_cast<unsigned long long>(caches->vkd3d), static_cast<unsigned long long>(caches->mesa)) > 0;
    ok = fclose(f) == 0 && ok;
    return ok;
}

bool ExistsWrapper(const void* slotName, int32_t userIndex)
{
    const bool exists = g_original(slotName, userIndex);
    if (g_decision != -1) return g_decision == 1 ? false : exists;
    g_decision = 0;
    char gpu[96] = "", lxs[kFp] = "", now[kFp] = "";
    Record rec;
    Caches caches;
    if (!exists) {
        Log("[shaderscreen] no settings save yet: the game's first launch shows its shader screen anyway");
        if (CurrentGpu(gpu, sizeof gpu)) {
            const bool lin = LinuxProbe(lxs, sizeof lxs, &caches);
            snprintf(now, sizeof now, lin ? "%s | %s" : "%s", gpu, lxs);
            WriteRecord(now, 0, nullptr, lin ? &caches : nullptr);
        }
        return exists;
    }
    if (!CurrentGpu(gpu, sizeof gpu)) {
        Log("[shaderscreen] the graphics card could not be read (DXGI): start-up as the game decides");
        return exists;
    }
    const bool lin = LinuxProbe(lxs, sizeof lxs, &caches);
    snprintf(now, sizeof now, lin ? "%s | %s" : "%s", gpu, lxs);
    if (lin) {
        g_cachesNow = caches;
        Log("[shaderscreen] Linux side: %s; shader caches: vkd3d-proton %.1f MB, Mesa %.1f MB", lxs,
            static_cast<double>(caches.vkd3d) / 1048576.0, static_cast<double>(caches.mesa) / 1048576.0);
    }
    if (!ReadRecord(&rec)) {
        const bool ok = WriteRecord(now, 0, nullptr, lin ? &caches : nullptr);
        Log("[shaderscreen] graphics card and driver recorded (%s)%s; the shader screen returns after the next change", now,
            ok ? "" : " - writing OblivionPerfFix-gpu.txt failed");
        return exists;
    }
    if (!lin) {   // the Linux side switched off (or off Wine): only the card and driver part of an earlier record counts
        if (char* bar = strstr(rec.gpu, " | ")) *bar = 0;
    }
    bool changed = strcmp(rec.gpu, now) != 0;
    const char* why = "graphics card or driver changed";
    char drop[160] = "";
    if (changed && lin && !strstr(rec.gpu, " | ") && strcmp(rec.gpu, gpu) == 0) {
        // a record from before the Linux side was followed: extend it, no screen
        const bool ok = WriteRecord(now, 0, nullptr, &caches);
        Log("[shaderscreen] graphics card and driver unchanged (%s): the Linux side (Mesa, vkd3d-proton, Wine, shader caches) is now "
            "recorded too%s", gpu, ok ? "" : " - writing OblivionPerfFix-gpu.txt failed");
        return exists;
    }
    if (!changed && lin && rec.caches.have) {
        constexpr uint64_t kMinRecorded = 1u << 20;   // a cache under 1 MB recorded says nothing
        const bool vk = rec.caches.vkd3d >= kMinRecorded && caches.vkd3d < rec.caches.vkd3d / 2;
        const bool me = rec.caches.mesa >= kMinRecorded && caches.mesa < rec.caches.mesa / 2;
        if (vk || me) {
            changed = true;
            why = "a shader cache was wiped or shrank";
            snprintf(drop, sizeof drop, "vkd3d-proton cache %.1f -> %.1f MB, Mesa cache %.1f -> %.1f MB",
                     static_cast<double>(rec.caches.vkd3d) / 1048576.0, static_cast<double>(caches.vkd3d) / 1048576.0,
                     static_cast<double>(rec.caches.mesa) / 1048576.0, static_cast<double>(caches.mesa) / 1048576.0);
        }
    }
    if (!changed) {
        if (lin && (!rec.caches.have || rec.caches.vkd3d != caches.vkd3d || rec.caches.mesa != caches.mesa)) WriteRecord(now, 0, nullptr, &caches);
        Log("[shaderscreen] graphics card and driver unchanged (%s): start-up as usual", now);
        return exists;
    }
    // Never a loop: at most two shows for one card and driver without the record catching up, and only with a record
    // that can be written (the "shown" line written now is that check).
    const int already = strcmp(rec.shownGpu, now) == 0 ? rec.shown : 0;
    const Caches* keep = rec.caches.have ? &rec.caches : nullptr;   // the old sizes stay until the precompile has finished
    if (already >= 2) {
        const bool ok = WriteRecord(now, 0, nullptr, lin ? &caches : nullptr);
        Log("[shaderscreen] %s (%s -> %s%s%s), but the shader screen was already shown twice for it "
            "without the precompile's end being recorded: start-up as the game decides; %s", why, rec.gpu, now, drop[0] ? "; " : "", drop,
            ok ? "the card is recorded now" : "writing OblivionPerfFix-gpu.txt failed");
        g_shownUnrecorded = already;
        return exists;
    }
    if (!WriteRecord(rec.gpu, already + 1, now, keep)) {
        Log("[shaderscreen] %s (%s -> %s), but OblivionPerfFix-gpu.txt cannot be written: "
            "start-up as the game decides (the shader screen would come back at every start)", why, rec.gpu, now);
        g_shownUnrecorded = -1;
        return exists;
    }
    g_shownUnrecorded = already + 1;
    g_decision = 1;
    // Recorded once the precompile has finished, so a start-up closed behind the screen shows it again next time; without
    // PsoPrecompileFast (which sees the end) it is recorded now.
    PsoPrecompileInfoOut pso{};
    const bool deferred = PsoPrecompileInfo(&pso);
    const bool ok = deferred || WriteRecord(now, 0, nullptr, lin ? &caches : nullptr);
    if (deferred) snprintf(g_pending, sizeof g_pending, "%s", now);
    // The game itself asks only for UE's Background pace behind that screen (8 pipelines per frame here; a warm precompile
    // still unfinished after 160 s, 2026-10-28): PsoPrecompileFast runs it at UE's Fast pace until the main menu.
    if (deferred) SetPsoPrecompileScreenHold(true);
    Log("[shaderscreen] %s (%s -> %s%s%s): the game's shader screen is shown at this start-up%s", why, rec.gpu, now, drop[0] ? "; " : "", drop,
        deferred ? "; recorded once the precompile has finished"
                 : ok ? "" : " (writing OblivionPerfFix-gpu.txt failed: it will show again next time)");
    return false;
}

}  // namespace

void ShaderScreenPrecompileFinished()
{
    if (!g_pending[0]) return;
    // the caches as they are now: the precompile has filled them again after a wipe
    char tokens[kFp];
    Caches fresh;
    const bool lin = strstr(g_pending, " | ") && LinuxProbe(tokens, sizeof tokens, &fresh);
    const bool ok = WriteRecord(g_pending, 0, nullptr, lin ? &fresh : nullptr);
    Log("[shaderscreen] the precompile has finished: %s recorded%s", g_pending, ok ? "" : " - writing OblivionPerfFix-gpu.txt failed");
    g_pending[0] = 0;
}

bool ApplyShaderScreenAfterDriverChange(bool beforeGameCode, const wchar_t* dir)
{
    if (g_call) return true;
    if (!beforeGameCode) {
        Log("[shaderscreen] can only be installed at start-up (version.dll), not installed");
        return false;
    }
    if (!dir) return false;
    const GameModule& game = Game();
    const auto hits = FindAll(game.text, ParsePattern(kCallSite));
    uint8_t* site = nullptr;
    int named = 0;
    for (uint8_t* p : hits) {
        const auto* const name = reinterpret_cast<const wchar_t*>(RipTarget(p + kNameLea, 3, 7));
        if (!game.rdata.Contains(name) || wcscmp(name, kSlot) != 0) continue;
        site = p;
        ++named;
    }
    if (named != 1) {
        Log("[shaderscreen] the start-up's Save_Settings check not found (%zu matches, %d with the name): "
            "ShaderScreenAfterDriverChange not installed", hits.size(), named);
        return false;
    }
    uint8_t* const call = site + kExistsCall;
    uint8_t* const target = RipTarget(call, 1, 5);
    if (call[0] != 0xE8 || !game.text.Contains(target) || !MatchesAt(target, ParsePattern(kExistsEntry))) {
        Log("[shaderscreen] the call at exe+0x%llX does not go to the expected DoesSaveGameExist: ShaderScreenAfterDriverChange not "
            "installed", static_cast<unsigned long long>(call - game.base));
        return false;
    }
    uint8_t* const region = AllocNearGame(0x1000);
    if (!region) {
        Log("[shaderscreen] no free memory near the game's code for the call stub: ShaderScreenAfterDriverChange not installed");
        return false;
    }
    const uint8_t jmp[6] = {0xFF, 0x25, 0, 0, 0, 0};
    void* const hook = reinterpret_cast<void*>(&ExistsWrapper);
    memcpy(region, jmp, sizeof jmp);
    memcpy(region + sizeof jmp, &hook, sizeof hook);
    DWORD old;
    VirtualProtect(region, 0x1000, PAGE_EXECUTE_READ, &old);
    FlushInstructionCache(GetCurrentProcess(), region, 14);
    const int64_t rel = region - (call + 5);
    if (rel != static_cast<int32_t>(rel)) {
        VirtualFree(region, 0, MEM_RELEASE);
        Log("[shaderscreen] call stub out of reach: ShaderScreenAfterDriverChange not installed");
        return false;
    }
    g_original = reinterpret_cast<ExistsFn>(target);
    g_target = target;
    g_recordPath = std::wstring(dir) + L"\\OblivionPerfFix-gpu.txt";
    const int32_t rel32 = static_cast<int32_t>(rel);
    if (!WriteCode(call + 1, std::span<const uint8_t>(reinterpret_cast<const uint8_t*>(&rel32), 4))) {
        VirtualFree(region, 0, MEM_RELEASE);
        g_original = nullptr;
        Log("[shaderscreen] writing the call at exe+0x%llX failed: ShaderScreenAfterDriverChange not installed",
            static_cast<unsigned long long>(call - game.base));
        return false;
    }
    g_call = call;
    g_stub = region;
    Log("[shaderscreen] the start-up's Save_Settings check (DoesSaveGameExist exe+0x%llX, called at exe+0x%llX) goes through "
        "ShaderScreenAfterDriverChange",
        static_cast<unsigned long long>(target - game.base), static_cast<unsigned long long>(call - game.base));
    return true;
}

bool ShaderScreenInfo(uint8_t** call, uint8_t** original, uint8_t** stub, void** hook)
{
    if (!g_call) return false;
    *call = g_call;
    *original = reinterpret_cast<uint8_t*>(g_original);
    *stub = g_stub;
    *hook = reinterpret_cast<void*>(&ExistsWrapper);
    return true;
}

void SetShaderScreenLinux(bool on) { g_linuxFp = on; }

void ShaderScreenTestLinux(bool (*probe)(char*, size_t, uint64_t*, uint64_t*)) { g_testLinux = probe; }

bool ShaderScreenRealLinuxProbe(char* tokens, size_t size, uint64_t* vkd3dBytes, uint64_t* mesaBytes)
{
    Caches c;
    const bool saved = g_linuxFp;
    g_linuxFp = true;
    const auto testSaved = g_testLinux;
    g_testLinux = nullptr;
    const bool ok = LinuxProbe(tokens, size, &c);
    g_testLinux = testSaved;
    g_linuxFp = saved;
    *vkd3dBytes = c.vkd3d;
    *mesaBytes = c.mesa;
    return ok;
}

void ShaderScreenTestSetup(void* original, bool (*gpu)(char*, size_t), const wchar_t* recordPath)
{
    g_original = reinterpret_cast<ExistsFn>(original ? original : g_target);
    g_testGpu = gpu;
    if (recordPath) g_recordPath = recordPath;
    g_decision = -1;
    g_shownUnrecorded = 0;
    g_pending[0] = 0;
    g_cachesNow = {};
}

int ShaderScreenShownUnrecorded() { return g_shownUnrecorded; }

}  // namespace opf
