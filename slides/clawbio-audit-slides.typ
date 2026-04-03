// ClawBio PharmGx Audit — LinkedIn Slide Deck
// 6 slides, landscape format, professional design

#let accent = rgb("#1e3a5f")
#let accent-light = rgb("#4a90d9")
#let danger = rgb("#c0392b")
#let safe = rgb("#27ae60")
#let warn = rgb("#e67e22")
#let muted = rgb("#6c757d")
#let bg-light = rgb("#f8f9fa")

#set page(
  paper: "presentation-16-9",
  margin: (x: 2.2cm, y: 1.8cm),
  fill: white,
)
#set text(font: "Libertinus Serif", size: 14pt, fill: rgb("#2c3e50"))
#set par(leading: 0.7em)

// ──────────────────────────────────────────────
// SLIDE 1 — Title
// ──────────────────────────────────────────────

#align(center + horizon)[
  #block(width: 100%)[
    #v(0.5cm)
    #text(28pt, weight: "bold", fill: accent)[
      When a PGx Tool Says "Normal"
    ]
    #v(0.3cm)
    #text(22pt, fill: accent-light)[
      And the Patient Isn't
    ]
    #v(1.2cm)
    #text(13pt, fill: muted)[
      A reproducible safety benchmark of ClawBio's PharmGx Reporter
    ]
    #v(0.4cm)
    #line(length: 30%, stroke: 0.5pt + accent-light)
    #v(0.4cm)
    #text(12pt, fill: muted)[
      3 April 2026 #h(1.5cm) 18 synthetic test cases #h(1.5cm) 3 commits #h(1.5cm) 6-category rubric
    ]
    #v(0.3cm)
    #text(11pt, style: "italic", fill: muted)[
      Ground truth: CPIC guidelines, PharmVar allele definitions, FDA drug labeling
    ]
  ]
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 2 — The Tool and the Stakes
// ──────────────────────────────────────────────

#text(22pt, weight: "bold", fill: accent)[What the tool does]
#v(0.4cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.5cm,
  [
    #text(13pt)[
      ClawBio's *PharmGx Reporter* takes a 23andMe genotype file,
      calls star alleles for 12 pharmacogenes, and outputs drug
      recommendations for 51 medications.
    ]
    #v(0.5cm)
    #text(13pt)[
      The drugs include *codeine* (opioid), *warfarin* (anticoagulant),
      *irinotecan* (chemotherapy), and *fluorouracil* (5-FU) --- all
      narrow-therapeutic-index medications where wrong dosing can be fatal.
    ]
    #v(0.5cm)
    #text(13pt)[
      The tool is labeled "research and educational purposes only."
      It produces reports with clinical-looking headers like
      *"AVOID --- DO NOT USE"* and *"Normal Metabolizer."*
    ]
  ],
  [
    #block(fill: bg-light, inset: 14pt, radius: 6pt, width: 100%)[
      #text(12pt, weight: "bold", fill: accent)[The question we tested:]
      #v(0.3cm)
      #text(13pt)[
        When the tool *doesn't know* the answer ---
        because the input data can't represent certain
        variant types --- does it say so?
      ]
      #v(0.5cm)
      #text(13pt)[
        Or does it say #text(fill: danger, weight: "bold")["Normal Metabolizer"]?
      ]
    ]
    #v(0.8cm)
    #block(fill: rgb("#fef3f3"), inset: 14pt, radius: 6pt, width: 100%)[
      #text(12pt, fill: danger, weight: "bold")[Key populations at risk:]
      #v(0.2cm)
      #text(12pt)[
        CYP2D6 Ultrarapid Metabolizers: up to *29%* in some African populations.
        The tool has no way to detect this status.
        It never says so.
      ]
    ]
  ],
)

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 3 — Three Failure Modes
// ──────────────────────────────────────────────

