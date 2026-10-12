# Fixed clipping bounds: source protocol

This document is the protocol under which the **fixed** clipping bounds of the manuscript were
derived from external sources alone (manuscript Section III-I; supplementary document Section S5
and Table S9). It gives the requirements a source must meet, the six tiers applied in order and a
further tier for the time axis, the clauses of the laboratory tier in full, the adopted bound of
every covariate, and every candidate that was considered and rejected, with the reason.

| What | Where |
|---|---|
| Adopted bound, tier, applied rule, units, conversion, citation, URL and access date of all 51 covariates | `main/06_report/output/tabS9_fixed_bounds.csv` (typeset as Table S9) |
| The same values as used by the code | `CLIPPING_BOUNDS_FIXED` and `FIXED_BOUNDS_SOURCES` in `main/02_dp_mechanisms/R/dp_bounds_comparison.R` |
| Width ratio and clipping rate of the 27 continuous covariates | `docs/fixed_bounds_clipping_check.csv` (Section 5) |
| Rejected candidates and rejected rules | Section 6 of this document |

## 0. Status and what is claimed

- **The bounds were specified after the datasets were available to us.** We therefore do not claim
  that the data were unseen. We claim that the justification of every bound rests on the protocol
  and an external source, never on a value of the analysed samples, so that a third party can
  re-derive each bound from this document and the cited source alone.
- **The clauses of the laboratory tier (Section 3.3) were written after the 12 laboratory
  variables had been inspected.** The eight disclosures of supplementary Section S1 list what was
  written or changed after which values had been seen. The defence against arbitrariness is
  therefore not the priority of the rules but the full disclosure of the rejected candidates
  (Section 6), each with the bound it would have given.
- **Guarantee and utility are separate.** Under fixed bounds the covariate perturbation of
  Phase 1 is ε-local-DP whatever the bound: a value outside the bound is clipped. The choice of
  bound sets only the balance between clipping bias and noise. The protocol requires that this
  choice be made from external sources; the expected effect on utility (how much the noise grows)
  is recorded as a disclosure but is never a reason to adopt or reject a source.
- **No variable was excluded from the formal claim by consulting the observed data.** The column
  `obs_ref` of `tabS9_fixed_bounds.csv` is "No reference" for all 51 rows.

## 1. Requirements for a source

1. **Data-independent justification.** No value of the analysed samples (lung, pbc, colon,
   rotterdam, flchain as prepared for the analysis) is used to justify a bound. Other published
   cohorts, national surveys and official statistics may be used.
2. **Citable.** The source has a bibliographic record or a URL that can be cited in Table S9.
3. **Available online, free of charge where possible.** Sources that require purchasing a
   textbook or a subscription are not adopted when a free official source exists. One adopted
   value needed a subscription full text (pbc `copper`, Section 3.4); its abstract is free, and
   the full text is identified so that the value can be checked.
4. **Uniform rules.** Variables of the same kind are bounded by the same rule, so that a third
   party can re-derive the same bound from this protocol and the source alone.
5. **Unit consistency.** The unit of the source is checked against the unit of the column in the
   prepared data, and every conversion factor is recorded in Table S9 (`conversion`).

Rejected candidates are recorded to the same standard (citation, version, URL, access date).

## 2. Tiers

The tiers are applied in order; a covariate takes the first tier that applies to it.

| Tier | Basis | Covariates | Rule |
|---|---|---|---|
| 0 | Domain of the coding convention | 24 binary and categorical covariates | The set of codes documented for the variable (R `survival` help page). This is the support of the randomized response. |
| 1 | Definitional range of an established scale | 3: lung `ph.ecog`, `ph.karno`, `pat.karno` | The range the instrument defines. |
| 2 | Pathological limit of a laboratory measurement | 12: pbc `bili`, `chol`, `albumin`, `copper`, `alk.phos`, `ast`, `trig`, `platelet`, `protime`; flchain `creatinine`, `kappa`, `lambda` | Section 3. |
| 3 | Censoring value of a cancer-registry coding convention | 2: colon `nodes`, rotterdam `nodes` | The upper truncation code of the national standard. |
| 4 | Cohort eligibility criterion (age) | 5: `age` in each dataset | The eligibility age stated by the source; otherwise the uniform rule [18, 110]. |
| 5 | Published study metadata and variable-specific derivations | 5: flchain `sample.yr`, lung `meal.cal`, `wt.loss`, rotterdam `pgr`, `er` | Section 4.3. |
| 6 | Time axis (formal comparison arm only) | flchain follow-up time | The interval from the published start of enrolment to the published end of follow-up. |

Tiers 0 to 5 bound the 51 covariates (24 + 3 + 12 + 2 + 5 + 5). Tier 6 fixes the time horizon
used to normalize time in the formal comparison arm (manuscript Section III-F); it does not
bound a covariate.

