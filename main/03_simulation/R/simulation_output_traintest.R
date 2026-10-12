library(survival)
library(dplyr)
library(furrr)
library(progressr)

run_single_output_simulation_traintest <- function(data, cox_formula, epsilon,
                                                    seed, iteration,
                                                    clipping_bounds,
                                                    covariate_types,
                                                    dataset_name,
                                                    split_base_seed = 100000,
                                                    standardize = FALSE,
                                                    use_dfbeta = FALSE) {
  split_seed <- split_base_seed + iteration
  split <- stratified_train_test_split(data, test_ratio = 0.3, seed = split_seed)

  train_data <- set_reference_levels(split$train, dataset_name)
  test_data  <- align_factor_levels(train_data, split$test, dataset_name)

  result <- tryCatch({
    fit <- coxph(cox_formula, data = train_data, x = TRUE)

    stopifnot(fit$n < nrow(data))

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
    } else if (standardize) {
      sens <- compute_sensitivity_standardized(fit, clipping_bounds, covariate_types)
    } else {
      sens <- compute_sensitivity(fit, clipping_bounds, covariate_types)
    }

    set.seed(seed)
    perturb_result <- perturb_cox_output(fit, epsilon, sens,
                                          seed = seed, precomputed = precomputed)

    mm_train <- fit$x
    lp_train_dp <- as.numeric(mm_train %*% perturb_result$beta_dp)
    surv_train <- Surv(train_data$time, train_data$status)
    c_index_train <- tryCatch({
      as.numeric(concordancefit(surv_train, -lp_train_dp)$concordance)
    }, error = function(e) NA_real_)

    mm_test <- model.matrix(cox_formula, data = test_data)
    mm_test <- mm_test[, colnames(mm_test) != "(Intercept)", drop = FALSE]

    common_cols <- intersect(colnames(mm_test), coef_names)
    if (length(common_cols) == 0) stop("No matching coefficients between fit and test model matrix")

    beta_dp_matched <- perturb_result$beta_dp[match(common_cols, coef_names)]
    lp_test_dp <- as.numeric(mm_test[, common_cols, drop = FALSE] %*% beta_dp_matched)
    surv_test <- Surv(test_data$time, test_data$status)
    c_index_test <- tryCatch({
      as.numeric(concordancefit(surv_test, -lp_test_dp)$concordance)
    }, error = function(e) NA_real_)

    p <- length(perturb_result$variable)
    p_naive <- 2 * pnorm(-abs(perturb_result$z_dp))

    if (is.infinite(epsilon)) {
      p_dp <- p_naive
    } else {
      p_dp <- mapply(
        dp_pvalue_analytical,
        z_obs = perturb_result$z_dp,
        noise_scale = perturb_result$noise_scale_z
      )
    }

    data.frame(
      variable       = perturb_result$variable,
      beta           = perturb_result$beta_dp,
      se             = perturb_result$se,
      hr             = perturb_result$hr_dp,
      p_value        = p_dp,
      p_value_mc     = NA_real_,
      p_value_naive  = p_naive,
      c_index        = c_index_train,
      c_index_test   = c_index_test,
      converged      = TRUE,
      error_msg      = NA_character_,
      beta_original  = perturb_result$beta_original,
      noise_scale_z  = perturb_result$noise_scale_z,
      laplace_scale  = perturb_result$laplace_scale,
      stringsAsFactors = FALSE,
      row.names      = NULL
    )
  },
  warning = function(w) {
    fit <- suppressWarnings(coxph(cox_formula, data = train_data, x = TRUE))

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
    } else if (standardize) {
      sens <- compute_sensitivity_standardized(fit, clipping_bounds, covariate_types)
    } else {
      sens <- compute_sensitivity(fit, clipping_bounds, covariate_types)
    }

    set.seed(seed)
    perturb_result <- perturb_cox_output(fit, epsilon, sens,
                                          seed = seed, precomputed = precomputed)

    mm_train <- fit$x
    lp_train_dp <- as.numeric(mm_train %*% perturb_result$beta_dp)
    surv_train <- Surv(train_data$time, train_data$status)
    c_index_train <- tryCatch({
      as.numeric(concordancefit(surv_train, -lp_train_dp)$concordance)
    }, error = function(e) NA_real_)

    mm_test <- tryCatch({
      m <- model.matrix(cox_formula, data = test_data)
      m[, colnames(m) != "(Intercept)", drop = FALSE]
    }, error = function(e) NULL)

    c_index_test <- NA_real_
    if (!is.null(mm_test)) {
      common_cols <- intersect(colnames(mm_test), coef_names)
      if (length(common_cols) > 0) {
        beta_dp_matched <- perturb_result$beta_dp[match(common_cols, coef_names)]
        lp_test_dp <- as.numeric(mm_test[, common_cols, drop = FALSE] %*% beta_dp_matched)
        surv_test <- Surv(test_data$time, test_data$status)
        c_index_test <- tryCatch({
          as.numeric(concordancefit(surv_test, -lp_test_dp)$concordance)
        }, error = function(e) NA_real_)
      }
    }

    p_naive <- 2 * pnorm(-abs(perturb_result$z_dp))
    if (is.infinite(epsilon)) {
      p_dp <- p_naive
    } else {
      p_dp <- mapply(dp_pvalue_analytical,
                     z_obs = perturb_result$z_dp,
                     noise_scale = perturb_result$noise_scale_z)
    }

    data.frame(
      variable       = perturb_result$variable,
      beta           = perturb_result$beta_dp,
      se             = perturb_result$se,
      hr             = perturb_result$hr_dp,
      p_value        = p_dp,
      p_value_mc     = NA_real_,
      p_value_naive  = p_naive,
      c_index        = c_index_train,
      c_index_test   = c_index_test,
      converged      = FALSE,
      error_msg      = conditionMessage(w),
      beta_original  = perturb_result$beta_original,
      noise_scale_z  = perturb_result$noise_scale_z,
      laplace_scale  = perturb_result$laplace_scale,
      stringsAsFactors = FALSE,
      row.names      = NULL
    )
  },
  error = function(e) {
    data.frame(
      variable       = "FAILED",
      beta           = NA_real_,
      se             = NA_real_,
      hr             = NA_real_,
      p_value        = NA_real_,
      p_value_mc     = NA_real_,
      p_value_naive  = NA_real_,
      c_index        = NA_real_,
      c_index_test   = NA_real_,
      converged      = FALSE,
      error_msg      = conditionMessage(e),
      beta_original  = NA_real_,
      noise_scale_z  = NA_real_,
      laplace_scale  = NA_real_,
      stringsAsFactors = FALSE,
      row.names      = NULL
    )
  })

  result$epsilon   <- epsilon
  result$seed      <- seed
  result$iteration <- iteration
  result
}

