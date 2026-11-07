// PsoRecordReplay (off by default until measured): record the pipeline states the game creates DURING PLAY, replay them
// behind the loading screen at the next start so the driver stack compiles and caches them before play.
//
// The problem. The start-up precompile (PsoPrecompileFast + ShaderGateBeforePlay) covers the pipelines the game's own
// pipeline cache lists. Unreal Engine 5's runtime PSO precaching asks for more while play goes on: a cell's meshes, an NPC's
// materials, clutter. Each such request ends in ID3D12Device::CreateGraphicsPipelineState / CreateComputePipelineState /
// ID3D12Device2::CreatePipelineState, which vkd3d-proton turns into a Vulkan pipeline compile (a persistent-cache hit is fast,
// a pipeline the machine never saw is a real compile) and UE may keep the object hidden until it is done.
//
// Measure (PsoRecordReplay=1 or 2). The three creation functions of the game's device (and CreateRootSignature) are hooked
// in the device's vtable (slots 10, 11, 47 and 16). The game's device is reached deterministically: at start-up d3d12.dll's
// export table entry for D3D12CreateDevice is pointed at a jump stub as soon as the DLL is mapped (a DLL load notification), so
// the wrapper hooks the vtable of every device the process creates before the game can call it. vkd3d-proton does not give
// every device the same vtable (a device made on the side, as an earlier version did, was not the game's), so each hooked
// vtable keeps its own originals and the device used for the replay is the one a hooked call came from. If no creation call is
// seen (redirect not possible) the device is found through its adapter after 20 s; if no hooked call is seen in 30 s of play a
// WARNING line says so. Every call
// that happens once play has begun (PsoPrecompileFast's "in play") is timed; each minute of play one line is logged:
//   [psorec] in play: N new PSOs, total X ms, max Y ms (...)
// "new" is a pipeline that the record file from earlier sessions did not already hold, i.e. one that was not replayed.
//
// Record (PsoRecordReplay=1). Such a pipeline's description is serialised into OblivionPerfFix-psorecord.bin next to the DLL:
// the description's plain fields, the shader bytecode (the game's own, recorded from the call, deduplicated by a 64-bit hash,
// stored only on the player's PC, never shipped), the input layout and the root signature. A root signature cannot be read back
// from the D3D12 object, so the blob given to CreateRootSignature is kept per object (a pipeline whose root signature was
// created before the hook was in is not recorded and counted as "unknown root signature"). The file is bounded
// (PsoRecordMaxMB), appended in checked records (a torn tail is cut off at the next start), tied to the game exe's
// TimeDateStamp (another build starts an empty file), and deduplicated by the pipeline's hash.
//
// Replay (PsoRecordReplay=1). As soon as the device is found at the next start, PsoReplayThreads worker threads create each
// recorded pipeline on the device through the original functions (not recorded again) and release it at once. The creation is
// what makes vkd3d-proton / Mesa compile and cache it, so the same call in play is a cache hit. ShaderGateBeforePlay keeps the
// first load after the main menu on its loading screen while the replay runs (same cap, ShaderGateMaxSeconds); a replay still
// running when play has begun is stopped.
//
// What changes: only when and where the compile happens; the pipelines are the game's own, the image is the same. A creation
// that fails or faults in the replay is skipped. Trade-off: the replay competes with the start-up precompile for the driver's
// compile threads and lengthens the start-up by the time the new pipelines need (nothing once the persistent caches hold them).
#include "common.h"

#include <d3d12.h>
#include <dxgi1_4.h>

