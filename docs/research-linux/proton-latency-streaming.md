# Oblivion Remastered on Proton: latency and streaming/pop-in research

Date: 2026-11-07. Method: web search/fetch only; nothing was benchmarked. Items marked **[SPECULATION]** are my inference. Items marked **[UNVERIFIED]** come from a single user report or a secondary repost. Coverage is thin: no Oblivion-specific vkd3d-proton or Proton GitHub issue was found.

## Key findings (evidence quality)

1. **No documented Oblivion-specific fix for input lag or pop-in exists.** ProtonDB reports mention input lag (an Arch/AMD user rated the game "silver at best" and tried GE and Experimental without help; an RX 6700 XT user reported slight input lag).
   - https://www.protondb.com/users/1575764388
   - https://www.protondb.com/users/554270766
   - ProtonDB page: https://www.protondb.com/app/2623190
   - I could not fetch the aggregate ProtonDB page, so its launch-option statistics are unknown.
2. **A bad lead to ignore.** A ProtonDB comment cites vkd3d-proton issue #2439 and Mesa issue 13011 for stutter. #2439 is a Monster Hunter Wilds crash on Intel Arc, not Oblivion and not AMD (https://github.com/HansKristian-Work/vkd3d-proton/issues/2439). Do not rely on it. I could not read Mesa issue 13011 (Anubis block).
3. **Pop-in and low FPS are listed among reported Linux problems** on a ProtonDB page, alongside `VKD3D_DISABLE_EXTENSIONS=VK_NV_low_latency2` as a user launch option. That page URL was returned by search under a different app id (2246340), so attribution to Oblivion is uncertain. https://www.protondb.com/app/2246340
4. **Some users report smooth performance with no tinkering** (Mint and Bazzite). The Oblivion ProtonDB discussion also mentions a shader-precache crash on newer Proton, with clearing the Unreal shader cache as the fix. https://www.protondb.com/app/2623190?device=any
5. **UE5 pop-in is partly engine behaviour [SPECULATION].** Oblivion Remastered runs the original game logic under UE5, with a separate world-streaming layer. Pop-in may also occur on Windows. I found no source quantifying it, so compare against known Windows behaviour before blaming Proton.

## Ranked recommendations (expected impact, testable)

### 1. Move the game off ntfs-3g (FUSE) to ext4/btrfs/xfs. Highest expected impact for pop-in/streaming.
- Valve's wiki discourages NTFS libraries and says it is an unsupported environment. It also covers the compatdata problem (compatdata must live on a Linux filesystem). https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
- Throughput numbers (vendor claims, not independent):
  - The ntfs-3g maintainer quotes ext4 read 3.4 GB/s vs ntfs-3g 2.8 GB/s, and write 1.3 vs 1.1 GB/s, in quick sequential tests.
  - He also says about 15-20% slower for typical transfers.
  - Another maintainer claim: tuning (`big_writes`, `kernel_cache`) matters.
  - https://lore.kernel.org/lkml/alpine.DEB.2.20.2109030047330.23375@tuxera.com/
- I found no published random-read IOPS or latency comparison of ntfs-3g vs ntfs3 vs ext4. Sequential numbers hide the main cost: UE5 streams many small, concurrent reads, and each FUSE read costs a kernel-to-userspace round trip. That impact is **[SPECULATION]**, and the effect on pop-in is unproven.
- Anecdote: one user got acceptable results with ntfs3 after moving compatdata off NTFS, while another saw no improvement moving to ext4. So the filesystem is not always the cause. https://lemm.ee/post/44579603
- Test (cheap, decisive): copy the game dir (the `OblivionRemastered` install, roughly 100+ GB; check actual size) to an ext4/btrfs SSD location, add that as a Steam library, and compare pop-in on the same save.
  - Measure raw read first: `fio --name=r --filename=<file on NTFS mount> --rw=randread --bs=64k --iodepth=16 --ioengine=libaio --direct=1 --runtime=30 --time_based` vs the same on ext4. Note: FUSE may reject O_DIRECT; if so, drop `--direct=1` and use a file larger than RAM.
- Fallback if it must stay NTFS: switch to the kernel `ntfs3` driver (mount options in the thread above: `uid=,gid=,umask=,exec,nocase,windows_names`) and keep `compatdata` on Linux. ntfs3 is expected to be faster than FUSE **[SPECULATION]**, though no benchmark was found.

