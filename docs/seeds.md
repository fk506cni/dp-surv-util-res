# Seed record

Every random draw in the simulations is seeded explicitly with `set.seed()` immediately before the
draw. The result rows of the simulation arms and of the formal comparison arm, written under
`data/03_simulation/` and `data/04_evaluation/` when the pipeline is run, carry the seed they were
drawn with (column `seed`). The formal comparison arm also records its train/test split seed
(column `split_seed` of `exp_g_pilot_flchain_raw.csv`); the other train/test arms and the subsampling
experiment do not store their split or draw seeds as a column, and those are given by the formulas
below. This document lists the seed formula of each arm and the band of seeds it consumes. The bands
below were measured on the result files used for the manuscript where a `seed` column exists, and
computed from the formula otherwise (the subsampling rows).

Notation: dataset offsets `d` = 0, 1, 2, 3, 4 for lung, pbc, colon, rotterdam, flchain;
`k` = 1, …, 15 is the position of ε in the grid
(0.1, 0.5, 1, 2, 3, 5, 7, 10, 15, 30, 60, 100, 250, 1000, ∞); `i` = 1, …, B is the Monte Carlo
iteration; B = 1,000.

| Arm | Seed of iteration `i` at budget `k` | Band | Code |
|---|---|---|---|
| Input perturbation, Phases 1–3 (in-sample and 70/30 train/test) | `42 + 100000·d + (k−1)·B + i` | 43 – 415,042 | `main/03_simulation/R/simulation_engine.R`, `simulation_phase3.R`, `*_traintest.R` |
| Output perturbation, central model (in-sample) | the same `+ 500000` (added inside `run_output_simulation_batch()`) | 500,043 – 915,042 | `main/03_simulation/R/simulation_output.R` |
| Output perturbation, central model (70/30 train/test) | `42 + 100000·d + (k−1)·B + i` (no offset) | 43 – 415,042 | `main/03_simulation/R/simulation_output_traintest.R` |
| Train/test split of iteration `i` (all train/test arms) | `100000 + i` | 100,001 – 101,000 | `main/03_simulation/R/data_split.R` |
| Fixed clipping bounds (Phase 1, in-sample and 70/30 train/test) | input-perturbation formula `+ 1000000` | 1,000,043 – 1,415,042 | `main/02_dp_mechanisms/R/dp_bounds_comparison.R` |
| Widened clipping bounds (Phase 1, in-sample and 70/30 train/test) | input-perturbation formula `+ 2000000` | 2,000,043 – 2,415,042 | same |
| Formal comparison arm (flchain; four specifications `s`, five λ values `l`) | `3100000 + (((s−1)·5 + (l−1))·15 + (k−1))·1000 + i` | 3,100,001 – 3,400,000 | `main/04_evaluation/R/nguyen2017_outpert.R`, `main/04_evaluation/exp_g_pilot_flchain.Rmd` |
| Subsampling experiment (flchain), subsample of size level `L` = 1, …, 7 | `2000000 + 100000·L + i` | 2,100,001 – 2,701,000 | `main/04_evaluation/fpr_subsampling.Rmd` |
| Subsampling experiment, perturbation noise at levels `L` = 1, …, 6 | `42 + 100000·(39 + L) + (k−1)·B + i` | 4,000,043 – 4,515,042 | same |
| Subsampling experiment, perturbation noise at level 7 (the full data) | `42 + 100000·4 + (k−1)·B + i` | 400,043 – 415,042 | same |

Notes.

- **Shared seeds by design.** Runs that differ only in a setting reuse the same seeds, so that the
  setting is the only difference: the reference-level runs (`*_reffix`, used in the revised
  manuscript) and the runs of the original submission; and level 7 of the subsampling experiment,
  which is the full flchain dataset, and the flchain Phase 1 run (their coefficients and standard
  errors are identical).
- **Numerical overlaps between streams of different purpose.** The split seeds (100,001–101,000)
  overlap the band of the pbc perturbation runs, and the subsample-draw seeds (2,100,001–2,701,000)
  overlap the band of the widened-bound arm. In each case one stream selects rows and the other
  draws perturbation noise, and no analysis combines the two. The train/test output-perturbation
  arm (third row) uses exactly the band of the input-perturbation arms (first row): at the same
  dataset, budget and iteration the two mechanisms draw from the same seed, which is harmless
  because they perturb different objects (the coefficient vector and the covariates) and are never
  combined.
- Documents that only summarise stored results call `set.seed(42)` by convention; the two single
  illustrative perturbations in `main/04_evaluation/phase3_discordance.Rmd` also use seed 42.
- The parallel workers do not use the `future` seed streams (`furrr_options(seed = FALSE)`); each
  iteration sets its own seed as above, so results do not depend on the number of workers.
