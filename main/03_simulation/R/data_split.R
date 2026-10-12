REFERENCE_LEVELS <- list(
  pbc       = list(sex = "f"),
  colon     = list(rx = "Obs"),
  lung      = list(),
  rotterdam = list(size = "<=20"),
  flchain   = list(sex = "F")
)

SPLIT_BASE_SEED <- 100000

stratified_train_test_split <- function(data, test_ratio = 0.3, seed,
                                        status_col = "status") {
  stopifnot(
    is.data.frame(data),
    status_col %in% names(data),
    test_ratio > 0 && test_ratio < 1,
    !missing(seed)
  )

  set.seed(seed)

  n <- nrow(data)
  status <- data[[status_col]]

  idx_event    <- which(status == 1)
  idx_censored <- which(status == 0)

  n_test_event    <- round(length(idx_event) * test_ratio)
  n_test_censored <- round(length(idx_censored) * test_ratio)

  test_event    <- sample(idx_event, size = n_test_event)
  test_censored <- sample(idx_censored, size = n_test_censored)

  test_idx  <- sort(c(test_event, test_censored))
  train_idx <- sort(setdiff(seq_len(n), test_idx))

  train <- data[train_idx, , drop = FALSE]
  test  <- data[test_idx, , drop = FALSE]

  event_rate_orig  <- mean(status == 1)
  event_rate_train <- mean(train[[status_col]] == 1)
  event_rate_test  <- mean(test[[status_col]] == 1)

  split_info <- list(
    n_total        = n,
    n_train        = nrow(train),
    n_test         = nrow(test),
    n_event_train  = sum(train[[status_col]] == 1),
    n_event_test   = sum(test[[status_col]] == 1),
    event_rate_orig  = event_rate_orig,
    event_rate_train = event_rate_train,
    event_rate_test  = event_rate_test,
    seed           = seed
  )

  list(
    train      = train,
    test       = test,
    train_idx  = train_idx,
    test_idx   = test_idx,
    split_info = split_info
  )
}

align_factor_levels <- function(train_data, test_data, dataset_name) {
  ref_levels <- REFERENCE_LEVELS[[dataset_name]]
  if (is.null(ref_levels) || length(ref_levels) == 0) {
    return(test_data)
  }

  for (col_name in names(ref_levels)) {
    if (!(col_name %in% names(test_data))) next

    ref_level <- ref_levels[[col_name]]
    train_col <- train_data[[col_name]]
    test_col  <- test_data[[col_name]]

    if (is.factor(train_col)) {
      train_levels <- levels(train_col)
    } else {
      train_levels <- sort(unique(as.character(train_col)))
    }

    test_vals <- as.character(test_col)
    missing_mask <- !(test_vals %in% train_levels)

    if (any(missing_mask)) {
      missing_levels <- unique(test_vals[missing_mask])
      n_remapped <- sum(missing_mask)
      warning(sprintf(
        "[%s$%s] test に %d 件の未知レベル (%s) → 参照レベル '%s' に写像",
        dataset_name, col_name, n_remapped,
        paste(missing_levels, collapse = ", "), ref_level
      ))
      test_vals[missing_mask] <- ref_level
    }

    ordered_levels <- c(ref_level, setdiff(train_levels, ref_level))
    test_data[[col_name]] <- factor(test_vals, levels = ordered_levels)

  }

  test_data
}

set_reference_levels <- function(train_data, dataset_name) {
  ref_levels <- REFERENCE_LEVELS[[dataset_name]]
  if (is.null(ref_levels) || length(ref_levels) == 0) {
    return(train_data)
  }

  for (col_name in names(ref_levels)) {
    if (!(col_name %in% names(train_data))) next

    ref_level <- ref_levels[[col_name]]
    col_vals <- as.character(train_data[[col_name]])
    all_levels <- sort(unique(col_vals))
    ordered_levels <- c(ref_level, setdiff(all_levels, ref_level))
    train_data[[col_name]] <- factor(col_vals, levels = ordered_levels)
  }

  train_data
}