### 2. Check that the shader/pipeline caches are warm, and where they live
- The vkd3d-proton cache is controlled by `VKD3D_SHADER_CACHE_PATH`. Setting it to `0` disables the internal cache. `pipeline_library_app_cache` is the alternative. https://raw.githubusercontent.com/HansKristian-Work/vkd3d-proton/master/README.md
- Keep Steam shader pre-caching enabled; keep the cache and prefix on a fast Linux filesystem. A Bazzite user reported a crash during shader precaching and fixed it by clearing the Unreal shader cache (see finding 4).
- Do not set `VKD3D_SHADER_CACHE_PATH=0`.
- Hitching on first visit to an area that disappears on the second pass indicates PSO compilation, not IO **[SPECULATION]**.

### 3. VKD3D_CONFIG=no_upload_hvv (test A/B, memory pressure)
- README: stops the UPLOAD heap from using host-visible VRAM (ReBAR), freeing VRAM at some GPU-performance cost. https://raw.githubusercontent.com/HansKristian-Work/vkd3d-proton/master/README.md
- A ProtonDB comment says it fixed stutter in this game and in Elden Ring. Other comments say the game runs fine without it. [UNVERIFIED] https://www.protondb.com/app/2246340
- Why it might matter here: the 7900 XTX has 24 GB so VRAM exhaustion is unlikely, but the user report suggests vkd3d uses extra VRAM. Low prior for this card; test it anyway because it is free.
- Launch option: `VKD3D_CONFIG=no_upload_hvv %command%`

### 4. Input latency: vkd3d low-latency frame pacing (Proton-CachyOS) and swapchain queue depth
- Proton-CachyOS (11.0-20260703 and later) includes `vkd3d-low-latency`, enabled by `PROTON_VKD3D_LOWLATENCY=1`. It implements Reflex in the translation layer and Waitable DXGI Swapchain pacing, and is hardware-agnostic. https://www.gamingonlinux.com/2026/07/proton-cachyos-adds-support-for-vkd3d-low-latency-upgrades-d7vk-and-more/
- It only paces if the game uses Reflex or Waitable Swapchains. Verify with `PROTON_LOG=1` and search the log for `waitable dxgi swapchain present percentage` (near 100% means active, missing or 0% means inactive). Whether Oblivion Remastered (UE5) uses either is **unknown** here. https://github.com/netborg-afps/vkd3d-low-latency
- Extra knobs from that README: `VKD3D_LOW_LATENCY_OFFSET` (0-500 microseconds, default 100; 150-300 for lower latency at some FPS cost), `VKD3D_FRAME_RATE=<n>`. Same README says the AMD Anti-Lag 2 path is not supported. It also recommends a sched_ext scheduler such as `scx_cosmos -c 0 -p 0`. (Your kernel is CachyOS, so scx may be available.)
- Launch options: `PROTON_VKD3D_LOWLATENCY=1 PROTON_LOG=1 %command%`
- `VKD3D_SWAPCHAIN_LATENCY_FRAMES=1`: a Linux latency study calls it crucial for DX12 latency, but warns it can roughly halve frame rate under Wayland. [UNVERIFIED, secondary repost; the variable is absent from the vkd3d-proton README I fetched, so confirm it exists in your vkd3d-proton version with `strings d3d12core.dll | grep SWAPCHAIN_LATENCY`.] https://fooqux.com/article/5675
- Present mode: README lists `VKD3D_SWAPCHAIN_PRESENT_MODE` accepting IMMEDIATE, MAILBOX, FIFO, FIFO_RELAXED, FIFO_LATEST_READY. https://raw.githubusercontent.com/HansKristian-Work/vkd3d-proton/master/README.md
  - Under XWayland with a compositor, true tearing present is usually not delivered, so gains are **[SPECULATION]**.
  - Mailbox, if honoured, avoids queued-frame vsync latency.
  - Try `VKD3D_SWAPCHAIN_PRESENT_MODE=MAILBOX` and `=IMMEDIATE` separately.
