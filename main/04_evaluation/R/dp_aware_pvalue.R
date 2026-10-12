NML_LAMBDA_THRESHOLD <- 1e-6

nml_cdf <- function(x, lambda) {
  stopifnot(is.numeric(lambda), length(lambda) == 1, lambda > 0)

  r <- 1.0 / lambda

  phi_x <- pnorm(x)

  log_A <- -r * x + r^2 / 2.0 + pnorm(x - r, log.p = TRUE)
  log_B <-  r * x + r^2 / 2.0 + pnorm(-x - r, log.p = TRUE)

  correction <- rep(0.0, length(x))

  for (i in seq_along(x)) {
    la <- log_A[i]
    lb <- log_B[i]

    if (is.finite(la) || is.finite(lb)) {
      max_log <- max(la, lb)
      min_log <- min(la, lb)
      sign <- if (la >= lb) 1.0 else -1.0
      if (max_log > 709) {
        correction[i] <- sign * exp(max_log + log1p(-exp(min_log - max_log)))
      } else {
        correction[i] <- exp(la) - exp(lb)
      }
    }
  }

  result <- phi_x - 0.5 * correction

  pmin(pmax(result, 0.0), 1.0)
}

dp_pvalue_analytical <- function(z_obs, noise_scale) {
  stopifnot(
    is.numeric(z_obs),
    is.numeric(noise_scale), length(noise_scale) == 1,
    noise_scale >= 0
  )

  if (is.infinite(noise_scale)) {
    return(rep(1.0, length(z_obs)))
  }

  if (noise_scale < NML_LAMBDA_THRESHOLD) {
    return(2.0 * pnorm(-abs(z_obs)))
  }

  cdf_val <- nml_cdf(z_obs, lambda = noise_scale)
  2.0 * pmin(cdf_val, 1.0 - cdf_val)
}

dp_pvalue_montecarlo <- function(z_obs, noise_scale, M = 10000L, seed = NULL) {
  stopifnot(
    is.numeric(z_obs), length(z_obs) == 1,
    is.numeric(noise_scale), length(noise_scale) == 1,
    noise_scale > 0,
    is.numeric(M), length(M) == 1, M >= 100
  )

  had_seed <- exists(".Random.seed", envir = .GlobalEnv)
  old_seed <- if (had_seed) {
    get(".Random.seed", envir = .GlobalEnv)
  } else {
    NULL
  }
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  if (!is.null(seed)) set.seed(seed)

  z_null <- rnorm(M, mean = 0, sd = 1)

  eta <- rexp(M, rate = 1 / noise_scale) - rexp(M, rate = 1 / noise_scale)

  z_dp_null <- z_null + eta

  (sum(abs(z_dp_null) >= abs(z_obs)) + 1) / (M + 1)
}

dp_pvalue_mc_from_null <- function(z_obs, null_abs_sorted) {
  M <- length(null_abs_sorted)
  abs_z <- abs(z_obs)

  n_below <- findInterval(abs_z, null_abs_sorted)

  (M - n_below + 1) / (M + 1)
}

generate_null_distribution <- function(noise_scale, M = 10000L, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  z_null <- rnorm(M, mean = 0, sd = 1)
  eta <- rexp(M, rate = 1 / noise_scale) - rexp(M, rate = 1 / noise_scale)
  sort(abs(z_null + eta))
}
