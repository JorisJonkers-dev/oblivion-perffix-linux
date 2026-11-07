// Diagnostic OtProfile / OtCrashContext ([Fixes] OtProfile=0, OtProfileMs=10, OtProfileSampleHz=1000, OtCrashContext=0): a
// read-only profiler of the old engine's thread ("OblivionThread", OT) and a crash breadcrumb for it. Nothing in the game
// changes: the hooks only read the clock around the game's own calls, and a faulting OT thread is only described.
//
// What one OT cycle is (build 19115871, docs/research-linux/oldengine-hotspots.md section 1):
//   loop head -> Begin(frame) -> message pump -> the frame body (exe+0x65D3940: menu gate, time, interface, ProcessLists, the
//   player and the cell grid, the door/arrival handler, water, the save entry) -> Handler_End (the OT's end-of-frame command
//   into the queue to the game thread) -> RunSession(-2): the OT runs the game thread's reverse commands until the game
//   thread's end command arrives, i.e. it WAITS for the game thread. The game thread's OnWorldPreActorTick calls
//   RunSession(-1) and waits there until the OT's end command is executed.
// A cycle runs from one entry of the frame body to the next. busy = cycle - idle, idle = the time inside RunSession(-2)
// (the OT waiting for the game thread). A cycle is slow when busy >= OtProfileMs.
//
// Where the time goes inside the frame is measured two ways:
//  - timing stubs: the CALL SITES (rel32 calls redirected to a stub that jumps to a hook that times the original target) of
//    the frame body, of ProcessLists' passes (the one before the main update, ProcessLists::Update with its four level
//    passes, the passes after it, the later time-driven pass), of the cell-grid change (two sites), of the door/arrival
//    handler, of the water update and of the save entry, plus the RunSession(-2) call (rewritten in place) and, when
//    NpcCreationPacing is not installed (it keys on that call's return address), the game thread's RunSession(-1);
//  - the engine's own stage marker (a DWORD the OT writes before each stage, exe+0x9484250): a sampler thread reads it
//    OtProfileSampleHz times a second and gives every cycle its most frequent marker, and every 2 s a histogram.
// OtCrashContext: a vectored exception handler that, only for a fault on the OT, writes the marker, the stage in progress,
// the last completed stages, the recent marker values and the faulting address as exe+offset to OblivionPerfFix.log and
// then CONTINUES THE SEARCH (it never handles or swallows an exception).
//
// Output: OblivionPerfFix-otprofile.csv next to the DLL (the previous session as .1.csv, 32 MB per session). Times are
// QueryPerformanceCounter milliseconds, the clock HitchLedger and the lab log use. F row = a slow cycle, S row = a 2 s
// aggregate, M row = the marker histogram of a 2 s window. tools/ot_profile.py ranks it.
// Game side: per-call accumulators on the OT only; a finished cycle becomes a fixed record pushed into a single-producer
// ring that the monitor thread drains once a second; no file I/O, no allocation, no lock on the OT.
// Cost when on: two clock reads per timed call (about 14 calls per cycle), about 1-2 us per cycle. Off: nothing is installed.
// Start-up only (version.dll route); afterwards the ini switches recording, the threshold and the crash handler live.
#include "common.h"

#include <atomic>
#include <cstdio>
#include <cstring>
#include <string>

