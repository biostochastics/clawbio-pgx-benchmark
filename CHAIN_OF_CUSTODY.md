# Chain of Custody — ClawBio PharmGx Benchmark

## Repository State Archive

| Field | Value |
|-------|-------|
| **Archive Date** | 2026-04-03T22:06:18Z |
| **Repository** | https://github.com/manuelcorpas/ClawBio |
| **HEAD commit** | `3c9383b136b6ab6d721e8e578c7d75d2d5a43621` |
| **HEAD date** | 2026-03-10 21:47:08 +0000 |
| **HEAD message** | Merge pull request #39 from jaymoore-research/add-data-extractor-skill |
| **Total commits** | 187 |
| **Tags** | v0.2.0, v0.3.0, v0.3.1 |
| **HEAD SHA-256** | `642406e49fa84f79bac505b168c78d750c1a2b1f581fab203296da56f0ad350b` |

## Key Commits for Three-Commit Comparison

| Commit | SHA | Date | Description |
|--------|-----|------|-------------|
| **Pre-patch** | Parent of `bbad73c` | 2026-02-28 | Last commit before silent degradation fix |
| **Patch** | `bbad73c1cd99720cb5925fdd63e4c79b988e1957` | 2026-02-28 21:37:28 +0000 | "Fix silent degradation across all 4 skills" |
| **HEAD** | `3c9383b136b6ab6d721e8e578c7d75d2d5a43621` | 2026-03-10 21:47:08 +0000 | Current state |

## Benchmark Materials

All synthetic test inputs, harness code, and ground truth specifications are in:
- `scripts/benchmark/test_inputs/` — 16 synthetic 23andMe-format test files
- `scripts/benchmark/run_benchmark.py` — Benchmark harness (produces JSON verdicts)
- `scripts/benchmark/CHAIN_OF_CUSTODY.md` — This document

## Evidence Policy

- SHA-256 checksums of all inputs and outputs
- UTC timestamps on all executions
- Git commit metadata preserved per run
- Ground truth pre-specified per CPIC/PharmVar/FDA, version-pinned
- Offline execution (`--no-enrich`) for determinism
- No modification of ClawBio source code (read-only checkout per commit)

## Audit Timeline

| Date | Event |
|------|-------|
| 2026-02-28 | Original audit commenced (16-task, 4-phase plan) |
| 2026-02-28 | Developer patch `bbad73c` — 32 claimed fixes |
| 2026-03-10 | Re-audit completed — 50% fix verification rate, 45 new findings |
| 2026-04-03 | Benchmark harness and synthetic test suite constructed |
| 2026-04-03 | Repository state archived at HEAD `3c9383b` |

## Archival Notes

The repository state at HEAD `3c9383b` is the version under test.
All runs execute against locally archived commit SHAs.
