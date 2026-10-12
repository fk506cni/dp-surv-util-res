library(survival)
library(dplyr)
library(furrr)
library(progressr)

run_single_simulation_phase3 <- function(data, epsilon, seed, K,
                                          clipping_bounds, covariate_types,
                                          cox_formula, spline_df = 3L,
                                          preserve_factor_levels = TRUE) {
  set.seed(seed)

  surv_cols <- c("time", "status")
  covariate_names <- setdiff(names(data), surv_cols)

  rhs_terms <- attr(terms(cox_formula), "term.labels")
  rhs_formula <- reformulate(rhs_terms)

  warn_msgs <- character(0)
  result <- withCallingHandlers(
    tryCatch({
      p3 <- perturb_discrete_phase3(
        data            = data,
        clipping_bounds = clipping_bounds,
        epsilon         = epsilon,
        K               = K,
        covariate_types = covariate_types,
        preserve_factor_levels = preserve_factor_levels
      )

      fit <- fit_discrete_cox(p3$stacked_data, covariate_names, spline_df = spline_df)

      coefs <- extract_covariate_coefs(fit)

      stopifnot("orig_id" %in% names(p3$stacked_data))
      first_idx <- !duplicated(p3$stacked_data$orig_id)
      perturbed_ind <- p3$stacked_data[first_idx, , drop = FALSE]

      mm <- model.matrix(rhs_formula, data = perturbed_ind)
      mm <- mm[, colnames(mm) != "(Intercept)", drop = FALSE]

      common <- intersect(colnames(mm), coefs$variable)
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

      surv_obj <- Surv(data$time, data$status)

      lp <- as.numeric(mm[, common, drop = FALSE] %*% beta_vec)
      c_obj <- tryCatch(concordancefit(surv_obj, -lp),
                        error = function(e) NULL)
      c_index <- if (!is.null(c_obj)) as.numeric(c_obj$concordance) else NA_real_

      mm_orig <- model.matrix(rhs_formula, data = data)
      mm_orig <- mm_orig[, colnames(mm_orig) != "(Intercept)", drop = FALSE]
      lp_orig <- as.numeric(mm_orig[, common, drop = FALSE] %*% beta_vec)
      c_obj_orig <- tryCatch(concordancefit(surv_obj, -lp_orig),
                             error = function(e) NULL)
      c_index_orig <- if (!is.null(c_obj_orig)) as.numeric(c_obj_orig$concordance) else NA_real_

      converged <- length(warn_msgs) == 0 && !coef_dropped

      data.frame(
        variable     = coefs$variable,
        beta         = coefs$beta,
        se           = coefs$se,
        hr           = exp(coefs$beta),
        p_value      = coefs$p_value,
        c_index      = c_index,
        c_index_orig = c_index_orig,
        converged    = converged,
        error_msg    = if (converged) NA_character_ else paste(warn_msgs, collapse = "; "),
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
    }),
    warning = function(w) {
      warn_msgs <<- c(warn_msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  result$epsilon <- epsilon
  result$seed    <- seed
  result
}

run_simulation_batch_phase3 <- function(data, epsilon_values, B, base_seed,
                                         K, clipping_bounds, covariate_types,
                                         cox_formula, dataset_name = "unknown",
                                         spline_df = 3L,
                                         preserve_factor_levels = TRUE) {
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
  message(sprintf("[%s, K=%d, ε/(q+2)] Running %d simulations (%d eps x %d iter)...",
                  dataset_name, K, n_tasks, length(epsilon_values), B))

  p <- progressor(steps = n_tasks)

  results <- future_map(
    seq_len(n_tasks),
    function(i) {
      res <- run_single_simulation_phase3(
        data            = data,
        epsilon         = params$epsilon[i],
        seed            = params$seed[i],
        K               = K,
        clipping_bounds = clipping_bounds,
        covariate_types = covariate_types,
        preserve_factor_levels = preserve_factor_levels,
        cox_formula     = cox_formula,
        spline_df       = spline_df
      )
      res$iteration <- params$iteration[i]
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