run_output_simulation_batch_traintest <- function(data, cox_formula,
                                                   epsilon_values, B,
                                                   base_seed,
                                                   clipping_bounds,
                                                   covariate_types,
                                                   dataset_name = "unknown",
                                                   split_base_seed = 100000,
                                                   standardize = FALSE,
                                                   use_dfbeta = FALSE) {
  data <- as.data.frame(data)

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
  method_label <- if (use_dfbeta) " (dfbeta)" else if (standardize) " (std)" else ""
  message(sprintf(
    "[%s output%s traintest] Running %d simulations (%d eps x %d iter)...",
    dataset_name, method_label,
    n_tasks, length(epsilon_values), B
  ))

  p <- progressor(steps = n_tasks)

  results <- future_map(
    seq_len(n_tasks),
    function(i) {
      res <- run_single_output_simulation_traintest(
        data            = data,
        cox_formula     = cox_formula,
        epsilon         = params$epsilon[i],
        seed            = params$seed[i],
        iteration       = params$iteration[i],
        clipping_bounds = clipping_bounds,
        covariate_types = covariate_types,
        dataset_name    = dataset_name,
        split_base_seed = split_base_seed,
        standardize     = standardize,
        use_dfbeta      = use_dfbeta
      )
      p()
      res
    },
    .options = furrr_options(seed = FALSE)
  )

  result_df <- bind_rows(results)
  result_df$dataset <- dataset_name
  result_df
}