#include <atomic>
#include <cstdio>
#include <cstring>
#include <deque>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace opf {
namespace {

// vtable slots (ID3D12Device 10, 11, 16; ID3D12Device2 47): counted in the SDK's d3d12.h
constexpr size_t kSlotGfx = 10, kSlotCompute = 11, kSlotRootSig = 16, kSlotStream = 47, kSlotCount = 48;
constexpr uint8_t kTagBlob = 'B', kTagPso = 'P';
constexpr uint8_t kBlobShader = 1, kBlobRootSig = 2, kBlobLayout = 3;
constexpr uint8_t kKindGfx = 1, kKindCompute = 2, kKindStream = 3;
constexpr size_t kMaxBlob = 32u << 20;
constexpr char kMagic[8] = {'O', 'P', 'F', 'P', 'S', 'O', '0', '1'};

using GfxFn = HRESULT(STDMETHODCALLTYPE*)(void*, const D3D12_GRAPHICS_PIPELINE_STATE_DESC*, REFIID, void**);
using ComputeFn = HRESULT(STDMETHODCALLTYPE*)(void*, const D3D12_COMPUTE_PIPELINE_STATE_DESC*, REFIID, void**);
using StreamFn = HRESULT(STDMETHODCALLTYPE*)(void*, const D3D12_PIPELINE_STATE_STREAM_DESC*, REFIID, void**);
using RootSigFn = HRESULT(STDMETHODCALLTYPE*)(void*, UINT, const void*, SIZE_T, REFIID, void**);

// ---- state ----
std::atomic<int> g_mode{0};            // 0 off, 1 record + replay, 2 measure only
std::atomic<int> g_forcePlay{-1};      // self-test: -1 ask PsoPlayStarted, 0/1 forced
std::atomic<uint32_t> g_minUs{0};
std::atomic<uint64_t> g_maxBytes{128ull << 20};
// One entry per device vtable hooked (vkd3d-proton does not give every device the same vtable: the first live run's hooks on a
// second device never saw the game's calls). A hook finds its originals through the vtable of the device it was called on.
struct VT {
    void** vt;
    void* orig[kSlotCount];
    bool stream;
};
constexpr int kMaxVt = 6;
VT g_vts[kMaxVt];
std::atomic<int> g_nvt{0};
VT* FindVt(void** vt)
{
    const int n = g_nvt.load();
    for (int i = 0; i < n; ++i)
        if (g_vts[i].vt == vt) return &g_vts[i];
    return nullptr;
}
VT* Of(void* self)
{
    VT* v = FindVt(*static_cast<void***>(self));
    return v ? v : &g_vts[0];
}
VT* g_rvt = nullptr;                      // the replay device's entry
std::atomic<void*> g_candidate{nullptr};  // first device a D3D12CreateDevice call of the process returned (a reference is held)
std::atomic<void*> g_gameDev{nullptr};    // a device a hooked pipeline / root-signature call was made on (the game's), reference held
std::atomic<uint64_t> g_hookSeen{0};      // every hooked call, in play or not
std::atomic<uint64_t> g_createSeen{0};    // D3D12CreateDevice calls that returned a device
ULONGLONG g_candidateAt = 0, g_firstTick = 0, g_playAt = 0;
bool g_started = false, g_warned = false, g_fallbackTried = false;
void* g_realCreate = nullptr;             // the real D3D12CreateDevice
uint32_t* g_eatSlot = nullptr;
uint32_t g_eatOrig = 0;
const char* g_how = "";
std::wstring g_path;
thread_local bool t_inReplay = false;

std::mutex g_mu;
struct Blob {
    uint8_t kind = 0;
    std::vector<uint8_t> data;
};
std::unordered_map<void*, uint64_t> g_rsOf;                 // root signature object -> blob hash
std::unordered_map<uint64_t, std::vector<uint8_t>> g_rsBlobs;   // root signature blobs seen (hash -> bytes)
std::unordered_map<uint64_t, Blob> g_pendBlobs;             // shader / layout blobs not yet in the file
std::unordered_set<uint64_t> g_savedBlobs;                  // blobs in the file (or being written)
std::unordered_set<uint64_t> g_knownPso;                    // pipelines in the file or pending
struct Rec {
    uint8_t kind = 0;
    uint64_t hash = 0;
    std::vector<uint8_t> pod;
    std::vector<uint64_t> refs;
};
std::vector<Rec> g_pendRecs;
uint64_t g_fileBytes = 0, g_pendBytes = 0;
bool g_full = false, g_fileReady = false;
std::unordered_set<uint64_t> g_loadedPso;                   // the PSOs the file held at start (what was replayed)

// replay data (freed when the replay is done)
struct ReplaySet {
    std::unordered_map<uint64_t, Blob> blobs;
    std::vector<Rec> recs;
};
ReplaySet* g_set = nullptr;
std::atomic<bool> g_replayBusy{false}, g_replayStop{false};
std::atomic<size_t> g_replayNext{0};
std::atomic<uint64_t> g_replayDone{0}, g_replayFail{0}, g_replayUs{0};
std::atomic<int> g_replayWorkers{0};
uint64_t g_replayT0 = 0;
size_t g_replayTotal = 0;
std::mutex g_rsMu;
std::unordered_map<uint64_t, ID3D12RootSignature*> g_rsMade;   // replay's root signatures
void* g_replayDevice = nullptr;
bool g_replayOwnDevice = false;

// stats
std::atomic<uint64_t> g_calls{0}, g_newN{0}, g_totalUs{0}, g_maxUs{0}, g_recorded{0}, g_skipped{0}, g_rsKnown{0}, g_rsUnknown{0},
    g_replayedSeen{0}, g_replayedUs{0};
std::atomic<uint64_t> g_iCalls{0}, g_iNew{0}, g_iUs{0}, g_iMaxUs{0}, g_iSlow{0};
ULONGLONG g_lastStat = 0, g_lastFlush = 0, g_nextTry = 0;
bool g_deviceTried = false;

uint64_t Qpc()
{
    LARGE_INTEGER c;
    QueryPerformanceCounter(&c);
    return static_cast<uint64_t>(c.QuadPart);
}
uint64_t UsSince(uint64_t t0)
{
    static const uint64_t f = [] {
        LARGE_INTEGER q;
        QueryPerformanceFrequency(&q);
        return static_cast<uint64_t>(q.QuadPart);
    }();
    return (Qpc() - t0) * 1000000ull / f;
}

uint64_t H64(const void* p, size_t n, uint64_t seed = 0x84222325CBF29CE4ull)
{
    const auto* b = static_cast<const uint8_t*>(p);
    uint64_t h = seed ^ (n * 0x9E3779B97F4A7C15ull);
    size_t i = 0;
    for (; i + 8 <= n; i += 8) {
        uint64_t w;
        memcpy(&w, b + i, 8);
        h = (h ^ w) * 0x9E3779B97F4A7C15ull;
        h ^= h >> 29;
    }
    uint64_t t = 0;
    memcpy(&t, b + i, n - i);
    h = (h ^ t) * 0xC2B2AE3D27D4EB4Full;
    h ^= h >> 32;
    h *= 0x165667B19E3779F9ull;
    h ^= h >> 29;
    return h ? h : 1;
}

bool PlayStarted()
{
    const int f = g_forcePlay.load();
    return f >= 0 ? f != 0 : PsoPlayStarted();
}

// ---- serialisation ----

void PutPtr(void* slot, uint64_t v) { memcpy(slot, &v, 8); }
uint64_t GetPtr(const void* slot)
{
    uint64_t v;
    memcpy(&v, slot, 8);
    return v;
}

void NormBlend(D3D12_BLEND_DESC& b)
{
    for (auto& rt : b.RenderTarget) {
        auto* p = reinterpret_cast<uint8_t*>(&rt);
        const size_t from = offsetof(D3D12_RENDER_TARGET_BLEND_DESC, RenderTargetWriteMask) + 1;
        memset(p + from, 0, sizeof rt - from);
    }
}
template <class T>
void NormDepth(T& d)
{
    auto* p = reinterpret_cast<uint8_t*>(&d);
    memset(p + offsetof(T, StencilWriteMask) + 1, 0, offsetof(T, FrontFace) - offsetof(T, StencilWriteMask) - 1);
}

struct SubInfo {
    uint32_t size, align;
};
bool SubInfoOf(uint32_t type, SubInfo* i)
{
    switch (type) {
        case 0: *i = {8, 8}; return true;                          // root signature
        case 1: case 2: case 3: case 4: case 5: case 6:           // VS PS DS HS GS CS
        case 24: case 25: *i = {16, 8}; return true;              // AS MS
        case 7: *i = {32, 8}; return true;                        // stream output
        case 8: *i = {sizeof(D3D12_BLEND_DESC), 4}; return true;
        case 9: *i = {4, 4}; return true;                         // sample mask
        case 10: *i = {sizeof(D3D12_RASTERIZER_DESC), 4}; return true;
        case 11: *i = {sizeof(D3D12_DEPTH_STENCIL_DESC), 4}; return true;
        case 12: *i = {16, 8}; return true;                       // input layout
        case 13: case 14: case 16: case 18: case 20: *i = {4, 4}; return true;
        case 15: *i = {36, 4}; return true;                       // render target formats
        case 17: *i = {8, 4}; return true;                        // sample desc
        case 19: *i = {16, 8}; return true;                       // cached PSO
        case 21: *i = {sizeof(D3D12_DEPTH_STENCIL_DESC1), 4}; return true;
        case 22: *i = {24, 8}; return true;                       // view instancing
        default: return false;
    }
}

// One call to f(type, payload, size) per subobject of a pipeline state stream; false if the stream is not understood.
template <class F>
bool WalkStream(const uint8_t* s, size_t n, F f)
{
    size_t at = 0;
    while (at < n) {
        if (at + 8 > n) return false;
        uint32_t type;
        memcpy(&type, s + at, 4);
        SubInfo si;
        if (!SubInfoOf(type, &si)) return false;
        const size_t pay = at + (si.align == 8 ? 8 : 4);
        if (pay + si.size > n) return false;
        if (!f(type, s + pay, si.size)) return false;
        at = (pay + si.size + 7) & ~size_t(7);
    }
    return true;
}

// callers hold g_mu. Returns the blob's hash (0: none).
uint64_t AddBlob(uint8_t kind, const void* p, size_t n, std::vector<uint64_t>* refs, uint64_t* newBytes)
{
    if (!p || !n || n > kMaxBlob) return 0;
    const uint64_t h = H64(p, n, kind);
    refs->push_back(h);
    if (!g_savedBlobs.count(h) && !g_pendBlobs.count(h)) {
        Blob& b = g_pendBlobs[h];
        b.kind = kind;
        b.data.assign(static_cast<const uint8_t*>(p), static_cast<const uint8_t*>(p) + n);
        *newBytes += n + 24;
    }
    return h;
}

uint64_t AddLayout(const D3D12_INPUT_LAYOUT_DESC& il, std::vector<uint64_t>* refs, uint64_t* newBytes, bool* ok)
{
    if (!il.pInputElementDescs || !il.NumElements) return 0;
    if (il.NumElements > 64) {
        *ok = false;
        return 0;
    }
    std::vector<uint8_t> b;
    const auto put32 = [&](uint32_t v) { b.insert(b.end(), reinterpret_cast<uint8_t*>(&v), reinterpret_cast<uint8_t*>(&v) + 4); };
    put32(il.NumElements);
    for (UINT i = 0; i < il.NumElements; ++i) {
        const auto& e = il.pInputElementDescs[i];
        put32(e.SemanticIndex);
        put32(e.Format);
        put32(e.InputSlot);
        put32(e.AlignedByteOffset);
        put32(e.InputSlotClass);
        put32(e.InstanceDataStepRate);
        const size_t len = e.SemanticName ? strnlen(e.SemanticName, 128) : 0;
        put32(static_cast<uint32_t>(len));
        b.insert(b.end(), e.SemanticName, e.SemanticName + len);
    }
    return AddBlob(kBlobLayout, b.data(), b.size(), refs, newBytes);
}

uint64_t AddShader(const D3D12_SHADER_BYTECODE& s, D3D12_SHADER_BYTECODE* out, std::vector<uint64_t>* refs, uint64_t* nb)
{
    const uint64_t h = AddBlob(kBlobShader, s.pShaderBytecode, s.BytecodeLength, refs, nb);
    out->pShaderBytecode = nullptr;
    out->BytecodeLength = 0;
    if (h) {
        PutPtr(&out->pShaderBytecode, h);
        out->BytecodeLength = s.BytecodeLength;
    }
    return h;
}

// root signature: object -> recorded hash (0: none given; ok=false: given but unknown)
uint64_t RsHash(ID3D12RootSignature* rs, std::vector<uint64_t>* refs, uint64_t* nb, bool* ok)
{
    if (!rs) return 0;
    const auto it = g_rsOf.find(rs);
    if (it == g_rsOf.end()) {
        *ok = false;
        return 0;
    }
    const uint64_t h = it->second;
    refs->push_back(h);
    if (!g_savedBlobs.count(h) && !g_pendBlobs.count(h)) {
        const auto b = g_rsBlobs.find(h);
        if (b == g_rsBlobs.end()) {
            *ok = false;
            return 0;
        }
        Blob& pb = g_pendBlobs[h];
        pb.kind = kBlobRootSig;
        pb.data = b->second;
        *nb += pb.data.size() + 24;
    }
    return h;
}

bool SerGraphics(const D3D12_GRAPHICS_PIPELINE_STATE_DESC& d, Rec* r, uint64_t* nb)
{
    if (d.StreamOutput.NumEntries || d.StreamOutput.NumStrides) return false;
    D3D12_GRAPHICS_PIPELINE_STATE_DESC c;
    memset(&c, 0, sizeof c);
    bool ok = true;
    PutPtr(&c.pRootSignature, RsHash(d.pRootSignature, &r->refs, nb, &ok));
    AddShader(d.VS, &c.VS, &r->refs, nb);
    AddShader(d.PS, &c.PS, &r->refs, nb);
    AddShader(d.DS, &c.DS, &r->refs, nb);
    AddShader(d.HS, &c.HS, &r->refs, nb);
    AddShader(d.GS, &c.GS, &r->refs, nb);
    c.BlendState = d.BlendState;
    NormBlend(c.BlendState);
    c.SampleMask = d.SampleMask;
    c.RasterizerState = d.RasterizerState;
    c.DepthStencilState = d.DepthStencilState;
    NormDepth(c.DepthStencilState);
    c.InputLayout.NumElements = d.InputLayout.NumElements;
    PutPtr(&c.InputLayout.pInputElementDescs, AddLayout(d.InputLayout, &r->refs, nb, &ok));
    c.IBStripCutValue = d.IBStripCutValue;
    c.PrimitiveTopologyType = d.PrimitiveTopologyType;
    c.NumRenderTargets = d.NumRenderTargets;
    memcpy(c.RTVFormats, d.RTVFormats, sizeof c.RTVFormats);
    c.DSVFormat = d.DSVFormat;
    c.SampleDesc = d.SampleDesc;
    c.NodeMask = d.NodeMask;
    c.Flags = d.Flags;
    r->kind = kKindGfx;
    r->pod.assign(reinterpret_cast<uint8_t*>(&c), reinterpret_cast<uint8_t*>(&c) + sizeof c);
    return ok;
}

bool SerCompute(const D3D12_COMPUTE_PIPELINE_STATE_DESC& d, Rec* r, uint64_t* nb)
{
    D3D12_COMPUTE_PIPELINE_STATE_DESC c;
    memset(&c, 0, sizeof c);
    bool ok = true;
    PutPtr(&c.pRootSignature, RsHash(d.pRootSignature, &r->refs, nb, &ok));
    AddShader(d.CS, &c.CS, &r->refs, nb);
    c.NodeMask = d.NodeMask;
    c.Flags = d.Flags;
    r->kind = kKindCompute;
    r->pod.assign(reinterpret_cast<uint8_t*>(&c), reinterpret_cast<uint8_t*>(&c) + sizeof c);
    return ok;
}

bool SerStream(const D3D12_PIPELINE_STATE_STREAM_DESC& d, Rec* r, uint64_t* nb)
{
    if (!d.pPipelineStateSubobjectStream || !d.SizeInBytes || d.SizeInBytes > (1u << 20)) return false;
    bool ok = true;
    std::vector<uint8_t>& pod = r->pod;
    const bool walked = WalkStream(static_cast<const uint8_t*>(d.pPipelineStateSubobjectStream), d.SizeInBytes,
                                   [&](uint32_t type, const uint8_t* p, size_t size) {
        if (type == 19) return true;   // cached PSO: dropped
        const size_t at = pod.size();
        pod.insert(pod.end(), reinterpret_cast<uint8_t*>(&type), reinterpret_cast<uint8_t*>(&type) + 4);
        pod.insert(pod.end(), p, p + size);
        uint8_t* q = pod.data() + at + 4;
        if (type == 0) {
            ID3D12RootSignature* rs;
            memcpy(&rs, p, 8);
            PutPtr(q, RsHash(rs, &r->refs, nb, &ok));
        } else if ((type >= 1 && type <= 6) || type == 24 || type == 25) {
            D3D12_SHADER_BYTECODE s, o;
            memcpy(&s, p, sizeof s);
            AddShader(s, &o, &r->refs, nb);
            memcpy(q, &o, sizeof o);
        } else if (type == 12) {
            D3D12_INPUT_LAYOUT_DESC il;
            memcpy(&il, p, sizeof il);
            const uint64_t h = AddLayout(il, &r->refs, nb, &ok);
            memset(q, 0, 16);
            PutPtr(q, h);
            memcpy(q + 8, &il.NumElements, 4);
        } else if (type == 7) {
            uint32_t n1, n2;
            memcpy(&n1, p + 8, 4);
            memcpy(&n2, p + 24, 4);
            if (n1 || n2) ok = false;
            memset(q, 0, 32);
        } else if (type == 22) {
            uint32_t n;
            memcpy(&n, p, 4);
            if (n) ok = false;
            memset(q, 0, 24);
        } else if (type == 8) {
            NormBlend(*reinterpret_cast<D3D12_BLEND_DESC*>(q));
        } else if (type == 11) {
            NormDepth(*reinterpret_cast<D3D12_DEPTH_STENCIL_DESC*>(q));
        } else if (type == 21) {
            NormDepth(*reinterpret_cast<D3D12_DEPTH_STENCIL_DESC1*>(q));
        }
        return true;
    });
    r->kind = kKindStream;
    return walked && ok;
}

void Finish(Rec* r)
{
    r->hash = H64(r->pod.data(), r->pod.size(), r->kind);
}

// ---- file ----

DWORD ExeStamp()
{
    const auto* base = reinterpret_cast<const uint8_t*>(GetModuleHandleW(nullptr));
    __try {
        const auto* dos = reinterpret_cast<const IMAGE_DOS_HEADER*>(base);
        const auto* nt = reinterpret_cast<const IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
        return nt->FileHeader.TimeDateStamp;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}
DWORD g_stamp = 0;

void PutBytes(std::vector<uint8_t>& o, const void* p, size_t n)
{
    o.insert(o.end(), static_cast<const uint8_t*>(p), static_cast<const uint8_t*>(p) + n);
}
void PutEntry(std::vector<uint8_t>& o, uint8_t tag, const std::vector<uint8_t>& payload)
{
    const uint32_t len = static_cast<uint32_t>(payload.size());
    o.push_back(tag);
    PutBytes(o, &len, 4);
    PutBytes(o, payload.data(), payload.size());
    const uint64_t h = H64(payload.data(), payload.size(), tag);
    PutBytes(o, &h, 8);
}
std::vector<uint8_t> Header()
{
    std::vector<uint8_t> h;
    PutBytes(h, kMagic, 8);
    PutBytes(h, &g_stamp, 4);
    const uint32_t z = 0;
    PutBytes(h, &z, 4);
    return h;
}

bool ReadFileAll(const std::wstring& path, std::vector<uint8_t>* out)
{
    FILE* f = nullptr;
    if (_wfopen_s(&f, path.c_str(), L"rb") != 0 || !f) return false;
    fseek(f, 0, SEEK_END);
    const long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n < 0 || n > (1l << 30)) {
        fclose(f);
        return false;
    }
    out->resize(static_cast<size_t>(n));
    const size_t got = n ? fread(out->data(), 1, out->size(), f) : 0;
    fclose(f);
    out->resize(got);
    return true;
}

// Parses the file's valid prefix into set (may be null: only the sets of known hashes). Returns the valid length (0: unusable).
size_t ParseFile(const std::vector<uint8_t>& f, ReplaySet* set)
{
    if (f.size() < 16 || memcmp(f.data(), kMagic, 8) != 0) return 0;
    DWORD stamp;
    memcpy(&stamp, f.data() + 8, 4);
    if (stamp != g_stamp) return 0;
    size_t at = 16, good = 16;
    while (at + 5 <= f.size()) {
        const uint8_t tag = f[at];
        uint32_t len;
        memcpy(&len, &f[at + 1], 4);
        if (at + 5 + len + 8 > f.size()) break;
        const uint8_t* p = &f[at + 5];
        uint64_t h;
        memcpy(&h, p + len, 8);
        if (h != H64(p, len, tag)) break;
        if (tag == kTagBlob && len > 9) {
            uint64_t bh;
            memcpy(&bh, p + 1, 8);
            g_savedBlobs.insert(bh);
            if (set) {
                Blob& b = set->blobs[bh];
                b.kind = p[0];
                b.data.assign(p + 9, p + len);
            }
        } else if (tag == kTagPso && len > 9) {
            Rec r;
            r.kind = p[0];
            memcpy(&r.hash, p + 1, 8);
            r.pod.assign(p + 9, p + len);
            g_knownPso.insert(r.hash);
            g_loadedPso.insert(r.hash);
            if (set) set->recs.push_back(std::move(r));
        } else {
            break;
        }
        at += 5 + len + 8;
        good = at;
    }
    return good;
}

bool TruncateTo(const std::wstring& path, size_t n)
{
    HANDLE h = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) return false;
    LARGE_INTEGER p;
    p.QuadPart = static_cast<LONGLONG>(n);
    const bool ok = SetFilePointerEx(h, p, nullptr, FILE_BEGIN) && SetEndOfFile(h);
    CloseHandle(h);
    return ok;
}

