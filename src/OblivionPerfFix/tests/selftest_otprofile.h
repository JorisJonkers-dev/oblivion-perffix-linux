// Diagnostic OtProfile / OtCrashContext self-test, included by selftest.cpp: its sites on the mapped exe (call sites
// redirected to stubs, the two RunSession rewrites, the stage marker), then the cycle bookkeeping with fake stage functions and
// a fake clock (busy / idle / stage columns, slow rows, 2 s aggregate, the sampler's marker per cycle), the crash context
// (logged, exception continues), and the cost per cycle with the real clock. Checks "at exe+0x..." pin build 19115871.
#pragma once

#include <fstream>
#include <map>
#include <sstream>

namespace otp {
uint64_t g_now = 0;  // us
uint64_t Clock() { return g_now; }
uint64_t RealClock()
{
    LARGE_INTEGER t;
    QueryPerformanceCounter(&t);
    return static_cast<uint64_t>(t.QuadPart);
}
enum { kBody, kPlPre, kPlUpdate, kLvlLow, kLvlMidLow, kLvlMidHigh, kLvlHigh, kPlPass2, kPlPass3, kGridPlayer, kGridOwn, kDoor,
       kPlTimed, kWater, kSave, kStages };
using Fn4 = uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t);
using FnF = uint64_t (*)(uint64_t, float, uint64_t, uint64_t);
using Fn5 = uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
void* g_hook[kStages];
void* g_runOt = nullptr;
uint64_t g_len[kStages];  // us each fake stage takes
uint64_t g_slowExtra = 0; // extra us in lvl_high (the slow cycle)
bool g_realSleep = false;
uint64_t g_seen[4];       // arguments the fake saw (rcx, rdx, r8, r9)
float g_seenF = 0;
void* g_vt[16];
struct Mgr { void** vt; } g_mgr{g_vt};
uint64_t g_runLen = 4000, g_gtLen = 1500;
uint8_t FakeRun(void*, int32_t key)
{
    g_now += key == -2 ? g_runLen : g_gtLen;
    return 0;
}
uint64_t Stage4(uint64_t a, uint64_t b, uint64_t c, uint64_t d) { g_seen[0] = a; g_seen[1] = b; g_seen[2] = c; g_seen[3] = d; return 7; }
template <int S> uint64_t FakeS4(uint64_t a, uint64_t b, uint64_t c, uint64_t d) { g_now += g_len[S]; return Stage4(a, b, c, d); }
template <int S> uint64_t FakeSF(uint64_t a, float f, uint64_t c, uint64_t d)
{
    g_now += g_len[S] + (S == kLvlHigh ? g_slowExtra : 0);
    if (S == kLvlHigh && g_realSleep) Sleep(40);
    g_seenF = f;
    g_seen[0] = a;
    g_seen[2] = c;
    return 7;
}
uint64_t FakeDoor(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t e) { g_now += g_len[kDoor]; g_seen[3] = e; return 7; }
uint64_t FakeBody(uint64_t, uint64_t, uint64_t, uint64_t)
{
    g_now += 200;
    reinterpret_cast<Fn4>(g_hook[kPlPre])(1, 2, 3, 4);
    reinterpret_cast<Fn4>(g_hook[kPlUpdate])(1, 2, 3, 4);
    g_now += 100;
    reinterpret_cast<FnF>(g_hook[kLvlHigh])(5, 0.0f, 0, 0);
    g_now += 100;
    reinterpret_cast<Fn4>(g_hook[kGridPlayer])(1, 2, 3, 4);
    reinterpret_cast<Fn5>(g_hook[kDoor])(1, 2, 3, 4, 0x1234);
    g_now += 1000;  // other work in the frame
    return 0;
}
std::vector<std::string> Split(const std::string& s)
{
    std::vector<std::string> out;
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, ',')) out.push_back(item);
    return out;
}
// one OT cycle: gap (Begin, pump), the frame body, Handler_End and RunSession(-2)
void Cycle(uint64_t gap = 300)
{
    g_now += gap;
    reinterpret_cast<Fn4>(g_hook[kBody])(0, 0, 0, 0);
    reinterpret_cast<uint64_t (*)(void*)>(g_runOt)(&g_mgr);
}

