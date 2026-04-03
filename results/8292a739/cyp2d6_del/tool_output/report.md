# ClawBio PharmGx Report

**Date**: 2026-04-03 22:13 UTC
**Input**: `cyp2d6_del.txt`
**Format detected**: unknown
**Checksum (SHA-256)**: `118257c854214faf65026b8bb8a85ad3a2bd93c05041f73668313457c8076498`
**Total SNPs in file**: 30
**Pharmacogenomic SNPs found**: 30/30
**Genes profiled**: 12
**Drugs assessed**: 51

---

## Drug Response Summary

| Category | Count |
|----------|-------|
| Standard dosing | 50 |
| Use with caution | 1 |
| Avoid / use alternative | 0 |

### Actionable Alerts

**USE WITH CAUTION:**

- **Tacrolimus** (Prograf) [CYP3A5]: Increase dose 1.5-2x. Titrate to target trough.

---

## Gene Profiles

| Gene | Full Name | Diplotype | Phenotype |
|------|-----------|-----------|-----------|
| CYP2C19 | Cytochrome P450 2C19 | *1/*1 | Normal Metabolizer |
| CYP2D6 | Cytochrome P450 2D6 | *1/*1 | Normal Metabolizer |
| CYP2C9 | Cytochrome P450 2C9 | *1/*1 | Normal Metabolizer |
| VKORC1 | Vitamin K Epoxide Reductase | GG | Normal Warfarin Sensitivity |
| SLCO1B1 | Solute Carrier Organic Anion Transporter 1B1 | TT | Normal Function |
| DPYD | Dihydropyrimidine Dehydrogenase | Normal/Normal | Normal Metabolizer |
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
| rs5030655 | CYP2D6 | *6 | CT | no_function |
| rs16947 | CYP2D6 | *2 | GG | normal_function |
| rs1065852 | CYP2D6 | *10 | CC | decreased_function |
| rs28371725 | CYP2D6 | *41 | CC | decreased_function |
| rs776746 | CYP3A5 | *3 | CC | no_function |
| rs10264272 | CYP3A5 | *6 | CC | no_function |
| rs41303343 | CYP3A5 | *7 | CC | no_function |
| rs3918290 | DPYD | *2A | GG | no_function |
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

| Drug | Brand | Class | Gene | Status | Recommendation |
|------|-------|-------|------|--------|----------------|
| Tacrolimus | Prograf | Immunosuppressant | CYP3A5 | CAUTION | Increase dose 1.5-2x. Titrate to target trough. |
| Amitriptyline | Elavil | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Aripiprazole | Abilify | Antipsychotic | CYP2D6 | OK | Use recommended dose. |
| Atazanavir | Reyataz | Antiretroviral | UGT1A1 | OK | Use recommended dose. |
| Atomoxetine | Strattera | ADHD Medication | CYP2D6 | OK | Use recommended dose. |
| Atorvastatin | Lipitor | Statin | SLCO1B1 | OK | Use desired starting dose. |
| Azathioprine | Imuran | Immunosuppressant | TPMT | OK | Use recommended dose. |
| Capecitabine | Xeloda | Antineoplastic | DPYD | OK | Use recommended dose. |
| Celecoxib | Celebrex | NSAID | CYP2C9 | OK | Use recommended dose. |
| Citalopram | Celexa | SSRI Antidepressant | CYP2C19 | OK | Use recommended starting dose. |
| Clomipramine | Anafranil | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Clopidogrel | Plavix | Antiplatelet Agent | CYP2C19 | OK | Use recommended dose. |
| Clozapine | Clozaril | Antipsychotic | CYP1A2 | OK | Use recommended dose. |
| Codeine | Tylenol w/ Codeine | Opioid Analgesic | CYP2D6 | OK | Use label-recommended dosing. |
| Desipramine | Norpramin | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Dexlansoprazole | Dexilant | Proton Pump Inhibitor | CYP2C19 | OK | Use recommended starting dose. |
| Doxepin | Sinequan | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Efavirenz | Sustiva | Antiretroviral | CYP2B6 | OK | Use recommended dose. |
| Escitalopram | Lexapro | SSRI Antidepressant | CYP2C19 | OK | Use recommended starting dose. |
| Esomeprazole | Nexium | Proton Pump Inhibitor | CYP2C19 | OK | Use recommended starting dose. |
| Fluorouracil | 5-FU | Antineoplastic | DPYD | OK | Use recommended dose. |
| Fluoxetine | Prozac | SSRI Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Flurbiprofen | Ansaid | NSAID | CYP2C9 | OK | Use recommended dose. |
| Haloperidol | Haldol | Antipsychotic | CYP2D6 | OK | Use recommended dose. |
| Hydrocodone | Vicodin | Opioid Analgesic | CYP2D6 | OK | Use label-recommended dosing. |
| Imipramine | Tofranil | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Irinotecan | Camptosar | Antineoplastic | UGT1A1 | OK | Use recommended dose. |
| Lansoprazole | Prevacid | Proton Pump Inhibitor | CYP2C19 | OK | Use recommended starting dose. |
| Meloxicam | Mobic | NSAID | CYP2C9 | OK | Use recommended dose. |
| Mercaptopurine | Purinethol | Immunosuppressant | TPMT | OK | Use recommended dose. |
| Metoprolol | Lopressor | Beta-Blocker | CYP2D6 | OK | Use recommended starting dose. |
| Nortriptyline | Pamelor | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Omeprazole | Prilosec | Proton Pump Inhibitor | CYP2C19 | OK | Use recommended starting dose. |
| Ondansetron | Zofran | Antiemetic | CYP2D6 | OK | Use recommended dose. |
| Oxycodone | OxyContin | Opioid Analgesic | CYP2D6 | OK | Use label-recommended dosing. |
| Pantoprazole | Protonix | Proton Pump Inhibitor | CYP2C19 | OK | Use recommended starting dose. |
| Paroxetine | Paxil | SSRI Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Phenytoin | Dilantin | Antiepileptic | CYP2C9 | OK | Use recommended dose. |
| Piroxicam | Feldene | NSAID | CYP2C9 | OK | Use recommended dose. |
| Pravastatin | Pravachol | Statin | SLCO1B1 | OK | Use desired starting dose. |
| Risperidone | Risperdal | Antipsychotic | CYP2D6 | OK | Use recommended dose. |
| Rosuvastatin | Crestor | Statin | SLCO1B1 | OK | Use desired starting dose. |
| Sertraline | Zoloft | SSRI Antidepressant | CYP2C19 | OK | Use recommended starting dose. |
| Simvastatin | Zocor | Statin | SLCO1B1 | OK | Use desired starting dose. |
| Tamoxifen | Nolvadex | SERM (Oncology) | CYP2D6 | OK | Use recommended dose. |
| Thioguanine | Tabloid | Immunosuppressant | TPMT | OK | Use recommended dose. |
| Tramadol | Ultram | Opioid Analgesic | CYP2D6 | OK | Use label-recommended dosing. |
| Trimipramine | Surmontil | Tricyclic Antidepressant | CYP2D6 | OK | Use recommended starting dose. |
| Venlafaxine | Effexor | SNRI Antidepressant | CYP2D6 | OK | Use recommended dose. |
| Voriconazole | Vfend | Antifungal | CYP2C19 | OK | Use recommended dose. |
| Warfarin | Coumadin | Anticoagulant | CYP2C9+VKORC1 | OK | Use warfarin dosing algorithm. Standard dose range expected. |

---

## Disclaimer

This report is for **research and educational purposes only**. It is NOT a diagnostic device and should NOT be used to make medication decisions without consulting a qualified healthcare professional.

Pharmacogenomic recommendations are based on CPIC guidelines (cpicpgx.org). DTC genetic tests have limitations: they may not detect all relevant variants, and results should be confirmed by clinical-grade testing before clinical use.

## Methods

- **Tool**: ClawBio PharmGx Reporter v0.1.0
- **SNP panel**: 31 pharmacogenomic variants across 12 genes
- **Star allele calling**: Simplified DTC-compatible algorithm (single-SNP per allele)
- **Phenotype assignment**: CPIC-based diplotype-to-phenotype mapping
- **Drug guidelines**: 51 drugs from CPIC (cpicpgx.org), simplified for DTC context

## Reproducibility

```bash
python pharmgx_reporter.py --input cyp2d6_del.txt --output report
```

**Input checksum**: `118257c854214faf65026b8bb8a85ad3a2bd93c05041f73668313457c8076498`

## References

- Corpas, M. (2026). ClawBio. https://github.com/ClawBio/ClawBio
- CPIC. Clinical Pharmacogenetics Implementation Consortium. https://cpicpgx.org/
- Caudle, K.E. et al. (2014). Standardizing terms for clinical pharmacogenetic test results. Genet Med, 16(9), 655-663.
- PharmGKB. https://www.pharmgkb.org/
