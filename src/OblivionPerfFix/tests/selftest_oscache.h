// OsPageCache self-test, included by selftest.cpp: the OS thunks and AllocateImpl's cache-miss calls on the
// mapped exe, then the cache core with fake OS functions: exact-size reuse (newest first), only for the cache-miss
// callers, the cap, the per-size limit, the size limit, the time-based trim, MemoryRelief's relief flush, the off switch, a
// failed allocation (flush and retry), and eight threads allocating and releasing at once.
#pragma once

#include <fstream>
#include <map>
#include <set>
#include <thread>

namespace osc {
std::mutex g_m;
std::set<void*> g_os;  // blocks the fake OS has handed out and not taken back
uint64_t g_osAllocs = 0, g_osFrees = 0, g_badFrees = 0;
bool g_failNext = false;
uint64_t g_now = 1000;

void* FakeAlloc(SIZE_T)
{
    std::lock_guard<std::mutex> l(g_m);
    if (g_failNext) {
        g_failNext = false;
        return nullptr;
    }
    void* p = _aligned_malloc(64, 64);  // identity only: the cache never touches a block's bytes
    g_os.insert(p);
    ++g_osAllocs;
    return p;
}
BOOL FakeFree(void* p)
{
    if (!p) return FALSE;  // VirtualFree(nullptr) fails, as in the game
    std::lock_guard<std::mutex> l(g_m);
    if (!g_os.erase(p)) ++g_badFrees;
    else _aligned_free(p);
    ++g_osFrees;
    return TRUE;
}
uint64_t FakeNow() { return g_now; }

OsPageCacheStatsOut S()
{
    OsPageCacheStatsOut s{};
    OsPageCacheTestStats(&s);
    return s;
}

// ---- OsPageCacheTrace: the binary trace writer (layout in os_page_cache_trace.cpp) ----
struct TraceRec {
    uint32_t kind, tid;
    uint64_t us;
    uint32_t id, size;
};
struct TraceFile {
    bool ok = false;
    char magic[9] = {};
    uint32_t version = 0, recSize = 0, capMB = 0, keepMs = 0, dropped = 0;
    uint64_t freq = 0, capacity = 0, total = 0, fileBytes = 0;
    std::vector<TraceRec> recs;  // oldest first (the ring unrolled)
};
TraceFile ReadTrace(const char* path)
{
    TraceFile t;
    std::ifstream in(path, std::ios::binary);
    if (!in) return t;
    uint8_t h[64];
    in.read(reinterpret_cast<char*>(h), 64);
    if (in.gcount() != 64) return t;
    memcpy(t.magic, h, 8);
    memcpy(&t.version, h + 8, 4);
    memcpy(&t.recSize, h + 12, 4);
    memcpy(&t.freq, h + 16, 8);
    memcpy(&t.capacity, h + 32, 8);
    memcpy(&t.total, h + 40, 8);
    memcpy(&t.capMB, h + 48, 4);
    memcpy(&t.keepMs, h + 52, 4);
    memcpy(&t.dropped, h + 60, 4);
    in.seekg(0, std::ios::end);
    t.fileBytes = static_cast<uint64_t>(in.tellg());
    in.seekg(64);
    std::vector<uint64_t> raw(static_cast<size_t>((t.fileBytes - 64) / 8));
    in.read(reinterpret_cast<char*>(raw.data()), static_cast<std::streamsize>(raw.size() * 8));
    const uint64_t n = (std::min)(t.total, t.capacity), first = t.total > t.capacity ? t.total % t.capacity : 0;
    for (uint64_t i = 0; i < n && 2 * ((first + i) % t.capacity) + 1 < raw.size(); ++i) {
        const uint64_t k = (first + i) % t.capacity, w0 = raw[2 * k], w1 = raw[2 * k + 1];
        t.recs.push_back({static_cast<uint32_t>(w0 & 0xFF), static_cast<uint32_t>((w0 >> 8) & 0xFFFF), w0 >> 24,
                          static_cast<uint32_t>(w1), static_cast<uint32_t>(w1 >> 32)});
    }
    t.ok = true;
    return t;
}
const char* const kTraceFile = "OblivionPerfFix-oscache-trace.bin";

static void RunTrace()
{
    constexpr size_t K64 = 64 << 10, K128 = 128 << 10;
    OsPageCacheTestInit(&FakeAlloc, &FakeFree, &FakeNow);
    g_now = 1000;
    // starts live through the key (1 MB file), records a scripted sequence
    SetOsPageCache(1, 64, 5, false, 0, 1);
    OsTraceStatsOut ts{};
    OsTraceStats(&ts);
    Check(ts.on && ts.capacity == (1u << 20) / 16 - 4, "trace: the key (traceMB 1) starts it, a ring of 1 MB");
    void* a = OsPageCacheTestAlloc(K64, true);    // miss
    OsPageCacheTestFree(a, K64);                  // kept
    void* b = OsPageCacheTestAlloc(K64, true);    // hit (a)
    void* o = OsPageCacheTestAlloc(K128, false);  // other caller
    OsPageCacheTestFree(b, K64);                  // kept
    OsPageCacheTestFree(o, K128);                 // kept
    OsPageCacheTestFree(OsPageCacheTestAlloc(9 << 20, true), 9 << 20);  // miss, then too big: passed
    g_now += 6000;
    SetOsPageCache(1, 64, 5, false, 0, 1);        // trim: the two kept blocks go
    SetOsPageCache(1, 32, 5, false, 0, 1);        // a settings change: a mark
    SetOsPageCache(0, 32, 5, false, 0, 1);        // off
    void* c = OsPageCacheTestAlloc(K64, true);    // cache off
    OsPageCacheTestFree(c, K64);                  // cache off
    const uint64_t total = OsTraceFlush();
    const TraceFile t = ReadTrace(kTraceFile);
    Check(t.ok && memcmp(t.magic, "OPFOSTRC", 8) == 0 && t.version == 1 && t.recSize == 16 && t.freq > 0, "trace: file header (magic, version 1, 16-byte records, QPC frequency)");
    // expected kinds in order (timestamps and thread ids are checked below)
    const uint32_t want[] = {kTraceMark, kTraceAllocMiss, kTraceFreeKept, kTraceAllocHit, kTraceAllocOther, kTraceFreeKept, kTraceFreeKept,
                             kTraceAllocMiss, kTraceFreePassed, kTraceEvictTrim, kTraceEvictTrim, kTraceMark, kTraceMark,
                             kTraceAllocOff, kTraceFreeOff};
    // the trims and the mark order: the two trimmed blocks, then the first settings mark (cap 32), then the off mark
    bool kindsOk = t.recs.size() == sizeof want / sizeof want[0] && t.total == total && total == t.recs.size();
    for (size_t i = 0; kindsOk && i < t.recs.size(); ++i) kindsOk = t.recs[i].kind == want[i];
    Check(kindsOk, "trace: every alloc, free, trim and settings change recorded in order with its kind");
    if (kindsOk) {
        const TraceRec* const r = t.recs.data() + 1;  // after the start-up mark
        Check(r[0].size == K64 && r[1].size == K64 && r[3].size == K128 && r[6].size == (9u << 20), "trace: sizes in bytes");
        Check(r[0].id == r[1].id && r[1].id == r[2].id && r[2].id == r[4].id && r[3].id == r[5].id && r[6].id == r[7].id,
              "trace: the alloc, free and hit of one block share its address id");
        bool mono = true;
        for (size_t i = 1; i < t.recs.size(); ++i) mono &= t.recs[i].us >= t.recs[i - 1].us;
        Check(mono && r[0].tid == (GetCurrentThreadId() & 0xFFFF), "trace: timestamps never go back, thread id recorded");
        Check(t.recs[0].size == (64ull << 20 | 1) && t.recs[11].size == (32ull << 20 | 1) && t.recs[11].id == 5000 && t.recs[12].size == (32ull << 20),
              "trace: a settings mark carries the cap in bytes (low bit = on) and the keep time");
        Check(t.capMB == 64 && t.keepMs == 0, "trace: header settings (live start: as the key had them)");
    }

    // the ring: more records than it holds -> bounded file, newest records kept, header total counts all
    OsPageCacheTestInstallTrace(L".", 64 << 10);  // 4092 records
    SetOsPageCache(1, 64, 5, false, 0, 1);
    OsTraceStats(&ts);
    const uint64_t cap = ts.capacity;
    Check(ts.on && cap == (65536 - 64) / 16, "trace: a small test ring (64 KB)");
    const uint32_t pairs = 10000;
    void* last = nullptr;
    for (uint32_t i = 0; i < pairs; ++i) {
        if (last) OsPageCacheTestFree(last, K64);
        last = OsPageCacheTestAlloc(K64, true);
        if ((i & 1023) == 0) OsTraceFlush();  // the writer thread also drains: this only keeps the 250 ms drain from being the limit
    }
    OsPageCacheTestFree(last, K64);
    const uint64_t total2 = OsTraceFlush();
    OsTraceStats(&ts);
    const TraceFile w = ReadTrace(kTraceFile);
    Check(w.ok && w.fileBytes == 64 + cap * 16 && w.total == total2 && total2 + ts.dropped >= 2ull * pairs && w.total > cap,
          "trace: the ring wrapped, the file stays at its size, the header counts every record written");
    Check(w.recs.size() == cap && (w.recs.back().kind == kTraceFreeKept || w.recs.back().kind == kTraceFreePassed) && w.recs.back().size == K64,
          "trace: after the wrap the last record read is the last operation");
    bool wmono = true;
    for (size_t i = 1; i < w.recs.size(); ++i) wmono &= w.recs[i].us >= w.recs[i - 1].us;
    Check(wmono, "trace: the unrolled ring is in time order");

    // many threads: every attempted record is written or counted as dropped, none twice
    OsPageCacheTestInstallTrace(L".", 8 << 20);
    SetOsPageCache(1, 64, 5, false, 0, 8);
    OsTraceFlush();
    OsTraceStats(&ts);
    const uint64_t base = ts.written + ts.dropped;
    std::atomic<uint64_t> attempts{0};
    std::vector<std::thread> th;
    for (int k = 0; k < 4; ++k)
        th.emplace_back([&] {
            for (int i = 0; i < 50000; ++i) {
                void* x = OsPageCacheTestAlloc(K64, true);
                OsPageCacheTestFree(x, K64);
                attempts += 2;
            }
        });
    for (auto& x : th) x.join();
    OsTraceFlush();
    OsTraceStats(&ts);
    const TraceFile m = ReadTrace(kTraceFile);
    uint64_t allocs = 0, frees = 0, marks = 0;
    for (const auto& r : m.recs) {
        allocs += r.kind == kTraceAllocHit || r.kind == kTraceAllocMiss;
        frees += r.kind == kTraceFreeKept || r.kind == kTraceFreePassed;
        marks += r.kind == kTraceMark;
    }
    Check(ts.written + ts.dropped - base == attempts && m.total == ts.written && m.recs.size() == (std::min)(m.total, m.capacity),
          "trace: 4 threads, 400000 records attempted: each one written or counted as dropped");
    Check(allocs + frees + marks == m.recs.size() && allocs > 0 && frees > 0 && m.dropped == ts.dropped, "trace: only alloc and free records in the file, dropped count in the header");
    printf("      (trace: 4 threads, %llu written, %llu dropped of %llu)\n", static_cast<unsigned long long>(ts.written),
           static_cast<unsigned long long>(ts.dropped), static_cast<unsigned long long>(attempts.load()));

    // off: the key stops it, nothing more is recorded, the file keeps what it has
    SetOsPageCache(1, 64, 5, false, 0, 0);
    OsTraceStats(&ts);
    const uint64_t kept = ts.written;
    OsPageCacheTestFree(OsPageCacheTestAlloc(K64, true), K64);
    OsTraceStats(&ts);
    const TraceFile z = ReadTrace(kTraceFile);
    Check(!ts.on && ts.written == kept && z.total == kept && !g_osTraceOn.load(), "trace: key 0 stops it, writes the rest, later operations are not recorded");
    SetOsPageCache(0, 64, 5, false);
    DeleteFileA(kTraceFile);
}

static void Run(const GameModule& game)
{
    Check(InstallOsPageCache(true, L".", 0), "os page cache: thunks and AllocateImpl's calls found, thunks detoured");
    OsPageCacheInfoOut info{};
    if (!Installed(OsPageCacheInfo(&info), "OsPageCache (os page cache)")) return;
    Check(info.allocFn == game.base + 0xF41A20 && info.freeFn == game.base + 0xF41A40,
          "BinnedAllocFromOS at exe+0xF41A20, BinnedFreeToOS at exe+0xF41A40");
    Check(info.cacheRet[0] == game.base + 0xDF1B4F && info.cacheRet[1] == game.base + 0xDF1B65,
          "AllocateImpl's cache-miss calls return to exe+0xDF1B4F / exe+0xDF1B65");
    Check(info.allocFn[0] == 0xE9 && info.freeFn[0] == 0xE9, "both thunks start with a jmp to the detours");

    constexpr size_t K64 = 64 << 10, K128 = 128 << 10, K512 = 512 << 10;
    OsPageCacheTestInit(&FakeAlloc, &FakeFree, &FakeNow);
    // off: every call goes to the OS
    SetOsPageCache(0, 64, 5, false);
    void* a = OsPageCacheTestAlloc(K64, true);
    OsPageCacheTestFree(a, K64);
    Check(g_osAllocs == 1 && g_osFrees == 1 && S().blocks == 0, "off: allocation and release go to the OS");
    // on: exact-size reuse, newest first, only for the cache-miss callers
    SetOsPageCache(1, 64, 5, false);
    void* b1 = OsPageCacheTestAlloc(K64, true);
    void* b2 = OsPageCacheTestAlloc(K64, true);
    OsPageCacheTestFree(b1, K64);
    OsPageCacheTestFree(b2, K64);
    Check(g_osFrees == 1 && S().blocks == 2 && S().held == 2 * K64, "on: released blocks are kept");
    Check(OsPageCacheTestAlloc(K64, false) != b2 && S().blocks == 2, "other callers get a fresh block");
    Check(OsPageCacheTestAlloc(K128, true) && S().blocks == 2, "another size: a fresh block, the kept ones stay");
    void* r1 = OsPageCacheTestAlloc(K64, true);
    void* r2 = OsPageCacheTestAlloc(K64, true);
    Check(r1 == b2 && r2 == b1 && S().blocks == 0 && S().hits == 2, "same size: the newest kept block first, then the older");
    OsPageCacheTestFree(r1, K64);
    OsPageCacheTestFree(r2, K64);
    // size limit: blocks over cap / 8 (and over 16 MB) go to the OS
    const uint64_t frees0 = g_osFrees;
    void* big = OsPageCacheTestAlloc(9 << 20, true);
    OsPageCacheTestFree(big, 9 << 20);
    Check(g_osFrees == frees0 + 1, "a block over cap / 8 is released to the OS");
    OsPageCacheTestFree(nullptr, K64);
    Check(S().blocks == 2, "a null release is not kept");
    // the per-size limit (cap / 2) and the cap: a 4 MB cap, 512 KB blocks
    SetOsPageCache(1, 4, 5, false);
    Check(S().blocks == 2, "lowering the cap above what is held keeps the blocks");
    void* p[12];
    for (auto& x : p) x = OsPageCacheTestAlloc(K512, true);
    for (auto& x : p) OsPageCacheTestFree(x, K512);
    Check(S().held <= (4ull << 20) && S().held - 2 * K64 <= (2ull << 20), "512 KB blocks: at most half the cap of one size");
    Check(S().evictSize >= 8, "the oldest of that size went to the OS");
    void* q[8];
    for (auto& x : q) x = OsPageCacheTestAlloc(K128 * 2, true);
    for (auto& x : q) OsPageCacheTestFree(x, K128 * 2);
    Check(S().held <= (4ull << 20) && S().evictCap > 0, "the cap holds: the oldest blocks went to the OS");
    // trim: blocks unused for the trim time go back on the next tick
    g_now += 3000;
    SetOsPageCache(1, 4, 5, false);
    const uint32_t kept3 = S().blocks;
    Check(kept3 > 0, "trim: blocks younger than 5 s stay");
    g_now += 2500;
    SetOsPageCache(1, 4, 5, false);
    Check(S().blocks == 0 && S().held == 0, "trim: blocks unused for 5 s went to the OS");
    // relief: flush, then releases pass through until it ends
    void* c1 = OsPageCacheTestAlloc(K64, true);
    OsPageCacheTestFree(c1, K64);
    Check(S().blocks == 1, "kept again");
    SetOsPageCache(1, 64, 5, true);
    Check(S().blocks == 0, "MemoryRelief relief: everything kept went to the OS");
    void* c2 = OsPageCacheTestAlloc(K64, true);
    OsPageCacheTestFree(c2, K64);
    Check(S().blocks == 0, "MemoryRelief relief: releases go to the OS");
    SetOsPageCache(1, 64, 5, false);
    void* c3 = OsPageCacheTestAlloc(K64, true);
    OsPageCacheTestFree(c3, K64);
    Check(S().blocks == 1, "relief over: kept again");
    // OsPageCacheKeepMs (wins over the seconds key): 500 ms
    g_now += 400;
    SetOsPageCache(1, 64, 5, false, 500);
    Check(S().blocks == 1, "OsPageCacheKeepMs=500: a block 0.4 s old stays");
    g_now += 200;
    SetOsPageCache(1, 64, 5, false, 500);
    Check(S().blocks == 0, "OsPageCacheKeepMs=500: a block 0.6 s old went to the OS (not after 5 s)");
    void* c5 = OsPageCacheTestAlloc(K64, true);
    OsPageCacheTestFree(c5, K64);
    SetOsPageCache(1, 64, 5, false);
    Check(S().blocks == 1, "KeepMs back to 0: the seconds key (5 s) rules again");
    // a failed allocation: what is kept goes back, then once more
    g_failNext = true;
    void* c4 = OsPageCacheTestAlloc(K128, true);
    Check(c4 && S().blocks == 0 && S().allocFails == 1, "a failed allocation: the kept blocks went back and the retry worked");
    OsPageCacheTestFree(c4, K128);
    // off switch: flush
    SetOsPageCache(0, 64, 5, false);
    Check(S().blocks == 0 && S().held == 0, "off: everything kept went to the OS");
    Check(g_badFrees == 0, "no block released twice or unknown to the OS");

    // eight threads at once: no block handed out twice, every block back at the end
    SetOsPageCache(1, 8, 5, false);
    const size_t osBefore = g_os.size();  // the two blocks the checks above keep
    std::mutex um;
    std::set<void*> inUse;
    std::atomic<int> dup{0};
    auto worker = [&](int seed) {
        uint32_t s = static_cast<uint32_t>(seed) * 2654435761u + 1;
        std::vector<std::pair<void*, size_t>> mine;
        for (int i = 0; i < 20000; ++i) {
            s = s * 1664525u + 1013904223u;
            if (mine.size() < 16 && (s >> 28) < 9) {
                const size_t sz = static_cast<size_t>(4096) * (1 + (s >> 8) % 48);
                void* x = OsPageCacheTestAlloc(sz, (s & 1) != 0);
                {
                    std::lock_guard<std::mutex> l(um);
                    if (!inUse.insert(x).second) ++dup;
                }
                mine.push_back({x, sz});
            } else if (!mine.empty()) {
                const size_t k = (s >> 4) % mine.size();
                {
                    std::lock_guard<std::mutex> l(um);
                    inUse.erase(mine[k].first);
                }
                OsPageCacheTestFree(mine[k].first, mine[k].second);
                mine[k] = mine.back();
                mine.pop_back();
            }
        }
        for (auto& m : mine) {
            {
                std::lock_guard<std::mutex> l(um);
                inUse.erase(m.first);
            }
            OsPageCacheTestFree(m.first, m.second);
        }
    };
    std::vector<std::thread> ts;
    for (int t = 0; t < 8; ++t) ts.emplace_back(worker, t + 1);
    for (auto& t : ts) t.join();
    const OsPageCacheStatsOut st = S();
    Check(dup == 0, "8 threads: no block handed out to two owners");
    Check(st.hits > 1000 && st.held <= (8ull << 20), "8 threads: blocks reused, the cap held");
    SetOsPageCache(0, 64, 5, false);
    Check(g_os.size() == osBefore && g_badFrees == 0, "8 threads: every block back to the OS after the off switch, none twice");
    printf("      (os page cache: 8 threads, %llu hits, %llu misses, %llu kept, %llu over cap, %llu over half)\n",
           static_cast<unsigned long long>(st.hits), static_cast<unsigned long long>(st.misses),
           static_cast<unsigned long long>(st.kept), static_cast<unsigned long long>(st.evictCap),
           static_cast<unsigned long long>(st.evictSize));
    RunTrace();
}
}  // namespace osc