**Tier 1.** lung `ph.ecog`: [0, 5] (ECOG performance status; ECOG-ACRIN, public-domain
instrument; Oken et al. 1982). lung `ph.karno` and `pat.karno`: [0, 100] (Karnofsky performance
status; Karnofsky & Burchenal 1949, reproduced free of charge by ECOG-ACRIN).

## 3. Tier 2: laboratory measurements

### 3.1 Sources

- **Reference ranges** are taken from the ABIM Laboratory Test Reference Ranges (January 2026
  edition, free PDF). They served only to check units and orders of magnitude (next bullet) and are
  **not** used to compute any bound; they are not recorded in Table S9.
- **Unit check for the free light chains**: ABIM reports κ and λ in mg/L only, whereas flchain
  stores mg/dL. The Mayo Clinic Laboratories test catalogue (κ 0.33–1.94 mg/dL, λ 0.57–2.63 mg/dL,
  equal to 3.3–19.4 / 5.7–26.3 mg/L) and Katzmann et al. 2002 confirm the unit.
- Reference values in catalogues are revised from time to time; Table S9 records the access date
  of every source, and the bound is fixed at the value read on that date.

### 3.2 Priorities and common rules

The upper bound of each laboratory variable is the value of the first external source found in the
following order of priority. No multiplier is applied.

| Priority | Kind of evidence | Content |
|---|---|---|
| **P1** | Physiological or analytical absolute limit | A value the quantity cannot exceed in principle, or the reporting limit of the assay. |
| **P2** | Reported upper value in the condition where the measurement is highest | Subdivided in Clause 2 into P2a-1, P2a-2, P2a-3 and P2b. |
| **P3** | Threshold of the top category of a clinical classification that includes the upper reference limit | Used when P1 and P2 give nothing, or when Clause 3 applies. |

Common rules:

- **Lower bound 0** for every laboratory variable (concentrations, activities, counts and times are
  non-negative).
- **Rounding**: the adopted value is the source value **rounded up to one significant digit**
  (for example 3,720 → 4,000). One digit removes the choice of the number of digits as a degree of
  freedom (31.26 would become 32 with two digits and 40 with one). Rounding up widens the bound,
  which works against the fixed arm. The code checks the rounding for all 12 variables on loading
  (`TIER2_SOURCE_VALUE_CONVERTED` and `ceil_1sig()` in `dp_bounds_comparison.R`).
- **Inclusion of the observed range is a check, not a rule.** The bound is taken from the source
  first. If the observed values exceed it, the bound is not moved; the clipping rate is disclosed
  (Section 5). Widening a bound to include the observed range is not allowed.
- **Sanity check**: after a bound is fixed, the ratio of its width to the observed width is
  computed. A ratio outside 1–50 sends the variable back to its source to look for a unit error or
  a wrong source. This is a check; it is never a reason to adjust a bound.

### 3.3 Clauses

The three priorities alone could not decide five situations met with the 12 variables. The
following clauses decide them without looking at the values. **All five were written after the
12 laboratory variables had been inspected** (supplementary Section S1, items 5 and 6).

**Clause 0 (same measurement conditions). Takes precedence over every other clause.**
A reported value used as the basis of an upper bound must measure the same quantity as the
variable, **under the same measurement conditions** (with or without a challenge, timing of the
sample, before or after treatment). A value measured under different conditions cannot be used,
however large.

*Application.* pbc `copper` is basal 24-hour urinary copper measured at trial entry, that is,
before treatment (Dickson et al., *Hepatology* 1989;10(1):1–7: data were collected "at entry";
its Table 1 median urine copper, 73, equals the median of `copper` in `survival::pbc`). The EASL
penicillamine-challenge threshold is measured after two doses of the chelator D-penicillamine and
is therefore excluded (Section 6).

**Clause 1 (no restriction by age group).**
Subject to Clause 0, the age group of a reported value does not matter. A bound gives the highest
value the measurement **can reach**, not a representative distribution of the analysed
population. A value of the same substance measured by the same kind of assay supports an upper
bound across age groups. (This is why pbc `alk.phos` and `chol` rest on paediatric sources.)

**Clause 2 (P2 subdivided).**

- **P2a-1**: the **upper end of the observed range** reported by a published series or cohort in
  the condition concerned. When a range is published, it takes precedence. When the source
  reports ranges for **several groups**, take **the largest of the group maxima** (by Clause 1;
  not the group with the most patients). An upper end that rests on a **single case** is not
  excluded as an outlier (also by Clause 1). These two sentences were written after the copper
  values had been seen (supplementary Section S1, item 8).
