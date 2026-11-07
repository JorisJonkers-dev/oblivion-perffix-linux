// Miss-cost micro-benchmark for OsPageCache: what one block costs when the cache does NOT reuse it, i.e. the allocator's
// VirtualAlloc(MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE) + first write to every page + VirtualFree(MEM_RELEASE), per size.
// Run by linux/oscache-bench.sh under headless Wine (build: same clang-cl / xwin set-up as linux/selftest.sh).
//   oscache_bench.exe [--sizes 64,128,...(KB)] [--threads 1,4] [--bg N] [--iters N] [--touch PERCENT]
// Output (stdout, CSV): size_kb,threads,bg_blocks,iters,alloc_us,touch_us,free_us,pair_us,pair_p50_us,pair_p95_us,retouch_us
//   alloc_us / touch_us / free_us = mean per block; pair_us = their sum (per thread, wall clock: with threads > 1 it includes
//   the lock waits of the OS's virtual memory code); retouch_us = writing every page of a block that is already resident,
//   the part of the work a cache hit still has to do.
// --bg N keeps N live 64 KB blocks (+ 256 live 1 MB blocks) first, so the address space is not empty, as in the game.
#include <windows.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

namespace {
double g_freq = 1.0;
double Now()
{
    LARGE_INTEGER q;
    QueryPerformanceCounter(&q);
    return static_cast<double>(q.QuadPart) * 1e6 / g_freq;
}

struct Job {
    size_t size;
    int iters, touchPct;
    double alloc = 0, touch = 0, free_ = 0, retouch = 0;
    std::vector<double> pairs;
    HANDLE go = nullptr;
};

void Touch(char* p, size_t size, int pct)
{
    const size_t n = size / 4096 * pct / 100;
    volatile char* v = p;
    for (size_t i = 0; i < n; ++i) v[i * 4096] = static_cast<char>(i + 1);
}

DWORD WINAPI Run(LPVOID arg)
{
    Job& j = *static_cast<Job*>(arg);
    WaitForSingleObject(j.go, INFINITE);
    const int warm = 3;
    for (int i = -warm; i < j.iters; ++i) {
        const double t0 = Now();
        char* p = static_cast<char*>(VirtualAlloc(nullptr, j.size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE));
        const double t1 = Now();
        if (!p) {
            fprintf(stderr, "VirtualAlloc(%zu) failed: %lu\n", j.size, GetLastError());
            return 1;
        }
        Touch(p, j.size, j.touchPct);
        const double t2 = Now();
        Touch(p, j.size, j.touchPct);  // resident now: what a reused block costs
        const double t3 = Now();
        VirtualFree(p, 0, MEM_RELEASE);
        const double t4 = Now();
        if (i < 0) continue;
        j.alloc += t1 - t0;
        j.touch += t2 - t1;
        j.retouch += t3 - t2;
        j.free_ += t4 - t3;
        j.pairs.push_back((t1 - t0) + (t2 - t1) + (t4 - t3));
    }
    return 0;
}

std::vector<int> ParseList(const char* s)
{
    std::vector<int> v;
    while (*s) {
        v.push_back(atoi(s));
        const char* c = strchr(s, ',');
        if (!c) break;
        s = c + 1;
    }
    return v;
}
}  // namespace

int main(int argc, char** argv)
{
    LARGE_INTEGER f;
    QueryPerformanceFrequency(&f);
    g_freq = static_cast<double>(f.QuadPart);
    std::vector<int> sizes = {64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384}, threads = {1};
    int bg = 0, iters = 0, touchPct = 100;
    for (int i = 1; i < argc; ++i) {
        const char* a = argv[i];
        const char* v = i + 1 < argc ? argv[i + 1] : "";
        if (!strcmp(a, "--sizes")) sizes = ParseList(v), ++i;
        else if (!strcmp(a, "--threads")) threads = ParseList(v), ++i;
        else if (!strcmp(a, "--bg")) bg = atoi(v), ++i;
        else if (!strcmp(a, "--iters")) iters = atoi(v), ++i;
        else if (!strcmp(a, "--touch")) touchPct = atoi(v), ++i;
        else {
            fprintf(stderr, "usage: oscache_bench [--sizes KB,..] [--threads N,..] [--bg N] [--iters N] [--touch PCT]\n");
            return 2;
        }
    }
    std::vector<void*> keep;  // live blocks that make the address space look used
    for (int i = 0; i < bg; ++i) keep.push_back(VirtualAlloc(nullptr, 64 << 10, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE));
    for (int i = 0; i < (bg ? 256 : 0); ++i) keep.push_back(VirtualAlloc(nullptr, 1 << 20, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE));
    for (void* p : keep)
        if (p) Touch(static_cast<char*>(p), 64 << 10, 100);
    printf("size_kb,threads,bg_blocks,iters,alloc_us,touch_us,free_us,pair_us,pair_p50_us,pair_p95_us,retouch_us\n");
    for (int t : threads) {
        for (int kb : sizes) {
            const size_t size = static_cast<size_t>(kb) << 10;
            const int n = iters ? iters : (std::max)(24, (std::min)(2000, static_cast<int>((768ull << 20) / size / t)));
            std::vector<Job> jobs(t);
            std::vector<HANDLE> hs;
            HANDLE go = CreateEventW(nullptr, TRUE, FALSE, nullptr);
            for (auto& j : jobs) {
                j.size = size;
                j.iters = n;
                j.touchPct = touchPct;
                j.go = go;
                hs.push_back(CreateThread(nullptr, 0, Run, &j, 0, nullptr));
            }
            Sleep(20);
            SetEvent(go);
            WaitForMultipleObjects(static_cast<DWORD>(hs.size()), hs.data(), TRUE, INFINITE);
            double a = 0, tc = 0, fr = 0, rt = 0;
            std::vector<double> all;
            for (auto& j : jobs) {
                a += j.alloc;
                tc += j.touch;
                fr += j.free_;
                rt += j.retouch;
                all.insert(all.end(), j.pairs.begin(), j.pairs.end());
            }
            const double cnt = static_cast<double>(all.size() ? all.size() : 1);
            std::sort(all.begin(), all.end());
            const double p50 = all.empty() ? 0 : all[all.size() / 2], p95 = all.empty() ? 0 : all[all.size() * 95 / 100];
            printf("%d,%d,%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n", kb, t, bg, n, a / cnt, tc / cnt, fr / cnt, (a + tc + fr) / cnt, p50, p95,
                   rt / cnt);
            fflush(stdout);
            for (HANDLE h : hs) CloseHandle(h);
            CloseHandle(go);
        }
    }
    return 0;
}
