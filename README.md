# dp-surv-util

Code and outputs for

> K. Fukuyama, Y. Mori, T. Kuroda, and H. Kikuchi, "Statistical Utility of Cox Regression Under
> Differential-Privacy-Style Perturbation: Clipping Bounds, Local and Central Mechanisms, and the
> Price of Formal Guarantees."

The supplementary document is `docs/supplementary.pdf`, also archived at
<https://doi.org/10.5281/zenodo.23185979>. It contains Figs. S1–S8 and Tables S1–S10.

This repository holds what is needed to regenerate the figures and tables of the manuscript and the
supplement from the five datasets of the R `survival` package: the perturbation mechanisms, the
simulations, the evaluation, and the documents that draw the figures and tables, together with the
outputs used in the manuscript.

## Contents

| Path | Content |
|---|---|
| `main/01_data_prep/` | Preparation of lung, pbc, colon, rotterdam and flchain from the R `survival` package |
| `main/02_dp_mechanisms/R/` | Perturbation mechanisms: Laplace and randomized response (input perturbation, Phases 1–3), output perturbation, fixed clipping bounds |
| `main/03_simulation/` | Simulations (in-sample and 70/30 train/test) and their engine functions (`R/`) |
| `main/04_evaluation/` | Evaluation: KPIs, significance-level sensitivity, false-positive mechanism, subsampling, Phase 3 diagnostics, formal comparison arm (Nguyen & Hui's Algorithm 1, `R/nguyen2017_outpert.R`) |
| `main/06_report/` | Documents that draw the figures and tables; outputs in `main/06_report/output/` |
| `docs/supplementary.pdf` | Supplementary document |
| `docs/fixed_bounds_source_protocol.md` | The protocol of the fixed clipping bounds, with every rejected candidate |
| `docs/fixed_bounds_clipping_check.csv` | Width ratio and clipping rate of the 27 continuous covariates under fixed bounds |
| `docs/seeds.md` | Seed formulas and seed bands of every simulation arm |
| `docker/`, `renv.lock` | Computing environment |

## Printed figures and tables

File names are stable identifiers and do not follow the printed numbers. Figures are in
`main/06_report/output/` as `.pdf`, tables as `.csv` and `.tex`. The suffix `_reffix` marks the runs
used in the revised manuscript: in these runs each factor-coded covariate keeps its reference level
(`REFERENCE_LEVELS` in `main/03_simulation/R/data_split.R`; the control arm for colon `rx`) at every
privacy budget.

| File | Printed number | Content | Written by |
|---|---|---|---|
| `fig1_lsr_reffix` | Fig. 1 | Loss of significance rate against ε, Phases 1–3 | `paper_results_reffix.Rmd` |
| `fig2_cindex_test_reffix` | Fig. 2 | Test C-index against ε | `paper_results_reffix.Rmd` |
| `figS3_fpr_reffix` | Fig. 3 | Mean false positive rate against ε | `paper_results_reffix.Rmd` |
| `fig5_bounds_comparison` | Fig. 4 | Data-driven, fixed and widened clipping bounds | `revise_results.Rmd` |
| `tabS5_variable_types` | Table I | Covariate types and mechanisms | `revise_results.Rmd` |
| `tab1_baseline_reffix` | Table II | Datasets and baseline Cox models | `paper_results_reffix.Rmd` |
| `tabS2_sim_params_reffix` | Table III | Simulation settings | `paper_results_reffix.Rmd` |
| `tab5_transition_zone_reffix` | Table IV | Loss of significance in the transition zone | `paper_results_reffix.Rmd` |
| `tab4_threshold_reffix` | Table V | Reference ε values | `paper_results_reffix.Rmd` |
| `tabS10_exp_g` | Table VI | Comparison with a formal DP method (flchain) | `revise_results.Rmd` |
| `figS1_lsr_per_variable_reffix` | Fig. S1 | Loss of significance per coefficient (lung) | `paper_results_reffix.Rmd` |
| `figS5_fpr_alpha_sensitivity` | Fig. S2 | False positive rate at three significance levels | `revise_results.Rmd` |
| `figS6_fpr_mechanism` | Fig. S3 | Mechanism of the false-positive peak | `revise_results.Rmd` |
| `figS7_fpr_subsampling` | Fig. S4 | Subsampling of flchain | `revise_results.Rmd` |
| `figS4_fpr_by_variable_reffix` | Fig. S5 | False positive rate per coefficient (pbc) | `paper_results_reffix.Rmd` |
| `fig6_exp_g` | Fig. S6 | Formal comparison arm (flchain) | `revise_results.Rmd` |
| `fig3_hr_distribution_reffix` | Fig. S7 | Hazard-ratio distributions | `paper_results_reffix.Rmd` |
| `fig4_hr_bias_reffix` | Fig. S8 | Hazard-ratio relative bias | `paper_results_reffix.Rmd` |
| `tab2_lsr_reffix` | Table S1 | Loss of significance rate, all values | `paper_results_reffix.Rmd` |
| `tab3_cindex_test_reffix` | Table S2 | Test C-index, all values | `paper_results_reffix.Rmd` |
| `tabS3_fpr_full` | Table S3 | False positive rate, all budgets | `revise_results.Rmd` |
| `tabS4_alpha_sensitivity` | Table S4 | Significance-level sensitivity | `revise_results.Rmd` |
| `tabS6_grr_variance` | Table S5 | Variance of generalized randomized response against optimized unary encoding | `revise_results.Rmd` |
| `tabS7_phase3_baseline_discordance` | Table S6 | Discrete-time model against the Cox baseline at zero noise | `revise_results.Rmd` |
| `tabS12_phase3_exclusion` | Table S7 | Self-referential Phase 3 baseline | `revise_results.Rmd` |
| `tabS8_bounds_comparison` | Table S8 | Clipping-bound strategies at representative budgets | `revise_results.Rmd` |
| `tabS9_fixed_bounds` | Table S9 | Fixed bounds of the 51 covariates with their sources | `revise_results.Rmd` |
| `tabS8_bounds_thresholds` | Table S10 | Reference ε values under each clipping-bound strategy | `revise_results.Rmd` |

The documents are in `main/06_report/`. Some printed tables are typeset from a form derived on the
manuscript side, with the same values: Table III selects and relabels eight rows of
`tabS2_sim_params_reffix`; Table IV omits the last column (`lsr_drop`) of
`tab5_transition_zone_reffix`; Table VI combines four specifications of `tabS10_exp_g` with
the flchain `Output` column of `tab3_cindex_test_reffix` and omits the price and gap columns;
Tables S3, S4, S5, S8 and S10 split or shorten the files above to fit the page; Table S9 shows a
subset of the columns of `tabS9_fixed_bounds.csv`, which also gives the applied rule, the unit
conversion and the full citation of every bound.

**Data files cited by name** (also in `main/06_report/output/`):

- `fpr_mechanism_coef_peaks.csv` — the peak false positive rate of every coefficient that is
  non-significant at baseline, for α ∈ {0.01, 0.05, 0.10} and Phases 1–3 (248 rows; the 27 rows
  with `alpha = 0.05` and `phase = "Phase 1"` are the coefficients of Section IV-D).
- `fpr_mechanism_peak_decomp.csv` — for those 27 coefficients, the centre `z_eff` and dispersion
  `disp_eff` (d_eff in the supplement) of the perturbed Wald statistic at the peak budget, the
  observed peak `fpr_full`, the single-route counterfactuals `fpr_se_only`, `fpr_beta_only` and
  `fpr_disp_only`, and the decomposition `z_base`, `shift_z`, `r_se`. The `driver` column is the
  single-route classification behind the counts 13 / 7 / 10 of Section IV-D and is written in
  Japanese: `β の変動が単独で十分` (the shift of β alone reproduces at least half of the peak; 10),
  `SE 縮小が単独で十分` (the shrinkage of the standard error alone suffices; 4),
  `両経路とも単独で十分` (either route alone suffices; 3) and
  `どちらも単独では不十分（相互作用）` (neither route alone suffices; 10).
- `alpha_sensitivity_lsr_detail.csv` — the loss of significance rate of every coefficient that is
  significant at the Cox baseline, for each α, phase, dataset and budget (3,300 rows). For Phase 3
  the coefficients excluded in Section III-D are removed.

## Reproducing the results

### Environment

The code runs in a Docker container with R 4.4.1 and the repository mounted at
`/home/rstudio/project` (all paths in the code are absolute to that location).

```bash
git clone https://github.com/fk506cni/dp-surv-util-res.git
cd dp-surv-util-res
docker compose -f docker/docker-compose.yml build      # or: --profile renv build rstudio-renv
docker compose -f docker/docker-compose.yml up -d      # RStudio Server at http://127.0.0.1:8788
```

`docker/Dockerfile.renv` with `renv.lock` pins every R package version (start it with
`--profile renv`; port 8789). The image also installs the `opendp` package (from R-Universe, compiled
with Rust) because the development environment used it as a reference implementation; none of the
documents in this repository uses it. The simulations run in parallel; to bound the load on the host,
limit the container, for example `docker update --cpus=12 dp-surv-util-rstudio`. The limit does not
change the results.

### Order

Render each document inside the container, for example

```bash
docker exec dp-surv-util-rstudio Rscript -e \
  "rmarkdown::render('/home/rstudio/project/main/01_data_prep/data_prep.Rmd')"
```

in this order. Outputs go to `data/` (created by the pipeline) and to `main/06_report/output/`.
Rendering also writes an HTML file next to each document and SVG, PNG and XLSX versions of the
printed outputs; these are not tracked (`.gitignore`), so `git status` stays clean after a full run.

| # | Document | Main outputs |
|---|---|---|
| 1 | `main/01_data_prep/data_prep.Rmd` | `data/01_prepared/` |
| 2 | `main/03_simulation/simulation_reffix.Rmd` | In-sample runs, Phases 1–3 and output perturbation |
| 3 | `main/03_simulation/simulation_reffix_traintest.Rmd` | 70/30 train/test runs |
| 4 | `main/04_evaluation/evaluation_reffix.Rmd` | Phase 3 exclusion set, summary KPIs |
| 5 | `main/04_evaluation/evaluation_reffix_artifacts.Rmd` | KPI tables read by step 12 |
| 6 | `main/03_simulation/simulation_bounds_comparison.Rmd` | Fixed- and widened-bound runs (in-sample) |
| 7 | `main/03_simulation/simulation_bounds_comparison_traintest.Rmd` | Fixed- and widened-bound runs (train/test) |
| 8 | `main/04_evaluation/phase3_discordance.Rmd` | Phase 3 diagnostics (Table S6) |
| 9 | `main/04_evaluation/phase3_exclusion_sensitivity.Rmd` | Self-referential baseline (Table S7) |
| 10 | `main/04_evaluation/fpr_subsampling.Rmd` | Subsampling experiment (Fig. S4) |
| 11 | `main/04_evaluation/exp_g_pilot_flchain.Rmd` | Formal comparison arm (Fig. S6, Table VI) |
| 12 | `main/06_report/paper_results_reffix.Rmd` | Figs. 1–3, Tables II–V, Figs. S1, S5, S7, S8, Tables S1, S2 |
| 13 | `main/04_evaluation/alpha_sensitivity.Rmd` | Significance-level sensitivity |
| 14 | `main/04_evaluation/fpr_mechanism.Rmd` | False-positive mechanism |
| 15 | `main/06_report/revise_results.Rmd` | The remaining figures and tables, and the three data files above |

Steps 6–11 depend only on steps 1–5 and can run in any order. Step 12 reads
`main/06_report/output/tabS5_variable_types.csv`, which step 15 rewrites with the same content.
Several documents check that their inputs were written after the code that produces them; render
them in the order above.

**Running time.** Steps 2, 3, 6, 7, 10 and 11 are Monte Carlo runs with B = 1,000 iterations. As
measured for the manuscript runs: step 2 about 32 minutes and step 3 about 26 minutes (24-core
host, 10 workers); steps 6 and 7 about 18 minutes each (container limited to 4–6 CPUs); step 10
under ten minutes (the simulation itself about 3.5 minutes with 16 workers); step 11 about two
hours (estimated from a 10-iteration run with 16 workers; the full run was not timed). Step 8 fits
many models in one process and takes about eight minutes on 6–8 cores; run it alone. The other
steps take seconds to a minute. Steps 2
and 3 accept `REFFIX_SMOKE=1` in the environment (10 iterations, written under `data/variants/`)
and step 10 accepts `B2_B_ITER=<n>` and `B2_N_WORKERS=<k>` (written under `data/variants/`) for a
quick test of the code path; the manuscript values need the full runs.

The results of the simulation arms do not depend on the number of workers (every iteration sets its
own seed). The last digits of the model fits of step 8 can depend on the number of threads the
BLAS library uses on the host; the printed tables are unaffected.

### Seeds

Every random draw is seeded explicitly; the formulas and bands are in `docs/seeds.md`. The result
rows of the simulation arms record their seed; the exceptions are listed there.

## Notes

- **Trust models.** The local model (input perturbation by each individual) and the central model
  (output perturbation by a trusted curator) are trust models, not guarantees. The data-driven
  clipping bounds and the dfbeta sensitivity carry no formal differential-privacy guarantee; a
  formal guarantee holds only for the fixed-bound arm (covariate-level, Phase 1; manuscript
  Section III-I) and the external comparison arm (Section III-F). The two trust models are described
  in Section III-B.
- **What was removed.** The documents in `main/` keep only their YAML header and their code
  chunks: all narrative text outside the chunks (section headings, the captions written in the
  narrative, and discussion), and all comments, were removed for this repository, so the HTML
  output of each document is a sequence of chunk outputs; the captions given inside `kable()`
  calls remain. A small number of string literals that referred to internal working records were
  edited (two cells of `tabS9_fixed_bounds.{csv,tex}` and of the constant that generates them,
  and one working-copy-only guard in `revise_helpers.R`, were substituted in the same way). In
  addition, two comments of `docker/docker-compose.yml` were translated into English, the `file=`
  fields of `main/06_report/references.bib` (local paths) were dropped, and one chunk label of
  `revise_results.Rmd` was renamed (`expc-cells`; the file it writes, `expc_cells.csv`, is named
  accordingly). The computations are otherwise the code that produced the results; this was
  verified by comparing the non-comment tokens of every file before and after the transformation,
  string literals being compared after the same edits.
- **Language.** Column names, chunk labels, the captions of `kable()` calls and some messages
  printed while knitting, and the two columns noted above, are in Japanese.

## License

[GNU General Public License v3.0](LICENSE)
