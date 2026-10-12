library(survival)
library(dplyr)
library(furrr)
library(progressr)

run_single_simulation_phase3_traintest <- function(data, epsilon, seed,
                                                    iteration, K,
                                                    clipping_bounds,
                                                    covariate_types,
                                                    cox_formula,
                                                    dataset_name,
                                                    split_base_seed = 100000,
                                                    spline_df = 3L,
                                                    preserve_factor_levels = TRUE) {
  split_seed <- split_base_seed + iteration
  split <- stratified_train_test_split(data, test_ratio = 0.3, seed = split_seed)

  train_data <- set_reference_levels(split$train, dataset_name)
  test_data  <- align_factor_levels(train_data, split$test, dataset_name)

  set.seed(seed)

  surv_cols <- c("time", "status")
  covariate_names <- setdiff(names(train_data), surv_cols)

  rhs_terms <- attr(terms(cox_formula), "term.labels")
  rhs_formula <- reformulate(rhs_terms)

  warn_msgs <- character(0)
  result <- withCallingHandlers(
    tryCatch({
      p3 <- perturb_discrete_phase3(
        data            = train_data,
        clipping_bounds = clipping_bounds,
        epsilon         = epsilon,
        K               = K,
        covariate_types = covariate_types,
        preserve_factor_levels = preserve_factor_levels
      )

      actual_K <- p3$actual_K

      fit <- fit_discrete_cox(p3$stacked_data, covariate_names, spline_df = spline_df)

      coefs <- extract_covariate_coefs(fit)

      stopifnot("orig_id" %in% names(p3$stacked_data))
      first_idx <- !duplicated(p3$stacked_data$orig_id)
      perturbed_ind <- p3$stacked_data[first_idx, , drop = FALSE]

      mm_train <- model.matrix(rhs_formula, data = perturbed_ind)
      mm_train <- mm_train[, colnames(mm_train) != "(Intercept)", drop = FALSE]

      common <- intersect(colnames(mm_train), coefs$variable)
      if (length(common) == 0) stop("No matching coefficients between GLM and model matrix")
      coef_dropped <- FALSE
      if (length(common) < length(coefs$variable)) {
        dropped <- setdiff(coefs$variable, common)
        warning(sprintf("Partial coefficient match: %d/%d dropped (%s)",
                        length(dropped), length(coefs$variable),
                        paste(dropped, collapse = ", ")))
        coef_dropped <- TRUE
      }

      beta_vec <- coefs$beta[match(common, coefs$variable)]

      surv_train <- Surv(train_data$time, train_data$status)
      lp_train <- as.numeric(mm_train[, common, drop = FALSE] %*% beta_vec)
      c_obj_train <- tryCatch(concordancefit(surv_train, -lp_train),
                              error = function(e) NULL)
      c_index <- if (!is.null(c_obj_train)) as.numeric(c_obj_train$concordance) else NA_real_

      mm_test <- model.matrix(rhs_formula, data = test_data)
      mm_test <- mm_test[, colnames(mm_test) != "(Intercept)", drop = FALSE]

      common_test <- intersect(colnames(mm_test), common)
      if (length(common_test) == 0) {
        c_index_test <- NA_real_
      } else {
        beta_test <- coefs$beta[match(common_test, coefs$variable)]
        surv_test <- Surv(test_data$time, test_data$status)
        lp_test <- as.numeric(mm_test[, common_test, drop = FALSE] %*% beta_test)
        c_obj_test <- tryCatch(concordancefit(surv_test, -lp_test),
                               error = function(e) NULL)
        c_index_test <- if (!is.null(c_obj_test)) as.numeric(c_obj_test$concordance) else NA_real_
      }

      converged <- length(warn_msgs) == 0 && !coef_dropped

      data.frame(
        variable     = coefs$variable,
        beta         = coefs$beta,
        se           = coefs$se,
        hr           = exp(coefs$beta),
        p_value      = coefs$p_value,
        c_index      = c_index,
        c_index_test = c_index_test,
        converged    = converged,
        error_msg    = if (converged) NA_character_ else paste(warn_msgs, collapse = "; "),
        actual_K     = actual_K,
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
        actual_K     = NA_integer_,
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    }),
    warning = function(w) {
      warn_msgs <<- c(warn_msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  result$epsilon   <- epsilon
  result$seed      <- seed
  result$iteration <- iteration
  result
}

run_simulation_batch_phase3_traintest <- function(data, epsilon_values, B,
                                                   base_seed, K,
                                                   clipping_bounds,
                                                   covariate_types,
                                                   cox_formula,
                                                   dataset_name = "unknown",
                                                   split_base_seed = 100000,
                                                   spline_df = 3L,
                                                   preserve_factor_levels = TRUE) {
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
    "[%s traintest, K=%d, ε/(q+2)] Running %d simulations (%d eps x %d iter)...",
    dataset_name, K, n_tasks, length(epsilon_values), B
  ))

  p <- progressor(steps = n_tasks)

  results <- future_map(
    seq_len(n_tasks),
    function(i) {
      res <- run_single_simulation_phase3_traintest(
        data            = data,
        epsilon         = params$epsilon[i],
        seed            = params$seed[i],
        iteration       = params$iteration[i],
        K               = K,
        preserve_factor_levels = preserve_factor_levels,
        clipping_bounds = clipping_bounds,
        covariate_types = covariate_types,
        cox_formula     = cox_formula,
        dataset_name    = dataset_name,
        split_base_seed = split_base_seed,
        spline_df       = spline_df
      )
      p()
      res
    },
    .options = furrr_options(seed = FALSE)
  )

  result_df <- bind_rows(results)
  result_df$dataset <- dataset_name
  result_df$K <- K
  result_df
}
