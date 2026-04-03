// ClawBio PharmGx Safety Audit — LinkedIn Carousel (Portrait 4:5)
// Sergey A. Kornilov — Biostochastics — Seattle, WA

#let navy    = rgb("#0f2440")
#let steel   = rgb("#2d4a6f")
#let sky     = rgb("#5b8dbf")
#let coral   = rgb("#d94f4f")
#let ember   = rgb("#cf7a30")
#let forest  = rgb("#3a8a5c")
#let slate   = rgb("#64748b")
#let pearl   = rgb("#f1f5f9")
#let snow    = rgb("#fafbfc")
#let ink     = rgb("#1e293b")
#let code-bg = rgb("#1a1b2e")
#let code-fg = rgb("#c9d1d9")
#let repo-url = "github.com/biostochastics/clawbio-pgx-benchmark"

#set page(
  width: 21cm,
  height: 26.25cm,
  margin: (x: 1.8cm, y: 1.6cm),
  fill: white,
)
#set text(font: "Libertinus Serif", size: 13pt, fill: ink)
#set par(leading: 0.65em, justify: false)

// Tasteful header rule for finding slides
#let finding-header(number, title, subtitle) = {
  block(width: 100%)[
    #text(11pt, weight: "bold", fill: sky, tracking: 0.08em)[FINDING #number]
    #v(0.15cm)
    #text(24pt, weight: "bold", fill: navy)[#title]
    #v(0.15cm)
    #text(12pt, fill: slate)[#subtitle]
    #v(0.2cm)
    #line(length: 100%, stroke: 0.4pt + sky.lighten(50%))
  ]
}

// ──────────────────────────────────────────────
// SLIDE 1 — Title
// ──────────────────────────────────────────────

#text(11pt, weight: "bold", fill: sky, tracking: 0.12em)[
  REPRODUCIBLE SAFETY BENCHMARK
]
#v(1cm)
#align(center)[
  #text(32pt, weight: "bold", fill: navy)[
    Pharmacogenomics \
    Safety Audit
  ]
  #v(0.25cm)
  #line(length: 25%, stroke: 1pt + sky)
  #v(0.25cm)
  #text(18pt, fill: steel)[
    ClawBio PharmGx Reporter
  ]
]
#v(1.5cm)
#align(center)[
  #text(14pt, fill: ink)[
    18 synthetic test cases scored against \
    CPIC guidelines across 3 git commits
  ]
]
#v(1cm)
#block(fill: pearl, inset: (x: 20pt, y: 14pt), radius: 4pt, width: 100%)[
  #align(center)[
    #text(14pt, fill: ink)[
      *50% pass rate before the patch. 44% after.* \
      The claimed fix introduced a new bug that silently \
      drops warfarin from reports. 137 commits later: unchanged.
    ]
  ]
]
#v(1cm)
#align(center)[
  #text(12pt, fill: slate)[
    Ground truth: CPIC guidelines #sym.dot.c PharmVar allele definitions #sym.dot.c FDA drug labeling
  ]
  #v(0.25cm)
  #text(10pt, font: "DejaVu Sans Mono", fill: sky)[#repo-url]
]
#v(1fr)
#line(length: 100%, stroke: 0.3pt + pearl)
#v(0.1cm)
#text(10pt, fill: slate)[
  Sergey A. Kornilov #h(0.2cm) #sym.dot.c #h(0.2cm)
  Biostochastics #h(0.2cm) #sym.dot.c #h(0.2cm)
  Seattle, WA #h(1fr) April 2026
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 2 — Warfarin: the drug that disappears
// ──────────────────────────────────────────────

#finding-header("1", "Warfarin silently disappears",
  "Anticoagulant. Narrow therapeutic index. Wrong dose causes bleeding or stroke.")
#v(0.3cm)

#text(14pt)[
  When a patient's VKORC1 genotype is missing, the tool should report
  warfarin as *indeterminate*. Instead:
]
#v(0.3cm)

#block(fill: code-bg, inset: 14pt, radius: 4pt, width: 100%)[
  #text(10.5pt, font: "DejaVu Sans Mono", fill: code-fg)[
    \# pharmgx\_reporter.py, line 1007 \
    return "indeterminate", "VKORC1 not genotyped..."  \
    #text(fill: rgb("#6a9955"))[\# returns TUPLE, not string] \
    \
    \# line 1029 \
    classification = get\_warfarin\_rec(profiles) \
    results.setdefault(classification, []).append(...) \
    #text(fill: rgb("#6a9955"))[\# tuple used as dict key]
  ]
]
#v(0.3cm)

