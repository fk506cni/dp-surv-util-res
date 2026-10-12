dp_perturb_survival_time <- function(time, t_max, epsilon_t) {
  stopifnot(
    is.numeric(time), length(time) >= 1,
    is.numeric(t_max), length(t_max) == 1, t_max > 0,
    is.numeric(epsilon_t), length(epsilon_t) == 1, epsilon_t > 0
  )

  n <- length(time)

  if (is.infinite(epsilon_t)) {
    clamped <- pmax(pmin(time, t_max), 0)
    return(list(
      time = clamped,
      n_negative = 0L,
      n_clamped_lower = sum(time < 0),
      n_clamped_upper = sum(time > t_max),
      n_clamped_total = sum(time < 0 | time > t_max),
      scale = 0
    ))
  }

  time <- pmax(pmin(time, t_max), 0)

  scale <- t_max / epsilon_t
  noise <- stats::rexp(n, rate = 1 / scale) - stats::rexp(n, rate = 1 / scale)
  noisy <- time + noise

  n_negative <- sum(noisy < 0)
  n_over <- sum(noisy > t_max)

  clamped <- pmax(pmin(noisy, t_max), 0)

  list(
    time = clamped,
    n_negative = as.integer(n_negative),
    n_clamped_lower = as.integer(n_negative),
    n_clamped_upper = as.integer(n_over),
    n_clamped_total = as.integer(n_negative + n_over),
    scale = scale
  )
}
