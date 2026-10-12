K_VALUES <- list(
  lung      = 8L,
  pbc       = 9L,
  colon     = 10L,
  rotterdam = 12L,
  flchain   = 13L
)

allocate_budget_phase3 <- function(total_epsilon, n_covariates) {
  stopifnot(
    is.numeric(total_epsilon), length(total_epsilon) == 1,
    total_epsilon > 0,
    is.numeric(n_covariates), length(n_covariates) == 1,
    n_covariates >= 1
  )
  total_epsilon / (n_covariates + 2)
}

perturb_discrete_phase3 <- function(data,
                                     clipping_bounds,
                                     epsilon,
                                     K,
                                     covariate_types,
                                     time_col = "time",
                                     status_col = "status",
                                     preserve_factor_levels = TRUE) {
  stopifnot(
    is.data.frame(data),
    is.list(clipping_bounds),
    is.numeric(epsilon), length(epsilon) == 1, epsilon > 0,
    is.numeric(K), length(K) == 1, K >= 2,
    is.list(covariate_types),
    time_col %in% names(data),
    status_col %in% names(data)
  )

  event_times <- data[[time_col]][data[[status_col]] == 1]
  intervals <- create_time_intervals(event_times, K)
  actual_K <- nrow(intervals)

  surv_cols <- c(time_col, status_col)
  covariate_names <- setdiff(names(data), surv_cols)
  n_cov <- length(covariate_names)

  times <- data[[time_col]]
  if (actual_K > 1) {
    breaks <- intervals$upper[-actual_K]
    k_star <- findInterval(times, breaks, left.open = TRUE) + 1L
  } else {
    k_star <- rep(1L, nrow(data))
  }

  eps_per_var <- allocate_budget_phase3(epsilon, n_cov)

  eps_cov <- if (is.infinite(epsilon)) Inf else eps_per_var
  perturbed_data <- perturb_covariates_core(data, covariate_names, clipping_bounds,
                                             covariate_types, eps_cov,
                                             preserve_factor_levels = preserve_factor_levels)

  if (is.infinite(epsilon)) {
    k_star_perturbed <- k_star
  } else {
    k_star_perturbed <- dp_rr_categorical_vec(
      k_star, categories = seq_len(actual_K), epsilon = eps_per_var
    )
  }
  n_k_flipped <- sum(k_star_perturbed != k_star)

  status_orig <- as.integer(data[[status_col]])
  if (is.infinite(epsilon)) {
    delta_perturbed <- status_orig
  } else {
    delta_perturbed <- dp_rr_binary_vec(status_orig, eps_per_var)
  }
  n_delta_flipped <- sum(delta_perturbed != status_orig)

  stacked <- expand_perturbed_data(
    perturbed_data  = perturbed_data,
    covariate_names = covariate_names,
    k_star          = k_star_perturbed,
    delta           = delta_perturbed,
    actual_K        = actual_K
  )

  n_total <- nrow(data)
  list(
    stacked_data    = stacked,
    intervals       = intervals,
    eps_per_var     = eps_per_var,
    n_covariates    = n_cov,
    actual_K        = actual_K,
    total_components = n_cov + 2L,
    n_k_flipped     = as.integer(n_k_flipped),
    k_flip_rate     = n_k_flipped / n_total,
    n_delta_flipped = as.integer(n_delta_flipped),
    delta_flip_rate = n_delta_flipped / n_total
  )
}