#text(14pt)[
  The report iterates `results["standard"]`, `results["avoid"]`, etc.
  None match a tuple key. *Warfarin is silently absent.* \
  Then `json.dumps()` crashes:
]
#v(0.3cm)

#block(fill: coral.lighten(90%), inset: 12pt, radius: 4pt, width: 100%,
       stroke: (left: 3pt + coral))[
  #text(10.5pt, font: "DejaVu Sans Mono", fill: coral)[
    TypeError: keys must be str, int, float, bool or None, not tuple
  ]
]
#v(0.3cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 0.8cm,
  [
    #block(fill: pearl, inset: 12pt, radius: 4pt, width: 100%)[
      #text(12pt, weight: "bold", fill: navy)[Report output]
      #v(0.2cm)
      #text(13pt)[
        *50 drugs assessed* \
        (should be 51 --- warfarin missing) \
        No error message. No warning.
      ]
    ]
  ],
  [
    #block(fill: pearl, inset: 12pt, radius: 4pt, width: 100%)[
      #text(12pt, weight: "bold", fill: navy)[Benchmark verdict]
      #v(0.2cm)
      #text(13pt, fill: coral, weight: "bold")[OMISSION]
      #text(13pt)[ --- drug silently \
      absent from report. Present in \
      *all 3 commits tested*.]
    ]
  ],
)
#v(0.2cm)
#text(12pt, style: "italic", fill: slate)[
  The warfarin tuple bug was *introduced* by the patch (`bbad73c`). The pre-patch code handled warfarin correctly.
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 3 — UGT1A1*28: stderr vs report
// ──────────────────────────────────────────────

#finding-header("2", "The warning nobody reads",
  [UGT1A1\*28 (rs8175347) --- irinotecan toxicity. Oncology drug. Severe neutropenia risk.])
#v(0.3cm)

#text(14pt)[
  UGT1A1\*28 is a TA-repeat polymorphism that DTC arrays cannot represent
  as a two-character genotype. The tool *knows this* --- it prints a warning.
  But the warning goes to stderr. The report says Normal.
]
#v(0.25cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 0.6cm,
  [
    #text(12pt, weight: "bold", fill: coral)[What the user sees]
    #text(11pt, fill: slate)[ #h(0.2cm) report.md]
    #v(0.2cm)
    #block(fill: pearl, inset: 12pt, radius: 4pt, width: 100%,
           stroke: (left: 3pt + coral.lighten(30%)))[
      #text(12pt, font: "DejaVu Sans Mono")[
        Gene: UGT1A1 \
        Diplotype: \*1/\*1 \
        Phenotype: *Normal* \
        *Metabolizer* \
        \
        Irinotecan: *Standard dose*
      ]
    ]
  ],
  [
    #text(12pt, weight: "bold", fill: slate)[What the terminal shows]
    #text(11pt, fill: slate)[ #h(0.2cm) stderr]
    #v(0.2cm)
    #block(fill: code-bg, inset: 12pt, radius: 4pt, width: 100%)[
      #text(11pt, font: "DejaVu Sans Mono", fill: ember)[
        WARNING: UGT1A1 \
        rs8175347 has \
        structural variant \
        alt=TA7, cannot \
        interpret from \
        DTC data
      ]
    ]
  ],
)
#v(0.25cm)

#block(fill: ember.lighten(90%), inset: 14pt, radius: 4pt, width: 100%,
       stroke: (left: 3pt + ember))[
  #text(13pt)[The same pattern affects three structural variants:]
  #v(0.2cm)
  #show table.cell.where(y: 0): set text(weight: "bold", size: 11pt)
  #table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    inset: 7pt,
    stroke: none,
    fill: (x, y) => if y == 0 { ember.lighten(80%) } else { none },
    [Variant], [Gene], [Drug], [Risk],
    [rs8175347 (TA7)], [UGT1A1\*28], [Irinotecan], [Severe neutropenia],
    [rs5030655 (DEL)], [CYP2D6\*6], [Codeine], [Respiratory depression],
    [rs41303343 (INS)], [CYP3A5\*7], [Tacrolimus], [Nephrotoxicity],
  )
  #v(0.1cm)
  #text(12pt)[
    All three: stderr warning present, report says *Normal Metabolizer*.
  ]
]
#v(0.3cm)
#text(13pt, weight: "bold")[Benchmark verdict: #text(fill: ember)[DISCLOSURE FAILURE] --- 5 of 18 tests]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 4 — DPYD partial coverage
// ──────────────────────────────────────────────

