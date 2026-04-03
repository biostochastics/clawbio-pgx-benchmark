# ClawBio PharmGx Report

**Date**: 2026-04-03 22:13 UTC
**Input**: `dpyd_2a_hom.txt`
**Format detected**: 23andme
**Checksum (SHA-256)**: `da5bf39da8d3f0ba0b91ee1422bf2058961cbb89804afb9058751f053d036210`
**Total SNPs in file**: 30
**Pharmacogenomic SNPs found**: 30/30
**Genes profiled**: 12
**Drugs assessed**: 51

---

## Drug Response Summary

| Category | Count |
|----------|-------|
| Standard dosing | 48 |
| Use with caution | 1 |
| Avoid / use alternative | 2 |

### Actionable Alerts

**AVOID / USE ALTERNATIVE:**

- **Fluorouracil** (5-FU) [DPYD]
- **Capecitabine** (Xeloda) [DPYD]

**USE WITH CAUTION:**

- **Tacrolimus** (Prograf) [CYP3A5]

---

## Gene Profiles

| Gene | Full Name | Diplotype | Phenotype |
|------|-----------|-----------|-----------|
| CYP2C19 | Cytochrome P450 2C19 | *1/*1 | Normal Metabolizer |
| CYP2D6 | Cytochrome P450 2D6 | *1/*1 | Normal Metabolizer |
| CYP2C9 | Cytochrome P450 2C9 | *1/*1 | Normal Metabolizer |
| VKORC1 | Vitamin K Epoxide Reductase | GG | Normal Warfarin Sensitivity |
| SLCO1B1 | Solute Carrier Organic Anion Transporter 1B1 | TT | Normal Function |
| DPYD | Dihydropyrimidine Dehydrogenase | *2A/*2A | Poor Metabolizer |
| TPMT | Thiopurine S-Methyltransferase | *1/*1 | Normal Metabolizer |
| UGT1A1 | UDP-Glucuronosyltransferase 1A1 | *1/*1 | Normal Metabolizer |
| CYP3A5 | Cytochrome P450 3A5 | *1/*1 | CYP3A5 Expressor |
| CYP2B6 | Cytochrome P450 2B6 | *1/*1 | Normal Metabolizer |
| NUDT15 | Nudix Hydrolase 15 | *1/*1 | Normal Metabolizer |
| CYP1A2 | Cytochrome P450 1A2 | *1/*1 | Normal Metabolizer |

## Detected Variants

| rsID | Gene | Star Allele | Genotype | Effect |
|------|------|-------------|----------|--------|
| rs762551 | CYP1A2 | *1F | CC | increased_function |
| rs2069514 | CYP1A2 | *1C | GG | decreased_function |
| rs3745274 | CYP2B6 | *9 | GG | decreased_function |
| rs28399499 | CYP2B6 | *18 | TT | no_function |
| rs4244285 | CYP2C19 | *2 | GG | no_function |
| rs4986893 | CYP2C19 | *3 | GG | no_function |
| rs12248560 | CYP2C19 | *17 | CC | increased_function |
| rs28399504 | CYP2C19 | *4 | CC | no_function |
| rs1799853 | CYP2C9 | *2 | CC | decreased_function |
| rs1057910 | CYP2C9 | *3 | AA | decreased_function |
| rs3892097 | CYP2D6 | *4 | CC | no_function |
| rs5030655 | CYP2D6 | *6 | TT | no_function |
| rs16947 | CYP2D6 | *2 | GG | normal_function |
| rs1065852 | CYP2D6 | *10 | CC | decreased_function |
| rs28371725 | CYP2D6 | *41 | CC | decreased_function |
| rs776746 | CYP3A5 | *3 | CC | no_function |
| rs10264272 | CYP3A5 | *6 | CC | no_function |
| rs41303343 | CYP3A5 | *7 | CC | no_function |
| rs3918290 | DPYD | *2A | TT | no_function |
| rs55886062 | DPYD | *13 | TT | no_function |
| rs67376798 | DPYD | D949V | TT | decreased_function |
| rs116855232 | NUDT15 | *3 | CC | no_function |
| rs147390019 | NUDT15 | *2 | GG | decreased_function |
| rs4149056 | SLCO1B1 | *5 | TT | decreased_function |
| rs1800460 | TPMT | *3B | CC | no_function |
| rs1142345 | TPMT | *3C | AA | no_function |
| rs1800462 | TPMT | *2 | CC | no_function |
| rs8175347 | UGT1A1 | *28 | CC | decreased_function |
| rs4148323 | UGT1A1 | *6 | GG | decreased_function |
| rs9923231 | VKORC1 | -1639G>A | GG | decreased_expression |

---

## Complete Drug Recommendations

| Drug | Brand | Class | Gene | Status |
|------|-------|-------|------|--------|
| Capecitabine | Xeloda | Antineoplastic | DPYD | AVOID |
| Fluorouracil | 5-FU | Antineoplastic | DPYD | AVOID |
| Tacrolimus | Prograf | Immunosuppressant | CYP3A5 | CAUTION |
| Amitriptyline | Elavil | Tricyclic Antidepressant | CYP2D6 | OK |
| Aripiprazole | Abilify | Antipsychotic | CYP2D6 | OK |
| Atazanavir | Reyataz | Antiretroviral | UGT1A1 | OK |
| Atomoxetine | Strattera | ADHD Medication | CYP2D6 | OK |
| Atorvastatin | Lipitor | Statin | SLCO1B1 | OK |
| Azathioprine | Imuran | Immunosuppressant | TPMT | OK |
| Celecoxib | Celebrex | NSAID | CYP2C9 | OK |
| Citalopram | Celexa | SSRI Antidepressant | CYP2C19 | OK |
| Clomipramine | Anafranil | Tricyclic Antidepressant | CYP2D6 | OK |
| Clopidogrel | Plavix | Antiplatelet Agent | CYP2C19 | OK |
| Clozapine | Clozaril | Antipsychotic | CYP1A2 | OK |
| Codeine | Tylenol w/ Codeine | Opioid Analgesic | CYP2D6 | OK |
| Desipramine | Norpramin | Tricyclic Antidepressant | CYP2D6 | OK |
| Dexlansoprazole | Dexilant | Proton Pump Inhibitor | CYP2C19 | OK |
| Doxepin | Sinequan | Tricyclic Antidepressant | CYP2D6 | OK |
| Efavirenz | Sustiva | Antiretroviral | CYP2B6 | OK |
| Escitalopram | Lexapro | SSRI Antidepressant | CYP2C19 | OK |
| Esomeprazole | Nexium | Proton Pump Inhibitor | CYP2C19 | OK |
| Fluoxetine | Prozac | SSRI Antidepressant | CYP2D6 | OK |
| Flurbiprofen | Ansaid | NSAID | CYP2C9 | OK |
| Haloperidol | Haldol | Antipsychotic | CYP2D6 | OK |
| Hydrocodone | Vicodin | Opioid Analgesic | CYP2D6 | OK |
| Imipramine | Tofranil | Tricyclic Antidepressant | CYP2D6 | OK |
| Irinotecan | Camptosar | Antineoplastic | UGT1A1 | OK |
| Lansoprazole | Prevacid | Proton Pump Inhibitor | CYP2C19 | OK |
| Meloxicam | Mobic | NSAID | CYP2C9 | OK |
| Mercaptopurine | Purinethol | Immunosuppressant | TPMT | OK |
| Metoprolol | Lopressor | Beta-Blocker | CYP2D6 | OK |
| Nortriptyline | Pamelor | Tricyclic Antidepressant | CYP2D6 | OK |
| Omeprazole | Prilosec | Proton Pump Inhibitor | CYP2C19 | OK |
| Ondansetron | Zofran | Antiemetic | CYP2D6 | OK |
| Oxycodone | OxyContin | Opioid Analgesic | CYP2D6 | OK |
| Pantoprazole | Protonix | Proton Pump Inhibitor | CYP2C19 | OK |
| Paroxetine | Paxil | SSRI Antidepressant | CYP2D6 | OK |
| Phenytoin | Dilantin | Antiepileptic | CYP2C9 | OK |
| Piroxicam | Feldene | NSAID | CYP2C9 | OK |
| Pravastatin | Pravachol | Statin | SLCO1B1 | OK |
| Risperidone | Risperdal | Antipsychotic | CYP2D6 | OK |
| Rosuvastatin | Crestor | Statin | SLCO1B1 | OK |
| Sertraline | Zoloft | SSRI Antidepressant | CYP2C19 | OK |
| Simvastatin | Zocor | Statin | SLCO1B1 | OK |
| Tamoxifen | Nolvadex | SERM (Oncology) | CYP2D6 | OK |
| Thioguanine | Tabloid | Immunosuppressant | TPMT | OK |
| Tramadol | Ultram | Opioid Analgesic | CYP2D6 | OK |
| Trimipramine | Surmontil | Tricyclic Antidepressant | CYP2D6 | OK |
| Venlafaxine | Effexor | SNRI Antidepressant | CYP2D6 | OK |
| Voriconazole | Vfend | Antifungal | CYP2C19 | OK |
| Warfarin | Coumadin | Anticoagulant | CYP2C9+VKORC1 | OK |

---

## Disclaimer

This report is for **research and educational purposes only**. It is NOT a diagnostic device and should NOT be used to make medication decisions without consulting a qualified healthcare professional.

Pharmacogenomic recommendations are based on CPIC guidelines (cpicpgx.org). DTC genetic tests have limitations: they may not detect all relevant variants, and results should be confirmed by clinical-grade testing before clinical use.

## Methods

- **Tool**: ClawBio PharmGx Reporter v0.2.0
- **SNP panel**: 31 pharmacogenomic variants across 12 genes
- **Star allele calling**: Simplified DTC-compatible algorithm (single-SNP per allele)
- **Phenotype assignment**: CPIC-based diplotype-to-phenotype mapping
- **Drug guidelines**: 51 drugs from CPIC (cpicpgx.org), simplified for DTC context

## Reproducibility

```bash
python pharmgx_reporter.py --input dpyd_2a_hom.txt --output report
```

**Input checksum**: `da5bf39da8d3f0ba0b91ee1422bf2058961cbb89804afb9058751f053d036210`

## References

- Corpas, M. (2026). ClawBio. https://github.com/ClawBio/ClawBio
- CPIC. Clinical Pharmacogenetics Implementation Consortium. https://cpicpgx.org/
- Caudle, K.E. et al. (2014). Standardizing terms for clinical pharmacogenetic test results. Genet Med, 16(9), 655-663.
- PharmGKB. https://www.pharmgkb.org/