#text(22pt, weight: "bold", fill: accent)[Three failure modes, one pattern]
#v(0.3cm)
#text(12pt, fill: muted)[Each independently confirmed across all commits. None fixed by the claimed patch.]
#v(0.5cm)

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 0.8cm,
  [
    #block(fill: rgb("#fef3f3"), inset: 12pt, radius: 6pt, width: 100%, height: 10cm)[
      #text(13pt, weight: "bold", fill: danger)[1. Silent Drug Omission]
      #v(0.3cm)
      #text(11.5pt)[
        When VKORC1 is not genotyped, `get_warfarin_rec()` returns a
        Python *tuple* instead of a string.
      ]
      #v(0.2cm)
      #text(11.5pt)[
        `lookup_drugs()` uses this as a dictionary key.
        The key is a tuple. The report iterates string keys.
      ]
      #v(0.2cm)
      #text(11.5pt, weight: "bold")[
        Warfarin silently disappears.
      ]
      #v(0.2cm)
      #text(11.5pt)[
        Then `json.dumps()` crashes with `TypeError`. The report was already written --- without warfarin.
      ]
      #v(0.3cm)
      #text(10pt, fill: muted)[
        Present in all 3 commits tested.
        Not a regression --- never worked.
      ]
    ]
  ],
  [
    #block(fill: rgb("#fff8f0"), inset: 12pt, radius: 6pt, width: 100%, height: 10cm)[
      #text(13pt, weight: "bold", fill: warn)[2. Non-Functional Transparency]
      #v(0.3cm)
      #text(11.5pt)[
        The tool cannot interpret DEL/INS/TA-repeat variants from DTC data. It *knows this* --- line 899 prints a `WARNING` to stderr.
      ]
      #v(0.2cm)
      #text(11.5pt)[
        But the report says *Normal Metabolizer*.
      ]
      #v(0.2cm)
      #text(11.5pt)[
        The warning goes where users don't look.
        The phenotype goes where they do.
      ]
      #v(0.3cm)
      #text(11.5pt)[
        This affects *irinotecan* (UGT1A1\*28), *codeine* (CYP2D6\*6), and *tacrolimus* (CYP3A5\*7).
      ]
      #v(0.3cm)
      #text(10pt, fill: muted)[
        Patch added the stderr warning.
        Did not change the report output.
      ]
    ]
  ],
  [
    #block(fill: rgb("#f0f7ff"), inset: 12pt, radius: 6pt, width: 100%, height: 10cm)[
      #text(13pt, weight: "bold", fill: accent)[3. False Reassurance]
      #v(0.3cm)
      #text(11.5pt)[
        When 1 of 3 DPYD SNPs is tested and found normal, the diplotype is annotated: `"Normal/Normal (1/3 SNPs tested)"`
      ]
      #v(0.2cm)
      #text(11.5pt)[
        This *looks* like transparency.
      ]
      #v(0.2cm)
      #text(11.5pt)[
        But `call_phenotype()` strips the parenthetical before matching. The phenotype becomes *Normal Metabolizer*.
      ]
      #v(0.2cm)
      #text(11.5pt)[
        5-FU recommendation: *standard dose*.
      ]
      #v(0.3cm)
      #text(10pt, fill: muted)[
        The annotation is decorative.
        The decision logic ignores it.
      ]
    ]
  ],
)

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 4 — The Three-Commit Comparison
// ──────────────────────────────────────────────

#text(22pt, weight: "bold", fill: accent)[The patch that changed nothing]
#v(0.3cm)
#text(12pt, fill: muted)[18 synthetic test cases scored against CPIC ground truth across 3 commits]
#v(0.5cm)

#show table.cell.where(y: 0): set text(weight: "bold", fill: white, size: 10pt)

#figure(
  table(
    columns: (3.5cm, auto, auto, auto, auto, auto, auto),
    align: (left, center, center, center, center, center, center),
    inset: 8pt,
    fill: (x, y) => if y == 0 { accent } else if calc.odd(y) { bg-light } else { white },
    stroke: none,
    [Commit], [Date], [Pass], [Disclosure], [Incorrect], [Omission], [Pass Rate],
    [Pre-patch], [Feb 28], [8], [3], [5], [2], [44%],
    [*Patch* `bbad73c`], [Feb 28], [8], [5], [3], [2], [44%],
    [*HEAD* `3c9383b`], [Mar 10], [8], [5], [3], [2], [44%],
  ),
)

#v(0.5cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.5cm,
  [
    #block(fill: bg-light, inset: 12pt, radius: 6pt)[
      #text(12pt, weight: "bold", fill: accent)[What the patch fixed (2 tests):]
      #v(0.2cm)
      #text(11.5pt)[
        - Empty file no longer produces a full report \
        - Completely absent DPYD now returns Indeterminate
      ]
    ]
  ],
  [
    #block(fill: rgb("#fef3f3"), inset: 12pt, radius: 6pt)[
      #text(12pt, weight: "bold", fill: danger)[What persists across all 3 commits:]
      #v(0.2cm)
      #text(11.5pt)[
        - Warfarin silently missing (TypeError crash) \
        - UGT1A1\*28 partial coverage #sym.arrow Normal \
        - DPYD 1/3 SNPs #sym.arrow Normal Metabolizer \
        - CYP2D6 CNV never disclosed
      ]
    ]
  ],
)

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 5 — Methodology
// ──────────────────────────────────────────────