// Loads the record at the start. Returns the replay set (owned by the caller via g_set).
ReplaySet* LoadRecord(bool wantSet)
{
    std::vector<uint8_t> f;
    g_savedBlobs.clear();
    g_knownPso.clear();
    g_loadedPso.clear();
    g_fileReady = false;
    auto* set = wantSet ? new ReplaySet : nullptr;
    size_t good = 0;
    if (ReadFileAll(g_path, &f)) {
        good = ParseFile(f, set);
        if (good && good < f.size()) {
            Log("[psorec] the record file had %zu bytes of an unfinished write at its end: cut off", f.size() - good);
            TruncateTo(g_path, good);
        } else if (!good && !f.empty()) {
            Log("[psorec] the record file is from another game build or unreadable: started empty");
            g_savedBlobs.clear();
            g_knownPso.clear();
            g_loadedPso.clear();
            if (set) *set = ReplaySet();
        }
    }
    if (!good) {
        FILE* o = nullptr;
        const std::vector<uint8_t> h = Header();
        if (_wfopen_s(&o, g_path.c_str(), L"wb") == 0 && o) {
            fwrite(h.data(), 1, h.size(), o);
            fclose(o);
            good = h.size();
        }
    }
    g_fileBytes = good;
    g_pendBytes = 0;
    g_fileReady = good != 0;
    if (!g_fileReady) Log("[psorec] the record file %ls cannot be written: nothing is recorded", g_path.c_str());
    return set;
}

