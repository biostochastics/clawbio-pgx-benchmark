// ClawBio PharmGx Audit — LinkedIn Carousel (Portrait)
// 6 slides: concrete findings with specific variants and results

#let accent = rgb("#1e3a5f")
#let accent-light = rgb("#4a90d9")
#let danger = rgb("#c0392b")
#let safe = rgb("#27ae60")
#let warn = rgb("#e67e22")
#let muted = rgb("#6c757d")
#let bg-light = rgb("#f8f9fa")
#let code-bg = rgb("#1e1e2e")
#let code-fg = rgb("#cdd6f4")

#set page(
  width: 21cm,
  height: 26.25cm,
  margin: (x: 2cm, y: 2cm),
  fill: white,
)
#set text(font: "Libertinus Serif", size: 14pt, fill: rgb("#2c3e50"))
#set par(leading: 0.7em)

// ──────────────────────────────────────────────
// SLIDE 1 — Title
// ──────────────────────────────────────────────

#align(center + horizon)[
  #block(width: 100%)[
    #text(30pt, weight: "bold", fill: accent)[
      Pharmacogenomics Safety Audit
    ]
    #v(0.4cm)
    #text(20pt, fill: accent-light)[
      ClawBio PharmGx Reporter
    ]
    #v(2cm)
    #text(15pt, fill: rgb("#2c3e50"))[
      18 synthetic test cases scored against \
      CPIC guidelines across 3 git commits
    ]
    #v(1.5cm)
    #block(fill: bg-light, inset: 16pt, radius: 8pt, width: 85%)[
      #text(14pt)[
        *44% pass rate* --- identical before and after \
        a claimed patch of 32 safety fixes. \
        137 subsequent commits changed no safety outcomes.
      ]
    ]
    #v(1.5cm)
    #text(12pt, fill: muted)[
      Ground truth: CPIC guidelines, PharmVar \
      allele definitions, FDA drug labeling
    ]
    #v(0.6cm)
    #line(length: 30%, stroke: 0.5pt + accent-light)
    #v(0.4cm)
    #text(11pt, fill: muted)[April 2026]
  ]
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 2 — Warfarin: the drug that disappears
// ──────────────────────────────────────────────

#text(24pt, weight: "bold", fill: danger)[Finding 1: Warfarin silently disappears]
#v(0.1cm)
#text(12pt, fill: muted)[Anticoagulant. Narrow therapeutic index. Wrong dose causes bleeding or stroke.]
#v(0.5cm)

#text(14pt)[
  When a patient's VKORC1 genotype is missing, the tool should report
  warfarin as *indeterminate*. Instead:
]
#v(0.4cm)

#block(fill: code-bg, inset: 14pt, radius: 6pt, width: 100%)[
  #text(11pt, font: "DejaVu Sans Mono", fill: code-fg)[
    \# pharmgx\_reporter.py, line 1007 \
    return "indeterminate", "VKORC1 not genotyped..."  \#\# returns TUPLE \
    \
    \# line 1029 \
    classification = get\_warfarin\_rec(profiles)  \#\# tuple, not string \
    results.setdefault(classification, []).append(...)  \#\# tuple as dict key
  ]
]
#v(0.3cm)

#text(14pt)[
  The report iterates `results["standard"]`, `results["avoid"]`, etc.
  None match a tuple key. *Warfarin is silently absent.*
  Then `json.dumps()` crashes:
]
#v(0.3cm)

