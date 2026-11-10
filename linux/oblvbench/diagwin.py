"""Which part of the fix's diagnostic CSVs to rank: the measured windows, without the runner's sync stalls.

The runner busy-loops the game thread for ~350 ms twice (before the warm-up and after the last scene) so the
MangoHud log can be aligned. HitchLedger records both as slow frames ("unlabelled: before the world tick"), so the
tools are pointed at the measured time range only, and never within MARGIN_S of a stall."""
from . import spin

MARGIN_S = 1.0


def ledger_range(ledger_text, markers, windows, margin=MARGIN_S):
    """Dict for result.json: the ledger-clock stalls and the [fromMs, toMs] range (ledger end_ms clock, the one
    stutter_ledger.py and tick_split.py take) covering `windows` (wall-clock (t0, t1) pairs) minus +-margin of each
    stall. fromMs/toMs are None when the ledger's clock cannot be anchored on the markers."""
    out = {"marginS": margin, "windowsWall": [[round(a, 3), round(b, 3)] for a, b in windows],
           "stallsWall": [round(w, 3) for w, _ in markers], "fromMs": None, "toMs": None, "offsetS": None}
    if not windows:
        out["note"] = "no measured windows"
        return out
    offset = spin.anchor_ledger(spin.ledger_frames(ledger_text), markers)
    if offset is None:
        out["note"] = ("the ledger's clock could not be matched to the sync stalls (needs both markers and a unique "
                       "pair of ~350 ms frames): the ranking covers the whole session, stalls included")
        return out
    lo = min(a for a, _ in windows)
    hi = max(b for _, b in windows)
    mid = (lo + hi) / 2
    for w, _ in sorted(markers):
        if w - margin < hi and w + margin > lo:           # the stall touches the measured range: cut it away
            if w < mid:
                lo = max(lo, w + margin)
            else:
                hi = min(hi, w - margin)
    out["offsetS"] = round(offset, 3)
    out["stallsLedgerMs"] = [round((w - offset) * 1000, 1) for w, _ in markers]
    out["fromMs"] = round((lo - offset) * 1000, 1)
    out["toMs"] = round((hi - offset) * 1000, 1)
    out["note"] = (f"ranked over the measured windows only ({hi - lo:.0f} s of wall clock from the first scene/slot to "
                   f"the last), without +-{margin:g} s around each sync stall; unfiltered csv files and "
                   "*-unfiltered.txt kept")
    return out


def exclusions(markers, margin=MARGIN_S):
    """Wall-clock (lo, hi) ranges around the sync stalls, for spin.split_ledger."""
    return [(w - margin, w + margin) for w, _ in markers]
