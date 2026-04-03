# ClawBio PharmGx Safety Benchmark

A reproducible benchmark for evaluating pharmacogenomics safety behavior in ClawBio's PharmGx Reporter. Produces machine-readable JSON verdicts scored against CPIC ground truth.

## What This Tests

ClawBio's `pharmgx_reporter.py` parses DTC genetic data (23andMe/AncestryDNA format), calls star alleles for 12 pharmacogenes, and outputs drug recommendations for 51 medications. This benchmark evaluates **safety behavior** — not variant detection capability — across three finding categories:

| Category | Description | Example |
|----------|-------------|---------|
| **Correctness Defects** | Pure software bugs producing wrong output | Warfarin silently disappears from report (TypeError from tuple dict keys) |
| **Communication Defects** | Tool knows something is wrong but doesn't tell the user | Structural variant warnings go to stderr only, not the report |
| **Unsafe Inference** | Absence of data treated as evidence of normality | DPYD 1/3 SNPs tested → "Normal Metabolizer" |

## Benchmark Design

- **16 synthetic 23andMe-format test files** with pre-specified ground truth per CPIC guidelines
- **6-category scoring rubric**: Correct-Determinate, Correct-Indeterminate, Incorrect-Determinate, Incorrect-Indeterminate, Omission, Disclosure Failure
- **Three-commit comparison**: pre-patch, patch (`bbad73c`), HEAD (`3c9383b`)
- **Full longitudinal mode**: run against all 187 commits for safety trajectory heatmap
- **Machine-readable JSON output** per (commit, input) pair

## Quick Start

```bash
# Clone this repo and the target
git clone <this-repo> benchmark/
git clone https://github.com/manuelcorpas/ClawBio

# Three-commit comparison
python3 benchmark/run_benchmark.py \
  --repo ClawBio \
  --commits 8292a739,bbad73c1,3c9383b1 \
  --inputs benchmark/test_inputs/

# Full longitudinal sweep (~1.7 hours)
python3 benchmark/run_benchmark.py \
  --repo ClawBio \
  --all-commits \
  --inputs benchmark/test_inputs/
```

## Results (3-Commit Comparison, 2026-04-03)

| Commit | Date | Pass | Fail | Disclosure | Omission | Pass Rate |
|--------|------|:----:|:----:|:----------:|:--------:|:---------:|
| Pre-patch (`8292a739`) | 2026-02-28 | 7 | 4 | 3 | 2 | 43.8% |
| Patch (`bbad73c`) | 2026-02-28 | 8 | 2 | 4 | 2 | 50.0% |
| HEAD (`3c9383b`) | 2026-03-10 | 8 | 2 | 4 | 2 | 50.0% |

**Key findings:**
- Patch fixed exactly 2 tests (`dpyd_absent`, `empty_no_pgx`). All other results identical.
- 137 commits between patch and HEAD changed zero safety behaviors.
- Warfarin tuple bug exists in **all three commits** (pre-existing, not a regression).
- Warfarin bug crashes `json.dumps` with `TypeError: keys must be str, not tuple`.

## Test Suite

| Test | Category | Target | Hazard Drug | CPIC Ref |
|------|----------|--------|-------------|----------|
| `ugt1a1_28_hom` | Disclosure failure | UGT1A1 | Irinotecan | CPIC Irinotecan v2.0 |
| `ugt1a1_28_het` | Disclosure failure | UGT1A1 | Irinotecan | CPIC Irinotecan v2.0 |
| `ugt1a1_28_absent` | Incorrect determinate | UGT1A1 | Irinotecan | CPIC Irinotecan v2.0 |
| `ugt1a1_neg` | Correct (control) | UGT1A1 | Irinotecan | CPIC Irinotecan v2.0 |
| `dpyd_2a_het` | Correct (control) | DPYD | Fluorouracil | CPIC Fluoropyrimidine v3.0 |
| `dpyd_2a_hom` | Correct (control) | DPYD | Fluorouracil | CPIC Fluoropyrimidine v3.0 |
| `dpyd_neg` | Correct (control) | DPYD | Fluorouracil | CPIC Fluoropyrimidine v3.0 |
| `dpyd_partial` | Incorrect determinate | DPYD | Fluorouracil | CPIC Fluoropyrimidine v3.0 |
| `dpyd_absent` | Correct indeterminate | DPYD | Fluorouracil | CPIC Fluoropyrimidine v3.0 |
| `cyp2d6_normal` | Disclosure failure | CYP2D6 | Codeine | CPIC Opioid v3.0 |
| `cyp2d6_pm` | Correct (control) | CYP2D6 | Codeine | CPIC Opioid v3.0 |
| `cyp2d6_del` | Disclosure failure | CYP2D6 | Codeine | CPIC Opioid v3.0 |
| `warfarin_normal` | Correct (control) | VKORC1 | Warfarin | CPIC Warfarin v2.0 |
| `warfarin_missing_vkorc1` | Omission | VKORC1 | Warfarin | CPIC Warfarin v2.0 |
| `warfarin_missing_both` | Omission | CYP2C9 | Warfarin | CPIC Warfarin v2.0 |
| `empty_no_pgx` | Correct (control) | N/A | N/A | N/A |

## Output Structure

```
results/<timestamp>/
  manifest.json           # Run metadata, input checksums, environment
  all_verdicts.json       # Every (commit, input) verdict
  heatmap_data.json       # Commits x tests matrix for visualization
  summary.json            # Per-commit statistics
  <commit_sha>/
    <test_name>/
      verdict.json        # Detailed scoring with ground truth
      stdout.log          # Tool stdout
      stderr.log          # Tool stderr (where warnings go)
      tool_output/
        report.md         # Generated report
        report.html       # Generated HTML report
        result.json       # Tool's JSON output
```

## Ground Truth Sources

| Source | Version | Use |
|--------|---------|-----|
| CPIC Opioid Guideline | v3.0 (2023) | CYP2D6 + codeine/tramadol |
| CPIC Fluoropyrimidine Guideline | v3.0 (2018, updated 2023) | DPYD + 5-FU |
| CPIC Irinotecan Guideline | v2.0 (2020) | UGT1A1 + irinotecan |
| CPIC Warfarin Guideline | v2.0 (2017) | CYP2C9/VKORC1 + warfarin |
| FDA Codeine Label | Boxed Warning (2017) | CYP2D6 UM contraindication |
| PharmVar CYP2D6 | Accessed 2026-04-03 | Allele definitions |

## License

Benchmark code: MIT. Ground truth derived from publicly available CPIC guidelines.
This benchmark does not include or modify ClawBio source code.
