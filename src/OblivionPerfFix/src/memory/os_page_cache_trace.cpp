// OsPageCacheTrace: a bounded binary trace of every alloc / free the OsPageCache sees, for tools/oscache_sim.py.
//
// Layout of OblivionPerfFix-oscache-trace.bin (little endian): a 64-byte header, then a ring of 16-byte records.
//   header: char magic[8] = "OPFOSTRC"; u32 version = 1; u32 recordSize = 16; u64 qpcFreq; u64 startQpc; u64 capacityRecords;
//           u64 totalRecords (all ever written; > capacity = the ring wrapped, the oldest record is at total % capacity);
//           u32 capMB; u32 keepMs (the settings at start); u32 flags (bit 0 = synthetic, written by the tools only);
//           u32 dropped (records lost because the in-memory buffer was full).
//   record: u64 w0 = kind (bits 0-7) | thread id low 16 bits (8-23) | microseconds since start (24-63);
//           u64 w1 = address id (low 32 bits: a hash of the block's address, equal for the alloc and the free of one block)
//                    | size in bytes, saturated at 4 GB - 1 (high 32 bits).
// Producers claim a slot of an in-memory ring with a compare-exchange (no lock), write w1, then publish w0 with release
// semantics; a writer thread copies published slots to the file every 250 ms and rewrites the header's total. When the
// buffer is full the record is dropped and counted. With the key off, one relaxed atomic load is all the cache pays.
#include "common.h"

#include <algorithm>
#include <atomic>
#include <cstdio>
#include <cstring>
#include <string>

