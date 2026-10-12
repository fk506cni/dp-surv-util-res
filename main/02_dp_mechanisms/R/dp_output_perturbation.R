library(survival)

compute_coefficient_ranges <- function(coef_names, clipping_bounds, covariate_types) {
  orig_var_names <- names(covariate_types)
  orig_var_names <- orig_var_names[order(-nchar(orig_var_names))]

  ranges <- numeric(length(coef_names))
  names(ranges) <- coef_names

  for (i in seq_along(coef_names)) {
    cn <- coef_names[i]
    matched <- FALSE

    for (var_name in orig_var_names) {
      cov_type <- covariate_types[[var_name]]
      bounds <- clipping_bounds[[var_name]]

      if (cn == var_name) {
        if (cov_type == "continuous") {
          ranges[i] <- bounds[2] - bounds[1]
        } else if (cov_type == "binary") {
          ranges[i] <- 1.0
        } else if (cov_type == "categorical") {
          if (is.numeric(bounds)) {
            ranges[i] <- max(bounds) - min(bounds)
          } else {
            ranges[i] <- 1.0
          }
        }
        matched <- TRUE
        break
      }

      if (startsWith(cn, var_name) && nchar(cn) > nchar(var_name)) {
        is_false_match <- any(vapply(orig_var_names, function(other) {
          other != var_name && startsWith(cn, other) && nchar(other) > nchar(var_name)
        }, logical(1)))
        if (!is_false_match) {
          ranges[i] <- 1.0
          matched <- TRUE
          break
        }
      }
    }

    if (!matched) {
      stop("Could not match coefficient '", cn, "' to any covariate. ",
           "All coefficients must have a corresponding entry in clipping_bounds/covariate_types.")
    }
  }

  ranges
}

compute_sensitivity <- function(fit, clipping_bounds, covariate_types) {
  n <- fit$n
  coef_names <- names(coef(fit))

  ranges <- compute_coefficient_ranges(coef_names, clipping_bounds, covariate_types)

  vcov_mat <- vcov(fit)
  info_matrix <- tryCatch(
    solve(vcov_mat),
    error = function(e) {
      warning("vcov matrix is singular, using pseudo-inverse via eigen decomposition")
      eig <- eigen(vcov_mat, symmetric = TRUE)
      pos <- eig$values > .Machine$double.eps * max(eig$values)
      if (!any(pos)) stop("vcov matrix is entirely zero/negative")
      eig$vectors[, pos, drop = FALSE] %*%
        diag(1 / eig$values[pos], nrow = sum(pos)) %*%
        t(eig$vectors[, pos, drop = FALSE])
    }
  )

  info_normalized <- info_matrix / n

  eigenvalues <- eigen(info_normalized, symmetric = TRUE, only.values = TRUE)$values
  lambda_min <- min(eigenvalues)

  if (lambda_min <= .Machine$double.eps) {
    warning("Information matrix is singular or near-singular (lambda_min = ",
            format(lambda_min, digits = 4), "). Sensitivity will be extremely large.")
    lambda_min <- .Machine$double.eps
  }

  delta_beta <- ranges / (n * lambda_min)

  list(
    delta_beta  = delta_beta,
    lambda_min  = lambda_min,
    ranges      = ranges,
    n           = n
  )
}

compute_sd_factors <- function(coef_names, model_matrix, covariate_types) {
  orig_var_names <- names(covariate_types)
  orig_var_names <- orig_var_names[order(-nchar(orig_var_names))]

  sd_factors <- numeric(length(coef_names))
  names(sd_factors) <- coef_names

  for (i in seq_along(coef_names)) {
    cn <- coef_names[i]
    sd_factors[i] <- 1.0

    for (var_name in orig_var_names) {
      cov_type <- covariate_types[[var_name]]

      if (cn == var_name) {
        if (cov_type == "continuous") {
          col_sd <- sd(model_matrix[, cn])
          if (col_sd > 0) sd_factors[i] <- col_sd
        }
        break
      }

      if (startsWith(cn, var_name) && nchar(cn) > nchar(var_name)) {
        is_false_match <- any(vapply(orig_var_names, function(other) {
          other != var_name && startsWith(cn, other) && nchar(other) > nchar(var_name)
        }, logical(1)))
        if (!is_false_match) {
          break
        }
      }
    }
  }

  sd_factors
}