namespace opf {
namespace {

// ---- patterns (build 19115871; the address of each match is in the comment) ----
// The loop's call of the frame body: mov rcx,[Main]; call body; cmp byte [..],0; je; mov rax,[Main]; mov byte [rax],1  (0x65D3334)
constexpr char kBodyCall[] = "48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 80 3D ?? ?? ?? ?? 00 74 0A 48 8B 05 ?? ?? ?? ?? C6 00 01";
constexpr size_t kBodyCallAt = 7;
// The frame body's entry (0x65D3940)
constexpr char kBodyEntry[] =
    "48 89 5C 24 08 48 89 6C 24 18 48 89 74 24 20 57 41 56 41 57 48 83 EC 60 48 8B E9 48 8B 05 ?? ?? ?? ?? 80 B8 1B 01 00 00 00 0F";
// The end of the frame: call [r9+38h] (Handler_End); cmp [frame counter],1; jbe; mov r8,[rbx]; mov edx,-2; mov rcx,rbx;
// call [r8+70h] (RunSession)  (0x65D3625; the mov edx at +16)
constexpr char kEndPair[] = "41 FF 51 38 83 3D ?? ?? ?? ?? 01 76 ?? 4C 8B 03 BA FE FF FF FF 48 8B CB 41 FF 50 70";
constexpr size_t kEndPairRun = 16;
// OnWorldPreActorTick's RunSession(-1): mov rax,[rsi]; mov edx,-1; mov rcx,rsi; call [rax+70h]; mov r8,[..]  (0x4899E09; edx at +3)
constexpr char kGtRun[] = "48 8B 06 BA FF FF FF FF 48 8B CE FF 50 70 4C 8B 05";
constexpr size_t kGtRunAt = 3;
// ProcessLists, part 1: mov [marker],r15d; call getter; mov rcx,rax; call pass; mov [marker],32h   (0x65D3D68; marker at +0)
constexpr char kPl1[] = "44 89 3D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B C8 E8 ?? ?? ?? ?? C7 05 ?? ?? ?? ?? 32 00 00 00";
constexpr size_t kPl1Call = 0x0F;
// ProcessLists, main update: marker 64h, Update; marker C8h, pass; marker 12Ch, pass; marker 190h   (0x65D3DAB)
constexpr char kPlMain[] =
    "C7 05 ?? ?? ?? ?? 64 00 00 00 E8 ?? ?? ?? ?? 48 8B C8 E8 ?? ?? ?? ?? C7 05 ?? ?? ?? ?? C8 00 00 00 E8 ?? ?? ?? ?? 48 8B C8 E8 "
    "?? ?? ?? ?? C7 05 ?? ?? ?? ?? 2C 01 00 00 E8 ?? ?? ?? ?? 48 8B C8 E8 ?? ?? ?? ?? C7 05 ?? ?? ?? ?? 90 01 00 00";
constexpr size_t kPlMainUpdate = 0x12, kPlMainPass2 = 0x29, kPlMainPass3 = 0x40;
constexpr size_t kPlMainMarkers[4] = {0x00, 0x17, 0x2E, 0x45};
// ProcessLists::Update's four level passes with their markers 78h, 82h, 8Ch, B4h and the end marker BEh   (0x674AD4E)
constexpr char kLevels[] =
    "B8 78 00 00 00 89 05 ?? ?? ?? ?? 80 BB 41 01 00 00 00 74 17 80 3D ?? ?? ?? ?? 00 75 0E 45 33 C0 0F 57 C9 48 8B CB E8 ?? ?? ?? ?? "
    "C7 05 ?? ?? ?? ?? 82 00 00 00 80 BB 43 01 00 00 00 74 0E 45 33 C0 0F 57 C9 48 8B CB E8 ?? ?? ?? ?? C7 05 ?? ?? ?? ?? 8C 00 00 00 "
    "80 BB 42 01 00 00 00 74 0E 45 33 C0 0F 57 C9 48 8B CB E8 ?? ?? ?? ?? C7 05 ?? ?? ?? ?? B4 00 00 00 80 BB 40 01 00 00 00 74 0E "
    "45 33 C0 0F 57 C9 48 8B CB E8 ?? ?? ?? ?? 0F 28 74 24 20 C7 05 ?? ?? ?? ?? BE 00 00 00";
constexpr size_t kLevelCalls[4] = {38, 71, 104, 137};
constexpr size_t kLevelMarkers[4] = {43, 76, 109, 147};  // plus the mov eax / mov [marker],eax pair at +5 (6-byte insn)
// ProcessLists::Update itself (0x674AC70)
constexpr char kUpdateFn[] = "40 53 48 83 EC 30 48 8B D9 0F 29 74 24 20 48 8B 0D ?? ?? ?? ?? C7 05 ?? ?? ?? ?? 6E 00 00 00 48 85 C9 74";
// The player's grid-change calls (0x65D3F20, 0x65D3F86)
constexpr char kGrid1[] = "41 B0 01 48 8D 54 24 30 48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B 15 ?? ?? ?? ?? 48 8B CB E8";
constexpr size_t kGrid1Call = 0x0F;
constexpr char kGrid2[] = "48 83 C2 64 41 B0 01 48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B 05 ?? ?? ?? ?? 44 38 78 79";
constexpr size_t kGrid2Call = 0x0E;
// the grid change's entry as the game has it (the ledger's pattern; HitchLedger's or CellBufferPacedEvict's detour changes it to a jmp)
constexpr char kGridFn[] = "44 88 44 24 18 53 56 57 41 56 48 83 EC 58 48 8B F9 45 0F B6 F0 48 8B 89 ?? ?? 00 00 48 8B F2 48 85 C9 74";
// The door / arrival handler call (0x65D4042): the stack-passed 5th argument is set just before   (0x65D402C)
constexpr char kPDoor[] = "44 88 7C 24 20 4C 8D 44 24 40 48 8D 54 24 50 48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0";
constexpr size_t kDoorCall = 0x16;
constexpr char kDoorFn[] = "48 8B C4 55 53 56 57 41 54 41 55 41 56 41 57 48 8D A8 38 FF FF FF 48 81 EC 88 01 00 00";
// ProcessLists, the later time-driven pass (0x65D406E; dt in xmm1)
constexpr char kPl2[] = "E8 ?? ?? ?? ?? 48 8B C8 F3 0F 10 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0 74 ?? 0F 57 C0";
constexpr size_t kPl2Call = 0x10;
// The water / time-driven update (0x65D40A1; dt in xmm1)
constexpr char kPWater[] = "0F 28 C8 48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? E8 ?? ?? ?? ?? 84 C0 75 ??";
constexpr size_t kWaterCall = 0x0A;
// The save entry (0x65D4212) and its function (0x65D4570)
constexpr char kPSave[] = "48 8B CD E8 ?? ?? ?? ?? 80 3D ?? ?? ?? ?? 00 74 ?? E8 ?? ?? ?? ?? C6 05";
constexpr size_t kSaveCall = 0x03;
constexpr char kSaveFn[] = "40 53 48 83 EC 20 B9 03 00 00 00 E8";
// callee entries (a prologue each)
constexpr char kPassFn[] = "41 57 48 81 EC 80 00 00 00 4C 8B F9 48 8B 0D ?? ?? ?? ?? E8";                  // 0x67406B0
constexpr char kPass3Fn[] = "40 57 48 83 EC 20 48 8D B9 B0 00 00 00 48 85 FF 0F 84";                       // 0x6749330
constexpr char kTimedFn[] = "40 53 57 41 56 48 83 EC 50 0F 29 74 24 20 33 DB";                              // 0x674AE00
constexpr char kWaterFn[] = "48 89 5C 24 10 48 89 6C 24 18 56 57 41 56 48 83 EC 50 0F 29 74 24 40";        // 0x66B1D50
constexpr char kLowFn[] = "41 55 41 57 48 81 EC 18 01 00 00 4C 8D 69 30";                                   // 0x6749B30
constexpr char kMidLowFn[] = "48 89 4C 24 08 53 41 54 41 55 41 56 41 57 48 81 EC 10 01 00 00";            // 0x674A580
constexpr char kMidHighFn[] = "40 55 41 54 41 56 48 81 EC A0 00 00 00 44 0F 29 44 24 60";                  // 0x674A1D0
constexpr char kHighFn[] = "48 8B C4 48 89 58 10 48 89 48 08 55 56 57 41 54 41 55 41 56 41 57 48 81 EC B0 00 00";  // 0x6749460

// The timed stages. kBody = the whole frame body; the four lvl_ entries are inside pl_update.
enum Stage {
    kBody, kPlPre, kPlUpdate, kLvlLow, kLvlMidLow, kLvlMidHigh, kLvlHigh, kPlPass2, kPlPass3, kGridPlayer, kGridOwn, kDoor,
    kPlTimed, kWater, kSave, kStages
};
const char* const kStageName[kStages] = {"body",     "pl_pre",   "pl_update", "lvl_low",     "lvl_midlow",  "lvl_midhigh", "lvl_high", "pl_pass2",
                                         "pl_pass3", "grid_player", "grid_own", "door", "pl_timed", "water", "save"};
// stages that are not inside another stage and not the body (their sum is subtracted from the body to get "other")
constexpr bool kTopLevel[kStages] = {false, true, true, false, false, false, false, true, true, true, true, true, true, true, true};

constexpr size_t kRing = 1024;
constexpr uint64_t kWindowUs = 2000000;
constexpr long kMaxFileBytes = 32L << 20;
constexpr int kMarkers = 512;  // marker values above this are counted in the last bin

struct Record {
    uint32_t kind = 0;  // 1 = slow cycle, 2 = 2 s aggregate
    uint32_t seq = 0;
    uint64_t endTicks = 0;
    uint64_t cycle = 0, busy = 0, idle = 0, body = 0;
    int64_t gtWait = -1;  // ticks the game thread waited in RunSession(-1) since the last cycle (-1 = not timed)
    uint32_t gtN = 0, idleN = 0;
    uint64_t stage[kStages] = {};
    uint32_t stageN[kStages] = {};
    // aggregate only
    uint64_t window = 0, maxBusy = 0, slowBusy = 0;
    uint32_t frames = 0, slow = 0;
    uint64_t slowStage[kStages] = {};
};

struct Top {  // the sampler's verdict for one cycle
    std::atomic<uint32_t> seq{0};
    uint32_t marker = 0, count = 0, total = 0;
};

struct StageEvent {
    uint32_t stage = 0, durTicks = 0;
    uint64_t endTicks = 0;
};

struct Sites {
    uint8_t* bodyCall = nullptr;
    uint8_t* endRun = nullptr;  // the 12 bytes mov edx,-2 .. call [r8+70h]
    uint8_t* gtRun = nullptr;   // the 11 bytes mov edx,-1 .. call [rax+70h]
    uint8_t* call[kStages] = {};
    uint8_t* target[kStages] = {};
    volatile uint32_t* marker = nullptr;
    uint8_t* region = nullptr;
};

using Fn4 = uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t);
using FnF = uint64_t (*)(uint64_t, float, uint64_t, uint64_t);
using Fn5 = uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
using RunFn = uint8_t (*)(void*, int32_t);

Sites st;
bool g_installed = false, g_profileInstalled = false, g_ctxInstalled = false, g_gtTimed = false;
uint8_t* g_target[kStages] = {};
std::atomic<bool> g_on{false}, g_ctxOn{false};
std::atomic<uint32_t> g_thresholdMs{10};
std::atomic<uint32_t> g_sampleHz{1000};
std::atomic<DWORD> g_otId{0};
std::atomic<uint32_t> g_frameSeq{0};
std::atomic<int64_t> g_gtWaitTicks{0};
std::atomic<uint32_t> g_gtWaitN{0}, g_dropped{0};
int64_t g_freq = 1;
uint64_t (*g_testClock)() = nullptr;
std::wstring g_path;
volatile uint32_t g_fakeMarker = 0;
const volatile uint32_t* g_markerOverride = nullptr;

// OT only
struct Acc {
    uint64_t stage[kStages] = {};
    uint32_t stageN[kStages] = {};
    uint64_t idle = 0;
    uint32_t idleN = 0;
};
Acc g_cur;
uint64_t g_cycleStart = 0, g_winStart = 0;
uint32_t g_seq = 0;
Record g_win;
uint64_t g_active[kStages] = {};  // start ticks of the stages in progress (0 = not running)
StageEvent g_events[16];
uint32_t g_eventIdx = 0;

// ring: OT produces, the monitor thread consumes
Record g_ring[kRing];
std::atomic<uint64_t> g_head{0}, g_tail{0};

// sampler
Top g_top[256];
std::atomic<uint32_t> g_hist[kMarkers];
std::atomic<uint32_t> g_recent[16];
std::atomic<uint32_t> g_recentIdx{0};
HANDLE g_sampler = nullptr;

// monitor thread
FILE* g_file = nullptr;
long g_fileBytes = 0;
bool g_fileFull = false, g_fileFailed = false;
uint64_t g_lastMTicks = 0;
uint32_t g_lastHist[kMarkers];

// crash context
PVOID g_veh = nullptr;
std::atomic<uint32_t> g_ctxLogged{0};
volatile LONG g_ctxBusy = 0;

uint64_t Now()
{
    if (g_testClock) return g_testClock();
    LARGE_INTEGER t;
    QueryPerformanceCounter(&t);
    return static_cast<uint64_t>(t.QuadPart);
}

double Ms(uint64_t ticks) { return static_cast<double>(ticks) * 1000.0 / static_cast<double>(g_freq); }
double MsI(int64_t ticks) { return ticks < 0 ? -1.0 : Ms(static_cast<uint64_t>(ticks)); }

bool OnOt() { return GetCurrentThreadId() == g_otId.load(std::memory_order_relaxed); }
bool Active() { return g_on.load(std::memory_order_relaxed) && OnOt(); }

uint32_t ReadMarker()
{
    const volatile uint32_t* const m = g_markerOverride ? g_markerOverride : st.marker;
    return m ? *m : 0;
}

void Push(const Record& r)
{
    const uint64_t h = g_head.load(std::memory_order_relaxed);
    if (h - g_tail.load(std::memory_order_acquire) >= kRing) {
        g_dropped.fetch_add(1, std::memory_order_relaxed);
        return;
    }
    g_ring[h % kRing] = r;
    g_head.store(h + 1, std::memory_order_release);
}

// ---- OT: stage scopes and cycle bookkeeping ----
void Account(int s, uint64_t t0, uint64_t t1)
{
    const uint64_t d = t1 > t0 ? t1 - t0 : 0;
    g_cur.stage[s] += d;
    g_cur.stageN[s]++;
    StageEvent& e = g_events[g_eventIdx++ & 15];
    e.stage = static_cast<uint32_t>(s);
    e.durTicks = d > 0xFFFFFFFFull ? 0xFFFFFFFFu : static_cast<uint32_t>(d);
    e.endTicks = t1;
}

struct Scope {
    int s;
    uint64_t t0;
    explicit Scope(int stage) : s(stage), t0(Now()) { g_active[s] = t0; }
    ~Scope()
    {
        g_active[s] = 0;
        Account(s, t0, Now());
    }
};

void EndCycle(uint64_t now)
{
    const uint64_t cycle = now - g_cycleStart;
    Record r;
    r.kind = 1;
    r.seq = g_seq;
    r.endTicks = now;
    r.cycle = cycle;
    r.idle = g_cur.idle < cycle ? g_cur.idle : cycle;
    r.busy = cycle - r.idle;
    r.body = g_cur.stage[kBody];
    r.idleN = g_cur.idleN;
    r.gtN = g_gtWaitN.exchange(0, std::memory_order_relaxed);
    const int64_t gt = g_gtWaitTicks.exchange(0, std::memory_order_relaxed);
    r.gtWait = g_gtTimed ? gt : -1;
    memcpy(r.stage, g_cur.stage, sizeof r.stage);
    memcpy(r.stageN, g_cur.stageN, sizeof r.stageN);
    const uint64_t thr = static_cast<uint64_t>(g_thresholdMs.load(std::memory_order_relaxed)) * static_cast<uint64_t>(g_freq) / 1000;
    const bool slow = r.busy >= thr;
    // the window
    Record& w = g_win;
    w.frames++;
    w.cycle += r.cycle;
    w.busy += r.busy;
    w.idle += r.idle;
    w.body += r.body;
    w.idleN += r.idleN;
    w.gtN += r.gtN;
    if (r.gtWait >= 0) w.gtWait = (w.gtWait < 0 ? 0 : w.gtWait) + r.gtWait;
    if (r.busy > w.maxBusy) w.maxBusy = r.busy;
    for (int s = 0; s < kStages; ++s) {
        w.stage[s] += r.stage[s];
        w.stageN[s] += r.stageN[s];
        if (slow) w.slowStage[s] += r.stage[s];
    }
    if (slow) {
        w.slow++;
        w.slowBusy += r.busy;
        Push(r);
    }
    if (now - g_winStart >= kWindowUs * static_cast<uint64_t>(g_freq) / 1000000) {
        w.kind = 2;
        w.seq = g_seq;
        w.endTicks = now;
        w.window = now - g_winStart;
        Push(w);
        w = Record{};
        w.gtWait = -1;
        g_winStart = now;
    }
    g_cur = Acc{};
}

void ResetOt()
{
    g_cycleStart = 0;
    g_cur = Acc{};
    g_win = Record{};
    g_win.gtWait = -1;
    memset(g_active, 0, sizeof g_active);
}

// ---- hooks ----
uint64_t FrameHook(uint64_t a, uint64_t b, uint64_t c, uint64_t d)
{
    const Fn4 fn = reinterpret_cast<Fn4>(g_target[kBody]);
    if (!g_otId.load(std::memory_order_relaxed)) g_otId.store(GetCurrentThreadId(), std::memory_order_relaxed);
    if (!g_on.load(std::memory_order_relaxed) || !OnOt()) {
        if (g_cycleStart) ResetOt();
        return fn(a, b, c, d);
    }
    const uint64_t now = Now();
    if (g_cycleStart) EndCycle(now);
    else {
        g_cur = Acc{};
        g_win = Record{};
        g_win.gtWait = -1;
        g_winStart = now;
        g_gtWaitTicks.store(0, std::memory_order_relaxed);
        g_gtWaitN.store(0, std::memory_order_relaxed);
    }
    g_cycleStart = now;
    ++g_seq;
    g_frameSeq.store(g_seq, std::memory_order_release);
    g_active[kBody] = now;
    const uint64_t r = fn(a, b, c, d);
    g_active[kBody] = 0;
    Account(kBody, now, Now());
    return r;
}

template <int S>
uint64_t Hook4(uint64_t a, uint64_t b, uint64_t c, uint64_t d)
{
    const Fn4 fn = reinterpret_cast<Fn4>(g_target[S]);
    if (!Active()) return fn(a, b, c, d);
    Scope scope(S);
    return fn(a, b, c, d);
}

template <int S>
uint64_t HookF(uint64_t a, float f, uint64_t c, uint64_t d)
{
    const FnF fn = reinterpret_cast<FnF>(g_target[S]);
    if (!Active()) return fn(a, f, c, d);
    Scope scope(S);
    return fn(a, f, c, d);
}

uint64_t HookDoor(uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e)
{
    const Fn5 fn = reinterpret_cast<Fn5>(g_target[kDoor]);
    if (!Active()) return fn(a, b, c, d, e);
    Scope scope(kDoor);
    return fn(a, b, c, d, e);
}

// RunSession(-2): the OT waits for the game thread
uint64_t HookRunOt(void* manager)
{
    const RunFn run = reinterpret_cast<RunFn>((*static_cast<void***>(manager))[0x70 / 8]);
    if (!Active()) return run(manager, -2);
    const uint64_t t0 = Now();
    const uint8_t r = run(manager, -2);
    g_cur.idle += Now() - t0;
    g_cur.idleN++;
    return r;
}

// RunSession(-1): the game thread waits for the OT
uint64_t HookRunGt(void* manager)
{
    const RunFn run = reinterpret_cast<RunFn>((*static_cast<void***>(manager))[0x70 / 8]);
    if (!g_on.load(std::memory_order_relaxed)) return run(manager, -1);
    const uint64_t t0 = Now();
    const uint8_t r = run(manager, -1);
    g_gtWaitTicks.fetch_add(static_cast<int64_t>(Now() - t0), std::memory_order_relaxed);
    g_gtWaitN.fetch_add(1, std::memory_order_relaxed);
    return r;
}

void* const kHooks[kStages] = {
    nullptr,
    reinterpret_cast<void*>(&Hook4<kPlPre>),
    reinterpret_cast<void*>(&Hook4<kPlUpdate>),
    reinterpret_cast<void*>(&HookF<kLvlLow>),
    reinterpret_cast<void*>(&HookF<kLvlMidLow>),
    reinterpret_cast<void*>(&HookF<kLvlMidHigh>),
    reinterpret_cast<void*>(&HookF<kLvlHigh>),
    reinterpret_cast<void*>(&Hook4<kPlPass2>),
    reinterpret_cast<void*>(&Hook4<kPlPass3>),
    reinterpret_cast<void*>(&Hook4<kGridPlayer>),
    reinterpret_cast<void*>(&Hook4<kGridOwn>),
    reinterpret_cast<void*>(&HookDoor),
    reinterpret_cast<void*>(&HookF<kPlTimed>),
    reinterpret_cast<void*>(&HookF<kWater>),
    reinterpret_cast<void*>(&Hook4<kSave>),
};

// ---- sampler thread: the engine's stage marker ----
DWORD WINAPI SamplerMain(void*)
{
    static uint32_t cur[kMarkers];
    uint32_t lastSeq = 0, lastMarker = 0xFFFFFFFFu;
    for (;;) {
        const uint32_t hz = g_sampleHz.load(std::memory_order_relaxed);
        if (!hz || (!g_on.load(std::memory_order_relaxed) && !g_ctxOn.load(std::memory_order_relaxed))) {
            Sleep(100);
            lastSeq = g_frameSeq.load(std::memory_order_acquire);
            memset(cur, 0, sizeof cur);
            continue;
        }
        const uint32_t seq = g_frameSeq.load(std::memory_order_acquire);
        if (seq != lastSeq) {
            if (lastSeq) {  // the finished cycle's most frequent marker
                uint32_t best = 0, total = 0;
                for (uint32_t m = 0; m < kMarkers; ++m) {
                    total += cur[m];
                    if (cur[m] > cur[best]) best = m;
                }
                Top& t = g_top[lastSeq & 255];
                t.seq.store(0, std::memory_order_relaxed);
                t.marker = best;
                t.count = cur[best];
                t.total = total;
                t.seq.store(lastSeq, std::memory_order_release);
            }
            memset(cur, 0, sizeof cur);
            lastSeq = seq;
        }
        const uint32_t m = ReadMarker();
        const uint32_t bin = m < kMarkers ? m : kMarkers - 1;
        cur[bin]++;
        g_hist[bin].fetch_add(1, std::memory_order_relaxed);
        if (m != lastMarker) {
            lastMarker = m;
            g_recent[g_recentIdx.fetch_add(1, std::memory_order_relaxed) & 15].store(m, std::memory_order_relaxed);
        }
        const DWORD ms = hz >= 1000 ? 1 : 1000 / (hz ? hz : 1);
        Sleep(ms);
    }
}

// ---- crash context ----
const char* MarkerName(uint32_t m)
{
    switch (m) {
        case 0x00: return "frame start / before ProcessLists";
        case 0x32: return "after ProcessLists pass 1";
        case 0x64: return "ProcessLists::Update";
        case 0x6E: return "Update: start";
        case 0x78: return "Update: first level pass";
        case 0x82: return "Update: second level pass";
        case 0x8C: return "Update: third level pass";
        case 0xB4: return "Update: fourth level pass";
        case 0xBE: return "Update: done";
        case 0xC8: return "ProcessLists pass 2";
        case 0x12C: return "ProcessLists pass 3";
        case 0x190: return "after the ProcessLists passes (player, grid, door, ...)";
        default: return (m >= 0x83 && m <= 0x8A) || m == 0x1F9 || m == 0x84 ? "inside the second level pass" : "?";
    }
}

std::string Where(const GameModule& game, uint64_t addr)
{
    char b[96];
    if (addr >= reinterpret_cast<uint64_t>(game.base) && addr < reinterpret_cast<uint64_t>(game.base) + game.sizeOfImage)
        snprintf(b, sizeof b, "exe+0x%llX", static_cast<unsigned long long>(addr - reinterpret_cast<uint64_t>(game.base)));
    else {
        HMODULE mod = nullptr;
        wchar_t name[MAX_PATH] = {};
        if (GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                               reinterpret_cast<LPCWSTR>(addr), &mod) && mod && GetModuleFileNameW(mod, name, MAX_PATH)) {
            const wchar_t* base = wcsrchr(name, L'\\');
            snprintf(b, sizeof b, "%ls+0x%llX", base ? base + 1 : name, static_cast<unsigned long long>(addr - reinterpret_cast<uint64_t>(mod)));
        } else snprintf(b, sizeof b, "0x%llX (outside the exe)", static_cast<unsigned long long>(addr));
    }
    return b;
}