#finding-header("3", "The annotation that does nothing",
  [DPYD + fluorouracil (5-FU). Standard dose in DPYD-deficient patients: 3--5% mortality.])
#v(0.3cm)

#text(14pt)[
  DPYD has 3 SNPs in the panel. When only 1 is tested,
  the tool annotates the diplotype:
]
#v(0.3cm)

#align(center)[
  #block(fill: pearl, inset: 14pt, radius: 4pt,
         stroke: 0.5pt + sky.lighten(40%))[
    #text(15pt, font: "DejaVu Sans Mono", fill: ink)[
      "Normal/Normal (1/3 SNPs tested)"
    ]
  ]
]
#v(0.3cm)

#text(14pt)[
  This *looks* like transparency. But two lines later:
]
#v(0.3cm)

#block(fill: code-bg, inset: 14pt, radius: 4pt, width: 100%)[
  #text(10.5pt, font: "DejaVu Sans Mono", fill: code-fg)[
    #text(fill: rgb("#6a9955"))[\# pharmgx\_reporter.py, line 950] \
    match\_str = norm.split("(")[0].strip() \
    \
    #text(fill: rgb("#6a9955"))[\# "Normal/Normal (1/3 SNPs tested)"] \
    #text(fill: rgb("#6a9955"))[\#   becomes "Normal/Normal"] \
    #text(fill: rgb("#6a9955"))[\#   matches phenotype table -> "Normal Metabolizer"]
  ]
]
#v(0.3cm)

#text(14pt)[
  The parenthetical is *created* at line 913
  and *stripped* at line 950. It cannot affect
  the phenotype assignment.
]
#v(0.25cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 0.8cm,
  [
    #block(fill: coral.lighten(92%), inset: 12pt, radius: 4pt, width: 100%,
           stroke: (left: 3pt + coral.lighten(30%)))[
      #text(12pt, weight: "bold", fill: navy)[Report output]
      #v(0.2cm)
      #text(13pt)[
        DPYD: Normal Metabolizer \
        Fluorouracil: *Standard dose* \
        Capecitabine: *Standard dose*
      ]
      #v(0.15cm)
      #text(10.5pt, fill: slate)[
        Missing: rs55886062 (\*13), rs67376798 (D949V)
      ]
    ]
  ],
  [
    #block(fill: pearl, inset: 12pt, radius: 4pt, width: 100%,
           stroke: (left: 3pt + sky.lighten(20%)))[
      #text(12pt, weight: "bold", fill: navy)[What CPIC requires]
      #v(0.2cm)
      #text(13pt)[
        Incomplete DPYD coverage should \
        produce: *Indeterminate* or \
        prominent safety warning.
      ]
      #v(0.15cm)
      #text(10.5pt, fill: slate)[
        CPIC Fluoropyrimidine Guideline v3.0
      ]
    ]
  ],
)
#v(0.3cm)
#text(13pt, weight: "bold")[Benchmark verdict: #text(fill: coral)[INCORRECT DETERMINATE] --- false Normal]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 5 — Results matrix
// ──────────────────────────────────────────────

#text(11pt, weight: "bold", fill: sky, tracking: 0.08em)[RESULTS]
#v(0.1cm)
#text(24pt, weight: "bold", fill: navy)[18 tests, 3 commits]
#v(0.15cm)
#line(length: 100%, stroke: 0.4pt + sky.lighten(50%))
#v(0.25cm)

#show table.cell.where(y: 0): set text(weight: "bold", fill: white, size: 11pt)

#align(center)[
  #table(
    columns: (5cm, auto, auto, auto, auto, auto),
    align: (left, center, center, center, center, center),
    inset: 10pt,
    fill: (x, y) => if y == 0 { navy } else if calc.odd(y) { pearl } else { white },
    stroke: none,
    [Commit], [Pass], [Disclosure], [Incorrect], [Omission], [Rate],
    [Pre-patch (Feb 28)], [9], [4], [5], [0], [*50%*],
    [Patch `bbad73c`], [8], [5], [3], [2], [*44%*],
    [HEAD `3c9383b`], [8], [5], [3], [2], [*44%*],
  )
]
#v(0.3cm)

