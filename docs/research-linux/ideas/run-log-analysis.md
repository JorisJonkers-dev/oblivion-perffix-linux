# Run log analysis: where frame time and hitches come from

Scope: the four runs with diag data (`linux/results/<run>/diag/`): `cs-ab3-1107-0950-on-r1`, `-on-r2`, `-on-r3` (Chapel Square, fix on, HitchLedger and TickSplit on) and `spin-canal-vt64` (canal spin, 8 slots). Sources are read-only. Numbers were computed with scripts in the scratchpad (`ledger_an.py`, `tick_an.py`, `mango_an.py`) and grep. Root: `/home/ExtraToast/Projects/oblivion-perffix-linux/linux/results/`. Abbreviations: "cs" = Chapel Square runs, "spin" = canal spin run.

## Harness artefact first: the two ~350 ms frames per run

Every run has two frames of about 350 ms that are not game work:

| run | frame | period ms | pre ms | location (UE x,y,z) |
|---|---:|---:|---:|---|
| cs-r1 | 2023 | 353 | 351 | 1090, -6, -804 |
| cs-r1 | 9265 | 359 | 351 | 175432, -129618, 10482 |
| cs-r2 | 1985, 10156 | 353, 359 | 351, 350 | same two places |
| cs-r3 | 2281, 10192 | 353, 359 | 351 | same two places |
| spin | 1506, 37742 | 352, 357 | 350, 351 | 1090,-6,-804; 172855,-132910,10324 |

They sit in the "before the world tick" bucket of `ledger.md` and match the runner's deliberate 350 ms busy loop (the sync stalls that anchor the ledger clock; see LOG.md, "The Linux benchmark works end to end"). The `ledger.md` "unlabelled: before the world tick" share (61–68% of in-world excess in the cs runs, source `diag/ledger.md`) is therefore almost all harness. Every number below excludes these frames (pre_ms > 300 ms). A 437 ms frame in cs-r1 (frame 7815, post 424 ms, location 175432,-129618,10482) is kept as a real unlabelled frame tail, but it could also be runner-side (it happens near the end of the session). Confidence: high for the anchors, medium for the 437 ms frame.

## 1. Game-thread tick groups (`tick_split.txt`, `OblivionPerfFix-ticksplit.csv`)

Per-run headers (`tick_split.txt`, "all windows"): 

| run | frames | frame period ms | actor phase ms/frame | of which pairing | tick groups ms/frame |
|---|---:|---:|---:|---:|---:|
| cs-r1 | 9264 | 10.4 | 3.58 | 1.04 | 2.28 |
| cs-r2 | 10156 | 9.4 | 2.73 | 0.59 | 1.92 |
| cs-r3 | 10155 | 9.3 | 2.90 | 0.66 | 2.01 |
| spin | 37741 | 10.8 | 3.81 | 0.37 | 3.13 |

Actor start (`actorstart`) costs 0.39–1.08 ms/frame; in r1 it is the largest bucket of the actor phase.

