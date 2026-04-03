#!/usr/bin/env python3
"""Render the 187-commit × 18-test safety heatmap as a publication-quality PNG."""

import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
import numpy as np

# ── Paths ──
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
HEATMAP_JSON = REPO_ROOT / "results" / "full_sweep" / "heatmap_data.json"
OUT_PNG = REPO_ROOT / "slides" / "heatmap_187commits.png"
OUT_PDF = REPO_ROOT / "slides" / "heatmap_187commits.pdf"

# ── Load data ──
with open(HEATMAP_JSON) as f:
    data = json.load(f)

commits = data["commits"]
test_cases = data["test_cases"]
matrix = data["matrix"]

# ── Category → integer mapping ──
CAT_MAP = {
    "correct_determinate": 0,
    "correct_indeterminate": 1,
    "incorrect_determinate": 2,
    "incorrect_indeterminate": 3,
    "omission": 4,
    "disclosure_failure": 5,
}
CAT_COLORS = {
    0: "#3a8a5c",   # correct_determinate — forest green
    1: "#6ec492",   # correct_indeterminate — light green
    2: "#d94f4f",   # incorrect_determinate — coral red
    3: "#e8a838",   # incorrect_indeterminate — amber
    4: "#0f2440",   # omission — dark navy
    5: "#cf7a30",   # disclosure_failure — ember orange
}
CAT_LABELS = {
    0: "Correct",
    1: "Correct (indeterminate)",
    2: "False Normal",
    3: "Unnecessary indeterminate",
    4: "Drug missing from report",
    5: "Warning on stderr only",
}

# ── Build matrix ──
n_commits = len(commits)
n_tests = len(test_cases)

# Reorder test cases: failures first, then controls
test_order = [
    # Persistent failures (omission)
    "warfarin_missing_both", "warfarin_missing_vkorc1",
    # Persistent failures (disclosure)
    "ugt1a1_28_hom", "ugt1a1_28_het", "cyp2d6_del",
    # Persistent failures (incorrect)
    "dpyd_partial", "ugt1a1_28_absent", "tpmt_compound_het",
    # Improved by patch
    "dpyd_absent", "empty_no_pgx",
    # Changed by patch (correct → disclosure)
    "cyp2d6_normal", "cyp3a5_7_ins",
    # Always pass (controls)
    "dpyd_2a_het", "dpyd_2a_hom", "dpyd_neg",
    "cyp2d6_pm", "ugt1a1_neg", "warfarin_normal",
]

mat = np.full((n_commits, len(test_order)), -1, dtype=int)
for i, commit in enumerate(commits):
    sha = commit["sha"]
    for j, test in enumerate(test_order):
        key = f"{sha}:{test}"
        if key in matrix:
            cat = matrix[key]["category"]
            mat[i, j] = CAT_MAP.get(cat, -1)

# ── Custom colormap ──
color_list = [CAT_COLORS[k] for k in sorted(CAT_COLORS.keys())]
cmap = mcolors.ListedColormap(color_list)
bounds = [-0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5]
norm = mcolors.BoundaryNorm(bounds, cmap.N)

# ── Figure ──
fig, ax = plt.subplots(figsize=(14, 22))

im = ax.imshow(mat, aspect="auto", cmap=cmap, norm=norm, interpolation="nearest")

# ── Y-axis: commits (show every 10th) ──
y_labels = []
y_ticks = []
for i, c in enumerate(commits):
    if i % 10 == 0 or i == n_commits - 1:
        date = c.get("date", "")[:10]
        y_labels.append(f"{c['short']} ({date})")
        y_ticks.append(i)

ax.set_yticks(y_ticks)
ax.set_yticklabels(y_labels, fontsize=7, fontfamily="monospace")

# ── X-axis: test cases ──
display_names = [t.replace("_", "\n") for t in test_order]
ax.set_xticks(range(len(test_order)))
ax.set_xticklabels(display_names, fontsize=7.5, rotation=0, ha="center",
                    fontfamily="monospace")
ax.xaxis.set_ticks_position("top")
ax.xaxis.set_label_position("top")

# ── Annotate key commits ──
key_commits = {
    "e2015a9f": "PharmGx added",
    "bbad73c1": "Patch (32 claimed fixes)",
    "3c9383b1": "HEAD",
}
for i, c in enumerate(commits):
    if c["short"] in key_commits:
        label = key_commits[c["short"]]
        ax.axhline(y=i, color="white", linewidth=1.5, alpha=0.8)
        ax.annotate(
            f"  {label}",
            xy=(len(test_order) - 0.5, i),
            xytext=(len(test_order) + 0.3, i),
            fontsize=8, fontweight="bold", color="#0f2440",
            va="center", ha="left",
            arrowprops=dict(arrowstyle="-", color="#0f2440", lw=0.8),
            annotation_clip=False,
        )

# ── Separators between test groups ──
for sep in [2, 5, 8, 10, 12]:
    ax.axvline(x=sep - 0.5, color="white", linewidth=1, alpha=0.6)

# ── Group labels at bottom ──
group_labels = [
    (1, "Omission"),
    (3.5, "Disclosure\nfailure"),
    (6.5, "False\nNormal"),
    (9, "Fixed by\npatch"),
    (11, "Reclassified"),
    (15, "Controls\n(always pass)"),
]
for x, label in group_labels:
    ax.text(x, n_commits + 3, label, ha="center", va="top", fontsize=7,
            color="#64748b", fontstyle="italic")

# ── Legend ──
legend_patches = [
    mpatches.Patch(color=CAT_COLORS[k], label=CAT_LABELS[k])
    for k in sorted(CAT_COLORS.keys())
]
ax.legend(
    handles=legend_patches, loc="lower center",
    bbox_to_anchor=(0.5, -0.06), ncol=3, fontsize=8,
    frameon=True, fancybox=True, edgecolor="#dee2e6",
)

# ── Title ──
ax.set_title(
    "ClawBio PharmGx Safety Trajectory\n"
    "187 commits × 18 CPIC-referenced tests",
    fontsize=14, fontweight="bold", color="#0f2440", pad=40,
)
fig.text(0.5, 0.005, "Sergey A. Kornilov · Biostochastics · github.com/biostochastics/clawbio-pgx-benchmark",
         ha="center", fontsize=7, color="#64748b")

plt.tight_layout(rect=[0, 0.04, 0.88, 0.97])

# ── Save ──
OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT_PNG, dpi=200, bbox_inches="tight", facecolor="white")
fig.savefig(OUT_PDF, bbox_inches="tight", facecolor="white")
print(f"Saved: {OUT_PNG} ({OUT_PNG.stat().st_size // 1024} KB)")
print(f"Saved: {OUT_PDF}")