void Flush()
{
    std::unordered_map<uint64_t, Blob> blobs;
    std::vector<Rec> recs;
    {
        std::lock_guard<std::mutex> lk(g_mu);
        if (g_pendRecs.empty() && g_pendBlobs.empty()) return;
        blobs.swap(g_pendBlobs);
        recs.swap(g_pendRecs);
        for (auto& b : blobs) g_savedBlobs.insert(b.first);
        g_pendBytes = 0;
    }
    std::vector<uint8_t> out;
    for (auto& b : blobs) {
        std::vector<uint8_t> p;
        p.push_back(b.second.kind);
        PutBytes(p, &b.first, 8);
        PutBytes(p, b.second.data.data(), b.second.data.size());
        PutEntry(out, kTagBlob, p);
    }
    for (auto& r : recs) {
        std::vector<uint8_t> p;
        p.push_back(r.kind);
        PutBytes(p, &r.hash, 8);
        PutBytes(p, r.pod.data(), r.pod.size());
        PutEntry(out, kTagPso, p);
    }
    FILE* f = nullptr;
    if (_wfopen_s(&f, g_path.c_str(), L"ab") == 0 && f) {
        fwrite(out.data(), 1, out.size(), f);
        fclose(f);
        std::lock_guard<std::mutex> lk(g_mu);
        g_fileBytes += out.size();
    }
}

// ---- hooks ----

void NoteStats(uint64_t us, bool isNew)
{
    g_calls++;
    g_iCalls++;
    g_totalUs += us;
    g_iUs += us;
    if (isNew) {
        g_newN++;
        g_iNew++;
    } else {
        g_replayedSeen++;
        g_replayedUs += us;
    }
    for (std::atomic<uint64_t>* m : {&g_maxUs, &g_iMaxUs}) {
        uint64_t cur = m->load();
        while (us > cur && !m->compare_exchange_weak(cur, us)) {}
    }
    if (us >= 20000) g_iSlow++;
}

void NoteGameDevice(void* self);

struct Ctx {
    int what;   // 0 gfx, 1 compute, 2 stream
    const void* desc;
    uint64_t us;
    bool done;
};

void AfterCall(Ctx* c)
{
    Rec r;
    uint64_t nb = 0;
    bool ok = false;
    const int mode = g_mode.load();
    bool isNew = true;
    {
        std::lock_guard<std::mutex> lk(g_mu);
        if (mode == 1 && g_fileReady) {
            try {
                ok = c->what == 0   ? SerGraphics(*static_cast<const D3D12_GRAPHICS_PIPELINE_STATE_DESC*>(c->desc), &r, &nb)
                     : c->what == 1 ? SerCompute(*static_cast<const D3D12_COMPUTE_PIPELINE_STATE_DESC*>(c->desc), &r, &nb)
                                    : SerStream(*static_cast<const D3D12_PIPELINE_STATE_STREAM_DESC*>(c->desc), &r, &nb);
            } catch (...) {
                ok = false;
            }
            if (ok) {
                Finish(&r);
                isNew = g_loadedPso.count(r.hash) == 0;
                if (!g_knownPso.count(r.hash) && c->us >= g_minUs.load()) {
                    const uint64_t cost = nb + r.pod.size() + 40;
                    if (g_fileBytes + g_pendBytes + cost > g_maxBytes.load()) {
                        if (!g_full) {
                            g_full = true;
                            Log("[psorec] the record is full (%.1f MB, PsoRecordMaxMB): no more pipelines recorded",
                                (g_fileBytes + g_pendBytes) / 1048576.0);
                        }
                        g_pendBlobs.clear();   // blobs added for this record only
                        g_skipped++;
                    } else {
                        g_knownPso.insert(r.hash);
                        g_pendBytes += cost;
                        g_pendRecs.push_back(std::move(r));
                        g_recorded++;
                    }
                } else if (!g_knownPso.count(r.hash)) {
                    g_pendBlobs.clear();
                }
            } else {
                // blobs added by a record that could not be finished stay pending: harmless, written with the next one
                g_skipped++;
            }
        }
    }
    NoteStats(c->us, isNew);
}

bool Guarded(void (*fn)(Ctx*), Ctx* c)
{
    __try {
        fn(c);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return false;
    }
}

template <class Fn, class Desc, int What>
HRESULT Common(Fn orig, void* self, const Desc* d, REFIID riid, void** ppv)
{
    g_hookSeen++;
    if (!t_inReplay) NoteGameDevice(self);
    if (g_mode.load() == 0 || t_inReplay || !d) return orig(self, d, riid, ppv);
    const uint64_t t0 = Qpc();
    const HRESULT hr = orig(self, d, riid, ppv);
    const uint64_t us = UsSince(t0);
    if (SUCCEEDED(hr) && PlayStarted()) {
        Ctx c{What, d, us, false};
        if (!Guarded(&AfterCall, &c)) g_skipped++;
    }
    return hr;
}