#text(22pt, weight: "bold", fill: accent)[Reproducible methodology]
#v(0.3cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.5cm,
  [
    #text(14pt, weight: "bold", fill: accent)[Benchmark design]
    #v(0.3cm)
    #text(12pt)[
      - *18 synthetic 23andMe-format test files* with pre-specified ground truth
      - *Positive controls* (variant present, correct answer known)
      - *Negative controls* (variant absent, Normal expected)
      - *Indeterminate controls* (correct answer is "insufficient data")
      - No real patient data --- fully synthetic, fully reproducible
    ]
    #v(0.5cm)
    #text(14pt, weight: "bold", fill: accent)[Six-category scoring rubric]
    #v(0.3cm)
    #text(12pt)[
      #text(fill: safe)[Correct-Determinate] --- right phenotype, right drug \
      #text(fill: safe)[Correct-Indeterminate] --- correctly says "insufficient" \
      #text(fill: danger)[Incorrect-Determinate] --- wrong phenotype (false Normal) \
      #text(fill: warn)[Incorrect-Indeterminate] --- unnecessary uncertainty \
      #text(fill: rgb("#1e1b4b"))[Omission] --- drug silently missing from report \
      #text(fill: warn)[Disclosure Failure] --- warning on stderr, not in report
    ]
  ],
  [
    #text(14pt, weight: "bold", fill: accent)[What we are _not_ testing]
    #v(0.3cm)
    #text(12pt)[
      We do not penalize the tool for limitations inherent to DTC data.
      No microarray can detect CYP2D6 gene duplications or TA-repeat lengths.
    ]
    #v(0.3cm)
    #text(12pt)[
      We test *what the tool does when it cannot know the answer.*
      The clinically safe behavior is: say so. The observed behavior is:
      say "Normal."
    ]
    #v(0.5cm)
    #text(14pt, weight: "bold", fill: accent)[Ground truth and output]
    #v(0.3cm)
    #text(12pt)[
      - CPIC Guidelines (version-pinned), PharmVar, FDA labeling \
      - No reference tool comparison --- CPIC is the authority \
      - Every run produces JSON verdicts with SHA-256 checksums, stderr capture, and CPIC references
    ]
  ],
)

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 6 — Implications
// ──────────────────────────────────────────────

#text(22pt, weight: "bold", fill: accent)[What this means for the field]
#v(0.5cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.5cm,
  [
    #block(fill: bg-light, inset: 12pt, radius: 6pt, width: 100%)[
      #text(13pt, weight: "bold", fill: accent)[The narrow finding]
      #v(0.2cm)
      #text(12pt)[
        When the tool encounters data it cannot interpret, it defaults to
        "Normal Metabolizer" without disclosing the limitation in the
        report. A claimed patch of 32 fixes changed safety outcomes for
        2 of 18 test cases. The warfarin bug predates the patch.
      ]
    ]
    #v(0.4cm)
    #block(fill: rgb("#f0f7ff"), inset: 12pt, radius: 6pt, width: 100%)[
      #text(13pt, weight: "bold", fill: accent)[The broader question]
      #v(0.2cm)
      #text(12pt)[
        How many bioinformatics AI tools produce confident-looking
        outputs when the correct answer is "I don't know"?
        This benchmark is open-source and reusable for any PGx tool
        that ingests DTC data.
      ]
    ]
  ],
  [
    #block(fill: rgb("#fef3f3"), inset: 12pt, radius: 6pt, width: 100%)[
      #text(13pt, weight: "bold", fill: danger)[The design pattern to watch for]
      #v(0.3cm)
      #text(12.5pt, weight: "bold")[
        Missing data #sym.arrow Reference assumption #sym.arrow Normal phenotype #sym.arrow Standard dosing
      ]
      #v(0.3cm)
      #text(12pt)[
        Every step looks reasonable alone. Together they convert
        *absence of evidence* into *evidence of safety*.
      ]
    ]
    #v(0.4cm)
    #block(stroke: 0.5pt + accent, inset: 12pt, radius: 6pt, width: 100%)[
      #text(12pt)[
        *Benchmark:* 18 test cases, 6-category rubric, JSON verdicts, chain of custody.
        Reproducible with Python 3.10+ and the target repo.
      ]
    ]
    #v(0.2cm)
    #align(right)[
      #text(10pt, fill: muted)[Benchmark version 1.0.0 --- April 2026]
    ]
  ],
)
