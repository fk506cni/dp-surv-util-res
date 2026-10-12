library(survival)
library(dplyr)
library(furrr)
library(progressr)

EPSILON_VALUES <- c(0.1, 0.5, 1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 15.0, 30.0, 60.0, 100.0, 250.0, 1000.0, Inf)

COX_FORMULAS <- list(
  lung  = Surv(time, status) ~ age + sex + ph.ecog + ph.karno +
    pat.karno + meal.cal + wt.loss,
  pbc   = Surv(time, status) ~ age + sex + trt + ascites + hepato +
    spiders + edema + bili + chol + albumin + copper + alk.phos +
    ast + trig + platelet + protime + stage,
  colon = Surv(time, status) ~ sex + age + obstruct + perfor + adhere +
    nodes + differ + extent + surg + node4 + rx,
  rotterdam = Surv(time, status) ~ age + meno + size + grade + nodes +
    pgr + er + hormon + chemo,
  flchain = Surv(time, status) ~ age + sex + sample.yr + kappa +
    lambda + creatinine + mgus
)

compute_c_index_orig <- function(cox_formula, data, beta) {
  tryCatch({
    rhs_terms <- attr(terms(cox_formula), "term.labels")
    rhs_formula <- reformulate(rhs_terms)
    mm_orig <- model.matrix(rhs_formula, data = data)
    mm_orig <- mm_orig[, colnames(mm_orig) != "(Intercept)", drop = FALSE]
    common <- intersect(colnames(mm_orig), names(beta))
    if (length(common) > 0) {
      lp_orig <- as.numeric(mm_orig[, common, drop = FALSE] %*% beta[common])
      surv_obj <- Surv(data$time, data$status)
      as.numeric(concordancefit(surv_obj, -lp_orig)$concordance)
    } else {
      NA_real_
    }
  }, error = function(e) NA_real_)
}

run_single_simulation <- function(data, perturb_fn, epsilon, seed, cox_formula) {
  set.seed(seed)

  perturbed_data <- perturb_fn(data, epsilon)

  result <- tryCatch(
    {
      fit <- coxph(cox_formula, data = perturbed_data)
      beta <- coef(fit)
      se <- sqrt(diag(vcov(fit)))
      var_names <- names(beta)
      hr <- exp(beta)
      z <- beta / se
      p_val <- 2 * pnorm(-abs(z))
      c_idx <- concordance(fit)$concordance

      c_idx_orig <- compute_c_index_orig(cox_formula, data, beta)

      data.frame(
        variable     = var_names,
        beta         = unname(beta),
        se           = unname(se),
        hr           = unname(hr),
        p_value      = unname(p_val),
        c_index      = as.numeric(c_idx),
        c_index_orig = c_idx_orig,
        converged    = TRUE,
        error_msg    = NA_character_,
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    },
    warning = function(w) {
      fit <- suppressWarnings(coxph(cox_formula, data = perturbed_data))
      beta <- coef(fit)
      se <- sqrt(diag(vcov(fit)))
      var_names <- names(beta)
      hr <- exp(beta)
      z <- beta / se
      p_val <- 2 * pnorm(-abs(z))
      c_idx <- tryCatch(concordance(fit)$concordance,
                        error = function(e) NA_real_)

      c_idx_orig <- compute_c_index_orig(cox_formula, data, beta)

      data.frame(
        variable     = var_names,
        beta         = unname(beta),
        se           = unname(se),
        hr           = unname(hr),
        p_value      = unname(p_val),
        c_index      = as.numeric(c_idx),
        c_index_orig = c_idx_orig,
        converged    = FALSE,
        error_msg    = conditionMessage(w),
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    },
    error = function(e) {
      data.frame(
        variable     = "FAILED",
        beta         = NA_real_,
        se           = NA_real_,
        hr           = NA_real_,
        p_value      = NA_real_,
        c_index      = NA_real_,
        c_index_orig = NA_real_,
        converged    = FALSE,
        error_msg    = conditionMessage(e),
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    }
  )

  result$epsilon <- epsilon
  result$seed    <- seed
  result
}

run_simulation_batch <- function(data,
                                 perturb_fn,
                                 epsilon_values,
                                 B,
                                 base_seed,
                                 cox_formula,
                                 dataset_name = "unknown") {
  if (!exists("set_reference_levels", mode = "function")) {
    stop("set_reference_levels() が見つからない。",
         "main/03_simulation/R/data_split.R を source すること")
  }
  data <- set_reference_levels(as.data.frame(data), dataset_name)

  params <- expand.grid(
    epsilon   = epsilon_values,
    iteration = seq_len(B),
    stringsAsFactors = FALSE
  )

  eps_lookup <- setNames(seq_along(epsilon_values), as.character(epsilon_values))
  params$seed <- base_seed +
    (eps_lookup[as.character(params$epsilon)] - 1L) * B +
    params$iteration

  n_tasks <- nrow(params)
  message(sprintf(
    "[%s] Running %d simulations (%d epsilon values x %d iterations)...",
    dataset_name, n_tasks, length(epsilon_values), B
  ))

  p <- progressor(steps = n_tasks)

  message(sprintf("[%s] Launching future_map with %d tasks...", dataset_name, n_tasks))

  results <- future_map(
    seq_len(n_tasks),
    function(i) {
      res <- run_single_simulation(
        data       = data,
        perturb_fn = perturb_fn,
        epsilon    = params$epsilon[i],
        seed       = params$seed[i],
        cox_formula = cox_formula
      )
      res$iteration <- params$iteration[i]
      p()
      res
    },
    .options = furrr_options(seed = FALSE)
  )

  message(sprintf("[%s] future_map completed.", dataset_name))

  result_df <- bind_rows(results)
  result_df$dataset <- dataset_name
  result_df
}