HRESULT STDMETHODCALLTYPE HookGfx(void* self, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* d, REFIID riid, void** ppv)
{
    return Common<GfxFn, D3D12_GRAPHICS_PIPELINE_STATE_DESC, 0>(reinterpret_cast<GfxFn>(Of(self)->orig[kSlotGfx]), self, d, riid, ppv);
}
HRESULT STDMETHODCALLTYPE HookCompute(void* self, const D3D12_COMPUTE_PIPELINE_STATE_DESC* d, REFIID riid, void** ppv)
{
    return Common<ComputeFn, D3D12_COMPUTE_PIPELINE_STATE_DESC, 1>(reinterpret_cast<ComputeFn>(Of(self)->orig[kSlotCompute]), self, d, riid, ppv);
}
HRESULT STDMETHODCALLTYPE HookStream(void* self, const D3D12_PIPELINE_STATE_STREAM_DESC* d, REFIID riid, void** ppv)
{
    return Common<StreamFn, D3D12_PIPELINE_STATE_STREAM_DESC, 2>(reinterpret_cast<StreamFn>(Of(self)->orig[kSlotStream]), self, d, riid, ppv);
}

struct RsCtx {
    const void* blob;
    SIZE_T len;
    void* obj;
};
void RsStore(RsCtx* c)
{
    if (!c->blob || !c->len || c->len > (1u << 20)) return;
    const uint64_t h = H64(c->blob, c->len, kBlobRootSig);
    std::lock_guard<std::mutex> lk(g_mu);
    if (!g_rsBlobs.count(h)) g_rsBlobs[h].assign(static_cast<const uint8_t*>(c->blob), static_cast<const uint8_t*>(c->blob) + c->len);
    g_rsOf[c->obj] = h;
    g_rsKnown++;
}
bool GuardedRs(RsCtx* c)
{
    __try {
        RsStore(c);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return false;
    }
}

HRESULT STDMETHODCALLTYPE HookRootSig(void* self, UINT mask, const void* blob, SIZE_T len, REFIID riid, void** ppv)
{
    g_hookSeen++;
    if (!t_inReplay) NoteGameDevice(self);
    const HRESULT hr = reinterpret_cast<RootSigFn>(Of(self)->orig[kSlotRootSig])(self, mask, blob, len, riid, ppv);
    if (g_mode.load() == 1 && !t_inReplay && SUCCEEDED(hr) && ppv && *ppv) {
        RsCtx c{blob, len, *ppv};
        GuardedRs(&c);
    }
    return hr;
}

// ---- replay ----

struct Made {
    std::deque<std::vector<D3D12_INPUT_ELEMENT_DESC>> layouts;
    std::deque<std::string> names;
};

const Blob* FindBlob(uint64_t h, uint8_t kind)
{
    const auto it = g_set->blobs.find(h);
    return it != g_set->blobs.end() && it->second.kind == kind ? &it->second : nullptr;
}

bool MakeLayout(uint64_t h, UINT count, Made* m, const D3D12_INPUT_ELEMENT_DESC** out)
{
    const Blob* b = FindBlob(h, kBlobLayout);
    if (!b || b->data.size() < 4) return false;
    const uint8_t* p = b->data.data();
    const uint8_t* e = p + b->data.size();
    uint32_t n;
    memcpy(&n, p, 4);
    p += 4;
    if (n != count || n > 64) return false;
    m->layouts.emplace_back();
    auto& v = m->layouts.back();
    for (uint32_t i = 0; i < n; ++i) {
        uint32_t f[7];
        if (p + 28 > e) return false;
        memcpy(f, p, 28);
        p += 28;
        if (p + f[6] > e) return false;
        m->names.emplace_back(reinterpret_cast<const char*>(p), f[6]);
        p += f[6];
        D3D12_INPUT_ELEMENT_DESC d{};
        d.SemanticName = m->names.back().c_str();
        d.SemanticIndex = f[0];
        d.Format = static_cast<DXGI_FORMAT>(f[1]);
        d.InputSlot = f[2];
        d.AlignedByteOffset = f[3];
        d.InputSlotClass = static_cast<D3D12_INPUT_CLASSIFICATION>(f[4]);
        d.InstanceDataStepRate = f[5];
        v.push_back(d);
    }
    *out = v.data();
    return true;
}

bool MakeRs(uint64_t h, ID3D12RootSignature** out)
{
    *out = nullptr;
    if (!h) return true;
    std::lock_guard<std::mutex> lk(g_rsMu);
    const auto it = g_rsMade.find(h);
    if (it != g_rsMade.end()) {
        *out = it->second;
        return it->second != nullptr;
    }
    const Blob* b = FindBlob(h, kBlobRootSig);
    ID3D12RootSignature* rs = nullptr;
    if (b) {
        auto* dev = static_cast<ID3D12Device*>(g_replayDevice);
        const auto fn = reinterpret_cast<RootSigFn>(g_rvt->orig[kSlotRootSig]);
        void* obj = nullptr;
        if (FAILED(fn(dev, 0, b->data.data(), b->data.size(), __uuidof(ID3D12RootSignature), &obj))) obj = nullptr;
        rs = static_cast<ID3D12RootSignature*>(obj);
    }
    g_rsMade[h] = rs;
    *out = rs;
    return rs != nullptr;
}

bool Shader(D3D12_SHADER_BYTECODE* s)
{
    const uint64_t h = GetPtr(&s->pShaderBytecode);
    if (!h) {
        s->pShaderBytecode = nullptr;
        s->BytecodeLength = 0;
        return true;
    }
    const Blob* b = FindBlob(h, kBlobShader);
    if (!b || b->data.size() != s->BytecodeLength) return false;
    s->pShaderBytecode = b->data.data();
    return true;
}

// One recorded pipeline created on the device (through the original functions) and released. 1 = created, 0 = failed.
int ReplayOne(const Rec& r)
{
    auto* dev = static_cast<ID3D12Device*>(g_replayDevice);
    Made m;
    void* pso = nullptr;
    HRESULT hr = E_FAIL;
    if (r.kind == kKindGfx && r.pod.size() == sizeof(D3D12_GRAPHICS_PIPELINE_STATE_DESC)) {
        D3D12_GRAPHICS_PIPELINE_STATE_DESC d;
        memcpy(&d, r.pod.data(), sizeof d);
        ID3D12RootSignature* rs;
        if (!MakeRs(GetPtr(&d.pRootSignature), &rs)) return 0;
        d.pRootSignature = rs;
        if (!Shader(&d.VS) || !Shader(&d.PS) || !Shader(&d.DS) || !Shader(&d.HS) || !Shader(&d.GS)) return 0;
        const uint64_t il = GetPtr(&d.InputLayout.pInputElementDescs);
        d.InputLayout.pInputElementDescs = nullptr;
        if (il && !MakeLayout(il, d.InputLayout.NumElements, &m, &d.InputLayout.pInputElementDescs)) return 0;
        hr = reinterpret_cast<GfxFn>(g_rvt->orig[kSlotGfx])(dev, &d, __uuidof(ID3D12PipelineState), &pso);
    } else if (r.kind == kKindCompute && r.pod.size() == sizeof(D3D12_COMPUTE_PIPELINE_STATE_DESC)) {
        D3D12_COMPUTE_PIPELINE_STATE_DESC d;
        memcpy(&d, r.pod.data(), sizeof d);
        ID3D12RootSignature* rs;
        if (!MakeRs(GetPtr(&d.pRootSignature), &rs)) return 0;
        d.pRootSignature = rs;
        if (!Shader(&d.CS)) return 0;
        hr = reinterpret_cast<ComputeFn>(g_rvt->orig[kSlotCompute])(dev, &d, __uuidof(ID3D12PipelineState), &pso);
    } else if (r.kind == kKindStream && g_rvt->stream) {
        // rebuild the aligned stream from the packed [type][payload] list
        std::vector<uint64_t> buf;   // 8-byte aligned storage
        size_t used = 0;
        size_t at = 0;
        bool ok = true;
        std::vector<uint8_t> stream;
        while (ok && at + 4 <= r.pod.size()) {
            uint32_t type;
            memcpy(&type, &r.pod[at], 4);
            SubInfo si;
            if (!SubInfoOf(type, &si) || at + 4 + si.size > r.pod.size()) {
                ok = false;
                break;
            }
            const size_t start = (stream.size() + 7) & ~size_t(7);
            stream.resize(start + (si.align == 8 ? 8 : 4) + si.size, 0);
            memcpy(&stream[start], &type, 4);
            uint8_t* q = &stream[start + (si.align == 8 ? 8 : 4)];
            memcpy(q, &r.pod[at + 4], si.size);
            if (type == 0) {
                ID3D12RootSignature* rs;
                if (!MakeRs(GetPtr(q), &rs)) ok = false;
                memcpy(q, &rs, 8);
            } else if ((type >= 1 && type <= 6) || type == 24 || type == 25) {
                if (!Shader(reinterpret_cast<D3D12_SHADER_BYTECODE*>(q))) ok = false;
            } else if (type == 12) {
                const uint64_t h = GetPtr(q);
                uint32_t n;
                memcpy(&n, q + 8, 4);
                const D3D12_INPUT_ELEMENT_DESC* e = nullptr;
                if (h && !MakeLayout(h, n, &m, &e)) ok = false;
                memcpy(q, &e, 8);
            }
            at += 4 + si.size;
        }
        (void)buf;
        (void)used;
        if (!ok || at != r.pod.size()) return 0;
        stream.resize((stream.size() + 7) & ~size_t(7));
        std::vector<uint64_t> aligned((stream.size() + 7) / 8);
        memcpy(aligned.data(), stream.data(), stream.size());
        D3D12_PIPELINE_STATE_STREAM_DESC sd{stream.size(), aligned.data()};
        hr = reinterpret_cast<StreamFn>(g_rvt->orig[kSlotStream])(dev, &sd, __uuidof(ID3D12PipelineState), &pso);
    } else {
        return 0;
    }
    if (SUCCEEDED(hr) && pso) static_cast<IUnknown*>(pso)->Release();
    return SUCCEEDED(hr) ? 1 : 0;
}