#text(14pt)[
  The patch claimed 32 fixes. It fixed 2 edge cases but *introduced*
  the warfarin tuple bug, dropping the pass rate from 50% to 44%.
  Every subsequent commit preserved this regression.
]
#v(0.25cm)

#text(15pt, weight: "bold", fill: navy)[Per-test breakdown]
#v(0.15cm)
#text(10.5pt, fill: slate)[Safety-critical tests only. 6 positive/negative controls (all PASS) omitted.]
#v(0.2cm)

#show table.cell.where(y: 0): set text(weight: "bold", size: 10pt, fill: navy)

#table(
  columns: (3.8cm, 2cm, 2.8cm, 2.8cm, 2.8cm),
  align: (left, left, center, center, center),
  inset: 6.5pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.7pt + navy) } else { (bottom: 0.3pt + pearl) },
  fill: (x, y) => if y == 0 { none } else { none },
  [Test], [Gene], [Pre-patch], [Patch], [HEAD],
  [warfarin\_missing], [VKORC1], [#text(fill: forest)[PASS]], [#text(fill: navy, weight: "bold")[OMIT]], [#text(fill: navy, weight: "bold")[OMIT]],
  [ugt1a1\_28\_hom], [UGT1A1], [#text(fill: ember)[DISC]], [#text(fill: ember)[DISC]], [#text(fill: ember)[DISC]],
  [dpyd\_partial], [DPYD], [#text(fill: coral)[FAIL]], [#text(fill: coral)[FAIL]], [#text(fill: coral)[FAIL]],
  [cyp2d6\_del], [CYP2D6], [#text(fill: ember)[DISC]], [#text(fill: ember)[DISC]], [#text(fill: ember)[DISC]],
  [tpmt\_compound], [TPMT], [#text(fill: coral)[FAIL]], [#text(fill: coral)[FAIL]], [#text(fill: coral)[FAIL]],
  [cyp3a5\_7\_ins], [CYP3A5], [#text(fill: forest)[PASS]], [#text(fill: ember)[DISC]], [#text(fill: ember)[DISC]],
  [dpyd\_absent], [DPYD], [#text(fill: coral)[FAIL]], [#text(fill: forest)[PASS]], [#text(fill: forest)[PASS]],
  [empty\_no\_pgx], [---], [#text(fill: coral)[FAIL]], [#text(fill: forest)[PASS]], [#text(fill: forest)[PASS]],
)
#v(0.15cm)
#text(10pt, fill: slate)[
  #text(fill: forest)[PASS] correct #h(0.5cm)
  #text(fill: ember)[DISC] stderr-only warning #h(0.5cm)
  #text(fill: coral)[FAIL] false Normal #h(0.5cm)
  #text(fill: navy)[OMIT] drug missing
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 6 — The pattern
// ──────────────────────────────────────────────

#text(11pt, weight: "bold", fill: sky, tracking: 0.08em)[IMPLICATIONS]
#v(0.1cm)
#text(24pt, weight: "bold", fill: navy)[The pattern]
#v(0.15cm)
#line(length: 100%, stroke: 0.4pt + sky.lighten(50%))
#v(0.25cm)

#block(fill: coral.lighten(92%), inset: 16pt, radius: 4pt, width: 100%,
       stroke: (left: 3pt + coral))[
  #text(17pt, weight: "bold", fill: navy)[
    Missing data #sym.arrow.r Reference assumption #sym.arrow.r \
    Normal phenotype #sym.arrow.r Standard dosing
  ]
  #v(0.25cm)
  #text(13pt)[
    Every step looks reasonable in isolation. Together they convert
    *absence of evidence* into *evidence of safety*.
    The report never mentions the gap.
  ]
]
#v(0.3cm)

#text(15pt, weight: "bold", fill: navy)[What we tested --- and what we didn't]
#v(0.2cm)
#text(13pt)[
  We did *not* penalize the tool for limitations inherent to DTC
  microarrays. No consumer genotyping chip can detect CYP2D6
  gene duplications or TA-repeat lengths. That's biology, not a bug.
]
#v(0.15cm)
#text(13pt)[
  We tested *what the tool does when it encounters data it cannot
  interpret*. The clinically safe behavior is to say so. The observed
  behavior --- across every commit in 187 days of development --- is
  to say "Normal."
]
#v(0.3cm)

#text(15pt, weight: "bold", fill: navy)[CYP2D6 Ultrarapid Metabolizers]
#v(0.2cm)
#text(13pt)[
  The tool's own guideline table says
  `ultrarapid_metabolizer: "avoid"` for codeine (line 361).
  But the phenotype caller has no Ultrarapid entry for CYP2D6
  (lines 113--117). The rule exists and can never fire.
  Prevalence: up to *29%* in Ethiopian and North African
  populations. The tool never discloses this.
]

#pagebreak()

// ──────────────────────────────────────────────
// SLIDE 7 — Conclusions
// ──────────────────────────────────────────────

#text(11pt, weight: "bold", fill: sky, tracking: 0.08em)[CONCLUSIONS]
#v(0.1cm)
#text(24pt, weight: "bold", fill: navy)[Three classes of safety defect]
#v(0.15cm)
#line(length: 100%, stroke: 0.4pt + sky.lighten(50%))
#v(0.3cm)

#block(inset: (left: 14pt, y: 6pt, right: 6pt), width: 100%,
       stroke: (left: 3pt + coral))[
  #text(13pt, weight: "bold", fill: navy)[1. Software bugs]
  #h(1fr) #text(10pt, fill: slate)[warfarin #sym.dot.c all commits]
  #v(0.1cm)
  #text(12pt)[
    Warfarin disappears due to a type error *introduced by the patch* --- `tuple` returned where `str` expected. The tool crashes with `TypeError` after writing a report missing a narrow-therapeutic-index drug.
  ]
]
#v(0.2cm)
#block(inset: (left: 14pt, y: 6pt, right: 6pt), width: 100%,
       stroke: (left: 3pt + ember))[
  #text(13pt, weight: "bold", fill: navy)[2. Communication failures]
  #h(1fr) #text(10pt, fill: slate)[5 of 18 tests]
  #v(0.1cm)
  #text(12pt)[
    Structural variant limitations are warned on `stderr` but not in the report. CYP2D6 CNV (up to 29% prevalence) neither assessed nor mentioned. Users see "Normal Metabolizer" where the answer is "insufficient data."
  ]
]
#v(0.2cm)
#block(inset: (left: 14pt, y: 6pt, right: 6pt), width: 100%,
       stroke: (left: 3pt + steel))[
  #text(13pt, weight: "bold", fill: navy)[3. Unsafe inference under uncertainty]
  #h(1fr) #text(10pt, fill: slate)[3 of 18 tests]
  #v(0.1cm)
  #text(12pt)[
    Partial gene coverage produces cosmetic annotations stripped before phenotype matching. Incomplete testing becomes confident "Normal" for drugs with lethal toxicity risk.
  ]
]
#v(0.3cm)