#block(fill: rgb("#fef3f3"), inset: 14pt, radius: 6pt, width: 100%)[
  #text(11pt, font: "DejaVu Sans Mono", fill: danger)[
    TypeError: keys must be str, int, float, bool or None, not tuple
  ]
]
#v(0.5cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  [
    #block(fill: bg-light, inset: 12pt, radius: 6pt, width: 100%)[
      #text(13pt, weight: "bold", fill: accent)[Report output:]
      #v(0.2cm)
      #text(13pt)[
        *50 drugs assessed* \
        (should be 51 --- warfarin missing) \
        No error message. No warning.
      ]
    ]
  ],
  [
    #block(fill: bg-light, inset: 12pt, radius: 6pt, width: 100%)[
      #text(13pt, weight: "bold", fill: accent)[Benchmark verdict:]
      #v(0.2cm)
      #text(13pt, fill: danger, weight: "bold")[OMISSION]
      #text(13pt)[ --- drug silently \
      absent from report. Present in \
      *all 3 commits tested*.]
    ]
  ],
)
#v(0.5cm)
#text(13pt, style: "italic", fill: muted)[
  This is not a regression. The warfarin handler never worked correctly.
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 3 — UGT1A1*28: stderr vs report
// ──────────────────────────────────────────────

#text(24pt, weight: "bold", fill: warn)[Finding 2: The warning nobody reads]
#v(0.1cm)
#text(12pt, fill: muted)[UGT1A1\*28 (rs8175347) --- irinotecan toxicity. Oncology drug. Severe neutropenia risk.]
#v(0.5cm)

#text(14pt)[
  UGT1A1\*28 is a TA-repeat polymorphism that DTC arrays cannot represent
  as a two-character genotype. The tool *knows this* --- it prints a warning.
  But the warning goes to stderr. The report says Normal.
]
#v(0.5cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 0.8cm,
  [
    #text(14pt, weight: "bold", fill: danger)[What the user sees]
    #text(12pt, fill: muted)[ (report.md)]
    #v(0.3cm)
    #block(fill: bg-light, inset: 12pt, radius: 6pt, width: 100%)[
      #text(12pt, font: "DejaVu Sans Mono")[
        Gene: UGT1A1 \
        Diplotype: \*1/\*1 \
        Phenotype: *Normal Metabolizer* \
        \
        Irinotecan: *Standard dose*
      ]
    ]
  ],
  [
    #text(14pt, weight: "bold", fill: muted)[What the terminal shows]
    #text(12pt, fill: muted)[ (stderr)]
    #v(0.3cm)
    #block(fill: code-bg, inset: 12pt, radius: 6pt, width: 100%)[
      #text(11pt, font: "DejaVu Sans Mono", fill: warn)[
        WARNING: UGT1A1 rs8175347 \
        has structural variant \
        alt=TA7, cannot interpret \
        from DTC data
      ]
    ]
  ],
)
#v(0.6cm)

#block(fill: rgb("#fff8f0"), inset: 14pt, radius: 6pt, width: 100%)[
  #text(14pt)[
    The same pattern affects three structural variants:
  ]
  #v(0.3cm)
  #table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    inset: 8pt,
    stroke: none,
    fill: (x, y) => if y == 0 { warn.lighten(80%) } else { none },
    [*Variant*], [*Gene*], [*Drug affected*], [*Risk*],
    [rs8175347 (TA7)], [UGT1A1\*28], [Irinotecan], [Severe neutropenia],
    [rs5030655 (DEL)], [CYP2D6\*6], [Codeine], [Respiratory depression],
    [rs41303343 (INS)], [CYP3A5\*7], [Tacrolimus], [Nephrotoxicity],
  )
  #v(0.2cm)
  #text(13pt)[
    All three: stderr warning present, report says *Normal Metabolizer*.
  ]
]
#v(0.5cm)
#text(13pt, weight: "bold")[Benchmark verdict: #text(fill: warn)[DISCLOSURE FAILURE] --- 5 of 18 tests]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 4 — DPYD partial coverage: decorative annotation
// ──────────────────────────────────────────────

#text(24pt, weight: "bold", fill: accent)[Finding 3: The annotation that does nothing]
#v(0.1cm)
#text(12pt, fill: muted)[DPYD + fluorouracil (5-FU). Standard dose in DPYD-deficient patients: 3--5% mortality.]
#v(0.5cm)

#text(14pt)[
  DPYD has 3 SNPs in the panel. When only 1 is tested,
  the tool annotates the diplotype:
]
#v(0.3cm)

#align(center)[
  #block(fill: bg-light, inset: 16pt, radius: 8pt)[
    #text(16pt, font: "DejaVu Sans Mono")[
      "Normal/Normal (1/3 SNPs tested)"
    ]
  ]
]
#v(0.4cm)