static // Own function without C++ objects: clang 21 crashes emitting SEH tables for a __try next to objects with destructors.
__declspec(noinline) static void RaiseProbe(bool* caught, bool* caughtOther)
{
    __try {
        RaiseException(0xC0000005, 0, 0, nullptr);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        *caught = true;
    }
    __try {
        RaiseException(0xE06D7363, 0, 0, nullptr);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        *caughtOther = true;
    }
}

void Run(const GameModule& game)
{
    Check(InstallOtProfile(true, L".", true, true, false, true), "OtProfile: installed on the mapped exe (profile and crash context)");
    OtProfileInfoOut i{};
    if (!Installed(OtProfileInfo(&i) && i.installed, "OtProfile")) return;
    auto rva = [&](const void* p) { return static_cast<unsigned>(static_cast<const uint8_t*>(p) - game.base); };
    Check(rva(i.marker) == 0x9484250, "OtProfile: the engine's stage marker at exe+0x9484250 (all marker writes in the sites name it)");
    Check(rva(i.bodyCall) == 0x65D333B && i.bodyCall[0] == 0xE8 && RipTarget(i.bodyCall, 1, 5) == i.region,
          "OtProfile: the OT loop's call of the frame body at exe+0x65D333B, now a call to its stub");
    Check(i.target[kBody] == nullptr || rva(i.target[kBody]) == 0x65D3940, "OtProfile: the frame body at exe+0x65D3940 (entry pattern)");
    struct Want { int stage; unsigned call, target; const char* name; };
    const Want want[] = {
        {kPlPre, 0x65D3D77, 0x67406B0, "ProcessLists pass 1"}, {kPlUpdate, 0x65D3DBD, 0x674AC70, "ProcessLists::Update"},
        {kPlPass2, 0x65D3DD4, 0x67406B0, "ProcessLists pass 2"}, {kPlPass3, 0x65D3DEB, 0x6749330, "ProcessLists pass 3"},
        {kLvlLow, 0x674AD74, 0x6749B30, "level pass 1"}, {kLvlMidLow, 0x674AD95, 0x674A580, "level pass 2"},
        {kLvlMidHigh, 0x674ADB6, 0x674A1D0, "level pass 3"}, {kLvlHigh, 0x674ADD7, 0x6749460, "level pass 4"},
        {kGridPlayer, 0x65D3F20, 0x66B2000, "grid change 1"}, {kGridOwn, 0x65D3F86, 0x66B2000, "grid change 2"},
        {kDoor, 0x65D4042, 0x6602180, "door handler"}, {kPlTimed, 0x65D407E, 0x674AE00, "time-driven pass"},
        {kWater, 0x65D40AB, 0x66B1D50, "water update"}, {kSave, 0x65D4215, 0x65D4570, "save entry"},
    };
    for (const Want& w : want) {
        const bool ok = i.call[w.stage] && rva(i.call[w.stage]) == w.call && i.call[w.stage][0] == 0xE8 &&
                        RipTarget(i.call[w.stage], 1, 5) == i.region + w.stage * 16;
        char what[200];
        snprintf(what, sizeof what, "OtProfile: %s call at exe+0x%X redirected to its stub", w.name, w.call);
        Check(ok, what);
        snprintf(what, sizeof what, "OtProfile: %s called exe+0x%X before the redirect", w.name, w.target);
        Check(i.target[w.stage] && rva(i.target[w.stage]) == w.target, what);
    }
    const uint8_t endCode[4] = {0x48, 0x8B, 0xCB, 0xE8};
    Check(i.endRun && rva(i.endRun) == 0x65D3635 && memcmp(i.endRun, endCode, 4) == 0 && i.endRun[8] == 0x0F &&
              RipTarget(i.endRun + 3, 1, 5) == i.region + 15 * 16,
          "OtProfile: the OT's RunSession(-2) call (mov edx,-2 .. call [r8+70h]) at exe+0x65D3635 rewritten to mov rcx,rbx; call stub");
    const uint8_t gtCode[4] = {0x48, 0x8B, 0xCE, 0xE8};
    Check(i.gtTimed && i.gtRun && rva(i.gtRun) == 0x4899E0C && memcmp(i.gtRun, gtCode, 4) == 0 &&
              RipTarget(i.gtRun + 3, 1, 5) == i.region + 16 * 16,
          "OtProfile: the game thread's RunSession(-1) call at exe+0x4899E0C rewritten the same way (NpcCreationPacing not hooked)");
    bool stubsOk = true;
    for (int s = 0; s < kStages; ++s)
        if (s == kBody || i.call[s]) {
            void* h;
            memcpy(&h, i.region + s * 16 + 6, 8);
            stubsOk = stubsOk && i.region[s * 16] == 0xFF && i.region[s * 16 + 1] == 0x25 && h == i.hook[s];
        }
    Check(stubsOk, "OtProfile: every stage stub is jmp [rip+0] to its hook");
    Check(i.ctxInstalled, "OtProfile: OtCrashContext's vectored handler installed");

    // ---- cycle bookkeeping with fakes ----
    void* fake[kStages] = {};
    fake[kBody] = reinterpret_cast<void*>(&FakeBody);
    fake[kPlPre] = reinterpret_cast<void*>(&FakeS4<kPlPre>);
    fake[kPlUpdate] = reinterpret_cast<void*>(&FakeS4<kPlUpdate>);
    fake[kLvlHigh] = reinterpret_cast<void*>(&FakeSF<kLvlHigh>);
    fake[kGridPlayer] = reinterpret_cast<void*>(&FakeS4<kGridPlayer>);
    fake[kDoor] = reinterpret_cast<void*>(&FakeDoor);
    g_len[kPlPre] = 1000; g_len[kPlUpdate] = 1500; g_len[kLvlHigh] = 500; g_len[kGridPlayer] = 400; g_len[kDoor] = 200;
    for (int s = 0; s < kStages; ++s) g_hook[s] = i.hook[s];
    g_runOt = i.runHookOt;
    g_vt[0x70 / 8] = reinterpret_cast<void*>(&FakeRun);
    const wchar_t* const path = L"selftest-otprofile.csv";
    DeleteFileW(path);
    DeleteFileW(L"selftest-otprofile.1.csv");
    OtProfileTestSetup(&Clock, 1000000, path, fake, 1000);
    g_now = 10000000;
    SetOtProfile(true, 8, 1000, true);
    Check(reinterpret_cast<Fn4>(g_hook[kPlPre])(11, 22, 33, 44) == 7 && g_seen[0] == 11 && g_seen[1] == 22 && g_seen[2] == 33 && g_seen[3] == 44,
          "OtProfile: a timed stage passes its four arguments and its return value through");
    reinterpret_cast<FnF>(g_hook[kLvlHigh])(5, 1.5f, 6, 7);
    Check(g_seenF == 1.5f && g_seen[0] == 5 && g_seen[2] == 6, "OtProfile: a level pass keeps its float argument (xmm1)");
    reinterpret_cast<Fn5>(g_hook[kDoor])(1, 2, 3, 4, 0xABCDEF);
    Check(g_seen[3] == 0xABCDEF, "OtProfile: the door handler's fifth (stack) argument passes through");
    for (int c = 0; c < 40; ++c) Cycle();  // fast cycles: busy 5.3 ms
    OtProfileTestMarker(0xB4);              // a slow cycle: the level pass takes 12 ms more, the marker says 0xB4 for 40 real ms
    g_slowExtra = 12000;
    g_realSleep = true;
    Cycle();
    g_realSleep = false;
    g_slowExtra = 0;
    OtProfileTestMarker(0x64);
    for (int c = 0; c < 300; ++c) Cycle();  // ~2.8 s of fake time: one 2 s aggregate
    reinterpret_cast<uint64_t (*)(void*)>(i.runHookGt)(&g_mgr);
    Sleep(60);
    OtProfileDrain();
    OtProfileTestClose();
    std::ifstream in("selftest-otprofile.csv");
    std::string line, head;
    std::vector<std::vector<std::string>> f, s, m;
    std::vector<std::string> names;
    while (std::getline(in, line)) {
        if (line.rfind("F,", 0) == 0) f.push_back(Split(line));
        else if (line.rfind("S,", 0) == 0) s.push_back(Split(line));
        else if (line.rfind("M,", 0) == 0) m.push_back(Split(line));
        else if (line.rfind("#F,", 0) == 0) names = Split(line.substr(1));
        else if (line.rfind("# OblivionPerfFix-otprofile", 0) == 0) head = line;
    }
    Check(head.find("qpc_freq=1000000") != std::string::npos && head.find("gt_wait=1") != std::string::npos,
          "OtProfile: the csv header names the clock and the signals");
    Check(f.size() == 1, "OtProfile: exactly one slow cycle row (the 17 ms one) among 341 cycles");
    if (f.size() == 1) {
        std::map<std::string, std::string> col;
        for (size_t k = 0; k < names.size() && k < f[0].size(); ++k) col[names[k]] = f[0][k];
        auto num = [&](const char* n) { return atof(col[n].c_str()); };
        Check(fabs(num("idle_ms") - 4.0) < 0.01 && fabs(num("busy_ms") - (num("cycle_ms") - 4.0)) < 0.01,
              "OtProfile: idle = the RunSession(-2) time (4 ms), busy = cycle - idle");
        Check(fabs(num("body_ms") - 17.0) < 0.01 && fabs(num("busy_ms") - 17.3) < 0.01, "OtProfile: the slow cycle's frame body (17.0 ms) and busy time (17.3 ms)");
        Check(fabs(num("pl_pre_ms") - 1.0) < 0.01 && fabs(num("pl_update_ms") - 1.5) < 0.01 && fabs(num("lvl_high_ms") - 12.5) < 0.01 &&
                  fabs(num("grid_player_ms") - 0.4) < 0.01 && fabs(num("door_ms") - 0.2) < 0.01,
              "OtProfile: per-stage times (pl_pre 1.0, pl_update 1.5, lvl_high 12.5, grid_player 0.4, door 0.2)");
        Check(fabs(num("other_ms") - (17.0 - 1.0 - 1.5 - 0.4 - 0.2)) < 0.02, "OtProfile: other = body - the top-level stages");
        Check(col["marker"] == "0xB4", "OtProfile: the sampler named the engine's marker 0xB4 for the slow cycle");
        Check(num("gtwait_n") == 0, "OtProfile: the game thread's RunSession(-1) wait is a column (0 calls before it ran)");
    } else Check(false, "OtProfile: the slow row has its columns");
    Check(s.size() == 1 && s[0].size() > 40 && atoi(s[0][4].c_str()) > 150 && atoi(s[0][5].c_str()) == 1,
          "OtProfile: one 2 s aggregate row (frames, 1 slow)");
    Check(!m.empty(), "OtProfile: a marker histogram row");

    // ---- crash context: logged, and the exception continues ----
    OtProfileInfoOut o0{};
    OtProfileInfo(&o0);
    bool caught = false, caughtOther = false;
    RaiseProbe(&caught, &caughtOther);
    OtProfileInfoOut o1{};
    OtProfileInfo(&o1);
    Check(caught && caughtOther, "OtCrashContext: the exception still reaches the program's handler (never swallowed)");
    Check(o1.ctxLogged == o0.ctxLogged + 1, "OtCrashContext: a fault on the OT is logged once, an ordinary C++ exception is not");
    SetOtProfile(false, 8, 1000, false);

    // ---- cost per cycle with the real clock (trivial fake stages) ----
    {
        void* fake2[kStages] = {};
        fake2[kBody] = reinterpret_cast<void*>(&FakeBody);
        LARGE_INTEGER fq;
        QueryPerformanceFrequency(&fq);
        for (int sidx = 0; sidx < kStages; ++sidx) g_len[sidx] = 0;
        g_runLen = 0;
        OtProfileTestSetup(&RealClock, fq.QuadPart, nullptr, fake2, 0);
        SetOtProfile(true, 1000, 0, false);
        Cycle();
        const uint64_t t0 = RealClock();
        const int n = 20000;
        for (int c = 0; c < n; ++c) Cycle(0);
        const double us = static_cast<double>(RealClock() - t0) * 1e6 / static_cast<double>(fq.QuadPart) / n;
        SetOtProfile(false, 1000, 0, false);
        char what[200];
        snprintf(what, sizeof what, "OtProfile: cost per cycle with 5 timed stages, the frame and the idle call, real clock: %.2f us (limit 20 us)", us);
        Check(us < 20.0, what);
    }
    OtProfileTestClose();
}
}  // namespace otp
