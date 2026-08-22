"""validate-spec helper modules — per-check structured parsers.

Each helper module is invoked as a script via `python <path> [args]` per the
save-verdict R2 LOCKED invocation contract; module-importability is a
side-benefit of the `if __name__ == "__main__"` idiom, not the contract.

Per-check helper mapping:
    spec_refs.py    — check-1: §-reference resolver
    bw_tickets.py   — check-2 + check-3: bw ticket existence + status + §13 placement walk
    drift_check.py  — check-6: invoke check-substrate-updates/check.sh; parse composite-status output
    trailers.py     — check-7: git log trailer-detection with bb12806 carve-out + post-Arc-40 ancestry
"""
