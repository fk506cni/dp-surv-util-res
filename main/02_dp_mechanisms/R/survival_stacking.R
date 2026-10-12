create_time_intervals <- function(event_times, K) {
  if (length(event_times) == 0) {
    stop("No event times provided; cannot create intervals. ",
         "All observations may be censored.")
  }
  stopifnot(
    is.numeric(event_times), length(event_times) >= 1,
    is.numeric(K), length(K) == 1, K >= 2
  )

  probs <- seq(0, 1, length.out = K + 1)
  boundaries <- as.numeric(quantile(event_times, probs = probs[-c(1, K + 1)]))

  boundaries <- sort(unique(boundaries))
  actual_K <- length(boundaries) + 1

  if (actual_K < K) {
    warning(sprintf(
      "Requested K=%d but only %d unique boundaries found. Using K=%d.",
      K, length(boundaries), actual_K
    ))
  }

  data.frame(
    interval_id = seq_len(actual_K),
    lower = c(0, boundaries),
    upper = c(boundaries, Inf),
    stringsAsFactors = FALSE
  )
}

stack_survival_data <- function(data, intervals,
                                time_col = "time", status_col = "status") {
  stopifnot(
    is.data.frame(data),
    is.data.frame(intervals),
    all(c("interval_id", "lower", "upper") %in% names(intervals)),
    time_col %in% names(data),
    status_col %in% names(data)
  )

  n <- nrow(data)
  K <- nrow(intervals)
  times <- data[[time_col]]
  status <- as.integer(data[[status_col]])

  if (K > 1) {
    breaks <- intervals$upper[-K]
    k_star <- findInterval(times, breaks, left.open = TRUE) + 1L
  } else {
    k_star <- rep(1L, n)
  }

  total_rows <- sum(k_star)

  orig_idx <- rep(seq_len(n), times = k_star)
  interval_idx <- unlist(lapply(k_star, seq_len))

  covariate_cols <- setdiff(names(data), c(time_col, status_col))
  stacked <- data[orig_idx, covariate_cols, drop = FALSE]
  rownames(stacked) <- NULL

  stacked$interval_id <- interval_idx
  stacked$orig_id <- orig_idx

  stacked[[time_col]] <- times[orig_idx]
  stacked[[status_col]] <- status[orig_idx]

  is_exit_interval <- (interval_idx == k_star[orig_idx])
  is_event <- (status[orig_idx] == 1L)
  stacked$y_ik <- as.integer(is_exit_interval & is_event)

  stacked
}

expand_perturbed_data <- function(perturbed_data, covariate_names,
                                   k_star, delta, actual_K) {
  n <- nrow(perturbed_data)
  stopifnot(
    length(k_star) == n,
    length(delta) == n,
    all(k_star >= 1L & k_star <= actual_K),
    all(delta %in% c(0L, 1L))
  )

  orig_idx <- rep(seq_len(n), times = k_star)
  interval_idx <- unlist(lapply(k_star, seq_len))

  stacked <- perturbed_data[orig_idx, covariate_names, drop = FALSE]
  rownames(stacked) <- NULL

  stacked$interval_id <- interval_idx
  stacked$orig_id <- orig_idx

  is_exit_interval <- (interval_idx == k_star[orig_idx])
  stacked$y_ik <- as.integer(is_exit_interval) * delta[orig_idx]

  stacked
}
