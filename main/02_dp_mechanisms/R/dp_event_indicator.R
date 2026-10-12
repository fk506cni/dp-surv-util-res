dp_perturb_event <- function(status, epsilon_delta) {
  stopifnot(
    is.numeric(status), length(status) >= 1,
    all(status %in% c(0, 1)),
    is.numeric(epsilon_delta), length(epsilon_delta) == 1,
    epsilon_delta > 0
  )

  n <- length(status)
  status_int <- as.integer(status)
  d_original <- sum(status_int)

  if (is.infinite(epsilon_delta)) {
    return(list(
      status = status_int,
      n_flip_1_to_0 = 0L,
      n_flip_0_to_1 = 0L,
      n_flip_total = 0L,
      d_original = as.integer(d_original),
      d_perturbed = as.integer(d_original),
      d_change = 0L,
      prob_truth = 1.0,
      prob_flip = 0.0
    ))
  }

  prob_truth <- 1 / (1 + exp(-epsilon_delta))
  prob_flip <- 1 - prob_truth

  keep <- stats::runif(n) < prob_truth
  result <- ifelse(keep, status_int, 1L - status_int)
  result <- as.integer(result)

  flipped <- result != status_int
  n_flip_1_to_0 <- sum(status_int == 1L & flipped)
  n_flip_0_to_1 <- sum(status_int == 0L & flipped)
  d_perturbed <- sum(result)

  list(
    status = result,
    n_flip_1_to_0 = as.integer(n_flip_1_to_0),
    n_flip_0_to_1 = as.integer(n_flip_0_to_1),
    n_flip_total = as.integer(n_flip_1_to_0 + n_flip_0_to_1),
    d_original = as.integer(d_original),
    d_perturbed = as.integer(d_perturbed),
    d_change = as.integer(d_perturbed - d_original),
    prob_truth = prob_truth,
    prob_flip = prob_flip
  )
}