struct OneCtx {
    const Rec* r;
    int res;
};
bool GuardedOne(OneCtx* c)
{
    __try {
        c->res = ReplayOne(*c->r);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        c->res = -1;
        return false;
    }
}

void ReplayFinish();

void Worker()
{
    t_inReplay = true;
    for (;;) {
        if (g_replayStop.load() || PlayStarted()) break;
        const size_t i = g_replayNext.fetch_add(1);
        if (i >= g_set->recs.size()) break;
        const uint64_t t0 = Qpc();
        OneCtx c{&g_set->recs[i], 0};
        try {
            GuardedOne(&c);
        } catch (...) {
            c.res = -1;
        }
        g_replayUs += UsSince(t0);
        if (c.res > 0) g_replayDone++;
        else g_replayFail++;
    }
    if (g_replayWorkers.fetch_sub(1) == 1) ReplayFinish();
}

void ReplayFinish()
{
    const uint64_t ms = (GetTickCount64() - g_replayT0);
    const bool stopped = g_replayNext.load() < g_replayTotal;
    Log("[psorec] replay %s: %llu of %zu recorded pipelines created (%llu failed or skipped) in %.1f s (%.1f s of creation time over the threads)",
        stopped ? "stopped (play began)" : "done", static_cast<unsigned long long>(g_replayDone.load()), g_replayTotal,
        static_cast<unsigned long long>(g_replayFail.load()), ms / 1000.0, g_replayUs.load() / 1e6);
    {
        std::lock_guard<std::mutex> lk(g_rsMu);
        for (auto& e : g_rsMade)
            if (e.second) e.second->Release();
        g_rsMade.clear();
    }
    if (g_replayDevice && g_replayOwnDevice) static_cast<IUnknown*>(g_replayDevice)->Release();
    g_replayDevice = nullptr;
    delete g_set;
    g_set = nullptr;
    g_replayBusy = false;
}

void StartReplay(ReplaySet* set, void* device, VT* vt, bool own, int threads)
{
    g_rvt = vt;
    if (!set || set->recs.empty() || !device) {
        delete set;
        if (device && own) static_cast<IUnknown*>(device)->Release();
        return;
    }
    g_set = set;
    g_replayDevice = device;
    g_replayOwnDevice = own;
    g_replayTotal = set->recs.size();
    g_replayNext = g_replayDone = g_replayFail = g_replayUs = 0;
    g_replayStop = false;
    g_replayT0 = GetTickCount64();
    if (threads < 1) threads = 1;
    if (threads > 8) threads = 8;
    g_replayWorkers = threads;
    g_replayBusy = true;
    Log("[psorec] replay: %zu recorded pipelines (%.1f MB of shaders) on %d threads%s", g_replayTotal,
        g_fileBytes / 1048576.0, threads, own ? " (on a device of our own: the game's was not shared)" : "");
    for (int i = 0; i < threads; ++i) std::thread(Worker).detach();
}

// ---- device ----

VT* Install(void* device)
{
    if (!device) return nullptr;
    void** vt = *static_cast<void***>(device);
    if (!vt) return nullptr;
    if (VT* have = FindVt(vt)) return have;
    const int n = g_nvt.load();
    if (n >= kMaxVt) return nullptr;
    VT& v = g_vts[n];
    memset(&v, 0, sizeof v);
    v.vt = vt;
    for (size_t s : {kSlotGfx, kSlotCompute, kSlotRootSig}) v.orig[s] = vt[s];
    ID3D12Device2* d2 = nullptr;
    if (SUCCEEDED(static_cast<IUnknown*>(device)->QueryInterface(__uuidof(ID3D12Device2), reinterpret_cast<void**>(&d2))) && d2) {
        v.orig[kSlotStream] = vt[kSlotStream];
        v.stream = true;
        d2->Release();
    }
    g_nvt.store(n + 1);   // published before the patch: a hook finds its entry at once
    bool ok = WritePointer(&vt[kSlotGfx], reinterpret_cast<void*>(&HookGfx)) &&
              WritePointer(&vt[kSlotCompute], reinterpret_cast<void*>(&HookCompute)) &&
              WritePointer(&vt[kSlotRootSig], reinterpret_cast<void*>(&HookRootSig));
    if (ok && v.stream) ok = WritePointer(&vt[kSlotStream], reinterpret_cast<void*>(&HookStream));
    if (!ok) {
        for (size_t s : {kSlotGfx, kSlotCompute, kSlotRootSig}) WritePointer(&vt[s], v.orig[s]);
        if (v.stream) WritePointer(&vt[kSlotStream], v.orig[kSlotStream]);
        return nullptr;   // the entry stays (harmless)
    }
    return &v;
}

void Unhook()
{
    const int n = g_nvt.load();
    for (int i = 0; i < n; ++i) {
        VT& v = g_vts[i];
        for (size_t s : {kSlotGfx, kSlotCompute, kSlotRootSig}) WritePointer(&v.vt[s], v.orig[s]);
        if (v.stream) WritePointer(&v.vt[kSlotStream], v.orig[kSlotStream]);
    }
    g_nvt.store(0);
}

// A device a D3D12CreateDevice call returned: its vtable is hooked at once, before the game can call it.
void OnCreated(void* dev, const char* how)
{
    if (!dev || !Install(dev)) return;
    g_createSeen++;
    void* none = nullptr;
    static_cast<IUnknown*>(dev)->AddRef();
    if (g_candidate.compare_exchange_strong(none, dev)) {
        g_candidateAt = GetTickCount64();
        g_how = how;
    } else {
        static_cast<IUnknown*>(dev)->Release();
    }
}

// A hooked call was made on this device: it is the game's (a probe device the game made and dropped never gets here).
void NoteGameDevice(void* self)
{
    if (g_gameDev.load() == self) return;
    if (g_gameDev.load()) return;   // the first device that calls; a second one does not take over
    static_cast<IUnknown*>(self)->AddRef();
    void* none = nullptr;
    if (!g_gameDev.compare_exchange_strong(none, self)) static_cast<IUnknown*>(self)->Release();
}

// ---- the game's D3D12CreateDevice: d3d12.dll's export table entry pointed at a stub, as soon as the DLL is mapped ----

HRESULT WINAPI HookCreateDevice(IUnknown* adapter, D3D_FEATURE_LEVEL fl, REFIID riid, void** pp)
{
    const HRESULT hr = reinterpret_cast<PFN_D3D12_CREATE_DEVICE>(g_realCreate)(adapter, fl, riid, pp);
    if (SUCCEEDED(hr) && pp && *pp && g_mode.load() > 0) OnCreated(*pp, "from the game's D3D12CreateDevice call");
    return hr;
}

