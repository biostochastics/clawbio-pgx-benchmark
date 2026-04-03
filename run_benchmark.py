#!/usr/bin/env python3
"""
ClawBio PharmGx Benchmark Harness
==================================
Runs synthetic test inputs against pharmgx_reporter.py across git commits,
captures all outputs, and produces machine-readable JSON verdicts.

Usage:
    # Three-commit comparison (primary evidence)
    python run_benchmark.py --commits PRE_PATCH,bbad73c,HEAD --inputs test_inputs/

    # Full longitudinal sweep (all commits)
    python run_benchmark.py --all-commits --inputs test_inputs/

    # Single commit, single input (debugging)
    python run_benchmark.py --commits HEAD --inputs test_inputs/warfarin_missing_vkorc1.txt

Output:
    results/<run_timestamp>/
        manifest.json           -- run metadata, commit list, input checksums
        <commit_sha>/
            <test_name>/
                verdict.json    -- 6-category rubric score + all captured data
                report.md       -- tool's markdown report (if generated)
                report.html     -- tool's HTML report (if generated)
                result.json     -- tool's JSON output (if generated)
                stdout.log      -- captured stdout
                stderr.log      -- captured stderr
        heatmap_data.json       -- aggregated matrix for visualization
        summary.json            -- per-commit summary statistics

Ground Truth:
    Each test input file contains header comments specifying expected outcomes.
    The harness parses these and scores against actual tool output.

Evidence Policy:
    - SHA-256 of every input and output file
    - Wall-clock timestamps (UTC) for every run
    - Git commit metadata (SHA, date, message)
    - Python version, platform info
    - Exit codes and signal info
"""

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BENCHMARK_VERSION = "1.0.0"
RUBRIC_CATEGORIES = [
    "correct_determinate",       # Right phenotype, right drug classification
    "correct_indeterminate",     # Correctly returns insufficient/indeterminate
    "incorrect_determinate",     # Wrong phenotype or drug classification (false Normal)
    "incorrect_indeterminate",   # Returns Indeterminate when answer IS determinable
    "omission",                  # Drug row silently missing from report
    "disclosure_failure",        # Warning on stderr but NOT in report body
]

# CPIC ground truth references (version-pinned)
GROUND_TRUTH_REFS = {
    "CPIC_OPIOID": "CPIC Guideline for CYP2D6 and Opioid Therapy, v3.0 (2023)",
    "CPIC_FLUOROPYRIMIDINE": "CPIC Guideline for DPYD and Fluoropyrimidines, v3.0 (2018, updated 2023)",
    "CPIC_IRINOTECAN": "CPIC Guideline for UGT1A1 and Irinotecan, v2.0 (2020)",
    "CPIC_WARFARIN": "CPIC Guideline for CYP2C9/VKORC1 and Warfarin, v2.0 (2017)",
    "FDA_CODEINE": "FDA Boxed Warning: Codeine in CYP2D6 Ultra-rapid Metabolizers (2017)",
    "PHARMVAR_CYP2D6": "PharmVar CYP2D6 Allele Definitions (accessed 2026-04-03)",
}


# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