- GPU at 99%: when the GPU is the bottleneck, the render queue fills, and mouse latency grows by about one frame per queued frame **[SPECULATION, standard pipelining behaviour]**. The most reliable latency lever is to leave GPU headroom: cap the FPS just below what the GPU sustains (`VKD3D_FRAME_RATE=<n>` or `MANGOHUD_CONFIG=fps_limit=<n>`), or lower the resolution scale or Lumen/Nanite settings.
- Anti-Lag: GamingOnLinux reports vkd3d-proton 3.0 added AMD Anti-Lag support [UNVERIFIED, from search snippet only; I did not open the article]. Separately, the third-party `low_latency_layer` implements `VK_NV_low_latency2` and `VK_AMD_anti_lag` on AMD, needing NVAPI forwarding in Proton and a source build; its gains are self-reported as a few milliseconds. https://www.kitguru.net/gaming/joao-silva/new-vulkan-layer-enables-nvidia-reflex-and-amd-anti-lag-on-any-gpu/ A RADV Anti-Lag merge request (freedesktop 12704) existed in March 2025; I could not confirm its status.
- `VKD3D_DISABLE_EXTENSIONS=VK_NV_low_latency2` appears as a user workaround for visual artifacts in one ProtonDB report. Not needed on AMD (RADV does not expose that extension).

### 5. Wayland vs XWayland
- `PROTON_ENABLE_WAYLAND=1` reportedly reduces latency substantially in some games, sometimes to Windows levels. [UNVERIFIED, single study] https://fooqux.com/article/5675
- Needs a Proton build with the Wayland driver (Proton 10+ / GE / CachyOS). Launch option: `PROTON_ENABLE_WAYLAND=1 %command%` (add `PROTON_ENABLE_HDR=1` only if you want HDR). Compare mouse feel directly; HDR/WSI can behave differently.
- Also: background apps and the compositor add latency (the study measured up to 3 ms from an idle editor) and BFI adds a full frame. Test with the GNOME compositor but no other windows open.

### 6. CPU/sync tuning (low expected impact for latency, moderate for streaming hitches)
- Use fsync (default in Proton) and keep ntsync enabled if your Proton and kernel support it (Linux 7.x kernels ship ntsync; Proton option `PROTON_USE_NTSYNC=1` on builds that support it **[verify in your build's docs]**).
- CPU governor: use `amd-pstate-epp` with `performance` EPP while testing: `echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference`. Expected effect is small; CPU is not the bottleneck at 99% GPU **[SPECULATION]**.
- `gamemoderun %command%` appears in several Oblivion reports, but no measured benefit. https://www.protondb.com/users/2037883696

### 7. RADV flags (low confidence, A/B only)
- `RADV_PERFTEST=gpl` was reported to remove stutter in Dead Space on a 7900 XTX [UNVERIFIED, other game]. On Mesa 26.x, GPL is already the default, so this is probably a no-op **[SPECULATION]**. https://www.protondb.com/users/1376509488
- `RADV_PERFTEST=sam` (SAM is on by default when ReBAR is present), `nggc` (default on RDNA2 and later per my knowledge, not verified here) and `rt` (only matters if the game enables ray tracing; UE5 Lumen hardware RT is off by default) are unlikely to help. `VKD3D_CONFIG=nodxr` removes the DXR path entirely (README) and can reduce shader compile work and VRAM if the game's RT is not needed. Test: `VKD3D_CONFIG=nodxr %command%`.
- Do not use `RADV_DEBUG` flags for performance; they are for debugging.

## Combined starting launch option set (change one thing at a time)
```
# baseline test of cache health and IO: game moved to ext4 library, then:
VKD3D_CONFIG=no_upload_hvv %command%
# latency test on Proton-CachyOS:
PROTON_VKD3D_LOWLATENCY=1 PROTON_ENABLE_WAYLAND=1 VKD3D_FRAME_RATE=<slightly below sustained fps> PROTON_LOG=1 %command%
```

## Gaps
- No frame-time or latency measurements for this game on 7900 XTX were found.
- No random-IO benchmark of ntfs-3g vs ntfs3 vs ext4.
- Could not read Mesa issue 13011, the aggregate ProtonDB page, or the Steam discussions beyond one thread.
- The Valve Proton repo and vkd3d-proton issue tracker were not searched for an Oblivion issue (search engine returned none); check `github.com/ValveSoftware/Proton/issues?q=2623190` manually.
