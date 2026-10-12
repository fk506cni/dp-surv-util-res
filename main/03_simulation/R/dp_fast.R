dp_laplace_vec <- function(x, lower, upper, epsilon) {
  stopifnot(!anyNA(x), lower < upper, epsilon > 0 || is.infinite(epsilon))
  x_clipped <- pmax(pmin(x, upper), lower)
  if (is.infinite(epsilon)) return(x_clipped)

  sensitivity <- upper - lower
  scale <- sensitivity / epsilon
  n <- length(x_clipped)

  noise <- rexp(n, rate = 1 / scale) - rexp(n, rate = 1 / scale)
  noisy <- x_clipped + noise

  pmax(pmin(noisy, upper), lower)
}

dp_rr_binary_vec <- function(x, epsilon) {
  stopifnot(!anyNA(x), all(x %in% c(0L, 1L)), epsilon > 0 || is.infinite(epsilon))
  if (is.infinite(epsilon)) return(as.integer(x))

  n <- length(x)
  prob <- 1 / (1 + exp(-epsilon))

  keep <- runif(n) < prob
  as.integer(ifelse(keep, x, 1L - as.integer(x)))
}

dp_rr_categorical_vec <- function(x, categories, epsilon,
                                  preserve_factor_levels = TRUE) {
  stopifnot(length(categories) >= 2, epsilon > 0 || is.infinite(epsilon))
  if (is.infinite(epsilon)) return(x)

  original_class <- class(x)[1]
  original_levels <- if (is.factor(x)) levels(x) else NULL
  x_char <- as.character(x)
  cat_char <- as.character(categories)
  stopifnot(!anyNA(x), all(x_char %in% cat_char))
  k <- length(cat_char)
  n <- length(x)

  prob <- 1 / (1 + (k - 1) * exp(-epsilon))
  keep <- runif(n) < prob
  random_cats <- vapply(x_char, function(xi) {
    sample(setdiff(cat_char, xi), 1L)
  }, character(1L), USE.NAMES = FALSE)
  result_char <- ifelse(keep, x_char, random_cats)

  if (original_class %in% c("integer", "numeric")) {
    lookup <- setNames(categories, cat_char)
    result <- unname(lookup[result_char])
    if (original_class == "integer") return(as.integer(result))
    return(as.numeric(result))
  }
  if (preserve_factor_levels && !is.null(original_levels)) {
    return(factor(result_char, levels = union(original_levels, cat_char)))
  }
  result_char
}

perturb_covariates_core <- function(data, covariate_names, clipping_bounds,
                                     covariate_types, eps_per_cov,
                                     preserve_factor_levels = TRUE) {
  result <- data

  for (col in covariate_names) {
    cov_type <- covariate_types[[col]]
    bounds <- clipping_bounds[[col]]

    result[[col]] <- switch(cov_type,
      "continuous"  = dp_laplace_vec(data[[col]], bounds[1], bounds[2], eps_per_cov),
      "binary"      = dp_rr_binary_vec(data[[col]], eps_per_cov),
      "categorical" = dp_rr_categorical_vec(data[[col]], bounds, eps_per_cov,
                                            preserve_factor_levels = preserve_factor_levels),
      stop("Unknown type: ", cov_type, " for ", col)
    )
  }

  result
}

perturb_covariates_phase1_fast <- function(data, clipping_bounds, epsilon,
                                            covariate_types,
                                            preserve_factor_levels = TRUE) {
  surv_cols <- SURV_COLS
  covariate_names <- setdiff(names(data), surv_cols)
  n_cov <- length(covariate_names)
  eps_j <- epsilon / n_cov

  perturb_covariates_core(data, covariate_names, clipping_bounds,
                          covariate_types, eps_j,
                          preserve_factor_levels = preserve_factor_levels)
}