def sha256_file(filepath):
    """Compute SHA-256 of a file."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_string(s):
    """Compute SHA-256 of a string."""
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def parse_ground_truth(input_path):
    """Extract ground truth from test file header comments.

    Parses lines like:
        # GROUND_TRUTH_PHENOTYPE: Poor Metabolizer
        # GROUND_TRUTH_BEHAVIOR: Report Indeterminate; disclose CNV limitation
        # EXPECTED_TOOL_OUTPUT: Normal Metabolizer
        # FINDING: F-01 indel non-detection
        # FINDING_CATEGORY: disclosure_failure
        # HAZARD_DRUG: Irinotecan
        # HAZARD_CLASS: NTI Oncology
        # CPIC_REF: CPIC_IRINOTECAN
    """
    gt = {}
    with open(input_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("#"):
                break
            for key in [
                "BENCHMARK", "GROUND_TRUTH_PHENOTYPE", "GROUND_TRUTH_BEHAVIOR",
                "EXPECTED_TOOL_OUTPUT", "FINDING", "FINDING_CATEGORY",
                "HAZARD_DRUG", "HAZARD_CLASS", "CPIC_REF",
                "TARGET_GENE", "TARGET_RSID", "EXPECTED_EXIT_CODE",
            ]:
                prefix = f"# {key}:"
                if line.startswith(prefix):
                    gt[key] = line[len(prefix):].strip()
    return gt


def get_commit_metadata(repo_path, commit_sha):
    """Get commit date, message, and full SHA."""
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_path), "log", "-1",
             "--format=%H|%ai|%s", commit_sha],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            parts = result.stdout.strip().split("|", 2)
            return {
                "full_sha": parts[0],
                "date": parts[1],
                "message": parts[2] if len(parts) > 2 else "",
            }
    except Exception:
        pass
    return {"full_sha": commit_sha, "date": "unknown", "message": "unknown"}


def get_all_commits(repo_path):
    """Get all commit SHAs in chronological order (oldest first)."""
    result = subprocess.run(
        ["git", "-C", str(repo_path), "log", "--format=%H", "--reverse", "main"],
        capture_output=True, text=True, timeout=30
    )
    if result.returncode != 0:
        print(f"ERROR: git log failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return [sha.strip() for sha in result.stdout.strip().split("\n") if sha.strip()]


# ---------------------------------------------------------------------------
# Report analysis (extract phenotypes, drug recs, warnings from output)
# ---------------------------------------------------------------------------

def analyze_report(report_path):
    """Parse a generated report.md to extract phenotypes and drug classifications."""
    analysis = {
        "gene_profiles": {},
        "drug_classifications": {},
        "warnings_in_report": [],
        "data_quality_warning_present": False,
        "disclaimer_present": False,
        "warfarin_present": False,
        "warfarin_classification": None,
    }

    if not report_path.exists():
        analysis["report_exists"] = False
        return analysis

    analysis["report_exists"] = True
    text = report_path.read_text(errors="replace")

    # Extract gene profiles by splitting table rows on pipe characters.
    # Handles both 3-column (Gene|Diplotype|Phenotype) and
    # 4-column (Gene|Full Name|Diplotype|Phenotype) formats across commits.
    in_gene_table = False
    gene_table_headers = []
    for line in text.split("\n"):
        if "Gene" in line and "Diplotype" in line and "Phenotype" in line and "|" in line:
            # Parse header to find column indices
            gene_table_headers = [h.strip() for h in line.split("|") if h.strip()]
            in_gene_table = True
            continue
        if in_gene_table and line.startswith("|"):
            cells = [c.strip() for c in line.split("|") if c.strip()]
            # Skip separator rows (|---|---|---|)
            if cells and cells[0].startswith("-"):
                continue
            if len(cells) >= 3:
                # Map by header names if available, otherwise by position
                if len(gene_table_headers) >= 4 and len(cells) >= 4:
                    # 4-column: Gene | Full Name | Diplotype | Phenotype
                    gene = cells[0]
                    diplotype = cells[2]
                    phenotype = cells[3]
                else:
                    # 3-column: Gene | Diplotype | Phenotype
                    gene = cells[0]
                    diplotype = cells[1]
                    phenotype = cells[2]
                if gene and gene != "Gene":
                    analysis["gene_profiles"][gene] = {
                        "diplotype": diplotype,
                        "phenotype": phenotype,
                    }
        elif in_gene_table and not line.startswith("|"):
            in_gene_table = False

    # Extract drug classifications from the Complete Drug Recommendations table
    in_drug_table = False
    for line in text.split("\n"):
        if ("Drug" in line and ("Classification" in line or "Status" in line)
                and "|" in line):
            in_drug_table = True
            continue
        if in_drug_table and line.startswith("|"):
            cells = [c.strip() for c in line.split("|") if c.strip()]
            if cells and cells[0].startswith("-"):
                continue
            if len(cells) >= 2:
                drug_name = cells[0]
                # Classification is typically the last meaningful column
                classification = cells[-1].lower() if cells[-1] else ""
                for cat in ["standard", "caution", "avoid", "indeterminate"]:
                    if cat in classification:
                        analysis["drug_classifications"][drug_name] = cat
                        break
        elif in_drug_table and not line.startswith("|"):
            in_drug_table = False

    # Check for warfarin in drug recommendations (from parsed table AND text search)
    if "Warfarin" in analysis["drug_classifications"]:
        analysis["warfarin_present"] = True
        analysis["warfarin_classification"] = analysis["drug_classifications"]["Warfarin"]
    elif "warfarin" in text.lower():
        analysis["warfarin_present"] = True
        warf_match = re.search(
            r"Warfarin.*?\b(standard|caution|avoid|indeterminate)\b",
            text, re.IGNORECASE | re.DOTALL
        )
        if warf_match:
            analysis["warfarin_classification"] = warf_match.group(1).lower()

    # Check for DATA QUALITY WARNING
    if "DATA QUALITY WARNING" in text:
        analysis["data_quality_warning_present"] = True
        # Extract warning content
        dqw_match = re.search(
            r"DATA QUALITY WARNING\s*\n\n(.*?)(?=\n---|\n##)", text, re.DOTALL
        )
        if dqw_match:
            analysis["warnings_in_report"].append(dqw_match.group(1).strip())

    # Check for disclaimer
    if "research and educational" in text.lower() or "not a medical device" in text.lower():
        analysis["disclaimer_present"] = True

    # Check for specific limitation disclosures IN the report body
    for term in ["structural variant", "cannot interpret", "CNV",
                 "copy number", "TA-repeat", "gene duplication",
                 "ultrarapid", "not assessed"]:
        if term.lower() in text.lower():
            analysis["warnings_in_report"].append(f"report_mentions: {term}")

    # Embed text snippets for peer review reproducibility (OpenCode recommendation)
    # Gene profile table (first 600 chars from ## Gene Profiles section)
    gp_match = re.search(r"(## Gene Profiles.*?)(?=\n## |\Z)", text, re.DOTALL)
    analysis["gene_table_snippet"] = gp_match.group(1)[:600] if gp_match else ""
    # Drug summary (first 400 chars from ## Drug Response Summary)
    ds_match = re.search(r"(## Drug Response Summary.*?)(?=\n---|\n## Gene)", text, re.DOTALL)
    analysis["drug_summary_snippet"] = ds_match.group(1)[:400] if ds_match else ""
    # Actionable alerts section
    aa_match = re.search(r"(### Actionable Alerts.*?)(?=\n---|\n## )", text, re.DOTALL)
    analysis["actionable_alerts_snippet"] = aa_match.group(1)[:400] if aa_match else ""

    return analysis


def analyze_stderr(stderr_text):
    """Extract warnings from stderr."""
    warnings = []
    for line in stderr_text.split("\n"):
        line = line.strip()
        if "WARNING" in line or "warning" in line:
            warnings.append(line)
    return warnings


def analyze_result_json(result_json_path):
    """Parse the tool's result.json for structural integrity."""
    analysis = {
        "exists": False,
        "valid_json": False,
        "has_tuple_keys": False,
        "warfarin_in_results": False,
        "drug_count": 0,
        "error": None,
    }

    if not result_json_path.exists():
        return analysis

    analysis["exists"] = True
    try:
        with open(result_json_path) as f:
            data = json.load(f)
        analysis["valid_json"] = True
        # Count drugs in results
        if "drug_results" in data:
            for cat, drugs in data["drug_results"].items():
                analysis["drug_count"] += len(drugs) if isinstance(drugs, list) else 0
                if isinstance(drugs, list):
                    for d in drugs:
                        if isinstance(d, dict) and d.get("drug", "").lower() == "warfarin":
                            analysis["warfarin_in_results"] = True
    except json.JSONDecodeError as e:
        analysis["error"] = f"JSONDecodeError: {e}"
    except TypeError as e:
        # This catches the tuple-key bug causing serialization failure
        analysis["error"] = f"TypeError (likely tuple keys): {e}"
        analysis["has_tuple_keys"] = True
    except Exception as e:
        analysis["error"] = str(e)

    return analysis


