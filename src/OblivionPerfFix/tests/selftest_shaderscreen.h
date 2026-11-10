// ShaderScreenAfterDriverChange (game bug) self-test, included by selftest.cpp: the start-up's Save_Settings
// check on the mapped exe, and the wrapper with a fake DoesSaveGameExist, a fake graphics card and a record file in the
// temp folder (first record, unchanged, changed once, no settings save).
#pragma once

#include <string>

namespace shs {

inline bool g_exists = true;
inline bool FakeExists(const void*, int32_t) { return g_exists; }
inline const char* g_gpu = "10DE 2B85 00000000 A1 32.0.15.8180";
inline bool FakeGpu(char* out, size_t size)
{
    snprintf(out, size, "%s", g_gpu);
    return true;
}

inline std::string ReadAll(const std::wstring& path)
{
    FILE* f = nullptr;
    if (_wfopen_s(&f, path.c_str(), L"rb") != 0 || !f) return "";
    char buf[2048] = "";
    const size_t n = fread(buf, 1, sizeof buf - 1, f);
    fclose(f);
    return std::string(buf, n);
}

// Linux side (ShaderScreenLinuxFingerprint): fake Mesa/vkd3d/Wine tokens and cache sizes
inline char g_tok[200] = "wine=9.0 proton=Proton_9.0/1700000000_proton-9.0-3 vkd3d=00aa.4096 icd=libvulkan_radeon.so:100:1:mesa=26.2.6";
inline uint64_t g_vk = 50u << 20, g_me = 200u << 20;
inline bool FakeLinux(char* out, size_t size, uint64_t* v, uint64_t* m)
{
    snprintf(out, size, "%s", g_tok);
    *v = g_vk;
    *m = g_me;
    return true;
}

inline void RunLinux(const std::wstring& record, void* hookFn)
{
    using namespace opf;
    using ExistsFn = bool (*)(const void*, int32_t);
    const auto wrap = reinterpret_cast<ExistsFn>(hookFn);
    const auto start = [&] { ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str()); };
    g_exists = true;
    g_gpu = "10DE 2B85 00000000 A1 32.0.15.8180";
    SetShaderScreenLinux(true);
    ShaderScreenTestLinux(&FakeLinux);
    DeleteFileW(record.c_str());
    start();
    Check(wrap(nullptr, 0), "shader screen (Linux side): no record yet: recorded, the game's answer");
    std::string rec = ReadAll(record);
    Check(rec.find(" | wine=9.0 proton=Proton_9.0/1700000000_proton-9.0-3 vkd3d=00aa.4096 icd=libvulkan_radeon.so:100:1:mesa=26.2.6") != std::string::npos &&
              rec.find("caches 52428800 209715200") != std::string::npos,
          "shader screen (Linux side): the record holds card, Wine, Proton, vkd3d-proton, Mesa and the two cache sizes");
    start();
    Check(wrap(nullptr, 0) && !PsoPrecompileScreenHold(), "shader screen (Linux side): nothing changed: start-up as usual");
    g_me = 400u << 20;   // a cache that grew (normal play)
    start();
    Check(wrap(nullptr, 0) && ReadAll(record).find("caches 52428800 419430400") != std::string::npos,
          "shader screen (Linux side): a grown cache is no change, the new size recorded");
    snprintf(g_tok, sizeof g_tok, "wine=9.0 proton=Proton_9.0/1700000000_proton-9.0-3 vkd3d=00aa.4096 icd=libvulkan_radeon.so:100:1:mesa=26.3.0");
    start();
    Check(!wrap(nullptr, 0), "shader screen (Linux side): Mesa updated (same DXGI card and driver): the first-launch path, the screen");
    Check(ReadAll(record).find("mesa=26.2.6") != std::string::npos, "shader screen (Linux side): the old record kept until the precompile has finished");
    ShaderScreenPrecompileFinished();
    Check(ReadAll(record).find("mesa=26.3.0") != std::string::npos, "shader screen (Linux side): the new Mesa recorded once it has finished");
    start();
    Check(wrap(nullptr, 0), "shader screen (Linux side): the next start-up with that Mesa: the game's answer");
    snprintf(g_tok, sizeof g_tok, "wine=9.0 proton=Proton_9.0/1700000000_proton-9.0-3 vkd3d=00bb.4096 icd=libvulkan_radeon.so:100:1:mesa=26.3.0");
    start();
    Check(!wrap(nullptr, 0), "shader screen (Linux side): vkd3d-proton's DLL changed: the screen");
    ShaderScreenPrecompileFinished();
    snprintf(g_tok, sizeof g_tok, "wine=9.0 proton=Proton_9.1/1700000001_proton-9.1-1 vkd3d=00bb.4096 icd=libvulkan_radeon.so:100:1:mesa=26.3.0");
    start();
    Check(!wrap(nullptr, 0), "shader screen (Linux side): another Proton: the screen");
    ShaderScreenPrecompileFinished();
    // a wiped cache
    g_vk = 50u << 20;
    g_me = 5u << 20;   // 419 MB -> 5 MB
    start();
    Check(!wrap(nullptr, 0), "shader screen (Linux side): Mesa's shader cache wiped (under half of its recorded size): the screen");
    Check(ReadAll(record).find("caches 52428800 419430400") != std::string::npos, "shader screen (Linux side): the old cache sizes kept until it has finished");
    g_me = 150u << 20;   // refilled during the screen
    ShaderScreenPrecompileFinished();
    Check(ReadAll(record).find("caches 52428800 157286400") != std::string::npos, "shader screen (Linux side): the refilled size recorded at the end");
    start();
    Check(wrap(nullptr, 0), "shader screen (Linux side): the next start-up: no screen");
    g_vk = 10u << 20;   // vkd3d-proton's cache file deleted/truncated
    start();
    Check(!wrap(nullptr, 0), "shader screen (Linux side): the vkd3d-proton pipeline cache wiped: the screen");
    ShaderScreenPrecompileFinished();
    // never a loop here either
    g_me = 1u << 20;
    for (int n = 1; n <= 2; ++n) {
        start();
        Check(!wrap(nullptr, 0) && ShaderScreenShownUnrecorded() == n, n == 1 ? "shader screen (Linux side): wiped again: shown (1)" : "shader screen (Linux side): ... still not recorded: shown (2)");
    }
    start();
    Check(wrap(nullptr, 0) && ShaderScreenShownUnrecorded() == 2, "shader screen (Linux side): after two shows without the end being recorded: the game's answer, no loop");
    // tiny recorded caches say nothing
    g_vk = 100u << 10;
    g_me = 100u << 10;
    DeleteFileW(record.c_str());
    start();
    wrap(nullptr, 0);
    g_vk = 0;
    g_me = 0;
    start();
    Check(wrap(nullptr, 0), "shader screen (Linux side): caches under 1 MB recorded going to 0: no screen");
    // a record from before the Linux side was followed: extended, no screen
    FILE* f = nullptr;
    if (_wfopen_s(&f, record.c_str(), L"wb") == 0 && f) {
        fputs("10DE 2B85 00000000 A1 32.0.15.8180\r\n", f);
        fclose(f);
    }
    g_vk = 50u << 20;
    g_me = 200u << 20;
    start();
    Check(wrap(nullptr, 0) && ReadAll(record).find(" | wine=") != std::string::npos, "shader screen (Linux side): an older record (card only): extended with the Linux side, no screen");
    // switched off: the Linux side is ignored
    SetShaderScreenLinux(false);
    snprintf(g_tok, sizeof g_tok, "wine=10.0 proton=? vkd3d=? icd=?");
    start();
    Check(wrap(nullptr, 0), "shader screen (Linux side): ShaderScreenLinuxFingerprint=0: the Linux side is ignored (a record with it still matches by card and driver)");
    // the real probe (only meaningful under Wine; Windows has no such Z: drive)
    char tokens[640] = "";
    uint64_t vkb = 0, meb = 0;
    const bool real = ShaderScreenRealLinuxProbe(tokens, sizeof tokens, &vkb, &meb);
    if (IsWine()) {
        Check(real && strstr(tokens, "wine=") == tokens && strstr(tokens, "proton=") && strstr(tokens, "vkd3d=") && strstr(tokens, "icd="),
              "shader screen (Linux side): the real probe under Wine gives wine, proton, vkd3d and icd tokens");
        printf("      real Linux-side tokens: %s\n      shader caches: vkd3d-proton %.1f MB, Mesa %.1f MB\n", tokens, vkb / 1048576.0, meb / 1048576.0);
    } else {
        Check(!real, "shader screen (Linux side): off Wine the probe gives nothing (Windows behaviour unchanged)");
    }
    ShaderScreenTestLinux(nullptr);
    SetShaderScreenLinux(true);
    SetPsoPrecompileScreenHold(false);
}

