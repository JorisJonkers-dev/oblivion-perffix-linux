// Guards the build-dll.sh flags: a __try/__except around plain loads of a bad pointer must catch the access violation
// in the optimised DLL build. clang-cl without /EHa drops such a __try (loads are not assumed to fault), the stale
// pointer then kills the game (tick_split ProbeKind crash). Built by selftest.sh with the EH flag taken from build-dll.sh.
#include <windows.h>
#include <cstdint>
#include <cstdio>

static int Probe(const uint8_t* obj)
{
    __try {
        const uint8_t* c = *reinterpret_cast<uint8_t* const*>(obj + 0x10);
        for (int i = 0; i < 4 && c; ++i) {
            const uint8_t* const next = *reinterpret_cast<uint8_t* const*>(c + 0x10);
            if (next == c) return 1;
            c = next;
        }
        return 2;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 3;
    }
}

int main(int argc, char**)
{
    const int r = Probe(reinterpret_cast<const uint8_t*>(0x0e080000bb81ull + static_cast<uint64_t>(argc - 1)));
    std::printf("%s  build flags: __try/__except catches an access violation in the optimised build (result %d)\n",
                r == 3 ? "PASS" : "FAIL", r);
    return r == 3 ? 0 : 1;
}