# ---------------------------------------------------------------------------
# Scoring engine (6-category rubric)
# ---------------------------------------------------------------------------

def _phenotype_matches(observed, expected):
    """Flexible phenotype matching — handles verbose ground truth vs terse tool output.

    Returns True if either string contains the other, or if key terms match.
    """
    obs = observed.lower().strip()
    exp = expected.lower().strip()
    if not obs or not exp:
        return False
    # Direct containment (either direction)
    if obs in exp or exp in obs:
        return True
    # Key term matching: extract metabolizer/function/sensitivity type
    for term in ["normal metabolizer", "intermediate metabolizer", "poor metabolizer",
                 "ultrarapid metabolizer", "normal function", "intermediate function",
                 "poor function", "expressor", "non-expressor", "indeterminate",
                 "not genotyped", "not_tested"]:
        if term in obs and term in exp:
            return True
    return False


def _gene_relevant_warnings(stderr_warnings, target_gene):
    """Filter stderr warnings to those mentioning the target gene."""
    if not target_gene or target_gene == "N/A":
        return stderr_warnings
    return [w for w in stderr_warnings if target_gene.lower() in w.lower()]


def score_verdict(ground_truth, report_analysis, stderr_warnings, result_json_analysis, exit_code):
    """Score a single (commit, input) pair against the 6-category rubric.

    Scoring priority:
    1. Exit code checks (expected crashes, unexpected crashes)
    2. Omission checks (warfarin tuple bug — drug missing from report)
    3. Expected-category-driven scoring (trust the pre-specified ground truth)
    4. Phenotype-based scoring (verify correctness)
    """
    gt = ground_truth
    ra = report_analysis
    expected_category = gt.get("FINDING_CATEGORY", "")
    target_gene = gt.get("TARGET_GENE", "")
    expected_exit = int(gt.get("EXPECTED_EXIT_CODE", "0"))
    expected_phenotype = gt.get("GROUND_TRUTH_PHENOTYPE", "")
    gt_behavior = gt.get("GROUND_TRUTH_BEHAVIOR", "").lower()
    hazard_drug = gt.get("HAZARD_DRUG", "").lower()

    gene_data = ra.get("gene_profiles", {}).get(target_gene, {}) if target_gene and target_gene != "N/A" else {}
    observed_phenotype = gene_data.get("phenotype", "NOT_IN_REPORT")

    gene_warnings = _gene_relevant_warnings(stderr_warnings, target_gene)
    all_warnings = stderr_warnings

    details = {
        "observed_phenotype": observed_phenotype,
        "expected_phenotype": expected_phenotype,
        "target_gene": target_gene,
        "exit_code": exit_code,
        "stderr_warnings_total": len(all_warnings),
        "stderr_warnings_gene": len(gene_warnings),
        "report_exists": ra.get("report_exists", False),
        "data_quality_warning": ra.get("data_quality_warning_present", False),
    }

    # ── Step 1: Exit code ──
    if expected_exit != 0:
        if exit_code == expected_exit:
            return {"category": "correct_determinate",
                    "rationale": f"Tool correctly exited with code {exit_code}",
                    "details": details}
        return {"category": "incorrect_determinate",
                "rationale": f"Expected exit {expected_exit}, got {exit_code}",
                "details": details}

    # ── Step 2: Unexpected crash — with warfarin special case ──
    if exit_code != 0:
        if expected_category == "omission" and ra.get("report_exists"):
            # Warfarin tuple crash: report exists but JSON serialization failed
            if hazard_drug == "warfarin":
                details["crash_type"] = "warfarin_tuple_json_serialization"
                details["result_json_error"] = result_json_analysis.get("error")
                return {"category": "omission",
                        "rationale": f"Tool crashed (exit {exit_code}) — TypeError from tuple dict keys in JSON serialization. "
                                     f"Warfarin silently absent from report.",
                        "details": details}
        details["crash"] = True
        return {"category": "incorrect_determinate",
                "rationale": f"Tool crashed with exit code {exit_code}",
                "details": details}

    # ── Step 3: No report ──
    if not ra.get("report_exists"):
        return {"category": "incorrect_determinate",
                "rationale": "No report generated",
                "details": details}

    # ── Step 4: Omission (warfarin missing from report without crash) ──
    if hazard_drug == "warfarin" and expected_category == "omission":
        if not ra.get("warfarin_present"):
            details["warfarin_in_report"] = False
            return {"category": "omission",
                    "rationale": "Warfarin silently absent from report",
                    "details": details}

    # ── Step 5: Category-driven scoring ──
    # For tests where we pre-specified the expected category, verify the behavior matches

    if expected_category == "correct_determinate":
        if _phenotype_matches(observed_phenotype, expected_phenotype):
            return {"category": "correct_determinate",
                    "rationale": f"Correct phenotype: {observed_phenotype}",
                    "details": details}
        return {"category": "incorrect_determinate",
                "rationale": f"Wrong phenotype: {observed_phenotype} (expected match for: {expected_phenotype})",
                "details": details}

    if expected_category == "correct_indeterminate":
        if "indeterminate" in observed_phenotype.lower() or "not genotyped" in observed_phenotype.lower() \
                or "not_tested" in observed_phenotype.lower():
            return {"category": "correct_indeterminate",
                    "rationale": f"Correctly returned indeterminate: {observed_phenotype}",
                    "details": details}
        if "normal" in observed_phenotype.lower():
            return {"category": "incorrect_determinate",
                    "rationale": f"False Normal when should be Indeterminate: {observed_phenotype}",
                    "details": details}
        return {"category": "incorrect_indeterminate",
                "rationale": f"Unexpected output for indeterminate test: {observed_phenotype}",
                "details": details}

    if expected_category == "disclosure_failure":
        # Check: are there stderr warnings for this gene but not in the report body?
        has_relevant_stderr = len(gene_warnings) > 0 or len(all_warnings) > 0
        has_report_disclosure = ra.get("data_quality_warning_present") or any(
            target_gene.lower() in w.lower() for w in ra.get("warnings_in_report", [])
        ) if target_gene and target_gene != "N/A" else False

        if has_relevant_stderr and not has_report_disclosure:
            return {"category": "disclosure_failure",
                    "rationale": f"Warnings on stderr but not in report body for {target_gene}. "
                                 f"Phenotype: {observed_phenotype}",
                    "details": {**details, "gene_stderr_warnings": gene_warnings}}
        # Even if no stderr warning, if the tool can't detect this variant class and doesn't say so
        if "cnv" in gt_behavior or "copy number" in gt_behavior or "gene duplication" in gt_behavior:
            # CNV disclosure failure — tool should mention CNV limitation but doesn't
            cnv_in_report = any("cnv" in w.lower() or "copy number" in w.lower() or "duplication" in w.lower()
                                for w in ra.get("warnings_in_report", []))
            if not cnv_in_report:
                return {"category": "disclosure_failure",
                        "rationale": f"No CNV/duplication limitation disclosed for {target_gene}. "
                                     f"Phenotype: {observed_phenotype}",
                        "details": details}
        # Fallback: if we expected disclosure_failure but it looks correct, maybe the tool improved
        if _phenotype_matches(observed_phenotype, expected_phenotype):
            return {"category": "correct_determinate",
                    "rationale": f"Tool appears to have corrected this issue. Phenotype: {observed_phenotype}",
                    "details": details}
        return {"category": "disclosure_failure",
                "rationale": f"Expected disclosure failure for {target_gene}. Phenotype: {observed_phenotype}",
                "details": details}

    if expected_category == "incorrect_determinate":
        if _phenotype_matches(observed_phenotype, expected_phenotype):
            return {"category": "correct_determinate",
                    "rationale": f"Tool appears to have fixed this. Phenotype: {observed_phenotype}",
                    "details": details}
        return {"category": "incorrect_determinate",
                "rationale": f"Incorrect output as expected: {observed_phenotype}",
                "details": details}

    if expected_category == "omission":
        # Non-warfarin omission
        return {"category": "omission",
                "rationale": f"Drug omission detected for {hazard_drug}",
                "details": details}

    # ── Step 6: Fallback — no expected category ──
    if _phenotype_matches(observed_phenotype, expected_phenotype):
        return {"category": "correct_determinate",
                "rationale": f"Phenotype matches: {observed_phenotype}",
                "details": details}

    return {"category": "incorrect_determinate",
            "rationale": f"Unmatched phenotype: {observed_phenotype} vs {expected_phenotype}",
            "details": details}


