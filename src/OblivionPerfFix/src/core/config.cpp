// Reads OblivionPerfFix.ini (next to the DLL) into a Config. A missing key keeps its default from common.h.
// main.cpp calls this at start-up and then every second (MonitorThread), so most fixes can be switched live.
#include "common.h"

namespace opf {

Config LoadConfig(const wchar_t* iniPath)
{
    Config c;
    auto get = [&](const wchar_t* section, const wchar_t* key, int def) {
        return static_cast<int>(GetPrivateProfileIntW(section, key, def, iniPath));
    };
    c.boneUploadStores = get(L"Fixes", L"BoneUploadStores", c.boneUploadStores) != 0;
    c.atmosphereDirtyFilter = get(L"Fixes", L"AtmosphereDirtyFilter", c.atmosphereDirtyFilter) != 0;
    c.atmosphereLightFastPath = get(L"Fixes", L"AtmosphereLightFastPath", c.atmosphereLightFastPath) != 0;
    c.atmosphereLightCloudPath = get(L"Fixes", L"AtmosphereLightCloudPath", c.atmosphereLightCloudPath) != 0;
    c.rdgParallelTranslate = get(L"Fixes", L"RdgParallelTranslate", c.rdgParallelTranslate);
    c.rdgFrameFence = get(L"Fixes", L"RdgFrameFence", c.rdgFrameFence) != 0;
    c.viewRenameGuard = get(L"Fixes", L"ViewRenameGuard", c.viewRenameGuard);
    c.rdgSubmitBatch = get(L"Fixes", L"RdgSubmitBatch", c.rdgSubmitBatch);
    c.rdgSubmitMaxAgeUs = get(L"Fixes", L"RdgSubmitMaxAgeUs", c.rdgSubmitMaxAgeUs);
    c.clothConfigCache = get(L"Fixes", L"ClothConfigCache", c.clothConfigCache) != 0;
    c.frozenClothStretchFix = get(L"Fixes", L"FrozenClothStretchFix", c.frozenClothStretchFix) != 0;
    c.npcFadeInNoRebuild = get(L"Fixes", L"NpcFadeInNoRebuild", c.npcFadeInNoRebuild) != 0;
    c.prepareCollisionBehindLoadingScreen =
        get(L"Fixes", L"PrepareCollisionBehindLoadingScreen", c.prepareCollisionBehindLoadingScreen) != 0;
    c.editorIdLookupGuard = get(L"Fixes", L"NameLookupCrashGuard", c.editorIdLookupGuard) != 0;
    c.trapCrashGuard = get(L"Fixes", L"TrapCrashGuard", c.trapCrashGuard) != 0;
    c.bowSneakAttackFix = get(L"Fixes", L"BowSneakAttackFix", c.bowSneakAttackFix) != 0;
    c.autosaveFollowsMenu = get(L"Fixes", L"AutosaveFollowsMenu", c.autosaveFollowsMenu) != 0;
    c.havokPickWarningGuard = get(L"Fixes", L"HavokPickWarningGuard", c.havokPickWarningGuard) != 0;
    c.frameGenCrashGuard = get(L"Fixes", L"FrameGenCrashGuard", c.frameGenCrashGuard) != 0;
    c.objectReplaceGuard = get(L"Fixes", L"ObjectReplaceCrashGuard", c.objectReplaceGuard);
    c.taskWaitDeadlockGuard = get(L"Fixes", L"TaskWaitDeadlockGuard", c.taskWaitDeadlockGuard);
    c.psoCompileThreadPool = get(L"Fixes", L"PsoCompileThreadPool", c.psoCompileThreadPool);
    c.psoCompileThreadPoolPriority = get(L"Fixes", L"PsoCompileThreadPoolPriority", c.psoCompileThreadPoolPriority);
    c.frameGenAsyncCompute = get(L"Fixes", L"FrameGenAsyncCompute", c.frameGenAsyncCompute) != 0;
    c.frameGenCameraInfo = get(L"Fixes", L"FrameGenCameraInfo", c.frameGenCameraInfo) != 0;
    c.frameGenPacingTuning = get(L"Fixes", L"FrameGenPacingTuning", c.frameGenPacingTuning);
    c.displayModeCache = get(L"Fixes", L"DisplayModeCache", c.displayModeCache) != 0;
    c.monitorNativeFromWindows = get(L"Fixes", L"MonitorNativeFromWindows", c.monitorNativeFromWindows) != 0;
    c.fullscreenAllResolutions = get(L"Fixes", L"FullscreenAllResolutions", c.fullscreenAllResolutions) != 0;
    c.separableSkinAbove4K = get(L"Fixes", L"SeparableSkinAbove4K", c.separableSkinAbove4K) != 0;
    c.screenshotFilterFast = get(L"Fixes", L"MenuScreenshotFilter", c.screenshotFilterFast) != 0;
    c.screenshotReadbackConvert = get(L"Fixes", L"ScreenshotReadbackConvert", c.screenshotReadbackConvert);
    c.screenshotParallel = get(L"Fixes", L"ScreenshotParallel", c.screenshotParallel);
    c.hdrMenuRows = get(L"Fixes", L"HdrMenuRows", c.hdrMenuRows) != 0;
    c.dlssRayReconstruction = get(L"Fixes", L"DlssRayReconstruction", c.dlssRayReconstruction) != 0;
    c.hudAspectRow = get(L"Fixes", L"HudAspectRow", c.hudAspectRow) != 0;
    c.hdrGamma22 = get(L"Fixes", L"HdrGamma22", c.hdrGamma22) != 0;
    c.hdrGamma22White = get(L"Fixes", L"HdrGamma22White", c.hdrGamma22White);
    c.hdrMenuBackground = get(L"Fixes", L"HdrMenuBackground", c.hdrMenuBackground) != 0;
    c.hdrSaveThumbnail = get(L"Fixes", L"HdrSaveThumbnail", c.hdrSaveThumbnail) != 0;
    c.restoreFsrAfterAltTab = get(L"Fixes", L"RestoreFsrAfterAltTab", c.restoreFsrAfterAltTab) != 0;
    c.lumenKeepArrayCapacity = get(L"Fixes", L"LumenKeepArrayCapacity", c.lumenKeepArrayCapacity) != 0;
    c.uploadMemoryKeep = get(L"Fixes", L"UploadMemoryKeep", c.uploadMemoryKeep) != 0;
    c.uploadMemoryKeepFrames = get(L"Fixes", L"UploadMemoryKeepFrames", c.uploadMemoryKeepFrames);
    c.uploadPagesToKeep = get(L"Fixes", L"UploadPagesToKeep", c.uploadPagesToKeep);
    c.uploadReleaseRampFrames = get(L"Fixes", L"UploadReleaseRampFrames", c.uploadReleaseRampFrames);
    c.physicsTreeTimeSlicing = get(L"Fixes", L"PhysicsTreeTimeSlicing", c.physicsTreeTimeSlicing) != 0;
    c.physicsSliceIterations = get(L"Fixes", L"PhysicsSliceIterations", c.physicsSliceIterations);
    c.physicsSliceCopyKB = get(L"Fixes", L"PhysicsSliceCopyKB", c.physicsSliceCopyKB);
    c.physicsSliceAdaptive = get(L"Fixes", L"PhysicsSliceAdaptive", c.physicsSliceAdaptive) != 0;
    c.physicsFlushParallel = get(L"Fixes", L"PhysicsFlushParallel", c.physicsFlushParallel) != 0;
    c.physicsFlushMinChanges = get(L"Fixes", L"PhysicsFlushMinChanges", c.physicsFlushMinChanges);
    c.instanceClearReserve = get(L"Fixes", L"InstanceClearReserve", c.instanceClearReserve) != 0;
    c.parallelStaticBodies = get(L"Fixes", L"ParallelStaticBodies", c.parallelStaticBodies) != 0;
    c.parallelStaticBodiesMin = get(L"Fixes", L"ParallelStaticBodiesMin", c.parallelStaticBodiesMin);
    c.parallelStaticBodiesThreads = get(L"Fixes", L"ParallelStaticBodiesThreads", c.parallelStaticBodiesThreads);
    c.parallelMinProcessors = get(L"Fixes", L"ParallelMinProcessors", c.parallelMinProcessors);
    c.pipelinedSceneAdd = get(L"Fixes", L"PipelinedSceneAdd", c.pipelinedSceneAdd) != 0;
    c.pipelinedSceneAddMin = get(L"Fixes", L"PipelinedSceneAddMin", c.pipelinedSceneAddMin);
    c.dirtyTreeQuickInsert = get(L"Fixes", L"DirtyTreeQuickInsert", c.dirtyTreeQuickInsert) != 0;
    c.helperThreadCaches = get(L"Fixes", L"HelperThreadCaches", c.helperThreadCaches) != 0;
    c.bulkIndexInsert = get(L"Fixes", L"BulkIndexInsert", c.bulkIndexInsert) != 0;
    c.bulkIndexInsertMin = get(L"Fixes", L"BulkIndexInsertMin", c.bulkIndexInsertMin);
    c.physicsInternalFlushParallel = get(L"Fixes", L"PhysicsInternalFlushParallel", c.physicsInternalFlushParallel) != 0;
    c.physicsQueueShrinkOnce = get(L"Fixes", L"PhysicsQueueShrinkOnce", c.physicsQueueShrinkOnce) != 0;
    c.physicsDestroyBatch = get(L"Fixes", L"PhysicsDestroyBatch", c.physicsDestroyBatch);
    c.physicsDestroyBatchMin = get(L"Fixes", L"PhysicsDestroyBatchMin", c.physicsDestroyBatchMin);
    c.npcBodiesOneLock = get(L"Fixes", L"NpcBodiesOneLock", c.npcBodiesOneLock);
    c.clothRegisterLite = get(L"Fixes", L"ClothRegisterLite", c.clothRegisterLite);
    c.rigVmHashMemo = get(L"Fixes", L"RigVmHashMemo", c.rigVmHashMemo);
    c.rigLogicMapCache = get(L"Fixes", L"RigLogicMapCache", c.rigLogicMapCache);
    c.rtSceneBufferKeep = get(L"Fixes", L"RtSceneBufferKeep", c.rtSceneBufferKeep);
    c.rayTracingBuildBatch = get(L"Fixes", L"RayTracingBuildBatch", c.rayTracingBuildBatch) != 0;
    c.waterCaptureFsrSkip = get(L"Fixes", L"WaterCaptureFsrSkip", c.waterCaptureFsrSkip) != 0;
    c.waterCaptureNoRhiFlush = get(L"Fixes", L"WaterCaptureNoRhiFlush", c.waterCaptureNoRhiFlush) != 0;
    c.waterCaptureNoOcclusionWait = get(L"Fixes", L"WaterCaptureNoOcclusionWait", c.waterCaptureNoOcclusionWait) != 0;
    c.waterCaptureFastMeshScan = get(L"Fixes", L"WaterCaptureFastMeshScan", c.waterCaptureFastMeshScan);
    c.naniteInitialRootPages = get(L"Fixes", L"NaniteInitialRootPages", c.naniteInitialRootPages);
    c.frameRateLimitAtStart = get(L"Fixes", L"FrameRateLimitAtStart", c.frameRateLimitAtStart);
    c.navLinkFast = get(L"Fixes", L"NavLinkFast", c.navLinkFast);
    c.saveBytesBulk = get(L"Fixes", L"SaveBytesBulk", c.saveBytesBulk);
    c.saveRefIdIndex = get(L"Fixes", L"SaveRefIdIndex", c.saveRefIdIndex);
    c.saveThumbnailAsync = get(L"Fixes", L"SaveThumbnailAsync", c.saveThumbnailAsync);
    // The public build has one ClothRegisterLite mode (3) and no verify / check / log-only modes (lab 2 and NavLinkFast's 3):
    // other values read as on.
    if (c.clothRegisterLite) c.clothRegisterLite = 3;
    if (c.rigVmHashMemo) c.rigVmHashMemo = 1;
    if (c.rigLogicMapCache) c.rigLogicMapCache = 1;
    if (c.rtSceneBufferKeep != 0 && c.rtSceneBufferKeep != 2) c.rtSceneBufferKeep = 1;
    if (c.waterCaptureFastMeshScan) c.waterCaptureFastMeshScan = 1;
    if (c.frameRateLimitAtStart) c.frameRateLimitAtStart = 1;
    if (c.navLinkFast) c.navLinkFast = 1;
    if (c.saveBytesBulk) c.saveBytesBulk = 1;
    if (c.saveRefIdIndex) c.saveRefIdIndex = 1;
    if (c.saveThumbnailAsync) c.saveThumbnailAsync = 1;
    if (c.taskWaitDeadlockGuard) c.taskWaitDeadlockGuard = 1;          // lab 2 (measure only) reads as on
    if (c.psoCompileThreadPool < -1) c.psoCompileThreadPool = -1;      // 0 the game's, N threads, -1 automatic
    c.menuOpenFlashFix = get(L"Fixes", L"MenuOpenFlashFix", c.menuOpenFlashFix) != 0;
    c.vramCounterFix = get(L"Fixes", L"VramCounterFix", c.vramCounterFix) != 0;
    c.shaderScreenAfterDriverChange = get(L"Fixes", L"ShaderScreenAfterDriverChange", c.shaderScreenAfterDriverChange) != 0;
    c.shaderScreenLinux = get(L"Fixes", L"ShaderScreenLinuxFingerprint", c.shaderScreenLinux) != 0;
    c.shaderGateBeforePlay = get(L"Fixes", L"ShaderGateBeforePlay", c.shaderGateBeforePlay);
    if (c.shaderGateBeforePlay < 0 || c.shaderGateBeforePlay > 2) c.shaderGateBeforePlay = 1;
    c.psoRecordReplay = get(L"Fixes", L"PsoRecordReplay", c.psoRecordReplay);
    c.psoRecordMaxMB = get(L"Fixes", L"PsoRecordMaxMB", c.psoRecordMaxMB);
    c.psoRecordMinMs = get(L"Fixes", L"PsoRecordMinMs", c.psoRecordMinMs);
    c.psoReplayThreads = get(L"Fixes", L"PsoReplayThreads", c.psoReplayThreads);
    c.shaderGateMaxSeconds = get(L"Fixes", L"ShaderGateMaxSeconds", c.shaderGateMaxSeconds);
    if (c.shaderGateMaxSeconds < 10) c.shaderGateMaxSeconds = 10;
    if (c.shaderGateMaxSeconds > 3600) c.shaderGateMaxSeconds = 3600;
    c.physAnimNoEmptyLock = get(L"Fixes", L"PhysAnimNoEmptyLock", c.physAnimNoEmptyLock) != 0;
    c.rigTraceReuse = get(L"Fixes", L"RigTraceReuse", c.rigTraceReuse);
    if (c.rigTraceReuse < 0 || c.rigTraceReuse > 2) c.rigTraceReuse = 1;  // 0 off, 1 on, 2 verify; anything else = on
    c.chaosMaxPayloadSize = get(L"Fixes", L"ChaosMaxPayloadSize", c.chaosMaxPayloadSize);
    c.osPageCache = get(L"Fixes", L"OsPageCache", c.osPageCache);
    c.osPageCacheMB = get(L"Fixes", L"OsPageCacheMB", c.osPageCacheMB);
    c.osPageCacheTrimSeconds = get(L"Fixes", L"OsPageCacheTrimSeconds", c.osPageCacheTrimSeconds);
    c.osPageCacheKeepMs = get(L"Fixes", L"OsPageCacheKeepMs", c.osPageCacheKeepMs);
    c.osPageCacheTrace = get(L"Fixes", L"OsPageCacheTrace", c.osPageCacheTrace);
    c.osPageCacheTraceMB = get(L"Fixes", L"OsPageCacheTraceMB", c.osPageCacheTraceMB);
    c.psoColdGuardWine = get(L"Fixes", L"PsoColdGuardWine", c.psoColdGuardWine) != 0;
    c.sharedMemoryGpuWine = get(L"Fixes", L"SharedMemoryGpuWine", c.sharedMemoryGpuWine) != 0;
    c.psoPrecompileFast = get(L"Fixes", L"PsoPrecompileFast", c.psoPrecompileFast) != 0;
    c.psoPrecompileFastInGameMenus = get(L"Fixes", L"PsoPrecompileFastInGameMenus", c.psoPrecompileFastInGameMenus) != 0;
    c.psoPrecompileFastBudgetMs = get(L"Fixes", L"PsoPrecompileFastBudgetMs", c.psoPrecompileFastBudgetMs);
    c.psoPrecompileColdQueue = get(L"Fixes", L"PsoPrecompileColdQueue", c.psoPrecompileColdQueue);
    c.animTeardownParallel = get(L"Fixes", L"AnimTeardownParallel", c.animTeardownParallel);
    c.cellBufferPacedEvict = get(L"Fixes", L"CellBufferPacedEvict", c.cellBufferPacedEvict);
    c.physicsPushParallel = get(L"Fixes", L"PhysicsPushParallel", c.physicsPushParallel);
    c.physicsPushMin = get(L"Fixes", L"PhysicsPushMin", c.physicsPushMin);
    c.physicsPushThreads = get(L"Fixes", L"PhysicsPushThreads", c.physicsPushThreads);
    c.pipelinedBodyCreation = get(L"Fixes", L"PipelinedBodyCreation", c.pipelinedBodyCreation) != 0;
    c.gpuSceneParallelUpload = get(L"Fixes", L"GpuSceneParallelUpload", c.gpuSceneParallelUpload) != 0;
    c.hitchLedger = get(L"Fixes", L"HitchLedger", c.hitchLedger) != 0;
    c.hitchLedgerMs = get(L"Fixes", L"HitchLedgerMs", c.hitchLedgerMs);
    c.otProfile = get(L"Fixes", L"OtProfile", c.otProfile) != 0;
    c.otProfileMs = get(L"Fixes", L"OtProfileMs", c.otProfileMs);
    c.otProfileSampleHz = get(L"Fixes", L"OtProfileSampleHz", c.otProfileSampleHz);
    c.otCrashContext = get(L"Fixes", L"OtCrashContext", c.otCrashContext) != 0;
    c.hitchLedgerTickSplit = get(L"Fixes", L"HitchLedgerTickSplit", c.hitchLedgerTickSplit) != 0;
    c.vtStreamingUploads = get(L"Fixes", L"VtStreamingUploads", c.vtStreamingUploads);
    c.doorDiag = get(L"Fixes", L"DoorDiag", c.doorDiag) != 0;
    c.doorDiagEarlyStream = get(L"Fixes", L"DoorDiagEarlyStream", c.doorDiagEarlyStream) != 0;
    c.fadeVtFlushSkip = get(L"Fixes", L"FadeVtFlushSkip", c.fadeVtFlushSkip) != 0;
    c.streamBehindLoading = get(L"Fixes", L"StreamBehindLoadingScreen", c.streamBehindLoading) != 0;
    c.streamPrewarm = get(L"Fixes", L"StreamPrewarmBehindLoading", c.streamPrewarm) != 0;
    c.streamPrewarmMaxHoldMs = get(L"Fixes", L"StreamPrewarmMaxHoldMs", c.streamPrewarmMaxHoldMs);
    c.unfreezeBehindLoading = get(L"Fixes", L"UnfreezeBehindLoadingScreen", c.unfreezeBehindLoading);
    c.unfreezeBehindLoadingFastTravel = get(L"Fixes", L"UnfreezeBehindLoadingScreenFastTravel", c.unfreezeBehindLoadingFastTravel);
    c.npcCreationPacing = get(L"Fixes", L"NpcCreationPacing", c.npcCreationPacing) != 0;
    c.pacingBudgetMs = get(L"Fixes", L"PacingBudgetMs", c.pacingBudgetMs);
    c.pacingMinDistance = get(L"Fixes", L"PacingMinDistance", c.pacingMinDistance);
    c.pacingMaxLagFrames = get(L"Fixes", L"PacingMaxLagFrames", c.pacingMaxLagFrames);
    c.clothBuildDefer = get(L"Fixes", L"ClothBuildDefer", c.clothBuildDefer) != 0;
    c.clothDeferQuietFrames = get(L"Fixes", L"ClothDeferQuietFrames", c.clothDeferQuietFrames);
    c.pacingUseSlack = get(L"Fixes", L"PacingUseSlack", c.pacingUseSlack) != 0;
    c.pacingFlowWait = get(L"Fixes", L"PacingFlowWait", c.pacingFlowWait) != 0;
    c.pacingFlowWaitFrames = get(L"Fixes", L"PacingFlowWaitFrames", c.pacingFlowWaitFrames);
    c.pacingLeanFlowDrain = get(L"Fixes", L"PacingLeanFlowDrain", c.pacingLeanFlowDrain) != 0;
    c.pacingFadeAware = get(L"Fixes", L"PacingFadeAware", c.pacingFadeAware);
    if (c.pacingFadeAware > 1) c.pacingFadeAware = 1;  // lab modes 2 / 3 read as on
    c.memoryRelief = get(L"Fixes", L"MemoryRelief", c.memoryRelief) != 0;
    c.memoryReliefRamMB = get(L"Fixes", L"MemoryReliefRamMB", c.memoryReliefRamMB);
    c.memoryReliefCommitMB = get(L"Fixes", L"MemoryReliefCommitMB", c.memoryReliefCommitMB);
    c.sharedMemoryGpu = get(L"Fixes", L"SharedMemoryGpu", c.sharedMemoryGpu);
    c.vramRelief = get(L"Fixes", L"VramRelief", c.vramRelief) != 0;
    c.vramReliefPauseTranslate = get(L"Fixes", L"VramReliefPauseTranslate", c.vramReliefPauseTranslate) != 0;
    c.navmeshBuildNoBusyWait = get(L"Fixes", L"NavmeshBuildNoBusyWait", c.navmeshBuildNoBusyWait) != 0;
    c.busyWaitFlagCheck = get(L"Fixes", L"BusyWaitFlagCheck", c.busyWaitFlagCheck) != 0;
    c.gpuSceneKeepCapacity = get(L"Fixes", L"GpuSceneKeepCapacity", c.gpuSceneKeepCapacity) != 0;
    c.commandAllocatorTrim = get(L"Fixes", L"CommandAllocatorTrim", c.commandAllocatorTrim) != 0;
    c.allocatorTrimWindowSeconds = get(L"Fixes", L"AllocatorTrimWindowSeconds", c.allocatorTrimWindowSeconds);
    c.immediateAllocatorLists = get(L"Fixes", L"ImmediateAllocatorLists", c.immediateAllocatorLists);
    c.allocatorTrimHeadroomMB = get(L"Fixes", L"AllocatorTrimHeadroomMB", c.allocatorTrimHeadroomMB);
    c.logFile = get(L"General", L"LogFile", c.logFile) != 0;
    c.gpuCrashReport = get(L"General", L"GpuCrashReport", c.gpuCrashReport) != 0;
    c.statsIntervalSeconds = get(L"General", L"StatsIntervalSeconds", c.statsIntervalSeconds);
    return c;
}

bool IsWine()
{
    static const bool wine = [] {
        HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
        return ntdll && GetProcAddress(ntdll, "wine_get_version") != nullptr;
    }();
    return wine;
}

// The ini is re-read only when it changed: every GetPrivateProfileIntW opens and parses the whole file (a wineserver round
// trip each under Wine, ~114 per second). One GetFileAttributesExW per second says whether size or last-write time moved.
// A file written within the last 2 s is re-read anyway (an editor may still be writing; coarse timestamps), so a live switch
// still lands within about a second and a half-written file never sticks.
bool LoadConfigIfChanged(const wchar_t* iniPath, Config* cfg, const unsigned long long* nowFileTime)
{
    static bool have = false, haveStat = false;
    static ULONGLONG lastWrite = 0, size = 0;
    WIN32_FILE_ATTRIBUTE_DATA a{};
    const bool ok = GetFileAttributesExW(iniPath, GetFileExInfoStandard, &a) != 0;
    ULONGLONG w = 0, sz = 0, nowFt = 0;
    if (ok) {
        w = (static_cast<ULONGLONG>(a.ftLastWriteTime.dwHighDateTime) << 32) | a.ftLastWriteTime.dwLowDateTime;
        sz = (static_cast<ULONGLONG>(a.nFileSizeHigh) << 32) | a.nFileSizeLow;
        if (nowFileTime) {
            nowFt = *nowFileTime;
        } else {
            FILETIME now;
            GetSystemTimeAsFileTime(&now);
            nowFt = (static_cast<ULONGLONG>(now.dwHighDateTime) << 32) | now.dwLowDateTime;
        }
    }
    const bool same = have && ok == haveStat && (!ok || (w == lastWrite && sz == size));
    const bool fresh = ok && nowFt >= w && nowFt - w < 20000000ull;  // written within 2 s (100 ns units)
    if (same && !fresh) return false;
    *cfg = LoadConfig(iniPath);
    have = true;
    haveStat = ok;
    lastWrite = w;
    size = sz;
    return true;
}

}  // namespace opf