Top 15 classes by game-thread time, all four runs (67,316 frames; `ticksplit.csv` #E rows, computed by `tick_an.py`):

| # | class | ms/frame | share of listed tick time | ms/frame in windows with a slow frame | ms/frame in clean windows | max single call ms |
|---:|---|---:|---:|---:|---:|---:|
| 1 | VPairedPawnMovementComponent | 0.630 | 26.0% | 0.281 | 0.728 | 2.12 |
| 2 | SkeletalMeshComponent | 0.293 | 12.1% | 0.179 | 0.325 | 2.40 |
| 3 | ChaosClothComponent | 0.218 | 9.0% | 0.144 | 0.238 | 3.18 |
| 4 | SkeletalMeshComponentBudgeted | 0.163 | 6.7% | 0.152 | 0.166 | 2.90 |
| 5 | VPairedPawnStateMachineComponent | 0.133 | 5.5% | 0.067 | 0.151 | 2.87 |
| 6 | World (start/end physics) | 0.099 | 4.1% | 0.053 | 0.112 | 4.64 |
| 7 | VPhysicsControllerComponent | 0.097 | 4.0% | 0.048 | 0.110 | 2.71 |
| 8 | BP_FluidSim_01_C | 0.069 | 2.8% | 0.078 | 0.066 | 82.98 |
| 9 | L_CheydinhalWorld (Niagara world manager) | 0.058 | 2.4% | 0.030 | 0.066 | 2.59 |
| 10 | BP_AltarPlayerController_C | 0.057 | 2.4% | 0.041 | 0.062 | 2.55 |
| 11 | tickable vt:exe+0x7BE8010 | 0.047 | 1.9% | 0.048 | 0.046 | 3.42 |
| 12 | BP_OblivionPlayerCharacter_C | 0.042 | 1.7% | 0.039 | 0.043 | 4.35 |
| 13 | AkComponent | 0.042 | 1.7% | 0.027 | 0.046 | 2.53 |
| 14 | BP_PairedPawnAIController_C | 0.037 | 1.5% | 0.017 | 0.043 | 1.62 |
| 15 | VAnimationPairingComponent | 0.036 | 1.5% | 0.017 | 0.041 | 2.24 |

Steady or spiky:
- Almost all of the listed time is steady. The top 7 classes cost more in clean windows than in windows with a slow frame, which is the opposite of a spike source. The "slow window" test is crude: a 2 s window with one slow frame still counts all its ms.
- Spiky candidates: BP_FluidSim_01_C has one 83 ms call (r1 windows at the start, one 37 ms `LastDemotable` call in menu frame 2), and tickable vt:exe+0x77C9FE0 has a single 254 ms call in the menu stall (frame 517 of r1). Both are start-up or menu, not in-world. Confidence: medium.
- Per-frame costs of the top class: VPairedPawnMovementComponent 79 us per call, 6.4 calls per frame (r1, `tick_split.txt`).

Conclusion: the tick groups total 2–3 ms per frame, about 25–30% of the frame period. With the GPU at 98% (below), this steady cost does not set the average fps. It explains little of the slow frames, which are 4–8% of the in-world excess (below).

## 2. Slow frames (`OblivionPerfFix-ledger.csv`, `ledger.md`, `stutter_ledger.txt`)

The ledger CSV logs only slow frames (>= 25 ms), so per-frame averages are not available. Play-state slow frames, anchors excluded (ms, sums over frames, stages overlap):

| run | play slow frames 25–300 ms | DLL excess ms (anchors out) | pre | actor | post | sync | tick groups (tg0+...) | pair | unit | gpu | frames with PSO tasks running | frames with gpu > period/2 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| cs-r1 | 51 (+1 at 437 ms) | ~1668 | 31 | 587 | 1481 | 1280 | 308 | 82 | 257 | 1040 | 17 of 51 | 33 of 51 |
| cs-r2 | 6 | 317 | 1 | 34 | 382 | 376 | 19 | 0 | 24 | 62 | 2 of 6 | 0 of 6 |
| cs-r3 | 17 | 434 | 5 | 30 | 682 | 664 | 22 | 1 | 16 | 401 | 12 of 17 | 11 of 17 |
| spin | 17 | 554 | 136 | 77 | 625 | 521 | 56 | 3 | 16 | 302 | 6 of 17 | 5 of 17 |

Causes, after anchors are removed (`ledger.md` shares recomputed; the ledger's own shares include the anchors):
- Render-thread and GPU PSO precompile in play is the largest labelled cause. In cs-r2, nearly all of the real in-world excess (302 of 317 ms, `ledger.md`) is render-thread PSO; in cs-r3, 282 ms render PSO plus 143 ms GPU PSO of 435 ms. In cs-r1 it is about 34% (355 + 212 ms of ~1670 ms, which includes the 437 ms frame).
- Frame-tail unlabelled (GC, UI, draw, level streaming): cs-r1 only, 498 ms of ~1670 ms (about 30%, mostly the 437 ms frame). Confidence: low. Cause not separable with the current stages.
- Render-thread bound (no PSO label): cs-r1 336 ms (about 20%).
- Actor arrival: cs-r1 155 ms (about 9%); cs-r3 10 ms.
- Tick work: cs-r1 104 ms (about 6%); the rest of the runs show almost none.
- Menu and loading: only one "old-engine wait" per run at launch (cs-r1 frame 517, 2,596 ms, actor 2,549 ms; cs-r2 frame 524, 2,532 ms; cs-r3 frame 528, 2,464 ms; spin frame 257, 3,323 ms). These are in the menu state and happen once, at the start. Confidence: high that it is one-off. Cause unknown.
- Loading screen: 14–17 slow frames per cs run, not ranked (`ledger.md`). The pacing lines below show that large unit bursts happen in the loading state.

In-world slow-frame rate (`ledger.md`, play slow frames over play frames): cs-r1 54 of 7,066 (0.8%, with the 437 ms frame), cs-r2 8 of 7,409 (0.1%), cs-r3 19 of 7,821 (0.2%), spin 19 of 7,251 (0.3%).

## 3. OblivionPerfFix.log: per-fix counters

Counter lines are `since last report` stats printed about every 60 s. Notable values (cs-r1 unless noted; the other runs are similar):

- [pso] precompile: seen from +9.7 s, finished at +54.2 s; 10.7 s at the Fast pace, 33.8 s at the game's pace (cs-r1). cs-r2 finished at +40.4 s, cs-r3 at +46.4 s, spin at +58.2 s. "driver threads up to 0 % of a core" in every run, and "no driver compile threads found" repeated 3–4 times per run. The driver-thread guard therefore does nothing here. Confidence: medium. Possible explanation: the driver does not expose compile threads under vkd3d-proton on this setup (guess).
- [taskwait] worker waits 18,800–20,400 per run, longest wait 144–260 ms. The longest wait is one of the larger single waits in the logs. Not analysed further.
- [pacing] 5,780 frames (cs-r1): units run 25, deferred 0, max 19 units and 54.8 ms of units per frame, longest unit 12.2 ms (equipment). The budget is 4.0 ms. Units exceeded it in a few frames:
  - Start-up burst (frames 517, 524, 528 and 257 in spin): 19 units, 45–117 ms, of which "create" 11. These are in the menu state (the same frame as the 2.5 s wait).
  - In play (cs-r1): frame 7327 (60.7 ms, one unit, "first" 60.7 ms), 7331 (21.0 ms), 7332 (23.1 ms), 7334 (24.9 ms), 7587 (19.3 ms), 7588 (20.5 ms), 7621 (18.9 ms), so a single NPC unit can cost 17–61 ms.
  - Loading state: 46 units and 166–253 ms of units in one frame (cs-r1 frame 7262, cs-r2 8014, cs-r3 7800, spin 14738). These are not visible in play, but they are the largest unit spikes.
  - So the 4 ms budget is not kept for single units. That is expected (units cannot be split, per LOG.md), so the budget only orders work. Confidence: medium.
- [oscache] (OS-side asset cache, 64 MB peak): the counters are cumulative since start, not per window. cs runs at their last report: 5,300–5,600 hits and 26,400–26,600 misses (about 3.5 GB of misses), released "over cap" 2,240–2,370. Spin at its last report: 42,612 hits and 53,394 misses (8.6 GB of misses), released over cap 9,904. The cap is hit constantly. Confidence: medium that it limits hit rate; not tested.
- [fadein] (spin only): 34,058 fade-in value changes in four windows, 22,757 sent to the GPU scene, 11,301 (33%) recreated the render state. Not linked to any slow frame. Confidence: low, a candidate cost.
- [streamload] fade-in lag after streaming started: 1.0 s (cs, first transition), 1.9–2.4 s (later transitions, r1, r2, r3, spin). Cs has no door transition, so this is not in these runs.
- [mem]: VRAM 4.6 GB (peak 4.8) of a 22.7 GB budget; RAM free 17–21 GB. No memory pressure in any run. "relief off".
- [bodies] cs-r1: parallel 0 calls in the last window, game thread 24 calls and 61 bodies at 23.3 us/body. The parallel path was unused in that window. Other windows not checked.
- [clothreg]: 6–11 lite proxies completed per window, 0 full builds, 0 mismatches. The cloth fix is working (no full builds).
- [atm] PostSet: about 270,000–297,000 skipped per window, 5,200–5,700 forwarded. Fine.
- [physanim]: all UpdateTargetActors calls skipped (nothing to do). Fine.
- Warnings (only harmless ones found): "could not resolve all System32\version.dll exports" (once per run); "[pso] ... no driver compile threads found" (above). No "disabled" or "not found" lines beyond the start-up `[pso]`/[autosave] `AutosaveFollowsMenu off` (needs a restart; no effect in these runs).

## 4. MangoHud frametime (`mangohud/*.csv`)

Whole sessions include menu, loading and the first ~25 s of warm-up, so the distribution below is mixed. Per-second bins are computed over all rows.

| run | rows | session s | median ms | p99 ms | p99.9 ms | frames >= 25 ms | 1-s bins GPU >= 90% | mean GPU % | mean CPU % |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| cs-r1 | 9,343 | 108 | 7.6 | 23.2 | 161 | 78 | 57% | 86.9 | 40.6 |
| cs-r2 | 10,227 | 106 | 7.0 | 17.0 | 55 | 26 | 84% | 90.7 | 26.8 |
| cs-r3 | 10,273 | 106 | 7.0 | 17.4 | 49 | 47 | 83% | 91.1 | 27.9 |
| spin | 37,813 | 417 | 10.9 | 17.9 | 31 | 58 | 93% | 95.6 | 48.9 |

- GPU-bound share: 57–93% of 1-second bins at GPU >= 90% (heuristic; the 1-s bins include menus). The canal spin is GPU-bound in 93% of bins. The CPU never reaches 80% for a sustained second in cs-r2/r3. Confidence: medium. Consistent with the 98% GPU in `result.json`.
- Spike timing: spikes of >= max(2 x median, 25 ms) cluster in the first ~30 s (warm-up, PSO) and near the end (session close). Cluster gaps: median 1.8–5.6 s, p90 10–50 s, no fixed period (the most common gap is 1 s, which is the inside of one cluster). The data show no regular every-N-second spike, so GC or autosave on a fixed timer is not supported. Confidence: medium. The autosave timer was not checked against the log's `[autosave]` times.
- Frame-time max 945–993 ms is in the loading frames. My filter dropped 4–9 rows per run above 1000 ms (MangoHud's garbage rows, cf. LOG.md on the 37,337,300 ms row).

## Top 5 targets (ranked by in-world slow-frame evidence)

1. PSO precompile running into play. Evidence: 17 of 51 play slow frames in cs-r1, 12 of 17 in cs-r3, 6 of 17 in spin had PSO tasks running; the render-thread PSO label is the whole real excess in cs-r2. Precompile finished 40–58 s after start, with the game's pace used for 20–38 s. Next step: measure a longer warm-up or a run that waits for PSO before "play", and check how many play frames still carry PSO (guess: the driver-thread guard is a no-op, so the queue drains only through the game's own pace).
2. Frame-end sync and GPU waits in slow frames. Evidence: sum of sync_ms across slow frames is 1280 ms (cs-r1), 664 (cs-r3), 521 (spin), with post_ms of the same order; 33 of 51 cs-r1 slow frames have gpu_ms above half the frame period. The frame waits for the GPU. Next step: which pass or upload stalls the GPU at these frames (PSO-linked ones first). Note that the earlier render-threading switches (`cs-render-off`) did not change fps, so test the GPU side directly. Confidence: medium.
3. Single NPC unit costs (actor arrival). Evidence: in play, single units cost 17–61 ms (frames 7327 and 7331–7621, cs-r1); pacing overruns are 3–9 per run; the in-world actor-arrival share is 9% of real excess in cs-r1 (155 ms). Next step: the first unit of each arrival (the 20–40 ms non-splittable steps in `research-linux/npc-creation.md`), which is already the target of the ClothBuildDefer/NpcCreationPacing fixes. Confidence: medium.
4. Steady tick cost of paired pawns. Evidence: VPairedPawnMovementComponent is 0.63 ms/frame (26% of listed tick time), 79 us per call, 6.4 calls per frame; with SkeletalMesh and Cloth the three cost about 1.1 ms/frame. Benefit for average fps is limited while the GPU is at 98%, but it is steady CPU time with no spike (top 1 in clean windows). Confidence: high that it is the largest steady tick cost; low that it changes the hitch rate.
5. OS-side asset cache misses and the 64 MB cap. Evidence: cs runs end with about 26,500 misses (3.5 GB) and about 2,300 releases over cap; spin ends with 53,394 misses (8.6 GB) and 9,904 releases over cap; hit rate 17% (cs) and 44% (spin) by count. Next step: test a larger cap on a door or travel scene (where reads happen) and check whether the hit rate and the frame-tail share (30% in cs-r1) move. Confidence: low (guess, untested).

Also watch, not ranked: fade-in render-state recreations (33% of fade-in changes, spin); the 2.5–3.3 s launch stall (one per run, menu state); taskwait's 144–260 ms longest worker wait.

## Caveats

- Only four runs have diag. Three are the same scene with the same settings, so "variance" across them is mostly noise. The spin run is a different scene (canal, GPU-bound, 417 s).
- The ledger CSV only holds slow frames, and the ticksplit windows are 2 s each, so "slow window vs clean window" is an approximation.
- The 350 ms anchors (above) are the main confound: they make "unlabelled" look like 50–68% of the excess. Any future ledger report should drop frames with pre_ms > 300 ms that sit at the two runner locations.
- No run was made. Everything is from logs. Fix-off comparisons were not repeated in these four runs.