#block(fill: pearl, inset: 12pt, radius: 4pt, width: 100%)[
  #text(12.5pt)[
    *The patch claimed 32 fixes.* It fixed 2 edge cases but introduced the warfarin tuple bug, dropping the pass rate from 50% to 44%. All other safety failures persisted unchanged across 187 commits.
  ]
]
#v(0.2cm)
#block(stroke: 0.5pt + sky.lighten(30%), inset: 12pt, radius: 4pt, width: 100%)[
  #text(12pt)[
    *Benchmark:* 18 synthetic tests #sym.dot.c 6-category rubric #sym.dot.c JSON verdicts with SHA-256 checksums #sym.dot.c CPIC ground truth (version-pinned) #sym.dot.c Reproducible: Python 3.10+, git clone, one command.
  ]
]

#v(1fr)
#line(length: 100%, stroke: 0.3pt + pearl)
#v(0.1cm)
#grid(
  columns: (1fr, auto),
  [
    #text(10pt, fill: slate)[
      Sergey A. Kornilov #h(0.2cm) #sym.dot.c #h(0.2cm)
      Biostochastics #h(0.2cm) #sym.dot.c #h(0.2cm)
      Seattle, WA
    ]
  ],
  [
    #text(9.5pt, font: "DejaVu Sans Mono", fill: sky)[
      #repo-url
    ]
  ],
)
