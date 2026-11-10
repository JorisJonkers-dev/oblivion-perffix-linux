// StreamPrewarmBehindLoading (off by default): faster texture streaming budgets while a transition's loading screen is up.
//
// Measured on Linux: after an exit to an exterior the textures keep sharpening for 3.5-4.5 s after the picture's
// brightness is stable, because the streaming budgets (a few virtual texture pages uploaded per frame, a few tiles
// produced per frame, the mip streamer's slow update) are tuned for play, where the GPU is busy. Behind the loading
// screen the GPU has room. StreamBehindLoadingScreen (stream_behind_loading.cpp) already starts the streamer when the
// new area's loading is idle; this raises the budgets for that window and puts every one back before the fade-in.
//
// What it does (game thread, from StreamBehindLoadingFrameEnd): when a transition's streaming starts (loading idle,
// gate armed) the console variables in kTable are looked up by name through the console manager (the manager's
// FindConsoleObject, vtable +0xC0, as the game's own r.VT.Flush function calls it; the manager is the global that
// function loads, found through FadeVtFlushSkip's search). A variable is touched only if its object has the same
// vtable as r.Streaming.PoolSize's (the cached variable StreamBehindLoadingScreen already uses, an int variable), so a
// command or a variable of another kind is never called through the wrong slots. Each is set to the faster value (never
// slower than the game's current value) with the priority it already has (Set with GetFlags & ECVF_SetByMask, as
// RestoreFsrAfterAltTab does), so later graphics-settings changes by the game still apply. When the gate has run
// (fade-to-game; the loading screen is going) every variable we changed is put back to the value it had, unless the
// game changed it meanwhile. Nothing else changes: the same pages are requested and uploaded, the settled picture is
// the same, only sooner.
//
// StreamPrewarmMaxHoldMs (default 0 = no extra hold): the fade gate's 0.5 s tick is skipped until the streaming has
// run this long (at most 3 s), through the gate delegate hooks of UnfreezeBehindLoadingScreen (installed at start-up
// when this is not 0). The loading screen is that much longer.
//
// Not available in this build: a count of the streamer's pending requests (no function for it is known), so the log
// reports the time, the frames and the streamer updates of the window instead of pending requests before and after.
#include "common.h"

#include <atomic>
#include <cstring>
#include <cwchar>

