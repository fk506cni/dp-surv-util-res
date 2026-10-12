library(survival)
library(dplyr)
library(furrr)

run_single_output_simulation <- function(fit, epsilon, seed,
                                          sensitivity_info, model_matrix,
                                          surv_obj, precomputed,
                                          null_distributions = NULL) {
  set.seed(seed)

  tryCatch({

  result <- perturb_cox_output(fit, epsilon, sensitivity_info,
                                seed = seed, precomputed = precomputed)

  lp_dp <- as.numeric(model_matrix %*% result$beta_dp)
  c_result <- tryCatch(
    {
      c_obj <- concordancefit(surv_obj, -lp_dp)
      as.numeric(c_obj$concordance)
    },
    error = function(e) NA_real_
  )

  p <- length(result$variable)

  p_naive <- 2 * pnorm(-abs(result$z_dp))

  if (is.infinite(epsilon)) {
    return(data.frame(
      variable       = result$variable,
      beta           = result$beta_dp,
      se             = result$se,
      hr             = result$hr_dp,
      p_value        = p_naive,
      p_value_mc     = p_naive,
      p_value_naive  = p_naive,
      c_index        = c_result,
      converged      = TRUE,
      error_msg      = NA_character_,
      epsilon        = epsilon,
      seed           = seed,
      beta_original  = result$beta_original,
      noise_scale_z  = result$noise_scale_z,
      laplace_scale  = result$laplace_scale,
      stringsAsFactors = FALSE,
      row.names      = NULL
    ))
  }

  p_dp_analytical <- mapply(
    dp_pvalue_analytical,
    z_obs = result$z_dp,
    noise_scale = result$noise_scale_z
  )

  if (!is.null(null_distributions)) {
    eps_key <- as.character(epsilon)
    p_dp_mc <- numeric(p)
    for (j in seq_len(p)) {
      var_name <- result$variable[j]
      null_key <- paste0(var_name, "_", eps_key)
      if (!is.null(null_distributions[[null_key]])) {
        p_dp_mc[j] <- dp_pvalue_mc_from_null(
          result$z_dp[j],
          null_distributions[[null_key]]
        )
      } else {
        p_dp_mc[j] <- NA_real_
      }
    }
  } else {
    p_dp_mc <- rep(NA_real_, p)
  }

  data.frame(
    variable       = result$variable,
    beta           = result$beta_dp,
    se             = result$se,
    hr             = result$hr_dp,
    p_value        = p_dp_analytical,
    p_value_mc     = p_dp_mc,
    p_value_naive  = p_naive,
    c_index        = c_result,
    converged      = TRUE,
    error_msg      = NA_character_,
    epsilon        = epsilon,
    seed           = seed,
    beta_original  = result$beta_original,
    noise_scale_z  = result$noise_scale_z,
    laplace_scale  = result$laplace_scale,
    stringsAsFactors = FALSE,
    row.names      = NULL
  )

  }, error = function(e) {
    data.frame(
      variable       = "FAILED",
      beta           = NA_real_,
      se             = NA_real_,
      hr             = NA_real_,
      p_value        = NA_real_,
      p_value_mc     = NA_real_,
      p_value_naive  = NA_real_,
      c_index        = NA_real_,
      converged      = FALSE,
      error_msg      = conditionMessage(e),
      epsilon        = epsilon,
      seed           = seed,
      beta_original  = NA_real_,
      noise_scale_z  = NA_real_,
      laplace_scale  = NA_real_,
      stringsAsFactors = FALSE,
      row.names      = NULL
    )
  })
}

run_output_simulation_batch <- function(data, cox_formula, epsilon_values,
                                         B, base_seed,
                                         clipping_bounds, covariate_types,
                                         dataset_name = "unknown",
                                         use_mc_pvalue = FALSE,
                                         M = 10000L,
                                         standardize = FALSE,
                                         use_dfbeta = FALSE) {
  if (!exists("set_reference_levels", mode = "function")) {
    stop("set_reference_levels() が見つからない。",
         "main/03_simulation/R/data_split.R を source すること")
  }
  data <- set_reference_levels(as.data.frame(data), dataset_name)

  data <- as.data.frame(data)
  fit <- coxph(cox_formula, data = data, x = TRUE)

  beta_orig <- unname(coef(fit))
  se_orig <- unname(sqrt(diag(vcov(fit))))
  coef_names <- names(coef(fit))

  precomputed <- list(
    beta = beta_orig,
    se = se_orig,
    var_names = coef_names
  )

  if (use_dfbeta) {
    sens <- compute_sensitivity_dfbeta(fit, covariate_types)
    message(sprintf("[%s] dfbeta sensitivity: max delta_beta = %.6f, median = %.6f",
                    dataset_name, max(sens$delta_beta), median(sens$delta_beta)))
  } else if (standardize) {
    sens <- compute_sensitivity_standardized(fit, clipping_bounds, covariate_types)
    message(sprintf("[%s] Standardized sensitivity: lambda_min %.4f -> %.4f (%.1fx improvement)",
                    dataset_name, sens$lambda_min_orig, sens$lambda_min_std,
                    sens$lambda_min_std / sens$lambda_min_orig))
  } else {
    sens <- compute_sensitivity(fit, clipping_bounds, covariate_types)
  }

  mm <- fit$x

  surv_obj <- Surv(data$time, data$status)

  null_distributions <- NULL
  if (use_mc_pvalue) {
    null_distributions <- list()
    p_coefs <- length(coef_names)
    eps_j_values <- epsilon_values / p_coefs

    for (ei in seq_along(epsilon_values)) {
      eps <- epsilon_values[ei]
      if (is.infinite(eps)) next
      eps_j <- eps_j_values[ei]

      for (j in seq_along(coef_names)) {
        ns <- sens$delta_beta[j] / (eps_j * se_orig[j])
        null_key <- paste0(coef_names[j], "_", as.character(eps))
        NULL_SEED_OFFSET <- 1000L
        null_distributions[[null_key]] <- generate_null_distribution(
          ns, M = M, seed = base_seed + ei * NULL_SEED_OFFSET + j
        )
      }
    }
    message(sprintf("[%s] Pre-generated %d null distributions (M=%d)",
                    dataset_name, length(null_distributions), M))
  }

  params <- expand.grid(
    epsilon   = epsilon_values,
    iteration = seq_len(B),
    stringsAsFactors = FALSE
  )

  eps_lookup <- setNames(seq_along(epsilon_values), as.character(epsilon_values))
  params$seed <- base_seed + 500000L +
    (eps_lookup[as.character(params$epsilon)] - 1L) * B +
    params$iteration

  n_tasks <- nrow(params)
  message(sprintf("[%s] Running %d output perturbation simulations (%d eps x %d iter)...",
                  dataset_name, n_tasks, length(epsilon_values), B))

  results <- future_map(
    seq_len(n_tasks),
    function(i) {
      res <- run_single_output_simulation(
        fit              = fit,
        epsilon          = params$epsilon[i],
        seed             = params$seed[i],
        sensitivity_info = sens,
        model_matrix     = mm,
        surv_obj         = surv_obj,
        precomputed      = precomputed,
        null_distributions = null_distributions
      )
      res$iteration <- params$iteration[i]
      res
    },
    .options = furrr_options(seed = FALSE)
  )

  result_df <- bind_rows(results)
  result_df$dataset <- dataset_name
  result_df
}
