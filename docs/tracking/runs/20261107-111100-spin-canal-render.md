# spin spin-canal-render (2026-11-07 11:11:00)

- spot `linux-hotspots/cheydinhal-canal`, profile `own`, hour/weather pinned: True, outcome **ok**
- 30 deg/s = 12.0 s per lap, pitch 0, 2 lap(s) per slot, settle 4 s, camera lag assumed 0.3 s
- order: base nopt nosb nocache nocache nosb nopt base base nopt nosb nocache nocache nosb nopt base
- frames: MangoHud (Proton); log start from sync marker (48501 frames in `OblivionRemastered-Win64-Shipping_2026-11-07_11-11-25.csv`)

| variant | kind | slots | avg fps | 1% low | 0.1% low | p99 ms | max ms | hitches | GPU % | CPU % |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | base | 4 | 75.5 | 56.0 | 38.2 | 17.97 | 32.2 | 0 | 98 | 49 |
| nopt | ini | 4 | 80.0 (+6% ~) | 59.8 (+7% ~) | 42.0 (+10% ~) | 16.95 (-6% ~) | 38.1 (+18% ~) | 0 (+0% ~) | 98 | 52 |
| nosb | ini | 4 | 68.3 (-9% ~) | 37.4 (-33% ~) | 18.4 (-52%) | 29.96 (+67%) | 56.2 (+75%) | 8 (+1400%) | 91 | 61 |
| nocache | ini | 4 | 79.0 (+5% ~) | 61.6 (+10% ~) | 44.2 (+16%) | 16.37 (-9% ~) | 32.8 (+2% ~) | 2 (+200%) | 98 | 45 |

Each cell: median over the variant's slots; the change is against `base`, `~` = under the larger of 5 % and the slot-to-slot spread of the two.

Slot-to-slot spread of avg fps (min - max, % of median):

- base: 72.2, 76.2, 83.6, 74.7 (15.1 %)
- nopt: 73.5, 86.5, 87.1, 60.2 (33.6 %)
- nosb: 54.1, 78.9, 81.5, 57.8 (40.1 %)
- nocache: 73.5, 72.6, 84.4, 84.7 (15.3 %)

## Avg fps by heading sector

| variant | N 0° | NE 45° | E 90° | SE 135° | S 180° | SW 225° | W 270° | NW 315° | worst |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 69.5 | 71.0 | 85.2 | 97.5 | 86.5 | 69.4 | 63.1 | 65.2 | W 270° |
| nopt | 71.5 (+3%) | 72.7 (+2%) | 90.2 (+6%) | 109.3 (+12%) | 93.4 (+8%) | 72.6 (+5%) | 66.9 (+6%) | 66.5 (+2%) | NW 315° |
| nosb | 56.5 (-19%) | 62.6 (-12%) | 78.6 (-8%) | 96.2 (-1%) | 88.7 (+2%) | 68.8 (-1%) | 57.5 (-9%) | 58.2 (-11%) | N 0° |
| nocache | 72.5 (+4%) | 73.0 (+3%) | 89.5 (+5%) | 103.1 (+6%) | 91.7 (+6%) | 73.1 (+5%) | 68.6 (+9%) | 68.0 (+4%) | NW 315° |

## Slots

| # | variant | s | frames | avg fps | 1% low | hitches | lap fps |
|---:|---|---:|---:|---:|---:|---:|---|
| 1 | base | 24.0 | 1733 | 72.2 | 51.4 | 1 | 70.8, 73.6 |
| 2 | nopt | 24.0 | 1765 | 73.5 | 52.9 | 1 | 75.2, 71.8 |
| 3 | nosb | 24.0 | 1298 | 54.1 | 19.9 | 64 | 68.0, 40.2 |
| 4 | nocache | 24.0 | 1762 | 73.5 | 31.7 | 3 | 75.3, 71.6 |
| 5 | nocache | 24.0 | 1742 | 72.6 | 55.8 | 6 | 76.6, 68.7 |
| 6 | nosb | 24.0 | 1893 | 78.9 | 49.7 | 2 | 78.2, 79.6 |
| 7 | nopt | 24.0 | 2075 | 86.5 | 66.7 | 0 | 86.1, 86.9 |
| 8 | base | 24.0 | 1829 | 76.2 | 60.7 | 0 | 76.4, 76.0 |
| 9 | base | 24.0 | 2006 | 83.6 | 66.8 | 0 | 83.7, 83.4 |
| 10 | nopt | 24.0 | 2090 | 87.1 | 67.3 | 0 | 87.0, 87.2 |
| 11 | nosb | 24.0 | 1955 | 81.5 | 61.3 | 0 | 81.5, 81.5 |
| 12 | nocache | 24.0 | 2025 | 84.4 | 68.6 | 0 | 84.9, 83.9 |
| 13 | nocache | 24.0 | 2032 | 84.7 | 67.5 | 0 | 84.4, 84.9 |
| 14 | nosb | 24.0 | 1388 | 57.8 | 25.1 | 13 | 62.1, 53.6 |
| 15 | nopt | 24.0 | 1446 | 60.2 | 24.5 | 19 | 79.0, 41.5 |
| 16 | base | 24.0 | 1791 | 74.7 | 34.3 | 4 | 76.3, 73.1 |

A hitch is a frame longer than max(2 x the window's median, 40 ms); 1% / 0.1% low = 1000 / the 99th / 99.9th percentile frame time. Sectors are 45 degrees centred on the compass points (heading 0 = north).