inline void Run(const opf::GameModule& game)
{
    using namespace opf;
    SetShaderScreenLinux(false);   // the checks below are the Windows ones (a single-line record)
    wchar_t tmp[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    std::wstring dir(tmp);
    if (!dir.empty() && dir.back() == L'\\') dir.pop_back();
    Check(ApplyShaderScreenAfterDriverChange(true, dir.c_str()), "shader screen: the start-up's Save_Settings check found, call redirected");
    uint8_t *call = nullptr, *orig = nullptr, *stub = nullptr;
    void* hook = nullptr;
    if (!Installed(ShaderScreenInfo(&call, &orig, &stub, &hook), "ShaderScreenAfterDriverChange (shader screen after a driver change)")) return;
    Check(call == game.base + 0x44E12C4, "shader screen: the start-up calls DoesSaveGameExist at exe+0x44E12C4");
    Check(orig == game.base + 0x31A4F30, "shader screen: DoesSaveGameExist at exe+0x31A4F30");
    Check(call[0] == 0xE8 && RipTarget(call, 1, 5) == stub && *reinterpret_cast<void* const*>(stub + 6) == hook,
          "shader screen: the call goes to the stub, the stub to the wrapper");
    Check(call[15] == 0x88 && call[16] == 0x87 && call[17] == 0x89, "shader screen: the answer goes to the flag at +0x89");

    using ExistsFn = bool (*)(const void*, int32_t);
    const auto wrap = reinterpret_cast<ExistsFn>(hook);
    const std::wstring record = dir + L"\\OblivionPerfFix-gpu-selftest.txt";
    DeleteFileW(record.c_str());
    g_exists = true;
    ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
    Check(wrap(nullptr, 0) && ReadAll(record).rfind("10DE 2B85", 0) == 0, "shader screen: no record yet: recorded, the game's answer");
    ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
    Check(wrap(nullptr, 0), "shader screen: same card and driver: the game's answer (save exists)");
    g_gpu = "10DE 2B85 00000000 A1 32.0.15.8215";
    ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
    Check(!wrap(nullptr, 0), "shader screen: driver changed: \"no settings save\" (the first-launch path)");
    PsoPrecompileInfoOut pso{};
    if (PsoPrecompileInfo(&pso)) Check(PsoPrecompileScreenHold(), "shader screen: PsoPrecompileFast told to run the screen at the Fast pace");
    Check(!wrap(nullptr, 0), "shader screen: the same start-up asks again: the same answer");
    Check(ReadAll(record).find("32.0.15.8180") != std::string::npos, "shader screen: the old record kept until the precompile has finished");
    ShaderScreenPrecompileFinished();
    Check(ReadAll(record).find("32.0.15.8215") != std::string::npos, "shader screen: the new driver recorded once it has finished");
    ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
    Check(wrap(nullptr, 0), "shader screen: the next start-up with that driver: the game's answer");
    // Never a loop (review rev124): at most two shows for one driver without the record catching up.
    if (PsoPrecompileInfo(&pso)) {
        g_gpu = "10DE 2B85 00000000 A1 32.0.15.9000";
        bool loop = true;
        for (int start = 1; start <= 2; ++start) {
            ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
            loop = loop && !wrap(nullptr, 0) && ShaderScreenShownUnrecorded() == start &&
                   ReadAll(record).find("shown " + std::to_string(start) + " 10DE 2B85 00000000 A1 32.0.15.9000") != std::string::npos;
        }
        ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
        loop = loop && wrap(nullptr, 0) && ReadAll(record).rfind("10DE 2B85 00000000 A1 32.0.15.9000\r\n", 0) == 0 &&
               ReadAll(record).find("shown") == std::string::npos;
        ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
        loop = loop && wrap(nullptr, 0);
        Check(loop, "shader screen: shown twice for a driver without being recorded: the third start-up is the game's and records it");
    }
    // A record that cannot be written: no screen (it would come back at every start).
    g_gpu = "10DE 2B85 00000000 A1 32.0.15.9100";
    SetFileAttributesW(record.c_str(), FILE_ATTRIBUTE_READONLY);
    ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
    Check(wrap(nullptr, 0) && ShaderScreenShownUnrecorded() == -1 && ReadAll(record).find("32.0.15.9100") == std::string::npos,
          "shader screen: driver changed but the record is read-only: the game's answer, nothing written");
    SetFileAttributesW(record.c_str(), FILE_ATTRIBUTE_NORMAL);
    g_exists = false;
    ShaderScreenTestSetup(reinterpret_cast<void*>(&FakeExists), &FakeGpu, record.c_str());
    Check(!wrap(nullptr, 0), "shader screen: no settings save at all: the game's answer (its own first launch)");
    DeleteFileW(record.c_str());
    SetPsoPrecompileScreenHold(false);
    g_exists = true;
    g_gpu = "10DE 2B85 00000000 A1 32.0.15.8180";
    RunLinux(record, hook);
    DeleteFileW(record.c_str());
    SetPsoPrecompileScreenHold(false);
    ShaderScreenTestSetup(nullptr, nullptr, nullptr);
}

}  // namespace shs
