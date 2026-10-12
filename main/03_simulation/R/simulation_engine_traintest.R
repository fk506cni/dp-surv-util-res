library(survival)
library(dplyr)
library(furrr)
library(progressr)

run_single_simulation_traintest <- function(data, perturb_fn, epsilon, seed,
                                             iteration, cox_formula,
                                             dataset_name,
                                             split_base_seed = 100000) {
  split_seed <- split_base_seed + iteration
  split <- stratified_train_test_split(data, test_ratio = 0.3, seed = split_seed)

  train_data <- set_reference_levels(split$train, dataset_name)
  test_data  <- align_factor_levels(train_data, split$test, dataset_name)

  set.seed(seed)
  perturbed_train <- perturb_fn(train_data, epsilon)

  result <- tryCatch(
    {
      fit <- coxph(cox_formula, data = perturbed_train)
      beta <- coef(fit)
      se <- sqrt(diag(vcov(fit)))
      var_names <- names(beta)
      hr <- exp(beta)
      z <- beta / se
      p_val <- 2 * pnorm(-abs(z))
      c_idx <- concordance(fit)$concordance

      lp_test <- predict(fit, newdata = test_data, type = "lp")
      surv_test <- Surv(test_data$time, test_data$status)
      c_idx_test <- as.numeric(concordancefit(surv_test, -lp_test)$concordance)

      data.frame(
        variable     = var_names,
        beta         = unname(beta),
        se           = unname(se),
        hr           = unname(hr),
        p_value      = unname(p_val),
        c_index      = as.numeric(c_idx),
        c_index_test = c_idx_test,
        converged    = TRUE,
        error_msg    = NA_character_,
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    },
    warning = function(w) {
      fit <- suppressWarnings(coxph(cox_formula, data = perturbed_train))
      beta <- coef(fit)
      se <- sqrt(diag(vcov(fit)))
      var_names <- names(beta)
      hr <- exp(beta)
      z <- beta / se
      p_val <- 2 * pnorm(-abs(z))
      c_idx <- tryCatch(concordance(fit)$concordance,
                        error = function(e) NA_real_)

      c_idx_test <- tryCatch({
        lp_test <- predict(fit, newdata = test_data, type = "lp")
        surv_test <- Surv(test_data$time, test_data$status)
        as.numeric(concordancefit(surv_test, -lp_test)$concordance)
      }, error = function(e) NA_real_)

      data.frame(
        variable     = var_names,
        beta         = unname(beta),
        se           = unname(se),
        hr           = unname(hr),
        p_value      = unname(p_val),
        c_index      = as.numeric(c_idx),
        c_index_test = c_idx_test,
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
        c_index_test = NA_real_,
        converged    = FALSE,
        error_msg    = conditionMessage(e),
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    }
  )

  result$epsilon   <- epsilon
  result$seed      <- seed
  result$iteration <- iteration
  result
}

run_simulation_batch_traintest <- function(data,
                                            perturb_fn,
                                            epsilon_values,
                                            B,
                                            base_seed,
                                            cox_formula,
                                            dataset_name = "unknown",
                                            split_base_seed = 100000) {
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
    "[%s traintest] Running %d simulations (%d epsilon values x %d iterations)...",
    dataset_name, n_tasks, length(epsilon_values), B
  ))

  p <- progressor(steps = n_tasks)

  results <- future_map(
    seq_len(n_tasks),
    function(i) {
      res <- run_single_simulation_traintest(
        data            = data,
        perturb_fn      = perturb_fn,
        epsilon         = params$epsilon[i],
        seed            = params$seed[i],
        iteration       = params$iteration[i],
        cox_formula     = cox_formula,
        dataset_name    = dataset_name,
        split_base_seed = split_base_seed
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
