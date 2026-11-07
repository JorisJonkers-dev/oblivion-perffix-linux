// PsoRecordReplay self-test, included by selftest.cpp: the vtable hooks on a FAKE device (a vtable of our own, no D3D12 runtime),
// synthetic descriptions (graphics, compute, stream) recorded, written, read back and replayed onto the fake; dedup,
// the size bound, a torn file tail, measure-only mode.
#pragma once

#include <string>
#include <vector>

namespace psr {

struct FakeObj {
    void** vt;
};
inline HRESULT STDMETHODCALLTYPE ObjQI(void*, REFIID, void**) { return E_NOINTERFACE; }
inline ULONG STDMETHODCALLTYPE ObjAddRef(void*) { return 2; }
inline ULONG STDMETHODCALLTYPE ObjRelease(void*) { return 1; }
inline void* g_objVt[3] = {reinterpret_cast<void*>(&ObjQI), reinterpret_cast<void*>(&ObjAddRef), reinterpret_cast<void*>(&ObjRelease)};
inline FakeObj g_objs[64];
inline int g_nObjs = 0;
inline FakeObj* NewObj()
{
    FakeObj* o = &g_objs[g_nObjs++ % 64];
    o->vt = g_objVt;
    return o;
}

struct Seen {
    int what;                      // 0 gfx, 1 compute, 2 stream
    std::vector<uint8_t> vs, ps, cs;
    std::vector<std::string> names;
    DXGI_FORMAT rtv0 = DXGI_FORMAT_UNKNOWN;
    UINT blendRt0Src = 0;
    std::vector<uint8_t> rsBlob;
    uint32_t cachedLen = 0;
};
inline std::vector<Seen> g_seen;
inline std::vector<std::pair<FakeObj*, std::vector<uint8_t>>> g_rsMade;
inline bool g_fail = false;

inline std::vector<uint8_t> Bytes(const D3D12_SHADER_BYTECODE& b)
{
    return b.pShaderBytecode ? std::vector<uint8_t>(static_cast<const uint8_t*>(b.pShaderBytecode),
                                                    static_cast<const uint8_t*>(b.pShaderBytecode) + b.BytecodeLength)
                             : std::vector<uint8_t>();
}
inline std::vector<uint8_t> RsBytes(const void* rs)
{
    for (auto& r : g_rsMade)
        if (r.first == rs) return r.second;
    return {};
}

inline HRESULT STDMETHODCALLTYPE DevQI(void* self, REFIID iid, void** out)
{
    if (IsEqualGUID(iid, __uuidof(ID3D12Device2))) {
        *out = self;
        return S_OK;
    }
    return E_NOINTERFACE;
}
inline HRESULT STDMETHODCALLTYPE DevGfx(void*, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* d, REFIID, void** pp)
{
    if (g_fail) return E_FAIL;
    Seen s;
    s.what = 0;
    s.vs = Bytes(d->VS);
    s.ps = Bytes(d->PS);
    for (UINT i = 0; i < d->InputLayout.NumElements; ++i) s.names.push_back(d->InputLayout.pInputElementDescs[i].SemanticName);
    s.rtv0 = d->RTVFormats[0];
    s.blendRt0Src = d->BlendState.RenderTarget[0].SrcBlend;
    s.rsBlob = RsBytes(d->pRootSignature);
    s.cachedLen = static_cast<uint32_t>(d->CachedPSO.CachedBlobSizeInBytes);
    g_seen.push_back(s);
    *pp = NewObj();
    return S_OK;
}
inline HRESULT STDMETHODCALLTYPE DevCompute(void*, const D3D12_COMPUTE_PIPELINE_STATE_DESC* d, REFIID, void** pp)
{
    if (g_fail) return E_FAIL;
    Seen s;
    s.what = 1;
    s.cs = Bytes(d->CS);
    s.rsBlob = RsBytes(d->pRootSignature);
    g_seen.push_back(s);
    *pp = NewObj();
    return S_OK;
}
inline HRESULT STDMETHODCALLTYPE DevStream(void*, const D3D12_PIPELINE_STATE_STREAM_DESC* d, REFIID, void** pp)
{
    if (g_fail) return E_FAIL;
    Seen s;
    s.what = 2;
    // walk the aligned stream the way a driver would: [type][payload] at 8-byte steps
    const auto* b = static_cast<const uint8_t*>(d->pPipelineStateSubobjectStream);
    size_t at = 0;
    while (at < d->SizeInBytes) {
        const int type = *reinterpret_cast<const int*>(b + at);
        size_t size = 0, off = 4;
        switch (type) {
            case 0: off = 8; size = 8; s.rsBlob = RsBytes(*reinterpret_cast<void* const*>(b + at + off)); break;
            case 1: off = 8; size = 16; s.vs = Bytes(*reinterpret_cast<const D3D12_SHADER_BYTECODE*>(b + at + off)); break;
            case 2: off = 8; size = 16; s.ps = Bytes(*reinterpret_cast<const D3D12_SHADER_BYTECODE*>(b + at + off)); break;
            case 8: size = sizeof(D3D12_BLEND_DESC); s.blendRt0Src = reinterpret_cast<const D3D12_BLEND_DESC*>(b + at + off)->RenderTarget[0].SrcBlend; break;
            case 9: size = 4; break;
            case 12: {
                off = 8; size = 16;
                const auto* il = reinterpret_cast<const D3D12_INPUT_LAYOUT_DESC*>(b + at + off);
                for (UINT i = 0; i < il->NumElements; ++i) s.names.push_back(il->pInputElementDescs[i].SemanticName);
                break;
            }
            case 15: size = 36; s.rtv0 = reinterpret_cast<const D3D12_RT_FORMAT_ARRAY*>(b + at + off)->RTFormats[0]; break;
            case 19: off = 8; size = 16; s.cachedLen = 1; break;
            default: g_fail = true; return E_FAIL;
        }
        at = (at + off + size + 7) & ~size_t(7);
    }
    g_seen.push_back(s);
    *pp = NewObj();
    return S_OK;
}
inline HRESULT STDMETHODCALLTYPE DevRs(void*, UINT, const void* blob, SIZE_T len, REFIID, void** pp)
{
    FakeObj* o = NewObj();
    g_rsMade.push_back({o, std::vector<uint8_t>(static_cast<const uint8_t*>(blob), static_cast<const uint8_t*>(blob) + len)});
    *pp = o;
    return S_OK;
}

struct alignas(8) SRs { int type = 0; void* p = nullptr; };
struct alignas(8) SVs { int type = 1; D3D12_SHADER_BYTECODE b{}; };
struct alignas(8) SPs { int type = 2; D3D12_SHADER_BYTECODE b{}; };
struct alignas(8) SBl { int type = 8; D3D12_BLEND_DESC b{}; };
struct alignas(8) SMask { int type = 9; UINT m = 0xFFFFFFFF; };
struct alignas(8) SIl { int type = 12; D3D12_INPUT_LAYOUT_DESC il{}; };
struct alignas(8) SFmt { int type = 15; D3D12_RT_FORMAT_ARRAY f{}; };
struct alignas(8) SCached { int type = 19; D3D12_CACHED_PIPELINE_STATE c{}; };
struct Stream {
    SRs rs; SVs vs; SPs ps; SBl bl; SMask mask; SIl il; SFmt fmt; SCached cached;
};

inline std::vector<uint8_t> Fill(size_t n, uint8_t seed)
{
    std::vector<uint8_t> v(n);
    for (size_t i = 0; i < n; ++i) v[i] = static_cast<uint8_t>(seed * 31 + i * 7 + (i >> 8));
    return v;
}
inline D3D12_SHADER_BYTECODE Bc(const std::vector<uint8_t>& v) { return {v.data(), v.size()}; }

struct Dev {
    void** vt;
};
inline void* g_devVt[64];
inline Dev g_dev{g_devVt};
inline void* g_devVtOrig[64];

inline void InitDev()
{
    for (int i = 0; i < 64; ++i) g_devVt[i] = nullptr;
    g_devVt[0] = reinterpret_cast<void*>(&DevQI);
    g_devVt[1] = reinterpret_cast<void*>(&ObjAddRef);
    g_devVt[2] = reinterpret_cast<void*>(&ObjRelease);
    g_devVt[10] = reinterpret_cast<void*>(&DevGfx);
    g_devVt[11] = reinterpret_cast<void*>(&DevCompute);
    g_devVt[16] = reinterpret_cast<void*>(&DevRs);
    g_devVt[47] = reinterpret_cast<void*>(&DevStream);
    memcpy(g_devVtOrig, g_devVt, sizeof g_devVt);
    g_seen.clear();
    g_rsMade.clear();
    g_fail = false;
}

using GfxFn = HRESULT(STDMETHODCALLTYPE*)(void*, const D3D12_GRAPHICS_PIPELINE_STATE_DESC*, REFIID, void**);
using CompFn = HRESULT(STDMETHODCALLTYPE*)(void*, const D3D12_COMPUTE_PIPELINE_STATE_DESC*, REFIID, void**);
using StrFn = HRESULT(STDMETHODCALLTYPE*)(void*, const D3D12_PIPELINE_STATE_STREAM_DESC*, REFIID, void**);
using RsFn = HRESULT(STDMETHODCALLTYPE*)(void*, UINT, const void*, SIZE_T, REFIID, void**);

inline Dev g_dev2{nullptr};
inline void* g_dev2Vt[64];
inline int g_dev2Gfx = 0;
inline HRESULT STDMETHODCALLTYPE Dev2Gfx(void* s, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* d, REFIID r, void** pp)
{
    ++g_dev2Gfx;
    return DevGfx(s, d, r, pp);
}
inline HRESULT WINAPI FakeCreate1(IUnknown*, D3D_FEATURE_LEVEL, REFIID, void** pp)
{
    *pp = &g_dev;
    return S_OK;
}
inline HRESULT WINAPI FakeCreate2(IUnknown*, D3D_FEATURE_LEVEL, REFIID, void** pp)
{
    *pp = &g_dev2;
    return S_OK;
}
inline void Dummy() {}

inline void Run()
{
    using namespace opf;
    wchar_t tmp[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    const std::wstring path = std::wstring(tmp) + L"opf-selftest-psorecord.bin";
    DeleteFileW(path.c_str());
    InitDev();
    PsoRecordTestReset();
    Check(PsoRecordTestAttach(&g_dev, path.c_str(), 1, 64, 0, 2), "psorec: hooks installed on a fake device (graphics, compute, root signature, stream slots)");
    Check(g_devVt[10] != reinterpret_cast<void*>(&DevGfx) && g_devVt[47] != reinterpret_cast<void*>(&DevStream) &&
              g_devVt[16] != reinterpret_cast<void*>(&DevRs) && g_devVt[11] != reinterpret_cast<void*>(&DevCompute),
          "psorec: the four vtable slots point at the hooks");
    auto gfx = reinterpret_cast<GfxFn>(g_devVt[10]);
    const auto comp = reinterpret_cast<CompFn>(g_devVt[11]);
    const auto str = reinterpret_cast<StrFn>(g_devVt[47]);
    const auto rsf = reinterpret_cast<RsFn>(g_devVt[16]);

    const auto rsA = Fill(60, 1), rsB = Fill(90, 2), vs1 = Fill(300, 3), ps1 = Fill(500, 4), cs1 = Fill(700, 5), vs2 = Fill(333, 6);
    void *rA = nullptr, *rB = nullptr, *unknownRs = NewObj(), *o = nullptr;
    rsf(&g_dev, 0, rsA.data(), rsA.size(), __uuidof(ID3D12RootSignature), &rA);
    rsf(&g_dev, 0, rsB.data(), rsB.size(), __uuidof(ID3D12RootSignature), &rB);
    D3D12_INPUT_ELEMENT_DESC el[2] = {{"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0},
                                      {"TEXCOORD", 1, DXGI_FORMAT_R32G32_FLOAT, 1, 12, D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA, 1}};
    D3D12_GRAPHICS_PIPELINE_STATE_DESC g;
    memset(&g, 0xCD, sizeof g);   // garbage in the padding: the dedup hash must not depend on it
    g.pRootSignature = static_cast<ID3D12RootSignature*>(rA);
    g.VS = Bc(vs1);
    g.PS = Bc(ps1);
    g.DS = {};
    g.HS = {};
    g.GS = {};
    g.StreamOutput = {};
    g.BlendState = {};
    g.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_SRC_ALPHA;
    g.SampleMask = 0xFFFFFFFF;
    g.RasterizerState = {};
    g.DepthStencilState = {};
    g.InputLayout = {el, 2};
    g.IBStripCutValue = D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_DISABLED;
    g.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
    g.NumRenderTargets = 1;
    for (auto& f : g.RTVFormats) f = DXGI_FORMAT_UNKNOWN;
    g.RTVFormats[0] = DXGI_FORMAT_R16G16B16A16_FLOAT;
    g.DSVFormat = DXGI_FORMAT_D32_FLOAT;
    g.SampleDesc = {1, 0};
    g.NodeMask = 0;
    g.CachedPSO = {};
    g.Flags = D3D12_PIPELINE_STATE_FLAG_NONE;

    PsoRecordTestSetPlay(0);
    gfx(&g_dev, &g, __uuidof(ID3D12PipelineState), &o);   // before play: not counted
    PsoRecordCounts c = PsoRecordTestCounts();
    Check(c.calls == 0 && c.recorded == 0, "psorec: creations before play are not counted or recorded");
    PsoRecordTestSetPlay(1);
    gfx(&g_dev, &g, __uuidof(ID3D12PipelineState), &o);   // 1: new
    gfx(&g_dev, &g, __uuidof(ID3D12PipelineState), &o);   // duplicate
    auto g2 = g;
    g2.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
    g2.VS = Bc(vs2);   // 2: other VS and blend, same PS (blob shared)
    g2.pRootSignature = static_cast<ID3D12RootSignature*>(rB);
    gfx(&g_dev, &g2, __uuidof(ID3D12PipelineState), &o);
    D3D12_COMPUTE_PIPELINE_STATE_DESC cd{};
    cd.pRootSignature = static_cast<ID3D12RootSignature*>(rB);
    cd.CS = Bc(cs1);
    comp(&g_dev, &cd, __uuidof(ID3D12PipelineState), &o);   // 3
    Stream s;
    s.rs.p = rA;
    s.vs.b = Bc(vs1);
    s.ps.b = Bc(ps1);
    s.bl.b.RenderTarget[0].SrcBlend = D3D12_BLEND_DEST_ALPHA;
    s.il.il = {el, 2};
    s.fmt.f.NumRenderTargets = 1;
    s.fmt.f.RTFormats[0] = DXGI_FORMAT_R8G8B8A8_UNORM;
    s.cached.c = {nullptr, 0};
    D3D12_PIPELINE_STATE_STREAM_DESC sd{sizeof s, &s};
    str(&g_dev, &sd, __uuidof(ID3D12PipelineState), &o);   // 4
    auto g3 = g;
    g3.pRootSignature = static_cast<ID3D12RootSignature*>(unknownRs);
    gfx(&g_dev, &g3, __uuidof(ID3D12PipelineState), &o);   // root signature never seen: counted, not recordable
    g_fail = true;
    gfx(&g_dev, &g, __uuidof(ID3D12PipelineState), &o);    // failing creation: not counted
    g_fail = false;
    c = PsoRecordTestCounts();
    Check(c.calls == 6 && c.recorded == 4 && c.skipped == 1, "psorec: 6 creations in play counted, 4 distinct recorded (duplicate deduped), 1 unrecordable");
    Check(c.rsKnown == 2, "psorec: both root signatures seen");
    PsoRecordTestFlush();
    c = PsoRecordTestCounts();
    const size_t written = c.fileBytes;
    Check(written > vs1.size() + ps1.size() + cs1.size() + vs2.size() + rsA.size() && written < 6000, "psorec: file written (shared blobs stored once)");

    // restart: replay onto a fresh fake
    PsoRecordTestReset();
    Check(g_devVt[10] == reinterpret_cast<void*>(&DevGfx) && g_devVt[47] == reinterpret_cast<void*>(&DevStream), "psorec: unhook puts the original slots back");
    InitDev();
    Check(PsoRecordTestAttach(&g_dev, path.c_str(), 1, 64, 0, 2) && PsoRecordTestWait(5000), "psorec: replay of the record finishes");
    c = PsoRecordTestCounts();
    Check(c.loaded == 4 && c.replayed == 4 && c.replayFailed == 0 && g_seen.size() == 4,
          "psorec: 4 pipelines loaded, 4 created on the device, none failed");
    bool g1ok = false, g2ok = false, cok = false, sok = false;
    for (auto& v : g_seen) {
        if (v.what == 0 && v.vs == vs1) g1ok = v.ps == ps1 && v.rsBlob == rsA && v.names == std::vector<std::string>{"POSITION", "TEXCOORD"} &&
                                                 v.rtv0 == DXGI_FORMAT_R16G16B16A16_FLOAT && v.blendRt0Src == D3D12_BLEND_SRC_ALPHA && v.cachedLen == 0;
        if (v.what == 0 && v.vs == vs2) g2ok = v.ps == ps1 && v.rsBlob == rsB && v.blendRt0Src == D3D12_BLEND_ONE;
        if (v.what == 1) cok = v.cs == cs1 && v.rsBlob == rsB;
        if (v.what == 2) sok = v.vs == vs1 && v.ps == ps1 && v.rsBlob == rsA && v.names.size() == 2 && v.rtv0 == DXGI_FORMAT_R8G8B8A8_UNORM &&
                               v.blendRt0Src == D3D12_BLEND_DEST_ALPHA && v.cachedLen == 0;
    }
    Check(g1ok, "psorec: round trip graphics: shaders, root signature, input layout, formats, blend identical");
    Check(g2ok, "psorec: round trip graphics 2 (shared pixel shader blob, other root signature)");
    Check(cok, "psorec: round trip compute");
    Check(sok, "psorec: round trip stream (aligned stream rebuilt, cached PSO dropped)");
    PsoRecordTestSetPlay(1);
    void* o2 = nullptr;
    void* rA2 = nullptr;   // the game creates its root signature again in the new session
    reinterpret_cast<RsFn>(g_devVt[16])(&g_dev, 0, rsA.data(), rsA.size(), __uuidof(ID3D12RootSignature), &rA2);
    g.pRootSignature = static_cast<ID3D12RootSignature*>(rA2);
    reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &g, __uuidof(ID3D12PipelineState), &o2);
    c = PsoRecordTestCounts();
    Check(c.recorded == 0 && c.newPsos == 0 && c.replayedSeen == 1, "psorec: the same pipeline in play is not new and not recorded again");

    // torn tail
    PsoRecordTestReset();
    InitDev();
    {
        FILE* f = nullptr;
        _wfopen_s(&f, path.c_str(), L"ab");
        const char junk[] = "P\x40\x00\x00\x00 torn write";
        fwrite(junk, 1, sizeof junk, f);
        fclose(f);
    }
    PsoRecordTestAttach(&g_dev, path.c_str(), 1, 64, 0, 1);
    PsoRecordTestWait(5000);
    c = PsoRecordTestCounts();
    Check(c.loaded == 4 && c.fileBytes == written, "psorec: a torn tail is cut off at the next start, the 4 records survive");

    // size bound: 1 MB, shaders of 400 KB
    PsoRecordTestReset();
    InitDev();
    DeleteFileW(path.c_str());
    PsoRecordTestAttach(&g_dev, path.c_str(), 1, 1, 0, 1);
    PsoRecordTestSetPlay(1);
    std::vector<std::vector<uint8_t>> big;
    uint64_t xs = 1234567ull;
    for (int i = 0; i < 5; ++i) {
        big.emplace_back(400 * 1024);
        for (auto& b : big.back()) {
            xs ^= xs << 13; xs ^= xs >> 7; xs ^= xs << 17;
            b = static_cast<uint8_t>(xs);
        }
    }
    for (int i = 0; i < 5; ++i) {
        auto gg = g;
        gg.pRootSignature = nullptr;
        gg.VS = Bc(big[i]);
        gfx = reinterpret_cast<GfxFn>(g_devVt[10]);
        gfx(&g_dev, &gg, __uuidof(ID3D12PipelineState), &o);
    }
    PsoRecordTestFlush();
    c = PsoRecordTestCounts();
    Check(c.full && c.recorded >= 1 && c.recorded <= 2 && c.fileBytes <= (1u << 20), "psorec: PsoRecordMaxMB bounds the file (full flag set, size under the limit)");

    // compression and the cap: a compressible shader is stored small and comes back identical; a record refused at the cap leaves the
    // blobs of the records before it alone (they were once dropped with it: those pipelines failed to replay)
    PsoRecordTestReset();
    InitDev();
    DeleteFileW(path.c_str());
    PsoRecordTestAttach(&g_dev, path.c_str(), 1, 1, 0, 1);
    PsoRecordTestSetPlay(1);
    {
        std::vector<uint8_t> rep(200 * 1024);
        for (size_t i = 0; i < rep.size(); ++i) rep[i] = static_cast<uint8_t>("DXIL shader bytecode pattern 0123456789"[i % 40]);
        std::vector<std::vector<uint8_t>> rnd(4, std::vector<uint8_t>(400 * 1024));
        uint64_t x = 88172645463325252ull;
        for (auto& v : rnd)
            for (auto& b : v) {
                x ^= x << 13; x ^= x >> 7; x ^= x << 17;
                b = static_cast<uint8_t>(x);
            }
        auto gg = g;
        gg.pRootSignature = nullptr;
        gg.VS = Bc(rep);
        reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &gg, __uuidof(ID3D12PipelineState), &o);
        PsoRecordTestFlush();
        c = PsoRecordTestCounts();
        Check(c.recorded == 1 && c.fileBytes < 30000, "psorec: a compressible 200 KB shader is stored in well under 30 KB (LZ4-style codec)");
        gg.VS = Bc(rnd[0]);
        reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &gg, __uuidof(ID3D12PipelineState), &o);   // pending when the cap is hit
        gg.VS = Bc(rnd[1]);
        reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &gg, __uuidof(ID3D12PipelineState), &o);
        gg.VS = Bc(rnd[2]);
        reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &gg, __uuidof(ID3D12PipelineState), &o);   // refused: over 1 MB
        PsoRecordTestFlush();
        c = PsoRecordTestCounts();
        Check(c.full && c.recorded == 3 && c.fileBytes <= (1u << 20), "psorec: the cap refuses the third incompressible shader, file under the limit");
        const uint64_t rec = c.recorded;
        PsoRecordTestReset();
        InitDev();
        PsoRecordTestAttach(&g_dev, path.c_str(), 1, 1, 0, 2);
        PsoRecordTestWait(5000);
        c = PsoRecordTestCounts();
        bool sameRep = false, sameRnd = false;
        for (auto& v : g_seen) {
            if (v.vs == rep) sameRep = true;
            if (v.vs == rnd[0]) sameRnd = true;
        }
        Check(c.replayed == rec && c.replayFailed == 0 && sameRep && sameRnd, "psorec: all recorded pipelines replay after a refused one (no lost blobs); compressed and raw blobs come back identical");
    }

    // measure only: counts, writes nothing
    PsoRecordTestReset();
    InitDev();
    DeleteFileW(path.c_str());
    PsoRecordTestAttach(&g_dev, path.c_str(), 2, 64, 0, 1);
    PsoRecordTestSetPlay(1);
    reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &g, __uuidof(ID3D12PipelineState), &o);
    c = PsoRecordTestCounts();
    Check(c.calls == 1 && c.newPsos == 1 && c.recorded == 0 && GetFileAttributesW(path.c_str()) == INVALID_FILE_ATTRIBUTES,
          "psorec: measure-only counts the creation and writes no file");
    PsoRecordTestReset();
    DeleteFileW(path.c_str());

    // the game's creation path: D3D12CreateDevice (fake) returns two devices with DIFFERENT vtables; each is hooked with its own originals
    InitDev();
    g_dev2.vt = g_dev2Vt;
    memcpy(g_dev2Vt, g_devVt, sizeof g_devVt);
    g_dev2Vt[10] = reinterpret_cast<void*>(&Dev2Gfx);
    g_dev2Gfx = 0;
    PsoRecordTick(2, 64, 0, 1, L".");   // sets the mode only
    void *d1 = nullptr, *d2 = nullptr;
    Check(PsoRecordTestCreateDevice(reinterpret_cast<void*>(&FakeCreate1), &d1) == S_OK && d1 == &g_dev &&
              g_devVt[10] != reinterpret_cast<void*>(&DevGfx) && PsoRecordTestCandidate() == &g_dev && PsoRecordTestGameDevice() == nullptr,
          "psorec: the device D3D12CreateDevice returned is hooked at once (found from the game's own creation path) and held as candidate");
    PsoRecordTestSetPlay(1);
    void* rs1 = nullptr;
    reinterpret_cast<RsFn>(g_devVt[16])(&g_dev, 0, rsA.data(), rsA.size(), __uuidof(ID3D12RootSignature), &rs1);
    Check(PsoRecordTestGameDevice() == &g_dev, "psorec: the first hooked call confirms the game's device");
    Check(PsoRecordTestCreateDevice(reinterpret_cast<void*>(&FakeCreate2), &d2) == S_OK && d2 == &g_dev2 && g_dev2Vt[10] != reinterpret_cast<void*>(&Dev2Gfx) &&
              PsoRecordTestCandidate() == &g_dev,
          "psorec: a second device with its own vtable is hooked too; the first stays the candidate");
    reinterpret_cast<GfxFn>(g_dev2Vt[10])(&g_dev2, &g, __uuidof(ID3D12PipelineState), &o);
    reinterpret_cast<GfxFn>(g_devVt[10])(&g_dev, &g, __uuidof(ID3D12PipelineState), &o);
    c = PsoRecordTestCounts();
    Check(g_dev2Gfx == 1 && g_seen.size() == 2 && c.calls == 2, "psorec: each hook calls the original of its own device's vtable and is counted");
    PsoRecordTestReset();
    Check(g_devVt[10] == reinterpret_cast<void*>(&DevGfx) && g_dev2Vt[10] == reinterpret_cast<void*>(&Dev2Gfx), "psorec: both vtables restored");

    // the export redirect on a real mapped module (a table entry pointed at a stub and put back)
    {
        const struct { const wchar_t* dll; const char* fn; } cands[] = {{L"user32.dll", "IsWindow"}, {L"advapi32.dll", "GetUserNameW"}, {L"user32.dll", "GetDC"}, {L"gdi32.dll", "SelectObject"}};
        bool done = false;
        for (auto& cand : cands) {
            HMODULE m = LoadLibraryW(cand.dll);
            if (!m) continue;
            FARPROC before = GetProcAddress(m, cand.fn);
            void* slot = nullptr;
            uint32_t rva = 0;
            void* stub = PsoRecordTestPatchExport(m, cand.fn, reinterpret_cast<void*>(&Dummy), &slot, &rva);
            if (!stub) continue;
            const bool patched = reinterpret_cast<void*>(GetProcAddress(m, cand.fn)) == stub && stub != reinterpret_cast<void*>(before);
            const uint8_t* sb = static_cast<const uint8_t*>(stub);
            const bool jmp = sb[0] == 0xFF && sb[1] == 0x25 && *reinterpret_cast<void* const*>(sb + 6) == reinterpret_cast<void*>(&Dummy);
            PsoRecordTestRestoreExport(slot, rva);
            Check(patched && jmp && GetProcAddress(m, cand.fn) == before, "psorec: an export table entry redirected to a jump stub and put back (GetProcAddress sees both)");
            done = true;
            break;
        }
        if (!done) Check(false, "psorec: an export table entry redirected to a jump stub and put back (no suitable module export found)");
    }
}

}  // namespace psr