#text(14pt)[
  This *looks* like transparency. But two lines later in the code:
]
#v(0.3cm)

#block(fill: code-bg, inset: 14pt, radius: 6pt, width: 100%)[
  #text(11.5pt, font: "DejaVu Sans Mono", fill: code-fg)[
    \# pharmgx\_reporter.py, line 950 \
    match\_str = norm.split("(")[0].strip() \
    \
    \# "Normal/Normal (1/3 SNPs tested)" becomes "Normal/Normal" \
    \# Matches phenotype table entry -> "Normal Metabolizer"
  ]
]
#v(0.5cm)

#text(14pt)[
  The parenthetical annotation is *created* at line 913
  and *stripped* at line 950. It cannot affect the phenotype assignment.
]
#v(0.5cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  [
    #block(fill: rgb("#fef3f3"), inset: 14pt, radius: 6pt, width: 100%)[
      #text(14pt, weight: "bold", fill: danger)[Report output:]
      #v(0.2cm)
      #text(13pt)[
        DPYD: Normal Metabolizer \
        Fluorouracil: *Standard dose* \
        Capecitabine: *Standard dose*
      ]
      #v(0.2cm)
      #text(11pt, fill: muted)[
        Missing: rs55886062 (\*13), rs67376798 (D949V)
      ]
    ]
  ],
  [
    #block(fill: bg-light, inset: 14pt, radius: 6pt, width: 100%)[
      #text(14pt, weight: "bold", fill: accent)[What CPIC requires:]
      #v(0.2cm)
      #text(13pt)[
        Incomplete DPYD coverage \
        should produce: *Indeterminate* \
        or prominent safety warning.
      ]
      #v(0.2cm)
      #text(11pt, fill: muted)[
        CPIC Fluoropyrimidine Guideline v3.0
      ]
    ]
  ],
)
#v(0.5cm)
#text(13pt, weight: "bold")[Benchmark verdict: #text(fill: danger)[INCORRECT DETERMINATE] --- false Normal]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 5 — Results matrix
// ──────────────────────────────────────────────

#text(24pt, weight: "bold", fill: accent)[Results: 18 tests, 3 commits]
#v(0.5cm)

#show table.cell.where(y: 0): set text(weight: "bold", fill: white, size: 11pt)

#align(center)[
  #table(
    columns: (5cm, auto, auto, auto, auto, auto),
    align: (left, center, center, center, center, center),
    inset: 10pt,
    fill: (x, y) => if y == 0 { accent } else if calc.odd(y) { bg-light } else { white },
    stroke: none,
    [Commit], [Pass], [Disclosure], [Incorrect], [Omission], [Rate],
    [Pre-patch (Feb 28)], [8], [3], [5], [2], [*44%*],
    [Patch `bbad73c`], [8], [5], [3], [2], [*44%*],
    [HEAD `3c9383b`], [8], [5], [3], [2], [*44%*],
  )
]
#v(0.5cm)

#text(14pt)[
  The patch claimed 32 fixes. On 18 safety-critical tests,
  it changed the outcome for *2*. Both were edge cases
  (empty file, fully absent gene). Every clinically dangerous
  failure mode is identical before and after.
]
#v(0.5cm)

#text(15pt, weight: "bold", fill: accent)[Per-test breakdown (safety-critical tests only)]
#v(0.2cm)

#show table.cell.where(y: 0): set text(weight: "bold", size: 9.5pt)