- **P2a-2**: when no range is published, and the measurement is pushed up continuously by a
  physiological state of a whole subpopulation rather than by a single condition, take the
  **upper limit of the reference interval** published for that subpopulation. This applies only
  when the measurement rises **as a consequence of** that state; when the measurement **defines**
  the state, P2b applies instead (its extremes are then set by individual acute conditions, not
  by the state of the subpopulation). *Disclosure duty*: a reference-interval upper limit is
  usually the 97.5th percentile, so about 2.5% of the source population exceeds it. Section 3.4,
  note (d), states this for the variables to which P2a-2 applies; where the individual values of
  the source are not published numerically, it says so.
- **P2a-3**: when neither a range nor a reference interval is published and only a **group
  mean** is available, take **twice the group mean rounded up to one significant digit**, in that
  order (round up, then double). When several group means are reported, take the largest (by
  Clause 1). The factor 2 is a value customarily used as a guide to the ratio of a group maximum
  to its mean for laboratory values; the one series in which both a group mean and a maximum are
  reported (Walshe 2011, hepatic group: 3,080 / 465.75 = 6.6) does not support it empirically. *This clause applies to no variable at present* (Section 3.4,
  `copper`); it is kept so that its history remains auditable (supplementary Section S1, item 2).
- **P2b**: only when no P2a value is available, the **highest value in a single case report** in
  the condition concerned.

Which branch applies depends only on whether a range is published, whether the rise is driven by
a whole-subpopulation state, and whether the measurement depends on that state; no value needs to
be seen. For the three variables where the dependency condition decides the branch:

| Variable | State of the subpopulation | Position of the measurement | Branch |
|---|---|---|---|
| flchain `kappa`, `lambda` | Kidney function | Rises as a consequence (renal excretion) | P2a-2 |
| flchain `creatinine` | Kidney function | Defines kidney function | P2b |

**Clause 3 (when P3 takes precedence over P2).**
When the P2 candidates are **single case reports only** (condition 1), and an authoritative
clinical guideline defines the top category **quantitatively** (condition 2), **P3 is taken, for
re-derivability**. The P3 value is the threshold that opens the top category, not its upper end;
since that category is open above, **values above the threshold are reported in the literature**,
and the table "Values above the P3 thresholds" in Section 3.4 records the exceeding cases found
(the `rule` column of Table S9 notes that such cases exist).

"Defines the top category quantitatively" means all three of the following:

- (i) the guideline divides **the magnitude of the measurement itself** into grades; a
  classification of clinical severity or of disease stage does not qualify;
- (ii) its top grade is **open above** and its threshold is written **as an absolute value of the
  measurement**; a grade defined as a multiple of the upper reference limit, or one decided in
  combination with other indicators, does not qualify (the upper reference limit differs between
  assays, so a third party could not reach the same value);
- (iii) a threshold for routine risk stratification does not qualify.

Conditions (ii) and (iii) were themselves added after the candidates of Section 6.1 had been seen.
Condition (ii) was then recast, from a test on the words a guideline
uses ("massive", "very severe") to the test above on how its threshold is written (supplementary
Section S1, item 7). No adopted bound changed.

**Clause 4 (a variable defined as a subset). Like Clause 0, takes precedence over the others.**
When a dataset defines a variable as measuring a **subset** of the quantity known by the general
name, take the highest value that **the subset** can reach. The decision rests on the published
definition of the dataset (the title of the primary publication, the variable definition), not on
values.

*Application (κ and λ only).* The primary publication of `survival::flchain` is Dispenzieri A, et
al., "Use of **nonclonal** serum immunoglobulin free light chains to predict overall survival in
the general population", *Mayo Clin Proc* 2012;87(6):517–523. The columns `kappa` and `lambda`
therefore measure **nonclonal** free light chains. Extremes of monoclonal free light chains do
not bound what these columns measure. The other 10 laboratory variables are defined as the
quantity of their general name, and the clause does not apply to them.

*Supporting fact (does not replace Clause 4).* The source of the adopted reference interval,
Peña et al. 2024, ran serum protein electrophoresis and free-light-chain assays on all 142
patients and excluded the 5 (3.5%) found to be monoclonal. The adopted interval is therefore that
of a population tested free of monoclonality.

*Disclosure.* The same supplement publishes the values of the 5 excluded patients (κ/λ, mg/L:
53.2/552.3, 166.4/242.6, 590.2/149.2, 326.8/82.9, 1224.2/73.9). In an unselected haemodialysis
population, 3.5% are monoclonal and κ reaches 122.4 mg/dL, four times the adopted bound of
30 mg/dL. Such a value in our sample would be clipped, and the local-DP guarantee would still hold.

### 3.4 Adopted bounds of the 12 laboratory variables