uint8_t* AllocNear(uint8_t* base)
{
    const auto* nt = reinterpret_cast<const IMAGE_NT_HEADERS*>(base + reinterpret_cast<const IMAGE_DOS_HEADER*>(base)->e_lfanew);
    uintptr_t at = (reinterpret_cast<uintptr_t>(base) + nt->OptionalHeader.SizeOfImage + 0xFFFF) & ~uintptr_t(0xFFFF);
    for (int i = 0; i < 2000; ++i, at += 0x100000) {
        void* p = VirtualAlloc(reinterpret_cast<void*>(at), 0x1000, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        if (p) return static_cast<uint8_t*>(p);
    }
    return nullptr;
}

// Points the export `name` of the mapped module at a stub that jumps to target. Returns the real address (0: not possible);
// slot / rva give the table entry and its old value (to put back).
uint8_t* PatchExport(HMODULE module, const char* name, void* target, uint32_t** slotOut, uint32_t* oldRva, uint8_t** stubOut)
{
    auto* base = reinterpret_cast<uint8_t*>(module);
    __try {
        const auto* nt = reinterpret_cast<const IMAGE_NT_HEADERS*>(base + reinterpret_cast<const IMAGE_DOS_HEADER*>(base)->e_lfanew);
        const auto& dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT];
        if (!dir.VirtualAddress) return nullptr;
        const auto* ex = reinterpret_cast<const IMAGE_EXPORT_DIRECTORY*>(base + dir.VirtualAddress);
        const auto* names = reinterpret_cast<const uint32_t*>(base + ex->AddressOfNames);
        const auto* ords = reinterpret_cast<const uint16_t*>(base + ex->AddressOfNameOrdinals);
        auto* funcs = reinterpret_cast<uint32_t*>(base + ex->AddressOfFunctions);
        for (uint32_t i = 0; i < ex->NumberOfNames; ++i) {
            if (strcmp(reinterpret_cast<const char*>(base + names[i]), name) != 0) continue;
            uint32_t* slot = &funcs[ords[i]];
            const uint32_t rva = *slot;
            if (rva >= dir.VirtualAddress && rva < dir.VirtualAddress + dir.Size) return nullptr;   // a forwarder
            uint8_t* stub = AllocNear(base);
            if (!stub) return nullptr;
            const uintptr_t off = reinterpret_cast<uintptr_t>(stub) - reinterpret_cast<uintptr_t>(base);
            if (off > 0xFFFFFFF0u) return nullptr;
            const uint8_t jmp[6] = {0xFF, 0x25, 0, 0, 0, 0};
            memcpy(stub, jmp, 6);
            memcpy(stub + 6, &target, 8);
            DWORD old;
            if (!VirtualProtect(slot, 4, PAGE_READWRITE, &old)) return nullptr;
            *slot = static_cast<uint32_t>(off);
            VirtualProtect(slot, 4, old, &old);
            *slotOut = slot;
            *oldRva = rva;
            *stubOut = stub;
            return base + rva;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
    }
    return nullptr;
}

void RestoreExport(uint32_t* slot, uint32_t rva)
{
    DWORD old;
    if (slot && VirtualProtect(slot, 4, PAGE_READWRITE, &old)) {
        *slot = rva;
        VirtualProtect(slot, 4, old, &old);
    }
}

uint8_t* g_createStub = nullptr;
void PatchD3d12(HMODULE m)
{
    if (g_realCreate) return;
    uint8_t* real = PatchExport(m, "D3D12CreateDevice", reinterpret_cast<void*>(&HookCreateDevice), &g_eatSlot, &g_eatOrig, &g_createStub);
    if (!real) {
        Log("[psorec] d3d12.dll's D3D12CreateDevice export could not be redirected: the game's device will be found through its adapter instead");
        return;
    }
    g_realCreate = real;
    Log("[psorec] d3d12.dll's D3D12CreateDevice export redirected: the game's device is hooked as it is created");
}

struct UStr {
    USHORT len, max;
    PWSTR buf;
};
struct DllNote {
    ULONG flags;
    const UStr* full;
    const UStr* base;
    PVOID dllBase;
    ULONG size;
};
VOID CALLBACK DllLoaded(ULONG reason, const DllNote* d, PVOID)
{
    if (reason != 1 || !d || !d->base || !d->base->buf) return;
    if (d->base->len == 18 && _wcsnicmp(d->base->buf, L"d3d12.dll", 9) == 0) PatchD3d12(static_cast<HMODULE>(d->dllBase));
}

// The game's device as memory_monitor.cpp reaches it: D3D12CreateDevice on the game's adapter.
void* FindDevice(bool* own)
{
    HMODULE d3d12 = GetModuleHandleW(L"d3d12.dll");
    HMODULE dxgi = GetModuleHandleW(L"dxgi.dll");
    if (!d3d12 || !dxgi || !GetModuleHandleW(L"D3D12Core.dll")) return nullptr;
    auto create = reinterpret_cast<PFN_D3D12_CREATE_DEVICE>(GetProcAddress(d3d12, "D3D12CreateDevice"));
    auto mkFactory = reinterpret_cast<HRESULT(WINAPI*)(REFIID, void**)>(GetProcAddress(dxgi, "CreateDXGIFactory1"));
    IDXGIFactory1* factory = nullptr;
    if (!create || !mkFactory || FAILED(mkFactory(IID_PPV_ARGS(&factory))) || !factory) return nullptr;
    IDXGIAdapter1* best = nullptr;
    SIZE_T bestMem = 0;
    IDXGIAdapter1* a = nullptr;
    for (UINT i = 0; factory->EnumAdapters1(i, &a) != DXGI_ERROR_NOT_FOUND; ++i) {
        DXGI_ADAPTER_DESC1 desc{};
        if (SUCCEEDED(a->GetDesc1(&desc)) && !(desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE) && (!best || desc.DedicatedVideoMemory > bestMem)) {
            if (best) best->Release();
            best = a;
            bestMem = desc.DedicatedVideoMemory;
        } else {
            a->Release();
        }
    }
    factory->Release();
    if (!best) return nullptr;
    ID3D12Device* dev = nullptr;
    void* result = nullptr;
    if (SUCCEEDED(create(best, D3D_FEATURE_LEVEL_11_0, IID_PPV_ARGS(&dev))) && dev) {
        const ULONG refs = dev->AddRef();
        dev->Release();
        *own = refs <= 2;   // only our reference: the runtime made a new device
        result = dev;
    }
    best->Release();
    return result;
}

void PrintStats(bool force)
{
    const uint64_t n = g_iNew.exchange(0), calls = g_iCalls.exchange(0), us = g_iUs.exchange(0), mx = g_iMaxUs.exchange(0),
                   slow = g_iSlow.exchange(0);
    Log("[psorec] in play: %llu new PSOs, total %.1f ms, max %.1f ms (last minute: %llu creations of all, %.1f ms in all, %llu of "
        "20 ms or more; since play began: %llu creations, %.1f s, %llu already replayed; record: %llu added, %llu not recordable, %llu "
        "root signatures seen, %llu pipelines with an unknown one%s)%s",
        static_cast<unsigned long long>(n), us / 1000.0, mx / 1000.0, static_cast<unsigned long long>(calls), us / 1000.0,
        static_cast<unsigned long long>(slow), static_cast<unsigned long long>(g_calls.load()), g_totalUs.load() / 1e6,
        static_cast<unsigned long long>(g_replayedSeen.load()), static_cast<unsigned long long>(g_recorded.load()),
        static_cast<unsigned long long>(g_skipped.load()), static_cast<unsigned long long>(g_rsKnown.load()),
        static_cast<unsigned long long>(g_rsUnknown.load()), g_mode.load() == 2 ? "; measure only" : "", force ? " [end]" : "");
}

void ApplyConfig(int mode, int maxMB, int minMs)
{
    g_maxBytes = static_cast<uint64_t>(maxMB < 1 ? 1 : maxMB > 4096 ? 4096 : maxMB) << 20;
    g_minUs = static_cast<uint32_t>((minMs < 0 ? 0 : minMs) * 1000);
    g_mode = mode < 0 ? 0 : mode > 2 ? 2 : mode;
}

}  // namespace

bool PsoReplayBusy() { return g_replayBusy.load(); }