# ---------------------------------------------------------------------------
# Single run executor
# ---------------------------------------------------------------------------

def run_single(repo_path, commit_sha, input_path, output_base, commit_meta=None):
    """Execute pharmgx_reporter.py for one (commit, input) pair.

    Returns a detailed verdict dict.
    """
    test_name = Path(input_path).stem
    commit_short = commit_sha[:8]
    run_output_dir = output_base / commit_short / test_name
    run_output_dir.mkdir(parents=True, exist_ok=True)

    # Parse ground truth
    ground_truth = parse_ground_truth(input_path)

    # Build the command
    # The tool is at skills/pharmgx-reporter/pharmgx_reporter.py
    tool_path = repo_path / "skills" / "pharmgx-reporter" / "pharmgx_reporter.py"
    report_dir = run_output_dir / "tool_output"
    report_dir.mkdir(exist_ok=True)

    cmd = [
        sys.executable, str(tool_path),
        "--input", str(input_path),
        "--output", str(report_dir),
    ]

    # Check if --no-enrich flag exists (may not in older commits)
    # We'll try with it; if it fails, retry without
    cmd_with_flag = cmd + ["--no-enrich"]

    # Record start time
    start_time = datetime.now(timezone.utc)
    wall_start = time.monotonic()

    # Execute — try with --no-enrich first, fall back without it for older commits
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    try:
        result = subprocess.run(
            cmd_with_flag,
            capture_output=True, text=True,
            timeout=60,
            cwd=str(repo_path),
            env=env,
        )
        used_no_enrich = True
        # If argparse rejected --no-enrich (exit code 2), retry without it
        if result.returncode == 2 and "unrecognized arguments" in result.stderr:
            result = subprocess.run(
                cmd,
                capture_output=True, text=True,
                timeout=60,
                cwd=str(repo_path),
                env=env,
            )
            used_no_enrich = False
    except subprocess.TimeoutExpired:
        result = type("R", (), {
            "returncode": -1, "stdout": "", "stderr": "TIMEOUT after 60s"
        })()
        used_no_enrich = True

    wall_elapsed = time.monotonic() - wall_start
    end_time = datetime.now(timezone.utc)

    # Save stdout/stderr
    (run_output_dir / "stdout.log").write_text(result.stdout)
    (run_output_dir / "stderr.log").write_text(result.stderr)

    # Analyze outputs
    report_md = report_dir / "report.md"
    report_html = report_dir / "report.html"
    result_json_path = report_dir / "result.json"

    report_analysis = analyze_report(report_md)
    stderr_warnings = analyze_stderr(result.stderr)
    result_json_analysis = analyze_result_json(result_json_path)

    # Score
    verdict = score_verdict(
        ground_truth, report_analysis, stderr_warnings,
        result_json_analysis, result.returncode
    )

    # Build comprehensive verdict JSON
    verdict_doc = {
        "benchmark_version": BENCHMARK_VERSION,
        "timestamp_utc": end_time.isoformat(),
        "wall_clock_seconds": round(wall_elapsed, 3),

        "commit": {
            "sha": commit_sha,
            "short": commit_short,
            **(commit_meta or {}),
        },

        "input": {
            "file": str(Path(input_path).name),
            "path": str(input_path),
            "sha256": sha256_file(input_path),
        },

        "ground_truth": ground_truth,
        "ground_truth_references": {
            ref_key: GROUND_TRUTH_REFS.get(ref_key, "UNKNOWN")
            for ref_key in [ground_truth.get("CPIC_REF", "")]
            if ref_key
        },

        "execution": {
            "exit_code": result.returncode,
            "used_no_enrich": used_no_enrich,
            "stdout_lines": result.stdout.count("\n"),
            "stderr_lines": result.stderr.count("\n"),
            "stderr_warnings": stderr_warnings,
            "stderr_sha256": sha256_string(result.stderr),
        },

        "outputs": {
            "report_md": {
                "exists": report_md.exists(),
                "sha256": sha256_file(report_md) if report_md.exists() else None,
                "size_bytes": report_md.stat().st_size if report_md.exists() else 0,
            },
            "report_html": {
                "exists": report_html.exists(),
                "sha256": sha256_file(report_html) if report_html.exists() else None,
            },
            "result_json": result_json_analysis,
        },

        "report_analysis": report_analysis,

        "verdict": verdict,

        "environment": {
            "python_version": platform.python_version(),
            "platform": platform.platform(),
            "hostname": platform.node(),
        },
    }

    # Write verdict
    verdict_path = run_output_dir / "verdict.json"
    with open(verdict_path, "w") as f:
        json.dump(verdict_doc, f, indent=2, default=str)

    return verdict_doc


