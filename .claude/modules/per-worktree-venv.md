# Per-worktree virtualenv reflex (Python projects) — instruction module

> Relocated from `MAJOR_PLINY.md` §5.4 (CONDITIONAL — read on fresh worktree in a Python
> editable-install project). Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md`
> + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.4
> stub + routing-map row (fresh worktree, Python editable) + relocation-index row in §4.2.

When a project uses `pip install -e` editable installs (Python projects), two parallel worktrees of the same source tree share the virtualenv state — and the `pip install -e` source path resolves to whichever worktree was installed last. Two parallel worktrees can produce import-from-the-other-worktree behavior under test, where code under test imports from the inactive worktree's source tree rather than the active one.

**Reflex:** when PLINY creates a fresh worktree for a build dispatch in a Python `pip install -e`-shaped project, also create + activate a `.venv` per-worktree (not shared with the source repo's main `.venv`). One-time ~30s cost per fresh worktree; eliminates the cross-worktree mutation entirely.

**Detection:** project uses `pip install -e .[dev]` (or similar editable-install pattern); or PRINCIPAL flags it; or surface the question in the activation phase if uncertain. The reflex is project-class-specific — it does not apply to non-Python projects, and it does not apply to Python projects that don't use editable installs.

This lives alongside the historical `.git/config` promote-and-drop reflex, which is now demoted (see `operating-disciplines.md` §9 status update). Together, the two reflexes express a more general pattern: on fresh worktree, apply project-class-specific setup steps before dispatching. The per-worktree `.venv` is the Python-project member of that family.

**Out of scope:** non-Python projects; non-`pip install -e` Python projects; wrapper-script automation for the .venv creation (the discipline ships; tooling does not).

Anchor: `stoa--xyb.10.1` (C-2 archive child ticket; orig `ariadne--b93`) — the empirical anchor for this reflex was filed cross-repo at `ariadne--b93` (ariadne-core-workspace, 2026-05-08, during the `ariadne--rld` arc-close as a sideband observation), which does NOT resolve in the-stoa bw; the verbose provenance is archived in the-stoa bw at the C-2 child ticket. Recover via `bw show stoa--xyb.10.1`.