namespace opf {
namespace {

constexpr uint32_t kRingRecords = 1u << 17;  // 2 MB of in-memory buffer
constexpr uint32_t kHeaderBytes = 64, kRecBytes = 16;
struct Slot {
    std::atomic<uint64_t> w0;
    uint64_t w1;
};
struct Header {
    char magic[8];
    uint32_t version, recSize;
    uint64_t qpcFreq, startQpc, capacity, total;
    uint32_t capMB, keepMs, flags, dropped;
};
static_assert(sizeof(Header) == kHeaderBytes, "trace header is 64 bytes");

Slot* g_ring = nullptr;
std::atomic<uint64_t> g_wr{0}, g_rd{0};
std::atomic<uint32_t> g_dropped{0};
std::atomic<bool> g_run{false};
HANDLE g_file = INVALID_HANDLE_VALUE, g_thread = nullptr, g_stop = nullptr;
SRWLOCK g_drainLock = SRWLOCK_INIT;
Header g_hdr{};
uint64_t g_qpcFreq = 0, g_start = 0;
uint64_t g_tail = 0;  // records written to the file (= g_hdr.total)
std::wstring g_path;

bool WriteAt(uint64_t off, const void* data, DWORD n)
{
    LARGE_INTEGER li;
    li.QuadPart = static_cast<LONGLONG>(off);
    DWORD wrote = 0;
    return SetFilePointerEx(g_file, li, nullptr, FILE_BEGIN) && WriteFile(g_file, data, n, &wrote, nullptr) && wrote == n;
}

// copies the published slots to the file (drain lock held); returns the records written
uint64_t DrainLocked()
{
    if (g_file == INVALID_HANDLE_VALUE) return 0;
    static uint64_t buf[2 * 4096];
    uint64_t done = 0;
    for (;;) {
        uint64_t r = g_rd.load(std::memory_order_relaxed);
        const uint64_t w = g_wr.load(std::memory_order_acquire);
        uint32_t n = 0;
        while (r + n < w && n < 4096) {
            Slot& s = g_ring[(r + n) & (kRingRecords - 1)];
            const uint64_t w0 = s.w0.load(std::memory_order_acquire);
            if (!w0) break;  // claimed, not yet published: next time
            buf[2 * n] = w0;
            buf[2 * n + 1] = s.w1;
            ++n;
        }
        if (!n) break;
        // into the file ring: at most two contiguous pieces
        uint32_t i = 0;
        while (i < n) {
            const uint64_t pos = (g_tail + i) % g_hdr.capacity;
            const uint32_t run = static_cast<uint32_t>((std::min<uint64_t>)(n - i, g_hdr.capacity - pos));
            if (!WriteAt(kHeaderBytes + pos * kRecBytes, buf + 2 * i, run * kRecBytes)) break;
            i += run;
        }
        g_tail += n;
        for (uint32_t k = 0; k < n; ++k) g_ring[(r + k) & (kRingRecords - 1)].w0.store(0, std::memory_order_relaxed);
        g_rd.store(r + n, std::memory_order_release);
        done += n;
        if (n < 4096) break;
    }
    if (done) {
        g_hdr.total = g_tail;
        g_hdr.dropped = g_dropped.load();
        WriteAt(0, &g_hdr, kHeaderBytes);
    }
    return done;
}

DWORD WINAPI WriterMain(LPVOID)
{
    while (WaitForSingleObject(g_stop, 250) == WAIT_TIMEOUT) {
        AcquireSRWLockExclusive(&g_drainLock);
        DrainLocked();
        ReleaseSRWLockExclusive(&g_drainLock);
    }
    return 0;
}

}  // namespace

std::atomic<bool> g_osTraceOn{false};

uint32_t OsTraceAddrId(const void* p)
{
    return static_cast<uint32_t>(((reinterpret_cast<uintptr_t>(p) >> 12) * 0x9E3779B97F4A7C15ull) >> 32);
}

void OsTraceRecord(uint32_t kind, uint64_t size, uint32_t id)
{
    if (!g_osTraceOn.load(std::memory_order_relaxed) || !g_ring) return;
    uint64_t w = g_wr.load(std::memory_order_relaxed);
    for (;;) {
        if (w - g_rd.load(std::memory_order_acquire) >= kRingRecords) {
            g_dropped.fetch_add(1, std::memory_order_relaxed);
            return;
        }
        if (g_wr.compare_exchange_weak(w, w + 1, std::memory_order_acq_rel, std::memory_order_relaxed)) break;
    }
    LARGE_INTEGER q;
    QueryPerformanceCounter(&q);
    const uint64_t us = static_cast<uint64_t>(q.QuadPart - static_cast<LONGLONG>(g_start)) * 1000000ull / g_qpcFreq;
    Slot& s = g_ring[w & (kRingRecords - 1)];
    s.w1 = id | (size > 0xFFFFFFFEull ? 0xFFFFFFFFull : size) << 32;
    s.w0.store(kind | static_cast<uint64_t>(GetCurrentThreadId() & 0xFFFF) << 8 | us << 24, std::memory_order_release);
}

bool OsTraceStart(const wchar_t* dir, uint64_t maxBytes, int capMB, int keepMs)
{
    if (g_osTraceOn.load()) return true;
    if (maxBytes < (64ull << 10)) maxBytes = 64ull << 10;
    if (!g_ring) g_ring = static_cast<Slot*>(VirtualAlloc(nullptr, sizeof(Slot) * kRingRecords, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE));
    if (!g_ring) return false;
    g_path = std::wstring(dir && *dir ? dir : L".") + L"\\OblivionPerfFix-oscache-trace.bin";
    g_file = CreateFileW(g_path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (g_file == INVALID_HANDLE_VALUE) return false;
    LARGE_INTEGER f, q;
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&q);
    g_qpcFreq = static_cast<uint64_t>(f.QuadPart);
    g_start = static_cast<uint64_t>(q.QuadPart);
    memset(&g_hdr, 0, sizeof g_hdr);
    memcpy(g_hdr.magic, "OPFOSTRC", 8);
    g_hdr.version = 1;
    g_hdr.recSize = kRecBytes;
    g_hdr.qpcFreq = g_qpcFreq;
    g_hdr.startQpc = g_start;
    g_hdr.capacity = (maxBytes - kHeaderBytes) / kRecBytes;
    g_hdr.capMB = static_cast<uint32_t>(capMB);
    g_hdr.keepMs = static_cast<uint32_t>(keepMs);
    g_tail = 0;
    g_wr = g_rd = 0;
    g_dropped = 0;
    for (uint32_t i = 0; i < kRingRecords; ++i) g_ring[i].w0.store(0, std::memory_order_relaxed);
    WriteAt(0, &g_hdr, kHeaderBytes);
    g_stop = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    g_thread = g_stop ? CreateThread(nullptr, 0, WriterMain, nullptr, 0, nullptr) : nullptr;
    if (!g_thread) {
        if (g_stop) CloseHandle(g_stop);
        g_stop = nullptr;
        CloseHandle(g_file);
        g_file = INVALID_HANDLE_VALUE;
        return false;
    }
    g_run = true;
    g_osTraceOn.store(true);
    Log("[oscache] trace on: %ls (ring of %llu records, %llu MB)", g_path.c_str(), static_cast<unsigned long long>(g_hdr.capacity),
        static_cast<unsigned long long>(maxBytes >> 20));
    return true;
}

// Stops recording, writes what is buffered, closes the file.
void OsTraceStop()
{
    if (!g_run.exchange(false)) return;
    g_osTraceOn.store(false);
    SetEvent(g_stop);
    WaitForSingleObject(g_thread, 2000);
    CloseHandle(g_thread);
    CloseHandle(g_stop);
    g_thread = g_stop = nullptr;
    AcquireSRWLockExclusive(&g_drainLock);
    DrainLocked();
    ReleaseSRWLockExclusive(&g_drainLock);
    CloseHandle(g_file);
    g_file = INVALID_HANDLE_VALUE;
    Log("[oscache] trace off: %llu records written, %u dropped", static_cast<unsigned long long>(g_tail), g_dropped.load());
}

// Writes the buffered records to the file now (self-test, stats); returns the total written so far.
uint64_t OsTraceFlush()
{
    if (!g_run.load()) return g_tail;
    AcquireSRWLockExclusive(&g_drainLock);
    DrainLocked();
    ReleaseSRWLockExclusive(&g_drainLock);
    return g_tail;
}

void OsTraceStats(OsTraceStatsOut* out)
{
    out->on = g_osTraceOn.load();
    out->written = g_tail;
    out->dropped = g_dropped.load();
    out->capacity = g_hdr.capacity;
}

}  // namespace opf