#table(
  columns: (4cm, 2cm, 2.8cm, 2.8cm, 2.8cm),
  align: (left, left, center, center, center),
  inset: 6pt,
  stroke: 0.3pt + rgb("#dee2e6"),
  fill: (x, y) => if y == 0 { bg-light } else { none },
  [*Test*], [*Gene*], [*Pre-patch*], [*Patch*], [*HEAD*],
  [warfarin\_missing], [VKORC1], [#text(fill: rgb("#1e1b4b"))[OMIT]], [#text(fill: rgb("#1e1b4b"))[OMIT]], [#text(fill: rgb("#1e1b4b"))[OMIT]],
  [ugt1a1\_28\_hom], [UGT1A1], [#text(fill: warn)[DISC]], [#text(fill: warn)[DISC]], [#text(fill: warn)[DISC]],
  [dpyd\_partial], [DPYD], [#text(fill: danger)[FAIL]], [#text(fill: danger)[FAIL]], [#text(fill: danger)[FAIL]],
  [cyp2d6\_del], [CYP2D6], [#text(fill: warn)[DISC]], [#text(fill: warn)[DISC]], [#text(fill: warn)[DISC]],
  [tpmt\_compound], [TPMT], [#text(fill: danger)[FAIL]], [#text(fill: danger)[FAIL]], [#text(fill: danger)[FAIL]],
  [cyp3a5\_7\_ins], [CYP3A5], [#text(fill: safe)[PASS]], [#text(fill: warn)[DISC]], [#text(fill: warn)[DISC]],
  [dpyd\_absent], [DPYD], [#text(fill: danger)[FAIL]], [#text(fill: safe)[PASS]], [#text(fill: safe)[PASS]],
  [empty\_no\_pgx], [---], [#text(fill: danger)[FAIL]], [#text(fill: safe)[PASS]], [#text(fill: safe)[PASS]],
)
#v(0.15cm)
#text(10pt, fill: muted)[
  #text(fill: safe)[PASS] = correct #h(0.4cm)
  #text(fill: warn)[DISC] = stderr-only warning #h(0.4cm)
  #text(fill: danger)[FAIL] = false Normal #h(0.4cm)
  #text(fill: rgb("#1e1b4b"))[OMIT] = drug missing
]
#v(0.1cm)
#text(10pt, fill: muted)[6 positive/negative controls (all PASS) omitted for space.]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 6 — The pattern and next steps
// ──────────────────────────────────────────────

#text(24pt, weight: "bold", fill: accent)[The pattern]
#v(0.5cm)

#block(fill: rgb("#fef3f3"), inset: 18pt, radius: 8pt, width: 100%)[
  #text(18pt, weight: "bold", fill: danger)[
    Missing data #sym.arrow.r Reference assumption #sym.arrow.r \
    Normal phenotype #sym.arrow.r Standard dosing
  ]
  #v(0.4cm)
  #text(14pt)[
    Every step looks reasonable in isolation. Together they convert
    *absence of evidence* into *evidence of safety*.
    The report never mentions the gap.
  ]
]
#v(0.7cm)

#text(16pt, weight: "bold", fill: accent)[What we tested --- and what we didn't]
#v(0.3cm)
#text(14pt)[
  We did *not* penalize the tool for limitations inherent to DTC microarrays.
  No consumer genotyping chip can detect CYP2D6 gene duplications or TA-repeat
  lengths. That's biology, not a bug.
]
#v(0.3cm)
#text(14pt)[
  We tested *what the tool does when it encounters data it cannot interpret*.
  The clinically safe behavior is to say so. The observed behavior --- across
  every commit in 187 days of development --- is to say "Normal."
]
#v(0.7cm)

#text(16pt, weight: "bold", fill: accent)[CYP2D6 Ultrarapid Metabolizers]
#v(0.2cm)
#text(13pt)[
  The tool's own guideline table says `ultrarapid_metabolizer: "avoid"`
  for codeine (line 361). But the phenotype caller has no Ultrarapid entry
  for CYP2D6 (lines 113--117). The rule exists and can never fire.
  Prevalence: up to *29%* in Ethiopian and North African populations.
]
#v(0.3cm)
#line(length: 100%, stroke: 0.3pt + rgb("#dee2e6"))
#v(0.2cm)
#text(11pt, fill: muted)[
  *Benchmark:* 18 synthetic tests, 6-category rubric, JSON verdicts with SHA-256 checksums.
  Reproducible: Python 3.10+, git clone, one command. Open source. #h(1fr) _v1.0.0 --- April 2026_
]