| Variable | Unit (data) | Rule | Source value before rounding | Source unit / conversion | Bound | Source |
|---|---|---|---|---|---|---|
| pbc `bili` | mg/dL | P2b | 41 | same | **[0, 50]** | Raza SM, et al. *Cureus* 2020;12(3):e7210 (extreme hyperbilirubinaemia, adult sickle-cell hepatic sequestration) |
| pbc `chol` | mg/dL | P2b | 1,730 | same | **[0, 2000]** | Colantuono R, et al. *Front Pediatr* 2022;10:969081 (lipoprotein-X cholestasis) |
| pbc `albumin` | g/dL | P3 | 8 | same | **[0, 8]** | *Clinical Methods* 3rd ed., ch. 101 (NCBI Bookshelf NBK204): "The normal serum protein level is 6 to 8 g/dl". See note (a). |
| pbc `copper` | µg/24 h | P2a-1 | 3,080 | same | **[0, 4000]** | Walshe JM. *QJM* 2011;104(9):775–778. See note (b). |
| pbc `alk.phos` | U/L | P2a-1 | 14,589 | IU/L = U/L | **[0, 20000]** | Shkalim Zemer V, et al. *Eur J Pediatr* 2023;182(7):3211–3216 (benign transient hyperphosphatasaemia, n = 382, "range 1002–14,589 IU/L") |
| pbc `ast` | U/mL as labelled; U/L in fact, see note (c) | P3 (Clause 3) | 10,000 | IU/L = U/L | **[0, 10000]** | StatPearls, *Liver Function Tests* (NBK482489): "Massive elevation: greater than 10,000 IU/L" |
| pbc `trig` | mg/dL | P3 (Clause 3) | 2,000 | same | **[0, 2000]** | Endocrine Society guideline (Berglund et al. *J Clin Endocrinol Metab* 2012;97:2969–89) / Endotext NBK326743: very severe hypertriglyceridaemia ≥ 2,000 mg/dL |
| pbc `platelet` | ×10⁹/L | P2b | 6 ×10⁶/mm³ | 1 ×10⁶/mm³ = 1,000 ×10⁹/L | **[0, 6000]** | Natelson EA. *Tex Heart Inst J* 2012;39(6):792–798 (PMC3528235) |
| pbc `protime` | s | P2b | > 180 | same | **[0, 200]** | Kong MCP, et al. *Cureus* 2025;17(12):e99159 (bromadiolone poisoning, "Prothrombin time (s) >180"; a reporting-limit value) |
| flchain `kappa` | mg/dL | P2a-2 (Clause 4) | 281.8 mg/L | 1 mg/dL = 10 mg/L → 28.18 | **[0, 30]** | Peña C, et al. *Haematologica* 2024;109(11):3751–3754 (reference interval in haemodialysis-dependent end-stage kidney disease, 64.5–281.8 mg/L) |
| flchain `lambda` | mg/dL | P2a-2 (Clause 4) | 312.6 mg/L | 1 mg/dL = 10 mg/L → 31.26 | **[0, 40]** | Same source (47.1–312.6 mg/L); same rule as κ |
| flchain `creatinine` | mg/dL | P2b | 73.8 | same | **[0, 80]** | Persaud C, et al. "Highest Recorded Serum Creatinine". *Case Rep Nephrol* 2021;2021:6048919 |

Notes.

- (a) **albumin.** The bound rests on two facts: albumin cannot exceed total serum protein; and in
  the conditions where total protein exceeds 8 g/dL (hypergammaglobulinaemia, myeloma) the excess
  is in the globulin fraction while the albumin fraction falls. The upper limit of normal of total
  protein therefore bounds what albumin can reach from above. Albumin itself is reported up to the
  6 g/dL range in dehydration. Since 8 g/dL is the upper limit of a normal range rather than an
  absolute limit, the rule is P3, not P1; the reference range belongs to a different test (total
  protein), linked to albumin by the structural constraint above. No variable is bounded by P1.
- (b) **copper.** The full text of Walshe 2011 (subscription; obtained 2026-08-30) reports the
  observed minimum and maximum of basal 24-hour urinary copper in the three groups of 192 patients
  with Wilson's disease: pre-symptomatic 11–550 (n = 31), hepatic 61–3,080 (n = 37), neurological
  61–782 (n = 124) µg/24 h. P2a-1 takes the largest of the group maxima, 3,080, rounded up to
  4,000. The 3,080 patient was in a haemolytic crisis and the source warns that such a figure
  "will skew the statistics"; that is a caution about the group mean, not about whether the value
  can be reached, so the case is kept (Clause 1). The bound was adopted in three steps: [0, 2000] from the EASL
  penicillamine-challenge threshold (replaced under Clause 0 because that value is post-challenge),
  then [0, 1000] from the hepatic-group mean under P2a-3 while only the abstract of Walshe 2011 was
  available, and finally [0, 4000] under P2a-1 once the full text showed the observed ranges
  (Section 6.1; supplementary Section S1, item 1, reports the net change 2,000 → 4,000). Measurement conditions match pbc (basal, before treatment; Clause 0).