bool IsFaultCode(DWORD c)
{
    switch (c) {
        case 0xC0000005: case 0xC0000006: case 0xC000001D: case 0xC0000096: case 0xC0000094: case 0xC00000FD:
        case 0xC0000409: case 0xC0000374: case 0xC000008C: case 0xC0000025: case 0xC0000026:
            return true;
        default: return false;
    }
}

// The std::string temporaries live in this helper, not inside the __try below: clang 21 crashes in the SEH table
// emission (/EHa) when a __try body holds objects with destructors.
__declspec(noinline) static int AppendWhere(char* line, int n, size_t cap, const GameModule& game, uint64_t rip)
{
    return n + snprintf(line + n, cap - n, " %s", Where(game, rip).c_str());
}

__declspec(noinline) static int StackText(EXCEPTION_POINTERS* ep, const GameModule& game, char* line, size_t cap, int n)
{
    __try {
        CONTEXT ctx = *ep->ContextRecord;
        for (int i = 0; i < 14 && ctx.Rip && n < 800; ++i) {
            n = AppendWhere(line, n, cap, game, ctx.Rip);
            DWORD64 base = 0;
            PRUNTIME_FUNCTION fn = RtlLookupFunctionEntry(ctx.Rip, &base, nullptr);
            if (!fn) {
                ctx.Rip = *reinterpret_cast<DWORD64*>(ctx.Rsp);
                ctx.Rsp += 8;
            } else {
                PVOID handler = nullptr;
                DWORD64 frame = 0;
                RtlVirtualUnwind(UNW_FLAG_NHANDLER, base, ctx.Rip, fn, &ctx, &handler, &frame, nullptr);
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        n += snprintf(line + n, cap - n, " (stack unreadable)");
    }
    return n;
}

void LogContext(EXCEPTION_POINTERS* ep, bool stackOverflow)
{
    const GameModule& game = Game();
    const EXCEPTION_RECORD& er = *ep->ExceptionRecord;
    const uint64_t now = Now();
    char acc[160] = "";
    if ((er.ExceptionCode == 0xC0000005 || er.ExceptionCode == 0xC0000006) && er.NumberParameters >= 2)
        snprintf(acc, sizeof acc, " (%s address 0x%llX)", er.ExceptionInformation[0] == 1 ? "write to" : er.ExceptionInformation[0] == 8 ? "execute at" : "read of",
                 static_cast<unsigned long long>(er.ExceptionInformation[1]));
    const uint32_t marker = ReadMarker();
    Log("[otctx] exception 0x%08lX%s on the OblivionThread at %s; stage marker 0x%X (%s); cycle %u; first-chance (it may be handled)",
        static_cast<unsigned long>(er.ExceptionCode), acc, Where(game, reinterpret_cast<uint64_t>(er.ExceptionAddress)).c_str(), marker,
        MarkerName(marker), g_seq);
    if (stackOverflow) return;
    // stages in progress (timing stubs) and the recent marker values
    char line[900];
    int n = snprintf(line, sizeof line, "[otctx] in progress:");
    bool any = false;
    for (int s = 0; s < kStages && n < 700; ++s)
        if (g_active[s]) {
            n += snprintf(line + n, sizeof line - n, " %s(%.1f ms)", kStageName[s], Ms(now - g_active[s]));
            any = true;
        }
    if (!any) n += snprintf(line + n, sizeof line - n, " none timed%s", g_profileInstalled ? "" : " (OtProfile is off)");
    n += snprintf(line + n, sizeof line - n, "; recent marker values (oldest first):");
    const uint32_t ri = g_recentIdx.load(std::memory_order_relaxed);
    const uint32_t cnt = ri < 16 ? ri : 16;
    for (uint32_t i = 0; i < cnt && n < 850; ++i)
        n += snprintf(line + n, sizeof line - n, " 0x%X", g_recent[(ri - cnt + i) & 15].load(std::memory_order_relaxed));
    Log("%s", line);
    // the last completed stages
    n = snprintf(line, sizeof line, "[otctx] last completed stages (newest first, ms ago / length):");
    for (uint32_t i = 1; i <= 16 && i <= g_eventIdx && n < 800; ++i) {
        const StageEvent& e = g_events[(g_eventIdx - i) & 15];
        n += snprintf(line + n, sizeof line - n, " %s(%.1f/%.2f)", kStageName[e.stage < kStages ? e.stage : 0], Ms(now - e.endTicks), Ms(e.durTicks));
    }
    if (!g_eventIdx) n += snprintf(line + n, sizeof line - n, " none recorded%s", g_profileInstalled ? "" : " (OtProfile is off)");
    Log("%s", line);
    // the call stack from the fault (the exe's .pdata)
    n = snprintf(line, sizeof line, "[otctx] stack:");
    n = StackText(ep, game, line, sizeof line, n);
    Log("%s", line);
}

LONG CALLBACK OtVeh(EXCEPTION_POINTERS* ep)
{
    if (!g_ctxOn.load(std::memory_order_relaxed) || !OnOt() || !ep || !ep->ExceptionRecord) return EXCEPTION_CONTINUE_SEARCH;
    if (!IsFaultCode(ep->ExceptionRecord->ExceptionCode)) return EXCEPTION_CONTINUE_SEARCH;
    if (g_ctxLogged.load(std::memory_order_relaxed) >= 24) return EXCEPTION_CONTINUE_SEARCH;
    if (InterlockedExchange(&g_ctxBusy, 1)) return EXCEPTION_CONTINUE_SEARCH;
    g_ctxLogged.fetch_add(1, std::memory_order_relaxed);
    __try {
        LogContext(ep, ep->ExceptionRecord->ExceptionCode == 0xC00000FD);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
    }
    InterlockedExchange(&g_ctxBusy, 0);
    return EXCEPTION_CONTINUE_SEARCH;  // never handled here
}

// ---- install helpers ----
uint8_t* FindOne(const GameModule& game, const char* pattern, const char* what)
{
    const auto hits = FindAll(game.text, ParsePattern(pattern));
    if (hits.size() == 1) return hits[0];
    Log("[otprofile] %s %s", what, hits.empty() ? "not found" : "ambiguous");
    return nullptr;
}

uint8_t* CallTarget(const GameModule& game, const uint8_t* call)
{
    if (!call || call[0] != 0xE8) return nullptr;
    uint8_t* const t = RipTarget(call, 1, 5);
    return game.text.Contains(t) ? t : nullptr;
}

void JmpStub(uint8_t* slot, void* hook)
{
    const uint8_t jmpAbs[6] = {0xFF, 0x25, 0, 0, 0, 0};
    memcpy(slot, jmpAbs, 6);
    memcpy(slot + 6, &hook, 8);
}

bool Rel32(const uint8_t* from, const uint8_t* to, int32_t* out)
{
    const int64_t rel = to - from;
    *out = static_cast<int32_t>(rel);
    return rel == *out;
}

bool RedirectCall(uint8_t* call, uint8_t* stub)
{
    int32_t rel;
    return Rel32(call + 5, stub, &rel) && WriteCode(call + 1, std::span<const uint8_t>(reinterpret_cast<const uint8_t*>(&rel), 4));
}

// All the engine's marker writes in the sites name one DWORD in .data
bool CheckMarker(const GameModule& game, uint8_t*& marker, const uint8_t* insn, size_t disp, size_t len)
{
    uint8_t* const m = RipTarget(insn, disp, len);
    if (!game.data.Contains(m) || (reinterpret_cast<uintptr_t>(m) & 3)) return false;
    if (marker && marker != m) return false;
    marker = m;
    return true;
}

bool Matches(const uint8_t* at, const char* pattern) { return at && MatchesAt(at, ParsePattern(pattern)); }

struct StageSite {
    Stage stage;
    uint8_t* call;
    const char* calleePattern;  // nullptr = no prologue check (the target must still be in .text)
    const char* what;
};

void FindStages(const GameModule& game, bool gridSafe, std::vector<StageSite>& out, uint8_t*& marker, bool& markersOk)
{
    markersOk = true;
    auto mark = [&](const uint8_t* insn, size_t disp, size_t len) {
        if (!CheckMarker(game, marker, insn, disp, len)) {
            markersOk = false;
            Log("[otprofile] marker write at exe+0x%X names exe+0x%X (expected the same global as the others, in .data)",
                static_cast<unsigned>(insn - game.base), static_cast<unsigned>(RipTarget(insn, disp, len) - game.base));
        }
    };
    if (uint8_t* p = FindOne(game, kPl1, "ProcessLists pass 1 (before the main update)")) {
        mark(p, 3, 7);
        mark(p + 20, 2, 10);
        out.push_back({kPlPre, p + kPl1Call, kPassFn, "ProcessLists pass 1"});
    }
    if (uint8_t* p = FindOne(game, kPlMain, "the ProcessLists main update sequence")) {
        for (size_t o : kPlMainMarkers) mark(p + o, 2, 10);
        out.push_back({kPlUpdate, p + kPlMainUpdate, kUpdateFn, "ProcessLists::Update"});
        out.push_back({kPlPass2, p + kPlMainPass2, kPassFn, "ProcessLists pass 2"});
        out.push_back({kPlPass3, p + kPlMainPass3, kPass3Fn, "ProcessLists pass 3"});
    }
    if (uint8_t* p = FindOne(game, kLevels, "ProcessLists::Update's level passes")) {
        mark(p + 5, 2, 6);
        for (size_t o : kLevelMarkers) mark(p + o, 2, 10);
        out.push_back({kLvlLow, p + kLevelCalls[0], kLowFn, "level pass 1"});
        out.push_back({kLvlMidLow, p + kLevelCalls[1], kMidLowFn, "level pass 2"});
        out.push_back({kLvlMidHigh, p + kLevelCalls[2], kMidHighFn, "level pass 3"});
        out.push_back({kLvlHigh, p + kLevelCalls[3], kHighFn, "level pass 4"});
    }
    if (gridSafe) {
        uint8_t* const g1 = FindOne(game, kGrid1, "the first grid-change call");
        uint8_t* const g2 = FindOne(game, kGrid2, "the second grid-change call");
        uint8_t* const t1 = CallTarget(game, g1 ? g1 + kGrid1Call : nullptr);
        uint8_t* const t2 = CallTarget(game, g2 ? g2 + kGrid2Call : nullptr);
        // the entry is the game's own, or already a detour (HitchLedger's) whose trampoline still ends in the game's code
        if (t1 && t1 == t2 && (Matches(t1, kGridFn) || t1[0] == 0xE9)) {
            out.push_back({kGridPlayer, g1 + kGrid1Call, nullptr, "grid change 1"});
            out.push_back({kGridOwn, g2 + kGrid2Call, nullptr, "grid change 2"});
        } else Log("[otprofile] the cell-grid change calls were not recognised: grid_player and grid_own are not timed");
    } else Log("[otprofile] CellBufferPacedEvict is on (it keys on the grid-change calls' return addresses): grid_player and grid_own are not timed");
    if (uint8_t* p = FindOne(game, kPDoor, "the door / arrival handler call")) out.push_back({kDoor, p + kDoorCall, kDoorFn, "door handler"});
    if (uint8_t* p = FindOne(game, kPl2, "ProcessLists' time-driven pass")) out.push_back({kPlTimed, p + kPl2Call, kTimedFn, "ProcessLists time-driven pass"});
    if (uint8_t* p = FindOne(game, kPWater, "the water update call")) out.push_back({kWater, p + kWaterCall, kWaterFn, "water update"});
    if (uint8_t* p = FindOne(game, kPSave, "the save entry call")) out.push_back({kSave, p + kSaveCall, kSaveFn, "save entry"});
}

// ---- the csv ----
void FormatStages(std::string& s, const uint64_t* v)
{
    char b[32];
    for (int i = 1; i < kStages; ++i) {
        snprintf(b, sizeof b, ",%.3f", Ms(v[i]));
        s += b;
    }
}

std::string FrameColumns()
{
    std::string s = "F,seq,end_ms,cycle_ms,busy_ms,idle_ms,body_ms,other_ms,gtwait_ms,gtwait_n,marker,marker_pct";
    for (int i = 1; i < kStages; ++i) s += std::string(",") + kStageName[i] + "_ms";
    return s;
}

std::string SummaryColumns()
{
    std::string s = "S,seq,end_ms,window_s,frames,slow,cycle_ms,busy_ms,idle_ms,body_ms,gtwait_ms,gtwait_n,max_busy_ms,slow_busy_ms";
    for (int i = 1; i < kStages; ++i) s += std::string(",") + kStageName[i] + "_ms";
    for (int i = 1; i < kStages; ++i) s += std::string(",slow_") + kStageName[i] + "_ms";
    for (int i = 1; i < kStages; ++i) s += std::string(",") + kStageName[i] + "_n";
    return s;
}

uint64_t Other(const Record& r)
{
    uint64_t sum = 0;
    for (int i = 1; i < kStages; ++i)
        if (kTopLevel[i]) sum += r.stage[i];
    return r.stage[kBody] > sum ? r.stage[kBody] - sum : 0;
}

std::string FormatRecord(const Record& r)
{
    char b[256];
    std::string s;
    const double endMs = static_cast<double>(QpcToMicroseconds(r.endTicks, static_cast<uint64_t>(g_freq))) / 1000.0;
    if (r.kind == 1) {
        uint32_t marker = 0, pct = 0;
        bool have = false;
        const Top& t = g_top[r.seq & 255];
        if (t.seq.load(std::memory_order_acquire) == r.seq && t.total) {
            marker = t.marker;
            pct = t.count * 100 / t.total;
            have = true;
        }
        snprintf(b, sizeof b, "F,%u,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%u,", r.seq, endMs, Ms(r.cycle), Ms(r.busy), Ms(r.idle), Ms(r.body),
                 Ms(Other(r)), MsI(r.gtWait), r.gtN);
        s = b;
        if (have) snprintf(b, sizeof b, "0x%X,%u", marker, pct);
        else snprintf(b, sizeof b, ",");
        s += b;
        FormatStages(s, r.stage);
        s += "\n";
        return s;
    }
    snprintf(b, sizeof b, "S,%u,%.3f,%.3f,%u,%u,%.3f,%.3f,%.3f,%.3f,%.3f,%u,%.3f,%.3f", r.seq, endMs, Ms(r.window) / 1000.0, r.frames, r.slow,
             Ms(r.cycle), Ms(r.busy), Ms(r.idle), Ms(r.body), MsI(r.gtWait), r.gtN, Ms(r.maxBusy), Ms(r.slowBusy));
    s = b;
    FormatStages(s, r.stage);
    FormatStages(s, r.slowStage);
    for (int i = 1; i < kStages; ++i) {
        snprintf(b, sizeof b, ",%u", r.stageN[i]);
        s += b;
    }
    s += "\n";
    return s;
}

void WriteLine(const std::string& line)
{
    if (!g_file || g_fileFull || line.empty()) return;
    if (g_fileBytes + static_cast<long>(line.size()) > kMaxFileBytes) {
        g_fileFull = true;
        fputs("# size limit reached: no more rows\n", g_file);
        fflush(g_file);
        Log("[otprofile] OblivionPerfFix-otprofile.csv reached %ld MB: no more rows this session", kMaxFileBytes >> 20);
        return;
    }
    fwrite(line.data(), 1, line.size(), g_file);
    g_fileBytes += static_cast<long>(line.size());
}

bool OpenFile()
{
    if (g_file) return true;
    if (g_fileFailed || g_path.empty()) return false;
    const std::wstring prev = g_path.substr(0, g_path.size() - 4) + L".1.csv";
    MoveFileExW(g_path.c_str(), prev.c_str(), MOVEFILE_REPLACE_EXISTING);
    g_file = _wfsopen(g_path.c_str(), L"w", _SH_DENYWR);
    if (!g_file) {
        g_fileFailed = true;
        Log("[otprofile] could not create %ls: no profile this session", g_path.c_str());
        return false;
    }
    std::string sig;
    char b[64];
    for (int i = 0; i < kStages; ++i) {
        snprintf(b, sizeof b, "%s%s:%d", i ? "," : "", kStageName[i], g_target[i] != nullptr);
        sig += b;
    }
    char head[1400];
    snprintf(head, sizeof head,
             "# OblivionPerfFix-otprofile v1, OblivionPerfFix " OPF_VERSION ", qpc_freq=%lld, pid=%lu, threshold_ms=%u, sample_hz=%u, "
             "gt_wait=%d, signals=%s\n# times: end_ms = QueryPerformanceCounter / frequency in ms (HitchLedger's clock); cycle = one OT frame "
             "body entry to the next, busy = cycle - idle, idle = RunSession(-2) (the OT waiting for the game thread), gtwait = the game "
             "thread inside RunSession(-1); other = body - the top-level stages\n",
             static_cast<long long>(g_freq), GetCurrentProcessId(), g_thresholdMs.load(), g_sampleHz.load(), g_gtTimed, sig.c_str());
    WriteLine(head);
    WriteLine("#" + FrameColumns() + "\n#" + SummaryColumns() + "\n#M,end_ms,samples,marker=count;...\n");
    fflush(g_file);
    Log("[otprofile] writing slow OT cycles (busy >= %u ms) and 2 s aggregates to %ls", g_thresholdMs.load(), g_path.c_str());
    return true;
}

}  // namespace

// ---- start-up ----
bool InstallOtProfile(bool beforeGameCode, const wchar_t* dir, bool profile, bool crashContext, bool pacingHooked, bool gridSafe)
{
    if (g_installed) return true;
    LARGE_INTEGER f;
    QueryPerformanceFrequency(&f);
    g_freq = f.QuadPart;
    if (dir) g_path = std::wstring(dir) + L"\\OblivionPerfFix-otprofile.csv";
    if (!profile && !crashContext) return false;
    if (!beforeGameCode) {
        Log("[otprofile] OtProfile / OtCrashContext: can only be installed at start-up (version.dll), not installed");
        return false;
    }
    const GameModule& game = Game();
    // the frame body's call: the one essential site (the OT's cycle, its thread id)
    uint8_t* const bodyHit = FindOne(game, kBodyCall, "the OT loop's call of the frame body");
    uint8_t* const bodyCall = bodyHit ? bodyHit + kBodyCallAt : nullptr;
    uint8_t* const body = CallTarget(game, bodyCall);
    if (!body || !Matches(body, kBodyEntry)) {
        Log("[otprofile] the frame body is not where expected: not installed");
        return false;
    }
    std::vector<StageSite> sites;
    uint8_t* marker = nullptr;
    bool markersOk = true;
    uint8_t* endHit = nullptr;
    uint8_t* gtHit = nullptr;
    if (profile) {
        FindStages(game, gridSafe, sites, marker, markersOk);
        endHit = FindOne(game, kEndPair, "the OT's Handler_End / RunSession(-2) pair");
        if (!pacingHooked) gtHit = FindOne(game, kGtRun, "the game thread's RunSession(-1) call");
        if (!marker || !markersOk) {
            Log("[otprofile] the engine's stage marker was not recognised (the marker writes name different globals): not installed");
            return false;
        }
        if (!endHit) {
            Log("[otprofile] the OT's end-of-frame pair was not found: not installed");
            return false;
        }
    } else {
        // crash context only: the marker alone
        uint8_t* p = FindOne(game, kPlMain, "the ProcessLists main update sequence");
        if (p) CheckMarker(game, marker, p, 2, 10);
        if (!marker) Log("[otprofile] the stage marker was not recognised: the crash context omits it");
    }
    uint8_t* const region = AllocNearGame(512);
    if (!region) {
        Log("[otprofile] no memory near the game's code: not installed");
        return false;
    }
    memset(region, 0xCC, 512);
    st.region = region;
    st.marker = reinterpret_cast<volatile uint32_t*>(marker);
    st.bodyCall = bodyCall;
    g_target[kBody] = body;
    // stubs: slot i*16 for stage i (the frame body is slot 0); the two RunSession(-n) stubs at 15 and 16
    JmpStub(region, reinterpret_cast<void*>(&FrameHook));
    std::vector<StageSite> good;
    for (const StageSite& s : sites) {
        uint8_t* const t = CallTarget(game, s.call);
        if (!t || (s.calleePattern && !Matches(t, s.calleePattern))) {
            Log("[otprofile] %s: the call or its target is not as expected, not timed", s.what);
            continue;
        }
        if (s.stage == kPlPre || s.stage == kPlPass2) {  // the same function: both calls must agree
            static uint8_t* pass = nullptr;
            if (pass && pass != t) {
                Log("[otprofile] ProcessLists passes 1 and 2 call different functions: %s not timed", s.what);
                continue;
            }
            pass = t;
        }
        JmpStub(region + s.stage * 16, kHooks[s.stage]);
        g_target[s.stage] = t;
        st.call[s.stage] = s.call;
        st.target[s.stage] = t;
        good.push_back(s);
    }
    uint8_t* runStubOt = nullptr;
    uint8_t* runStubGt = nullptr;
    if (endHit) {
        uint8_t* const at = endHit + kEndPairRun;
        runStubOt = region + kStages * 16;
        JmpStub(runStubOt, reinterpret_cast<void*>(&HookRunOt));
        st.endRun = at;
    }
    if (gtHit) {
        runStubGt = region + (kStages + 1) * 16;
        JmpStub(runStubGt, reinterpret_cast<void*>(&HookRunGt));
        st.gtRun = gtHit + kGtRunAt;
    }
    DWORD old;
    VirtualProtect(region, 512, PAGE_EXECUTE_READ, &old);
    FlushInstructionCache(GetCurrentProcess(), region, 512);
    // the writes: the frame body call first (it also gives the OT's thread id)
    if (!RedirectCall(bodyCall, region)) {
        Log("[otprofile] could not redirect the frame body call: not installed");
        return false;
    }
    g_installed = true;
    int redirected = 0;
    std::string timed;
    for (const StageSite& s : good) {
        if (RedirectCall(s.call, region + s.stage * 16)) {
            ++redirected;
            timed += std::string(timed.empty() ? "" : ", ") + kStageName[s.stage];
        } else {
            Log("[otprofile] could not redirect the %s call: not timed", s.what);
            g_target[s.stage] = nullptr;
            st.call[s.stage] = nullptr;
        }
    }
    bool otRun = false;
    if (st.endRun) {
        // mov edx,-2; mov rcx,rbx; call [r8+70h]  ->  mov rcx,rbx; call stub; nop4
        int32_t rel;
        uint8_t code[12] = {0x48, 0x8B, 0xCB, 0xE8, 0, 0, 0, 0, 0x0F, 0x1F, 0x40, 0x00};
        if (Rel32(st.endRun + 8, runStubOt, &rel)) {
            memcpy(code + 4, &rel, 4);
            otRun = WriteCode(st.endRun, std::span<const uint8_t>(code, 12));
        }
        if (!otRun) {
            Log("[otprofile] could not rewrite the RunSession(-2) call: idle time not measured");
            st.endRun = nullptr;
        }
    }
    if (st.gtRun) {
        // mov edx,-1; mov rcx,rsi; call [rax+70h]  ->  mov rcx,rsi; call stub; nop3
        int32_t rel;
        uint8_t code[11] = {0x48, 0x8B, 0xCE, 0xE8, 0, 0, 0, 0, 0x0F, 0x1F, 0x00};
        if (Rel32(st.gtRun + 8, runStubGt, &rel)) {
            memcpy(code + 4, &rel, 4);
            g_gtTimed = WriteCode(st.gtRun, std::span<const uint8_t>(code, 11));
        }
        if (!g_gtTimed) {
            Log("[otprofile] could not rewrite the game thread's RunSession(-1) call: gtwait not measured");
            st.gtRun = nullptr;
        }
    }
    g_profileInstalled = profile;
    Log("[otprofile] installed: frame body %s; stages timed: %s; OT idle (RunSession(-2)) %s; game-thread wait (RunSession(-1)) %s; marker at "
        "exe+0x%X",
        "timed", timed.empty() ? "none" : timed.c_str(), otRun ? "timed" : "-",
        g_gtTimed ? "timed" : pacingHooked ? "- (NpcCreationPacing owns that call; HitchLedger's pair column has it)" : "-",
        marker ? static_cast<unsigned>(marker - game.base) : 0u);
    if (crashContext) {
        g_veh = AddVectoredExceptionHandler(1, &OtVeh);
        g_ctxInstalled = g_veh != nullptr;
        Log("[otctx] OtCrashContext %s (a fault on the OblivionThread is described in this log; the exception is never handled here)",
            g_ctxInstalled ? "installed" : "NOT installed (AddVectoredExceptionHandler failed)");
    }
    return true;
}

void StartOtSampler()
{
    if (!g_installed || g_sampler) return;
    g_sampler = CreateThread(nullptr, 0, SamplerMain, nullptr, 0, nullptr);
    if (g_sampler) {
        DescribeThread(g_sampler, L"OPF OT marker sampler");
        SetThreadPriority(g_sampler, THREAD_PRIORITY_BELOW_NORMAL);
    }
}

void SetOtProfile(bool on, int thresholdMs, int sampleHz, bool crashContext)
{
    const int ms = thresholdMs < 1 ? 1 : thresholdMs > 1000 ? 1000 : thresholdMs;
    g_thresholdMs.store(static_cast<uint32_t>(ms), std::memory_order_relaxed);
    g_sampleHz.store(sampleHz < 0 ? 0 : sampleHz > 1000 ? 1000 : static_cast<uint32_t>(sampleHz), std::memory_order_relaxed);
    if (!g_installed) {
        static bool logged = false;
        if ((on || crashContext) && !logged) {
            logged = true;
            Log("[otprofile] OtProfile / OtCrashContext are on but were not installed at start-up: restart the game to use them");
        }
        return;
    }
    const bool want = on && g_profileInstalled;
    if (g_on.exchange(want) != want) Log("[otprofile] %s", want ? "recording" : "stopped");
    const bool ctx = crashContext && g_ctxInstalled;
    if (g_ctxOn.exchange(ctx) != ctx) Log("[otctx] %s", ctx ? "active" : "stopped");
    if (want || ctx) StartOtSampler();
}

void OtProfileDrain()
{
    if (!g_installed || !g_profileInstalled) return;
    if (g_head.load() == g_tail.load(std::memory_order_relaxed) && !g_on.load(std::memory_order_relaxed)) {
        if (g_file) fflush(g_file);
        return;
    }
    if (!OpenFile()) {
        g_tail.store(g_head.load(std::memory_order_acquire), std::memory_order_release);
        return;
    }
    for (uint64_t t = g_tail.load(std::memory_order_relaxed); t != g_head.load(std::memory_order_acquire);) {
        const Record r = g_ring[t % kRing];
        g_tail.store(++t, std::memory_order_release);
        WriteLine(FormatRecord(r));
    }
    // the marker histogram of the last ~2 s
    const uint64_t now = Now();
    if (g_on.load(std::memory_order_relaxed) && g_sampleHz.load(std::memory_order_relaxed) &&
        now - g_lastMTicks >= 2 * static_cast<uint64_t>(g_freq)) {
        g_lastMTicks = now;
        uint32_t total = 0;
        std::string row;
        char b[48];
        for (int m = 0; m < kMarkers; ++m) {
            const uint32_t v = g_hist[m].load(std::memory_order_relaxed);
            const uint32_t d = v - g_lastHist[m];
            g_lastHist[m] = v;
            if (!d) continue;
            total += d;
            snprintf(b, sizeof b, "%s0x%X=%u", row.empty() ? "" : ";", m, d);
            row += b;
        }
        const uint32_t dropped = g_dropped.exchange(0, std::memory_order_relaxed);
        if (total) {
            snprintf(b, sizeof b, "M,%.3f,%u,", static_cast<double>(QpcToMicroseconds(now, static_cast<uint64_t>(g_freq))) / 1000.0, total);
            WriteLine(std::string(b) + row + "\n");
        }
        if (dropped) {
            snprintf(b, sizeof b, "# dropped %u rows (ring full)\n", dropped);
            WriteLine(b);
        }
    }
    fflush(g_file);
}

bool OtProfileInfo(OtProfileInfoOut* out)
{
    if (!out) return false;
    *out = OtProfileInfoOut{};
    out->installed = g_installed;
    out->bodyCall = st.bodyCall;
    out->endRun = st.endRun;
    out->gtRun = st.gtRun;
    for (int i = 0; i < kStages; ++i) {
        out->call[i] = st.call[i];
        out->target[i] = st.target[i];
        out->hook[i] = i == kBody ? reinterpret_cast<void*>(&FrameHook) : kHooks[i];
    }
    out->marker = const_cast<uint32_t*>(st.marker);
    out->region = st.region;
    out->runHookOt = reinterpret_cast<void*>(&HookRunOt);
    out->runHookGt = reinterpret_cast<void*>(&HookRunGt);
    out->ctxHandler = reinterpret_cast<void*>(&OtVeh);
    out->ctxInstalled = g_ctxInstalled;
    out->gtTimed = g_gtTimed;
    out->stages = kStages;
    out->ctxLogged = g_ctxLogged.load();
    out->recordSize = sizeof(Record);
    return true;
}

void OtProfileTestSetup(uint64_t (*clock)(), int64_t freq, const wchar_t* path, void* const* fakeTargets, uint32_t sampleHz)
{
    g_testClock = clock;
    g_freq = freq;
    if (fakeTargets)
        for (int i = 0; i < kStages; ++i)
            if (fakeTargets[i]) g_target[i] = static_cast<uint8_t*>(fakeTargets[i]);
    if (path) {
        if (g_file) { fclose(g_file); g_file = nullptr; }
        g_path = path;
        g_fileBytes = 0;
        g_fileFull = g_fileFailed = false;
    }
    g_markerOverride = &g_fakeMarker;
    g_sampleHz.store(sampleHz);
    g_otId.store(GetCurrentThreadId());
    g_installed = true;
    g_profileInstalled = true;
    g_ctxInstalled = true;
    ResetOt();
}

void OtProfileTestMarker(uint32_t m) { g_fakeMarker = m; }

void OtProfileTestClose()
{
    if (g_file) { fclose(g_file); g_file = nullptr; }
}

}  // namespace opf