namespace opf {
namespace {

constexpr size_t kFindObject = 0xC0, kGetFlags = 0x18, kSet = 0x80, kGetInt = 0x90;
constexpr int32_t kSetByMask = static_cast<int32_t>(0xFF000000);
constexpr char kFlushShape[] =
    "48 89 5C 24 18 41 56 48 83 EC 30 4C 8B F1 48 8B 0D ?? ?? ?? ?? 48 85 C9 75 0C E8 ?? ?? ?? ?? 48 8B 0D ?? ?? ?? ?? "
    "48 8B 01 48 8D 15 ?? ?? ?? ?? 41 B0 01 FF 90 C0 00 00 00";
unsigned Rva(const void* p) { return static_cast<unsigned>(static_cast<const uint8_t*>(p) - Game().base); }
constexpr size_t kManagerLoad = 14;  // mov rcx,[console manager] (RIP-relative, 7 bytes)

struct Entry {
    const wchar_t* name;
    int32_t target;      // the faster value
    bool lower;          // true: a smaller number is faster (the update interval)
    bool skipIfZero;     // 0 means "unlimited" for this one: leave it
    bool vtUploadsKey;   // VtStreamingUploads writes this one itself: leave it while that key is on
};
constexpr Entry kTable[] = {
    {L"r.VT.MaxUploadsPerFrame.Streaming", 64, false, false, true},
    {L"r.VT.MaxUploadsPerFrame", 64, false, false, false},
    {L"r.VT.MaxTilesProducedPerFrame", 64, false, false, false},
    {L"r.Streaming.FramesForFullUpdate", 1, true, false, false},
    {L"r.Streaming.MaxNumTexturesToStreamPerFrame", 4096, false, true, false},
};
constexpr int kCount = static_cast<int>(sizeof kTable / sizeof kTable[0]);

using FindFn = void* (*)(void* manager, const wchar_t* name, bool track);
using GetIntFn = int32_t (*)(void* cvar);
using GetFlagsFn = int32_t (*)(void* cvar);
using SetFn = void (*)(void* cvar, const wchar_t* value, int32_t flags);

struct Raised {
    void* cvar = nullptr;
    int32_t before = 0, raised = 0;
};

void** g_managerSlot = nullptr;       // the global holding the IConsoleManager*
bool g_searched = false;
std::atomic<bool> g_on{false};
std::atomic<int> g_holdMs{0};
std::atomic<bool> g_vtKeyOn{false};
Raised g_raised[kCount];
int g_nRaised = 0;
bool g_active = false;
uint64_t g_beginUs = 0;
uint32_t g_begins = 0, g_restores = 0, g_gameChanged = 0;

uint64_t NowUs()
{
    static const uint64_t freq = [] { LARGE_INTEGER f; QueryPerformanceFrequency(&f); return static_cast<uint64_t>(f.QuadPart); }();
    LARGE_INTEGER c;
    QueryPerformanceCounter(&c);
    return static_cast<uint64_t>(c.QuadPart) * 1000000 / freq;
}

void* FindObject(const wchar_t* name)
{
    __try {
        void* const mgr = g_managerSlot ? *g_managerSlot : nullptr;
        if (!mgr) return nullptr;
        return reinterpret_cast<FindFn>((*reinterpret_cast<void***>(mgr))[kFindObject / 8])(mgr, name, true);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return nullptr;
    }
}

bool ReadInt(void* cvar, int32_t* v)
{
    __try {
        *v = reinterpret_cast<GetIntFn>((*reinterpret_cast<void***>(cvar))[kGetInt / 8])(cvar);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return false;
    }
}

// Set(value) with the priority the variable already has; true if it reads back as value.
bool SetSamePriority(void* cvar, int32_t value)
{
    __try {
        void** const vt = *reinterpret_cast<void***>(cvar);
        const int32_t flags = reinterpret_cast<GetFlagsFn>(vt[kGetFlags / 8])(cvar) & kSetByMask;
        wchar_t text[16];
        swprintf(text, 16, L"%d", value);
        reinterpret_cast<SetFn>(vt[kSet / 8])(cvar, text, flags);
        return reinterpret_cast<GetIntFn>(vt[kGetInt / 8])(cvar) == value;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return false;
    }
}

void* VtableOf(void* obj)
{
    __try {
        return obj ? *reinterpret_cast<void**>(obj) : nullptr;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return nullptr;
    }
}

}  // namespace

bool FindStreamPrewarm()
{
    if (g_managerSlot) return true;
    if (g_searched) return false;
    g_searched = true;
    FadeVtFlushInfo info;
    if (!FindFadeVtFlush(&info) || !info.flush) {
        Log("[prewarm] the console manager's lookup (through the r.VT.Flush function) not found: StreamPrewarmBehindLoading unavailable");
        return false;
    }
    if (!MatchesAt(info.flush, ParsePattern(kFlushShape))) {
        Log("[prewarm] the r.VT.Flush function is not as expected: StreamPrewarmBehindLoading unavailable");
        return false;
    }
    void** const slot = reinterpret_cast<void**>(RipTarget(info.flush + kManagerLoad, 3, 7));
    if (!slot || !Game().data.Contains(reinterpret_cast<uint8_t*>(slot))) {
        Log("[prewarm] the console manager pointer is not in the game's data: StreamPrewarmBehindLoading unavailable");
        return false;
    }
    g_managerSlot = slot;
    Log("[prewarm] console manager pointer at exe+0x%X: StreamPrewarmBehindLoading available", Rva(slot));
    return true;
}

void SetStreamPrewarm(bool on, int holdMs, bool vtUploadsKeyOn)
{
    holdMs = holdMs < 0 ? 0 : (holdMs > 3000 ? 3000 : holdMs);
    g_holdMs.store(holdMs, std::memory_order_relaxed);
    g_vtKeyOn.store(vtUploadsKeyOn, std::memory_order_relaxed);
    if (g_on.exchange(on) != on)
        Log("[prewarm] StreamPrewarmBehindLoading %s (extra hold %d ms)",
            on ? "on: streaming budgets raised while a loading screen idles" : "off: the game's budgets", holdMs);
}

int StreamPrewarmHoldMs()
{
    return g_on.load(std::memory_order_relaxed) ? g_holdMs.load(std::memory_order_relaxed) : 0;
}

bool StreamPrewarmActive() { return g_active; }

// Raise the budgets (game thread). poolCvar: r.Streaming.PoolSize's variable, the class reference.
void StreamPrewarmBegin(void* poolCvar)
{
    if (g_active || !g_on.load(std::memory_order_relaxed)) return;
    if (!g_managerSlot && !FindStreamPrewarm()) return;
    void* const refVt = VtableOf(poolCvar);
    if (!refVt) return;
    g_nRaised = 0;
    g_beginUs = NowUs();
    char line[512];
    size_t used = 0;
    line[0] = 0;
    for (const Entry& e : kTable) {
        void* const cvar = FindObject(e.name);
        char name[64];
        snprintf(name, sizeof name, "%ls", e.name);
        if (!cvar) { used += snprintf(line + used, sizeof line - used, " %s:absent", name + 2); continue; }
        if (VtableOf(cvar) != refVt) { used += snprintf(line + used, sizeof line - used, " %s:other-kind", name + 2); continue; }
        if (e.vtUploadsKey && g_vtKeyOn.load(std::memory_order_relaxed)) {
            used += snprintf(line + used, sizeof line - used, " %s:VtStreamingUploads-owns", name + 2);
            continue;
        }
        int32_t cur = 0;
        if (!ReadInt(cvar, &cur)) continue;
        if (e.skipIfZero && cur <= 0) { used += snprintf(line + used, sizeof line - used, " %s:unlimited", name + 2); continue; }
        const int32_t want = e.lower ? (cur < e.target ? cur : e.target) : (cur > e.target ? cur : e.target);
        if (want == cur) { used += snprintf(line + used, sizeof line - used, " %s:already-%d", name + 2, cur); continue; }
        if (!SetSamePriority(cvar, want)) {
            SetSamePriority(cvar, cur);
            used += snprintf(line + used, sizeof line - used, " %s:not-applied", name + 2);
            continue;
        }
        g_raised[g_nRaised++] = {cvar, cur, want};
        used += snprintf(line + used, sizeof line - used, " %s:%d->%d", name + 2, cur, want);
        if (used >= sizeof line - 80) break;
    }
    g_active = true;
    ++g_begins;
    Log("[prewarm] budgets raised for this transition (%d changed):%s", g_nRaised, line);
}

// Put every changed variable back (game thread); `updates` is only for the log.
void StreamPrewarmEnd(uint32_t updates)
{
    if (!g_active) return;
    g_active = false;
    int back = 0, changed = 0;
    for (int i = 0; i < g_nRaised; ++i) {
        const Raised& r = g_raised[i];
        int32_t cur = 0;
        if (!ReadInt(r.cvar, &cur)) continue;
        if (cur != r.raised) { ++changed; ++g_gameChanged; continue; }  // the game set another value: it keeps it
        if (SetSamePriority(r.cvar, r.before)) ++back;
    }
    g_restores += back;
    Log("[prewarm] %.0f ms window, %u streamer updates, %d of %d variables put back (%d left as the game changed them); "
        "pending requests are not exposed in this build", (NowUs() - g_beginUs) / 1000.0, updates, back, g_nRaised, changed);
    g_nRaised = 0;
}

void LogStreamPrewarmStats()
{
    if (!g_on.load() && !g_begins) return;
    Log("[prewarm] %s: %u transitions raised, %u variables put back, %u left because the game changed them",
        g_on.load() ? "on" : "off", g_begins, g_restores, g_gameChanged);
}

void StreamPrewarmTestSetup(void** managerSlot)
{
    g_managerSlot = managerSlot;
    g_searched = true;
    g_active = false;
    g_nRaised = 0;
    g_begins = g_restores = g_gameChanged = 0;
    g_on = false;
    g_holdMs = 0;
    g_vtKeyOn = false;
}

}  // namespace opf