- (c) **ast.** The R help page labels the unit U/ml, but the observed values 26.35–457.25 would be
  26,350–457,250 U/L in that unit, which is not physiological; the unit is taken to be U/L, as
  Table S9 states. This inference consulted the observed magnitudes. It concerns the unit label of
  the data (which decides whether the source value 10,000 IU/L is 10,000 or 10 in data units), not
  the source value; it is the one place where the sample informed an entry of Table S9, and it is
  disclosed here. `obs_ref` records "No reference" because the source value was not chosen with
  reference to the data.
- (d) **kappa, lambda (P2a-2 disclosure).** The adopted limits are the upper ends of a reference
  interval, usually the 97.5th percentile, so about 2.5% of the source population (the
  haemodialysis cohort of Peña et al. 2024) exceed them. The 137 individual values of that cohort
  are published only as a figure (Supplementary Figure 1 of the source), so the exceeding values
  cannot be quoted numerically (Section 6.1).

**Values above the P3 thresholds** (Clause 3):

| Variable | Threshold adopted | Values above it in the literature |
|---|---|---|
| pbc `ast` | 10,000 IU/L | The same StatPearls chapter: "serum ALT and AST activities may exceed 200 times the upper limits of normal" |
| pbc `trig` | 2,000 mg/dL | 10,612 mg/dL (PMC6120174) and 10,320 mg/dL (PMC6556268), both free full text |

### 3.5 Search record

P2b is used only when no P2a value is found, so the unsuccessful searches are part of the record.

| Item | Content |
|---|---|
| Databases | PubMed (E-utilities, `db=pubmed`), PMC, NCBI Bookshelf (`db=books`), full texts of the sources |
| Dates | 2026-08-23 and 2026-08-24 |
| Search terms | P2a-1: variable + `series` / `cohort` / `range`. P2a-2: variable + `reference interval` / `reference range` + subpopulation (`end-stage liver disease`, `cirrhosis`, `cholestasis`, `hemodialysis`). P2a-3: variable + `mean` / `group mean`. P2b: variable + `highest reported` / `case report`. P3: variable + `classification` / `categories` / `severity` / `guideline` |
| Restriction | Free and immediately available sources (Requirement 3) |

- **P2a-1** was not found for `bili`, `chol`, `platelet`, `protime` or `creatinine`: no published
  series of the condition concerned reporting the upper end of a range was found. These are rare
  conditions in which series seldom exist.
- **P2a-2** opens only for `bili` and `chol` (the other three define the state concerned, so the
  dependency condition sends them to P2b). No reference interval for end-stage liver disease or
  cholestasis was found (PubMed, 2026-08-24: `"reference interval"[tiab] AND bilirubin[tiab] AND
  ("end-stage liver disease"[tiab] OR cirrhosis[tiab])`, 1 hit; `"reference range"[tiab] AND
  bilirubin[tiab] AND cholestasis[tiab]`, 6 hits; `"reference interval"[tiab] AND
  cholesterol[tiab] AND cholestasis[tiab]`, 2 hits; `"reference range"[tiab] AND "total
  cholesterol"[tiab] AND ("cholestatic liver disease"[tiab] OR "primary biliary"[tiab])`, 1 hit;
  none relevant).
- **Clause 3** was checked for the five P2b variables, since all five meet its condition 1. The
  candidates found and the reason none meets condition 2 are in Section 6.1. The keyword search
  was noisy and not exhaustive: the table lists the candidates found, not all that exist.
- **Limitation.** A keyword search cannot enumerate "the highest value ever reported". The five
  P2b bounds are the highest values found, not necessarily the highest that exist. This weakens
  re-derivability (Requirement 4) for P2b, though not the bounds themselves: a higher true
  maximum would only have widened the bound and increased the noise.

## 4. Tiers 3 to 6

### 4.1 Tier 3: registry censoring value