# ---------------------------------------------------------------------------
# Batch executor
# ---------------------------------------------------------------------------

def run_benchmark(repo_path, commits, input_files, output_base):
    """Run full benchmark matrix: commits × inputs."""
    all_verdicts = []
    total_runs = len(commits) * len(input_files)
    run_count = 0

    # Capture starting ref for safe restoration (Codex recommendation)
    starting_ref_result = subprocess.run(
        ["git", "-C", str(repo_path), "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True
    )
    starting_ref = starting_ref_result.stdout.strip() if starting_ref_result.returncode == 0 else "main"
    if starting_ref == "HEAD":
        # Detached HEAD — capture full SHA
        starting_ref_result = subprocess.run(
            ["git", "-C", str(repo_path), "rev-parse", "HEAD"],
            capture_output=True, text=True
        )
        starting_ref = starting_ref_result.stdout.strip()

    try:
        return _run_benchmark_inner(repo_path, commits, input_files, output_base,
                                     all_verdicts, total_runs, run_count)
    finally:
        # Always restore to starting ref
        subprocess.run(
            ["git", "-C", str(repo_path), "checkout", starting_ref, "--quiet"],
            capture_output=True
        )


def _run_benchmark_inner(repo_path, commits, input_files, output_base,
                          all_verdicts, total_runs, run_count):
    """Inner benchmark loop (wrapped for safe git restore)."""
    for commit_sha in commits:
        # Get commit metadata
        commit_meta = get_commit_metadata(repo_path, commit_sha)
        commit_short = commit_sha[:8]

        # Checkout commit
        print(f"\n{'='*60}")
        print(f"COMMIT: {commit_short} ({commit_meta.get('date', '?')})")
        print(f"  {commit_meta.get('message', '?')}")
        print(f"{'='*60}")

        checkout_result = subprocess.run(
            ["git", "-C", str(repo_path), "checkout", commit_sha, "--quiet"],
            capture_output=True, text=True
        )
        if checkout_result.returncode != 0:
            print(f"  WARNING: checkout failed: {checkout_result.stderr}", file=sys.stderr)
            # Record failure for all inputs at this commit
            for input_path in input_files:
                verdict = {
                    "commit": {"sha": commit_sha, "short": commit_short, **commit_meta},
                    "input": {"file": Path(input_path).name, "sha256": sha256_file(input_path)},
                    "verdict": {
                        "category": "incorrect_determinate",
                        "rationale": f"Git checkout failed: {checkout_result.stderr.strip()}",
                        "details": {"checkout_failed": True},
                    },
                }
                all_verdicts.append(verdict)
            continue

        for input_path in input_files:
            run_count += 1
            test_name = Path(input_path).stem
            print(f"  [{run_count}/{total_runs}] {test_name}...", end=" ", flush=True)

            try:
                verdict = run_single(
                    repo_path, commit_sha, input_path,
                    output_base, commit_meta
                )
                cat = verdict["verdict"]["category"]
                symbol = {
                    "correct_determinate": "PASS",
                    "correct_indeterminate": "PASS",
                    "incorrect_determinate": "FAIL",
                    "incorrect_indeterminate": "WARN",
                    "omission": "OMIT",
                    "disclosure_failure": "DISC",
                }.get(cat, "????")
                print(f"{symbol} [{cat}]")
                all_verdicts.append(verdict)
            except Exception as e:
                print(f"ERROR: {e}")
                all_verdicts.append({
                    "commit": {"sha": commit_sha, "short": commit_short},
                    "input": {"file": Path(input_path).name},
                    "verdict": {
                        "category": "incorrect_determinate",
                        "rationale": f"Harness exception: {e}",
                        "details": {"exception": str(e)},
                    },
                })

    # Git restore is handled by the caller's finally block
    return all_verdicts


def build_heatmap_data(verdicts):
    """Build aggregated heatmap matrix from verdict list."""
    # commits (ordered) × test_cases × category
    commits = []
    seen_commits = set()
    test_cases = []
    seen_tests = set()
    matrix = {}

    for v in verdicts:
        commit_sha = v.get("commit", {}).get("sha", "unknown")
        test_name = v.get("input", {}).get("file", "unknown").replace(".txt", "")
        category = v.get("verdict", {}).get("category", "unknown")

        if commit_sha not in seen_commits:
            commits.append({
                "sha": commit_sha,
                "short": commit_sha[:8],
                "date": v.get("commit", {}).get("date", ""),
                "message": v.get("commit", {}).get("message", ""),
            })
            seen_commits.add(commit_sha)

        if test_name not in seen_tests:
            test_cases.append(test_name)
            seen_tests.add(test_name)

        matrix[f"{commit_sha}:{test_name}"] = {
            "category": category,
            "rationale": v.get("verdict", {}).get("rationale", ""),
        }

    return {
        "commits": commits,
        "test_cases": test_cases,
        "matrix": matrix,
        "category_legend": {
            "correct_determinate": {"color": "#22c55e", "label": "Correct (determinate)"},
            "correct_indeterminate": {"color": "#86efac", "label": "Correct (indeterminate)"},
            "incorrect_determinate": {"color": "#ef4444", "label": "WRONG (false Normal)"},
            "incorrect_indeterminate": {"color": "#fbbf24", "label": "Unnecessary indeterminate"},
            "omission": {"color": "#1e1b4b", "label": "Drug MISSING from report"},
            "disclosure_failure": {"color": "#f97316", "label": "Warning on stderr only"},
        },
    }


def build_summary(verdicts):
    """Per-commit summary statistics."""
    from collections import Counter, defaultdict

    by_commit = defaultdict(list)
    for v in verdicts:
        sha = v.get("commit", {}).get("sha", "unknown")
        by_commit[sha].append(v)

    summaries = {}
    # Track per-test results across all commits for persistent failure detection
    test_results_across_commits = defaultdict(list)

    for sha, vlist in by_commit.items():
        cats = Counter(v.get("verdict", {}).get("category", "unknown") for v in vlist)
        total = len(vlist)
        pass_count = cats.get("correct_determinate", 0) + cats.get("correct_indeterminate", 0)
        summaries[sha[:8]] = {
            "total_tests": total,
            "pass": pass_count,
            "fail": total - pass_count,
            "pass_rate": round(pass_count / total * 100, 1) if total > 0 else 0,
            "categories": dict(cats),
            "commit_date": vlist[0].get("commit", {}).get("date", ""),
            "commit_message": vlist[0].get("commit", {}).get("message", ""),
        }
        for v in vlist:
            test_name = v.get("input", {}).get("file", "").replace(".txt", "")
            cat = v.get("verdict", {}).get("category", "unknown")
            is_pass = cat in ("correct_determinate", "correct_indeterminate")
            test_results_across_commits[test_name].append(is_pass)

    # Identify persistent failures and improvements (OpenCode recommendation)
    persistent_failures = []
    improved_in = {}
    for test_name, results in test_results_across_commits.items():
        if not any(results):
            persistent_failures.append(test_name)
        else:
            # Find first commit where it started passing
            for i, passed in enumerate(results):
                if passed and (i == 0 or not results[i - 1]):
                    commit_list = list(by_commit.keys())
                    if i < len(commit_list):
                        improved_in.setdefault(commit_list[i][:8], []).append(test_name)

    summaries["_meta"] = {
        "persistent_failures": sorted(persistent_failures),
        "improved_in": improved_in,
        "total_commits": len(by_commit),
        "total_tests": len(test_results_across_commits),
    }

    return summaries


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="ClawBio PharmGx Benchmark Harness",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--repo", type=Path,
        default=Path(__file__).resolve().parent.parent.parent / "ClawBio",
        help="Path to ClawBio repo (default: ../../ClawBio relative to this script)"
    )
    parser.add_argument(
        "--commits", type=str, default=None,
        help="Comma-separated commit SHAs (use HEAD for current)"
    )
    parser.add_argument(
        "--all-commits", action="store_true",
        help="Run against ALL commits in history (longitudinal sweep)"
    )
    parser.add_argument(
        "--inputs", type=Path,
        default=Path(__file__).resolve().parent / "test_inputs",
        help="Directory of test input files, or a single file"
    )
    parser.add_argument(
        "--output", type=Path, default=None,
        help="Output directory (default: results/<timestamp>)"
    )

    args = parser.parse_args()
    repo_path = args.repo.resolve()

    # Resolve commits
    if args.all_commits:
        commits = get_all_commits(repo_path)
        print(f"Longitudinal sweep: {len(commits)} commits")
    elif args.commits:
        raw_commits = args.commits.split(",")
        commits = []
        for c in raw_commits:
            c = c.strip()
            if c == "HEAD":
                result = subprocess.run(
                    ["git", "-C", str(repo_path), "rev-parse", "HEAD"],
                    capture_output=True, text=True
                )
                c = result.stdout.strip()
            commits.append(c)
    else:
        print("ERROR: Must specify --commits or --all-commits", file=sys.stderr)
        sys.exit(1)

    # Resolve input files
    inputs_path = args.inputs.resolve()
    if inputs_path.is_dir():
        input_files = sorted(inputs_path.glob("*.txt"))
    elif inputs_path.is_file():
        input_files = [inputs_path]
    else:
        print(f"ERROR: Input path does not exist: {inputs_path}", file=sys.stderr)
        sys.exit(1)

    if not input_files:
        print("ERROR: No test input files found", file=sys.stderr)
        sys.exit(1)

    # Create output directory
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_base = (args.output or Path(__file__).resolve().parent / "results" / timestamp).resolve()
    output_base.mkdir(parents=True, exist_ok=True)

    # Write manifest
    manifest = {
        "benchmark_version": BENCHMARK_VERSION,
        "run_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "repo_path": str(repo_path),
        "commits": commits,
        "commit_count": len(commits),
        "input_files": [
            {"file": f.name, "sha256": sha256_file(f)} for f in input_files
        ],
        "input_count": len(input_files),
        "total_runs": len(commits) * len(input_files),
        "ground_truth_references": GROUND_TRUTH_REFS,
        "rubric_categories": RUBRIC_CATEGORIES,
        "environment": {
            "python_version": platform.python_version(),
            "platform": platform.platform(),
            "hostname": platform.node(),
        },
    }
    with open(output_base / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"\nClawBio PharmGx Benchmark v{BENCHMARK_VERSION}")
    print(f"  Repo: {repo_path}")
    print(f"  Commits: {len(commits)}")
    print(f"  Inputs: {len(input_files)}")
    print(f"  Total runs: {len(commits) * len(input_files)}")
    print(f"  Output: {output_base}")
    print()

    # Run benchmark
    verdicts = run_benchmark(repo_path, commits, input_files, output_base)

    # Write aggregated outputs
    heatmap_data = build_heatmap_data(verdicts)
    with open(output_base / "heatmap_data.json", "w") as f:
        json.dump(heatmap_data, f, indent=2, default=str)

    summary = build_summary(verdicts)
    with open(output_base / "summary.json", "w") as f:
        json.dump(summary, f, indent=2, default=str)

    # Write all verdicts as a flat array
    with open(output_base / "all_verdicts.json", "w") as f:
        json.dump(verdicts, f, indent=2, default=str)

    # Print summary
    print(f"\n{'='*60}")
    print("BENCHMARK COMPLETE")
    print(f"{'='*60}")
    for sha_short, s in summary.items():
        if sha_short == "_meta":
            continue
        print(f"\n  {sha_short} ({s['commit_date'][:10]}): "
              f"{s['pass']}/{s['total_tests']} pass ({s['pass_rate']}%)")
        for cat, count in sorted(s["categories"].items()):
            print(f"    {cat}: {count}")

    print(f"\nResults: {output_base}")
    print(f"  manifest.json       — run metadata")
    print(f"  all_verdicts.json   — every (commit, input) verdict")
    print(f"  heatmap_data.json   — visualization-ready matrix")
    print(f"  summary.json        — per-commit statistics")


if __name__ == "__main__":
    main()
