T_MAX <- list(
  lung      = 1022,
  pbc       = 4556,
  colon     = 3329,
  rotterdam = 7043,
  flchain   = 5215
)

allocate_budget_phase2 <- function(total_epsilon, n_covariates) {
  stopifnot(
    is.numeric(total_epsilon), length(total_epsilon) == 1,
    total_epsilon > 0,
    is.numeric(n_covariates), length(n_covariates) == 1,
    n_covariates >= 1
  )
  total_epsilon / (n_covariates + 2)
}

perturb_all_phase2 <- function(data,
                               clipping_bounds,
                               t_max,
                               epsilon,
                               covariate_types,
                               time_col = "time",
                               status_col = "status",
                               preserve_factor_levels = TRUE) {
  stopifnot(
    is.data.frame(data),
    is.list(clipping_bounds),
    is.numeric(t_max), length(t_max) == 1, t_max > 0,
    is.numeric(epsilon), length(epsilon) == 1, epsilon > 0,
    is.list(covariate_types),
    time_col %in% names(data),
    status_col %in% names(data)
  )

  surv_cols <- c(time_col, status_col)
  covariate_names <- setdiff(names(data), surv_cols)
  n_cov <- length(covariate_names)

  eps_per_var <- allocate_budget_phase2(epsilon, n_cov)

  result <- data

  result <- perturb_covariates_core(result, covariate_names, clipping_bounds,
                                    covariate_types, eps_per_var,
                                    preserve_factor_levels = preserve_factor_levels)

  time_result <- dp_perturb_survival_time(
    time = data[[time_col]],
    t_max = t_max,
    epsilon_t = eps_per_var
  )
  result[[time_col]] <- time_result$time

  event_result <- dp_perturb_event(
    status = data[[status_col]],
    epsilon_delta = eps_per_var
  )
  result[[status_col]] <- event_result$status

  list(
    data = result,
    eps_per_var = eps_per_var,
    n_covariates = n_cov,
    total_components = n_cov + 2,
    time_diagnostics = time_result,
    event_diagnostics = event_result
  )
}