// Start-up (ahead of the game's device): the export redirect, so the game's own D3D12CreateDevice result is hooked.
bool PsoRecordInstallEarly(int mode)
{
    if (mode <= 0) return false;
    g_mode = mode > 2 ? 2 : mode;
    if (HMODULE m = GetModuleHandleW(L"d3d12.dll")) PatchD3d12(m);
    if (g_realCreate) return true;
    HMODULE nt = GetModuleHandleW(L"ntdll.dll");
    using RegFn = LONG(NTAPI*)(ULONG, void*, PVOID, PVOID*);
    auto reg = nt ? reinterpret_cast<RegFn>(GetProcAddress(nt, "LdrRegisterDllNotification")) : nullptr;
    PVOID cookie = nullptr;
    if (!reg || reg(0, reinterpret_cast<void*>(&DllLoaded), nullptr, &cookie) != 0) {
        Log("[psorec] no DLL load notification: the game's device will be found through its adapter instead");
        return false;
    }
    Log("[psorec] waiting for d3d12.dll to be mapped to redirect its D3D12CreateDevice");
    return true;
}

void PsoRecordTick(int mode, int maxMB, int minMs, int threads, const wchar_t* dir)
{
    ApplyConfig(mode, maxMB, minMs);
    if (mode <= 0) {
        if (g_replayBusy.load()) g_replayStop = true;
        return;
    }
    const ULONGLONG now = GetTickCount64();
    if (!g_firstTick) g_firstTick = now;
    if (!g_started) {
        // fallback: no D3D12CreateDevice call was seen (redirect not possible, or the game created its device another way)
        if (!g_candidate.load() && !g_gameDev.load() && now - g_firstTick > 20000 && now >= g_nextTry && GetModuleHandleW(L"D3D12Core.dll")) {
            g_nextTry = now + 5000;
            bool own = false;
            void* dev = FindDevice(&own);
            if (dev) {
                if (!g_fallbackTried) Log("[psorec] no D3D12CreateDevice call of the game was seen after 20 s: using the device found through its adapter (%s)",
                                          own ? "a device of our own: may not be the game's" : "the game's");
                g_fallbackTried = true;
                OnCreated(dev, "found through the adapter (fallback)");
                static_cast<IUnknown*>(dev)->Release();
            }
        }
        void* dev = g_gameDev.load();
        bool confirmed = dev != nullptr;
        if (!dev) {
            dev = g_candidate.load();
            if (!dev || now - g_candidateAt < 30000) return;   // wait for a hooked call to name the game's device
        }
        VT* vt = FindVt(*static_cast<void***>(dev));
        if (!vt) return;
        g_started = true;
        g_stamp = ExeStamp();
        g_path = std::wstring(dir) + L"\\OblivionPerfFix-psorecord.bin";
        ReplaySet* set = nullptr;
        if (mode == 1) {
            std::lock_guard<std::mutex> lk(g_mu);
            set = LoadRecord(true);
        }
        g_lastStat = g_lastFlush = now;
        Log("[psorec] %s: the game's device %s (%s), pipeline creation hooked (graphics, compute%s, root signatures; %d vtable%s), %zu "
            "pipelines in the record (%.1f MB; limit %.0f MB)%s; PsoPrecompileFast's \"in play\" starts the counting",
            mode == 1 ? "record and replay" : "measure only", confirmed ? "confirmed by its first hooked call" : "NOT confirmed (no hooked call seen in 30 s)",
            g_how, vt->stream ? ", stream" : "", g_nvt.load(), g_nvt.load() == 1 ? "" : "s", g_loadedPso.size(), g_fileBytes / 1048576.0,
            g_maxBytes.load() / 1048576.0, mode == 1 ? "" : " (nothing written)");
        if (mode == 1) StartReplay(set, dev, vt, false, threads);
        return;
    }
    if (PlayStarted()) {
        if (!g_playAt) g_playAt = now;
        if (!g_warned && now - g_playAt > 30000 && g_calls.load() == 0 && g_hookSeen.load() == 0) {
            g_warned = true;
            Log("[psorec] WARNING: hook sees no game PSO creations (%llu D3D12CreateDevice calls seen, %d vtable(s) hooked, none of them called in 30 s of play): "
                "nothing is counted or recorded; looking for the device through the adapter",
                static_cast<unsigned long long>(g_createSeen.load()), g_nvt.load());
            bool own = false;
            if (void* dev = FindDevice(&own)) {
                OnCreated(dev, "found through the adapter (after the warning)");
                static_cast<IUnknown*>(dev)->Release();
            }
        }
        if (now - g_lastStat >= 60000) {
            g_lastStat = now;
            PrintStats(false);
        }
        if (mode == 1 && now - g_lastFlush >= 10000) {
            g_lastFlush = now;
            Flush();
        }
    } else {
        g_lastStat = now;
    }
}

void LogPsoRecordStats() {}

void PsoRecordTestSetPlay(int v) { g_forcePlay = v; }
bool PsoRecordTestAttach(void* device, const wchar_t* path, int mode, int maxMB, int minMs, int threads)
{
    ApplyConfig(mode, maxMB, minMs);
    g_stamp = 0x5EED0001;
    g_path = path;
    VT* vt = Install(device);
    if (!vt) return false;
    ReplaySet* set = nullptr;
    if (mode == 1) {
        std::lock_guard<std::mutex> lk(g_mu);
        set = LoadRecord(true);
    }
    if (mode == 1) StartReplay(set, device, vt, false, threads);
    return true;
}
// The game's creation path with a fake D3D12CreateDevice: the wrapper hooks what it returns.
long PsoRecordTestCreateDevice(void* fakeReal, void** out)
{
    g_realCreate = fakeReal;
    return HookCreateDevice(nullptr, D3D_FEATURE_LEVEL_11_0, __uuidof(ID3D12Device), out);
}
void* PsoRecordTestGameDevice() { return g_gameDev.load(); }
void* PsoRecordTestCandidate() { return g_candidate.load(); }
// The export redirect on a real mapped module: returns the stub GetProcAddress now hands out (0: not possible); restore puts it back.
void* PsoRecordTestPatchExport(HMODULE m, const char* name, void* target, void** restoreSlot, uint32_t* restoreRva)
{
    uint32_t* slot = nullptr;
    uint8_t* stub = nullptr;
    if (!PatchExport(m, name, target, &slot, restoreRva, &stub)) return nullptr;
    *restoreSlot = slot;
    return stub;
}
void PsoRecordTestRestoreExport(void* slot, uint32_t rva) { RestoreExport(static_cast<uint32_t*>(slot), rva); }
void PsoRecordTestFlush() { Flush(); }
bool PsoRecordTestWait(uint32_t ms)
{
    const ULONGLONG t0 = GetTickCount64();
    while (g_replayBusy.load() && GetTickCount64() - t0 < ms) Sleep(5);
    return !g_replayBusy.load();
}
void PsoRecordTestReset()
{
    Unhook();
    g_candidate = nullptr;
    g_gameDev = nullptr;
    g_realCreate = nullptr;
    g_hookSeen = g_createSeen = 0;
    g_rvt = nullptr;
    std::lock_guard<std::mutex> lk(g_mu);
    g_rsOf.clear();
    g_rsBlobs.clear();
    g_pendBlobs.clear();
    g_pendRecs.clear();
    g_savedBlobs.clear();
    g_knownPso.clear();
    g_loadedPso.clear();
    g_fileBytes = g_pendBytes = 0;
    g_full = false;
    g_fileReady = false;
    g_calls = g_newN = g_totalUs = g_maxUs = g_recorded = g_skipped = g_rsKnown = g_rsUnknown = g_replayedSeen = g_replayedUs = 0;
    g_iCalls = g_iNew = g_iUs = g_iMaxUs = g_iSlow = 0;
    g_forcePlay = -1;
}
PsoRecordCounts PsoRecordTestCounts()
{
    PsoRecordCounts c{};
    c.calls = g_calls;
    c.newPsos = g_newN;
    c.recorded = g_recorded;
    c.skipped = g_skipped;
    c.rsKnown = g_rsKnown;
    c.loaded = g_loadedPso.size();
    c.replayed = g_replayDone;
    c.replayFailed = g_replayFail;
    c.fileBytes = g_fileBytes;
    c.full = g_full;
    c.replayedSeen = g_replayedSeen;
    return c;
}

}  // namespace opf