compute_sensitivity_standardized <- function(fit, clipping_bounds, covariate_types) {
  n <- fit$n
  coef_names <- names(coef(fit))
  p <- length(coef_names)

  mm <- fit$x
  if (is.null(mm)) {
    stop("fit must be created with x=TRUE for standardized sensitivity calculation")
  }

  ranges <- compute_coefficient_ranges(coef_names, clipping_bounds, covariate_types)

  sd_factors <- compute_sd_factors(coef_names, mm, covariate_types)

  ranges_std <- ranges / sd_factors

  vcov_mat <- vcov(fit)
  info_matrix <- tryCatch(
    solve(vcov_mat),
    error = function(e) {
      warning("vcov matrix is singular, using pseudo-inverse via eigen decomposition")
      eig <- eigen(vcov_mat, symmetric = TRUE)
      pos <- eig$values > .Machine$double.eps * max(eig$values)
      if (!any(pos)) stop("vcov matrix is entirely zero/negative")
      eig$vectors[, pos, drop = FALSE] %*%
        diag(1 / eig$values[pos], nrow = sum(pos)) %*%
        t(eig$vectors[, pos, drop = FALSE])
    }
  )
  info_normalized <- info_matrix / n

  eigenvalues_orig <- eigen(info_normalized, symmetric = TRUE, only.values = TRUE)$values
  lambda_min_orig <- min(eigenvalues_orig)

  D_inv <- diag(1 / sd_factors, nrow = p)
  info_std_normalized <- D_inv %*% info_normalized %*% D_inv

  eigenvalues_std <- eigen(info_std_normalized, symmetric = TRUE, only.values = TRUE)$values
  lambda_min_std <- min(eigenvalues_std)

  if (lambda_min_std <= .Machine$double.eps) {
    warning("Standardized information matrix is singular or near-singular (lambda_min_std = ",
            format(lambda_min_std, digits = 4), "). Sensitivity will be extremely large.")
    lambda_min_std <- .Machine$double.eps
  }

  delta_beta_std <- ranges_std / (n * lambda_min_std)

  delta_beta_orig <- delta_beta_std / sd_factors

  list(
    delta_beta      = delta_beta_orig,
    delta_beta_std  = delta_beta_std,
    lambda_min      = lambda_min_std,
    lambda_min_std  = lambda_min_std,
    lambda_min_orig = lambda_min_orig,
    ranges          = ranges,
    ranges_std      = ranges_std,
    sd_factors      = sd_factors,
    n               = n,
    standardized    = TRUE
  )
}

compute_sensitivity_dfbeta <- function(fit, covariate_types = NULL) {
  n <- fit$n
  coef_names <- names(coef(fit))
  p <- length(coef_names)

  dfb <- residuals(fit, type = "dfbeta")

  if (!is.null(colnames(dfb))) {
    stopifnot(all(colnames(dfb) == coef_names))
  }

  delta_beta <- apply(abs(dfb), 2, max)
  names(delta_beta) <- coef_names

  dfbeta_q99 <- apply(abs(dfb), 2, quantile, probs = 0.99)
  names(dfbeta_q99) <- coef_names

  zero_vars <- delta_beta <= .Machine$double.eps
  if (any(zero_vars)) {
    warning("dfbeta max is zero for variables: ",
            paste(coef_names[zero_vars], collapse = ", "),
            ". These variables will not be perturbed (sensitivity = 0).")
    delta_beta[zero_vars] <- 0
  }

  sd_factors <- NULL
  if (!is.null(covariate_types) && !is.null(fit$x)) {
    sd_factors <- compute_sd_factors(coef_names, fit$x, covariate_types)
  }

  list(
    delta_beta  = delta_beta,
    dfbeta_max  = delta_beta,
    dfbeta_q99  = dfbeta_q99,
    sd_factors  = sd_factors,
    n           = n,
    method      = "dfbeta"
  )
}

perturb_cox_output <- function(fit, epsilon, sensitivity_info, seed = NULL,
                                precomputed = NULL) {
  stopifnot(
    inherits(fit, "coxph"),
    is.numeric(epsilon), length(epsilon) == 1, epsilon > 0
  )

  if (!is.null(seed)) set.seed(seed)

  if (!is.null(precomputed)) {
    beta <- precomputed$beta
    se <- precomputed$se
    var_names <- precomputed$var_names
  } else {
    beta <- coef(fit)
    se <- sqrt(diag(vcov(fit)))
    var_names <- names(beta)
    beta <- unname(beta)
    se <- unname(se)
  }
  p <- length(beta)

  eps_j <- epsilon / p

  delta_beta <- sensitivity_info$delta_beta

  if (is.infinite(epsilon)) {
    return(list(
      variable       = var_names,
      beta_original  = beta,
      beta_dp        = beta,
      se             = se,
      hr_dp          = exp(beta),
      z_dp           = beta / se,
      noise_scale_z  = rep(0, p),
      eps_per_coef   = Inf,
      delta_beta     = delta_beta,
      laplace_scale  = rep(0, p)
    ))
  }

  laplace_scale <- delta_beta / eps_j

  u <- runif(p)
  u <- pmax(pmin(u, 1 - .Machine$double.eps), .Machine$double.eps)
  noise <- -laplace_scale * sign(u - 0.5) * log(1 - 2 * abs(u - 0.5))
  noise[laplace_scale == 0] <- 0

  beta_dp <- beta + noise

  noise_scale_z <- delta_beta / (eps_j * se)
  noise_scale_z[se == 0] <- Inf

  z_dp <- beta_dp / se
  z_dp[se == 0] <- ifelse(beta_dp[se == 0] == 0, 0, sign(beta_dp[se == 0]) * Inf)

  list(
    variable       = var_names,
    beta_original  = beta,
    beta_dp        = beta_dp,
    se             = se,
    hr_dp          = exp(beta_dp),
    z_dp           = z_dp,
    noise_scale_z  = noise_scale_z,
    eps_per_coef   = eps_j,
    delta_beta     = delta_beta,
    laplace_scale  = laplace_scale
  )
}