colon `nodes` and rotterdam `nodes`: **[0, 90]**. SEER Program Coding and Staging Manual 2025 (US
National Cancer Institute), Regional Nodes Positive (NAACCR item #820, p. 197): code 90 = "90 or
more nodes are positive"; supporting: Regional Nodes Examined (#830, p. 200): code 90 = "90 or more
nodes were examined". Code 90 is the upper truncation value declared by the national registry
standard, not an anatomical maximum; it is a threshold declared in advance by a public body,
independently of our samples.

### 4.2 Tier 4: age

- **Rule.** If the primary publication or the dataset documentation states an eligibility age,
  use it; otherwise use the uniform rule **[18, 110]**.
- **One-sided criteria.** If the criterion gives only one side, that side is taken from the
  criterion and the other from the uniform rule.
- **Application.** Only flchain states an eligibility age ("residents of Olmsted County aged 50 or
  greater"), giving **[50, 110]**. lung (Loprinzi et al. 1994), pbc (Therneau & Grambsch 2000),
  colon (Laurie et al. 1989; Moertel et al. 1990) and rotterdam (Royston & Altman 2013) state none
  and take [18, 110]. The help pages of all five datasets were checked (`tools::Rd_db("survival")`).

### 4.3 Tier 5: study metadata and variable-specific derivations

| Variable | Bound | Rule | Sources |
|---|---|---|---|
| flchain `sample.yr` | [1995, 2003] | First and last year of the published recruitment period, as they stand | Dispenzieri et al. 2012: "Baseline information was obtained between March 13, 1995, and November 21, 2003". The bound coincides with the observed range; the observed data were not consulted, and the fixed and data-driven arms have the same noise scale for this variable. |
| lung `meal.cal` | [0, 4000] kcal/day | Lower 0 (intake is non-negative); upper = largest official estimated energy requirement, rounded up to the next 1,000 kcal | IOM Dietary Reference Intakes, EER for very active men 3,720 kcal/day; Dietary Guidelines for Americans 2015–2020, Appendix 2 |
| lung `wt.loss` | [−50, 100] lb per 6 months (positive = loss) | Loss side: the upper side (mean + SD = 32.89 + 20.22 = 53.1 kg ≈ 117 lb) of the largest reported 6-month loss, rounded to the nearest 50 lb (100 lb); gain side: about twice the most extreme pharmacological gain | Gastric bypass, 32.89 ± 20.22 kg at 6 months (Bahadori et al. 2022, PMC9629942); olanzapine-induced gain 11.35 kg (Correll et al. 2023, PMC10388390); Minnesota Starvation Experiment as modelled by Hargrove et al. 2008 (PMC2596786) |
| rotterdam `pgr` | [0, 2000] fmol/mg | Lower 0 (receptor concentration is non-negative); upper = about twice the maximum documented in an external series | Iqbal et al. 1986 (upper 1,102 fmol/mg, PMC2001611); Pichon et al. 1996 (2,257 cases, up to 1,000 fmol/mg, PMC2074541); corroborating: Bezwoda et al. 1991 (range 3–1,000 fmol/mg), Navarro et al. 1989 (uterine fibroids, same ligand-binding method, 805–2,000 fmol/mg) |
| rotterdam `er` | [0, 2000] fmol/mg | Same rule as `pgr`: the assay is the same kind of ligand-binding method | Same sources |

For `pgr` and `er` the bound does not include the observed range. Following Section 3.2, the bound
was not moved and the clipping rate is disclosed: 0.23% for `pgr` (7 of 2,982) and 0.20% for `er`
(6 of 2,982).

### 4.4 Tier 6: time axis of the formal comparison arm

- **Rule.** The horizon is the interval from the published date on which enrolment (baseline data
  collection) began to the published date up to which follow-up was ascertained. Both dates are
  published study metadata; no observed value is consulted. No rounding.
- **flchain.** Dispenzieri et al. 2012: "Baseline information was obtained between March 13, 1995,
  and November 21, 2003, and follow-up status and cause of death were identified through June 30,
  2009." Horizon = 1995-03-13 to 2009-06-30 = **5,223 days** (`T_MAX_FIXED_NGUYEN` in
  `main/04_evaluation/R/nguyen2017_outpert.R`). It includes the longest follow-up in the analysed
  data, so no time is clipped.

## 5. Table S9 columns and the clipping check

`main/06_report/output/tabS9_fixed_bounds.csv` has one row per covariate (51 rows):

| Column | Content |
|---|---|
| `dataset`, `variable` | Covariate |
| `tier` | Tier 0–5 (Section 2) |
| `rule` | The rule or clause applied (for Tier 2, the priority P1/P2a-1/P2a-2/P2a-3/P2b/P3 and the clause) |
| `domain` | The adopted bound (or code set) |
| `unit_data`, `source_value`, `unit_source`, `conversion` | Units of the data and of the source, the source value, and the conversion factor (Requirement 5) |
| `source_citation`, `source_url`, `access_date` | The source |
| `obs_ref` | Whether the observed data were consulted: "No reference" for every row |

Table S9 holds no quantity computed from the analysed samples (the one place where the samples
informed an entry is the unit label of pbc `ast`, note (c) of Section 3.4). The **clipping rate and
the width ratio** depend on the data and are computed separately, by `main/03_simulation/simulation_bounds_comparison.Rmd`,
which writes them to `data/03_simulation/phase1_bounds_fixed/bounds_check.csv`. A copy of that file
as produced for the manuscript is `docs/fixed_bounds_clipping_check.csv` (27 continuous covariates;
columns `obs`, `fixed`, `widened` give the observed range and the two bounds, `fixed_ratio` and
`widened_ratio` the width ratios, `fixed_clip_pct` and `widened_clip_pct` the percentage of values
clipped; `unit_flag` is `要確認` ("check") where the fixed ratio lies outside 1–50).

Results of the check:

- Under fixed bounds only rotterdam `pgr` (0.23%) and `er` (0.20%) are clipped; their width ratios,
  0.40 and 0.61, are the only ones outside 1–50.
- The 12 laboratory variables have width ratios between 1.21 (`chol`) and 24.69 (`protime`) and
  no clipping. No unit error was detected.
- 16 of the 27 continuous covariates have a width ratio below 2.0. Ratios of 5 or more occur for
  5 variables: pbc `ast` 23.21, `protime` 24.69, `platelet` 11.98, `copper` 6.85, and flchain
  `creatinine` 7.69.

## 6. Rejected candidates and rejected rules

"Consequence" gives the bound the candidate would have produced and, where it would have clipped
the observed data, the observed maximum. Such consequences are recorded for disclosure; as stated
in Section 0, they are not grounds for adopting or rejecting a source.

### 6.1 Laboratory variables (Tier 2)

| Variable | Candidate | Value | Consequence | Reason for rejection |
|---|---|---|---|---|
| pbc `bili` | CTCAE v5.0, "Blood bilirubin increased", grade 4 (original checked 2026-08-24) | > 10.0 × upper reference limit | [0, 20] with an upper limit of 1.2 mg/dL (12 mg/dL); clips the observed maximum 28.0 | Clause 3, condition (ii): the top grade is a multiple of the reference limit, not an absolute value. |
| | Published series with the range of the condition (P2a-1) | — | — | Not found (2026-08-23, 2026-08-24). |
| | Reference interval in end-stage liver disease or cholestasis (P2a-2) | — | — | Not found (queries in Section 3.5). |
| pbc `chol` | NCEP ATP III total cholesterol "high" (*JAMA* 2001;285(19):2486–2497; original checked 2026-08-24) | ≥ 240 mg/dL | [0, 300]; clips the observed maximum 1,775 | Clause 3, condition (iii): a risk-stratification threshold. ATP III has since been superseded (2013). |
| | Reference interval in cholestasis (P2a-2) | — | — | Not found (queries in Section 3.5). |
| pbc `albumin` | Upper reference limit of albumin itself | 5.0 g/dL | [0, 5] | An upper reference limit, not a value albumin can reach (values in the 6 g/dL range are reported in dehydration). |
| | Total protein in hypergammaglobulinaemia or myeloma | > 10 g/dL | — | A pathological value of total protein; the excess is globulin and albumin does not follow it (note (a) of Section 3.4). |
| | P1 classification of the 8 g/dL value | 8 g/dL | Same bound | 8 g/dL is the upper limit of a normal range, not an absolute limit; reclassified as P3. The bound did not change. |
| pbc `copper` | EASL guideline, penicillamine challenge test, diagnostic level > 25 µmol/24 h (1,575 µg/24 h) | 1,575 µg/24 h | [0, 2000] (the first adopted bound) | Clause 0: measured after two doses of D-penicillamine, not basal. EASL itself states that the test "has only been standardized in a pediatric population" and is not recommended for diagnosis in adults. |
| | EASL guideline, basal diagnostic threshold > 1.6 µmol/24 h | 100 µg/24 h | [0, 100]; clips the observed maximum 588 | A diagnostic threshold, not an upper limit. |
| | GeneReviews: urinary copper early in chelation treatment can exceed 16 µmol (1,000 µg)/24 h | Open | Undefined | Clause 0 (after treatment); no upper end. |
| | Walshe 2011, hepatic-group mean 465.75 µg/24 h under P2a-3 (500 × 2) | 465.75 µg/24 h | [0, 1000] (adopted after the Clause 0 replacement, until the full text was obtained) | Superseded: the full text reports the observed ranges, so P2a-1 takes precedence and P2a-3 is not reached. |
| | Walshe 2011, maxima of the pre-symptomatic or neurological group | 550 / 782 µg/24 h | [0, 600] / [0, 800] | P2a-1 takes the largest of the group maxima (Clause 1), not the group with the most patients. |
| | Walshe 2011, hepatic maximum excluding the haemolytic-crisis case | Not reported | Undefined | The source does not report the next value, and excluding the case would narrow the bound against Clause 1. |
| pbc `alk.phos` | Series in adult cholestasis with a reported range | — | — | Not found (2026-08-23, 2026-08-24); case reports exist but no series reports a range. |
| pbc `ast` | StatPearls: AST "may exceed 200 times the upper limits of normal" | Open | Undefined | No upper end. |
| pbc `trig` | Highest values in single case reports (PMC6120174, PMC6556268) | 10,612 / 10,320 mg/dL | [0, 20000]; width ratio 35 | Clause 3 gives precedence to the guideline threshold for re-derivability. The two cases are disclosed as values above the threshold. |
| pbc `platelet` | WHO essential thrombocythaemia, major criterion 1 (as quoted by StatPearls NBK539709; checked 2026-08-24) | ≥ 450 ×10⁹/L | — | A diagnostic threshold (the lower end of a category), not a graded magnitude (Clause 3, condition (i)). Only one P2b candidate was found. |
| pbc `protime` | CTCAE v5.0, "INR increased" | Multiples of the upper reference limit | — | Graded on the INR, not on seconds (Requirement 5). Only one P2b candidate was found; the adopted "> 180 s" is a reporting-limit value. |
| flchain `kappa`, `lambda` | Light-chain myeloma series (Singh G. *Lab Med* 2019;50(2):189–193) | κ 9,970 mg/L, λ 27,091 mg/L | κ [0, 1000], λ [0, 3000] mg/dL; width ratios 48.8 and 113 | Clause 4: the columns measure nonclonal free light chains. The width ratio is not the reason. |
| | Observed range of the haemodialysis cohort of Peña et al. 2024 (P2a-1) | Published as a figure only | — | The 137 individual values appear only as Supplementary Figure 1 (an image), so the range cannot be re-derived in the form Requirement 4 asks (supplementary Section S1, item 4). Had it been published numerically, P2a-1 would apply and the bound would be wider. |
| flchain `creatinine` | Previous highest reported value cited by Persaud et al. 2021 | 53 mg/dL | — | The same paper reports a higher value (73.8). |
| | KDIGO acute kidney injury, stage 3 (*Kidney Int Suppl* 2012;2(1):1–138; checked 2026-08-24) | ≥ 4.0 mg/dL, or 3 × baseline, or start of renal replacement therapy (with urine-output criteria) | [0, 4]; clips the observed maximum 10.8 | Clause 3, conditions (i) and (ii): a staging of a syndrome, decided in combination with other indicators. |
| | Reference interval in haemodialysis-dependent kidney disease (P2a-2) | — | — | Dependency condition of Clause 2: creatinine defines kidney function; its extremes are set by individual acute conditions. |

### 6.2 Rejected rules

| Rule | Reason |
|---|---|
| A single compendium of reference ranges with one common multiplier k for all laboratory variables (upper bound = upper reference limit × k) | No common k exists. The multiplier needed to avoid clipping ranges from 0.84 (albumin) to 115.5 (alk.phos). With k = 10, 53.5% of pbc `alk.phos` would be clipped and 18.6% still with k = 20, while k = 20 makes the albumin bound 41 times its observed width. Laboratory variables fall into those that rise steeply in disease (alk.phos, bili, ast) and those that do not (albumin, platelet, protime), so one multiplier cannot fit both. The comparison used the observed ranges, which is disclosed here. Replaced by the variable-specific priorities of Section 3.2 before any bound was adopted. Variable-specific physiological ranges are also the form of the precedents in the DP literature (for example BMI 10–60, age 0–125). |
| Restricting the conditions considered to those possible within the published eligibility criteria of the dataset (for flchain, excluding light-chain myeloma because known plasma-cell disorders were excluded) | Contrary to fact for `survival::flchain`: the exclusion applied to the analysis population of the 2012 paper, while the dataset contains 115 subjects with `mgus` = 1 (96 after preprocessing), entered as a covariate. Replaced by Clauses 0, 1 and 4. |
| Clause 0 with a second criterion, "or a different mechanism of rise" | Undecidable (how finely a mechanism is distinguished changes the outcome); inconsistent with Clause 1; read literally it would disqualify the sources of four variables (and the replacement source of `copper`). Withdrawn; the κ/λ decision now rests on Clause 4. |
| Clause 3, condition (ii) as a test on words ("massive", "very severe", "extreme", …) | The word list was open-ended, the free-source restriction biases sources towards English, and the test duplicated condition (i). Recast as the test on how the threshold is written. No bound changed. |

### 6.3 Other tiers

| Variable | Candidate | Reason for rejection |
|---|---|---|
| flchain `age` | [50, 101] | Its upper end is the observed maximum, which would make the bound data-dependent. The one-sided rule (Section 4.2) gives [50, 110]. |
| flchain `age` | [18, 110] | Ignores the stated eligibility age. |
| lung `meal.cal` | [0, 3200] (top of the table range of the Dietary Guidelines) | The largest official estimated energy requirement (3,720 kcal/day for very active men) exceeds it; the rule takes the largest official value. |
| flchain time horizon (Tier 6) | 5,478.75 days (15 × 365.25; follow-up assumed to end on 2009-12-31) | The end date had no primary source. Replaced by the published dates (5,223 days). |

## 7. Access notes

The adopted sources were accessed on the dates recorded in Table S9 (2026-08-15, 2026-08-23,
2026-08-25 and 2026-08-30); the rejected candidates of Section 6 were checked on 2026-08-23 and
2026-08-24. Automated download of some publisher pages (ABIM, the Mayo Clinic
Laboratories catalogue, the *Journal of Hepatology* page of the EASL guideline) was refused; they
are free to read in a browser, and the values used are quoted in Table S9 or in this document. The
full text of Walshe 2011 is available by subscription only; its abstract is free (PubMed
21622540).
