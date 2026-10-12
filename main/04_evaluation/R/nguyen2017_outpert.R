library(survival)

nguyen_basis <- function(t, e = 3L) {
  stopifnot(is.numeric(t), all(t >= 0 & t <= 1), e >= 3L)
  knots <- seq(0, 1, length.out = e)
  d_fn <- function(tt, j) {
    (pmax(tt - knots[j], 0)^3 - pmax(tt - knots[e], 0)^3) / (knots[e] - knots[j])
  }
  B <- matrix(NA_real_, nrow = length(t), ncol = e)
  B[, 1] <- 1
  B[, 2] <- t
  for (i in seq_len(e - 2L)) B[, i + 2L] <- d_fn(t, i) - d_fn(t, e - 1L)
  colnames(B) <- paste0("A", seq_len(e))
  B
}

nguyen_S <- function(t_s, e = 3L) {
  A <- nguyen_basis(t_s, e)
  an <- sqrt(rowSums(A^2))
  list(S = sum(sqrt(4 + an^2)) + max(sqrt(4 * an^2 + 4)), A_norms = an)
}

nguyen_sensitivity <- function(S, n, lambda) S / (n * lambda)

draw_nguyen_noise <- function(d, sens, epsilon) {
  stopifnot(length(epsilon) == 1L, !is.na(epsilon), epsilon > 0,
            length(sens) == 1L, is.finite(sens), sens >= 0,
            length(d) == 1L, d >= 1L)
  if (is.infinite(epsilon)) return(rep(0, d))
  r <- rgamma(1, shape = d, scale = sens / epsilon)
  u <- rnorm(d)
  r * u / sqrt(sum(u^2))
}

make_nguyen_obj <- function(X, yr, n, lambda) {
  list(
    fn = function(f) {
      z <- yr * as.vector(X %*% f)
      loss <- ifelse(z > 0, log1p(exp(-z)), -z + log1p(exp(z)))
      sum(loss) / n + 0.5 * lambda * sum(f^2)
    },
    gr = function(f) {
      z <- yr * as.vector(X %*% f)
      as.vector(crossprod(X, -yr / (1 + exp(z)))) / n + lambda * f
    }
  )
}

fit_nguyen_erm <- function(X, yr, n, lambda, init = NULL,
                           tol = 1e-6, max_restart = 5L) {
  o <- make_nguyen_obj(X, yr, n, lambda)
  f <- if (is.null(init)) rep(0, ncol(X)) else init
  gn <- NA_real_
  for (k in seq_len(max_restart)) {
    res <- optim(f, o$fn, o$gr, method = "BFGS",
                 control = list(maxit = 1000, reltol = 1e-12))
    f <- res$par
    gn <- sqrt(sum(o$gr(f)^2)) / max(1, sqrt(sum(f^2)))
    if (gn < tol) break
  }
  list(par = f, grad_norm = gn, converged = (gn < tol), restarts = k)
}

nguyen_fixed_intervals <- function(t_max_fixed, q) {
  stopifnot(is.numeric(t_max_fixed), length(t_max_fixed) == 1L, t_max_fixed > 0,
            length(q) == 1L, q >= 2L)
  upper_time <- (seq_len(q) / q) * t_max_fixed
  upper_time[q] <- Inf
  list(intervals = data.frame(interval_id = seq_len(q),
                              lower = c(0, upper_time[-q]),
                              upper = upper_time),
       t_s = seq_len(q) / q)
}

build_nguyen_design_traintest <- function(train_data, test_data, K, cox_formula,
                                          standardize = FALSE, e_knots = 3L,
                                          fixed_time = NULL) {
  if (is.null(fixed_time)) {
    ev <- train_data$time[train_data$status == 1]
    intervals <- create_time_intervals(ev, K)
    actual_K <- nrow(intervals)
  } else {
    stopifnot(is.list(fixed_time), all(c("t_max", "q") %in% names(fixed_time)))
    fi <- nguyen_fixed_intervals(fixed_time$t_max, fixed_time$q)
    intervals <- fi$intervals
    actual_K <- as.integer(fixed_time$q)
  }
  stacked <- stack_survival_data(train_data, intervals)

  rhs <- reformulate(attr(terms(cox_formula), "term.labels"))
  mm_tr   <- model.matrix(rhs, data = train_data)[, -1, drop = FALSE]
  mm_stk  <- model.matrix(rhs, data = stacked)[, -1, drop = FALSE]
  mm_te   <- model.matrix(rhs, data = test_data)[, -1, drop = FALSE]
  stopifnot(identical(colnames(mm_tr), colnames(mm_stk)),
            identical(colnames(mm_tr), colnames(mm_te)))

  ctr <- colMeans(mm_tr)
  sdv <- if (standardize) apply(mm_tr, 2, sd) else rep(1, ncol(mm_tr))
  sdv[!is.finite(sdv) | sdv <= 0] <- 1
  mmc <- sweep(sweep(mm_tr, 2, ctr, "-"), 2, sdv, "/")
  scale_unit <- max(sqrt(rowSums(mmc^2)))
  stopifnot(scale_unit > 0)

  norm_cov <- function(M) sweep(sweep(sweep(M, 2, ctr, "-"), 2, sdv, "/"), 2, scale_unit, "/")
  Xcov      <- norm_cov(mm_stk)
  Xcov_test <- norm_cov(mm_te)
  stopifnot(max(sqrt(rowSums(Xcov^2))) <= 1 + 1e-9)

  if (is.null(fixed_time)) {
    ub <- intervals$upper
    ub[actual_K] <- max(train_data$time)
    t_s <- ub / max(train_data$time)
    stopifnot(all(t_s > 0 & t_s <= 1))
  } else {
    t_s <- fi$t_s
  }

  A_rows <- nguyen_basis(t_s[stacked$interval_id], e_knots)
  X      <- cbind(A_rows, Xcov)
  X_orig <- cbind(A_rows, sweep(mm_stk, 2, ctr, "-"))
  yr     <- ifelse(stacked$y_ik == 1L, 1, -1)

  stopifnot(nrow(X) == length(yr), !anyNA(X))
  list(X = X, X_orig = X_orig, yr = yr, y01 = stacked$y_ik,
       X_test_cov = Xcov_test, t_s = t_s,
       n = nrow(train_data), d = ncol(X), e = e_knots,
       actual_K = actual_K, rows = nrow(X),
       scale_unit = scale_unit, sd_vec = sdv,
       ctr = ctr)
}

fit_nguyen_f_star <- function(dsg) {
  g <- suppressWarnings(glm.fit(dsg$X_orig, dsg$y01, family = binomial(link = "logit")))
  f_orig <- unname(g$coefficients)
  if (anyNA(f_orig)) f_orig[is.na(f_orig)] <- 0
  idx_cov <- (dsg$e + 1L):dsg$d
  f_norm <- f_orig
  f_norm[idx_cov] <- f_orig[idx_cov] * dsg$sd_vec * dsg$scale_unit
  list(par = f_norm, converged = isTRUE(g$converged), iter = g$iter)
}

nguyen_c_index_test <- function(dsg, f, surv_test) {
  beta <- f[(dsg$e + 1L):dsg$d]
  lp <- as.numeric(dsg$X_test_cov %*% beta)
  if (!is.finite(sum(lp)) || diff(range(lp)) < .Machine$double.eps) return(NA_real_)
  co <- tryCatch(concordancefit(surv_test, -lp), error = function(e) NULL)
  if (is.null(co)) NA_real_ else as.numeric(co$concordance)
}

T_MAX_FIXED_NGUYEN_DATES <- c(
  start = "1995-03-13",
  end   = "2009-06-30"
)
T_MAX_FIXED_NGUYEN <- list(
  flchain = as.numeric(as.Date(T_MAX_FIXED_NGUYEN_DATES[["end"]]) -
                       as.Date(T_MAX_FIXED_NGUYEN_DATES[["start"]]))
)
stopifnot(isTRUE(all.equal(T_MAX_FIXED_NGUYEN$flchain, 5223)))

if (!exists("CLIPPING_BOUNDS_FIXED")) {
  stop(paste0("nguyen2017_outpert.R: main/02_dp_mechanisms/R/dp_bounds_comparison.R を先に source して",
              "ください（その前に dp_input_perturbation_phase1.R も必要）。",
              ""))
}

derive_nguyen_bounds <- function(fixed_bounds) {
  b <- fixed_bounds[["flchain"]]
  if (is.null(b)) stop("derive_nguyen_bounds: CLIPPING_BOUNDS_FIXED$flchain が見つかりません")
  if (!identical(b$sex, c("F", "M"))) {
    stop("derive_nguyen_bounds: CLIPPING_BOUNDS_FIXED$flchain$sex が c(\"F\", \"M\") ではない。",
         "実験 G の sexM ダミーの参照水準を確認すること")
  }
  out <- list(
    age        = as.numeric(b$age),
    sexM       = c(0, 1),
    sample.yr  = as.numeric(b$sample.yr),
    kappa      = as.numeric(b$kappa),
    lambda     = as.numeric(b$lambda),
    creatinine = as.numeric(b$creatinine),
    mgus       = as.numeric(b$mgus)
  )
  out
}

FIXED_BOUNDS_NGUYEN <- list(flchain = derive_nguyen_bounds(CLIPPING_BOUNDS_FIXED))

local({
  expected <- list(age = c(50, 110), sample.yr = c(1995, 2003),
                   kappa = c(0, 30), lambda = c(0, 40), creatinine = c(0, 80),
                   sexM = c(0, 1), mgus = c(0, 1))
  for (nm in names(expected)) {
    got <- FIXED_BOUNDS_NGUYEN$flchain[[nm]]
    if (!isTRUE(all.equal(as.numeric(got), expected[[nm]]))) {
      stop(sprintf(paste0("FIXED_BOUNDS_NGUYEN$flchain$%s が規約の確定値と食い違います",
                          "（規約 %s / 導出 %s）。docs/fixed_bounds_source_protocol.md を確認すること",
                          ""),
                   nm, paste(expected[[nm]], collapse = "-"), paste(got, collapse = "-")))
    }
  }
  invisible(TRUE)
})

build_nguyen_design_formal <- function(train_data, test_data, cox_formula,
                                       bounds, t_max_fixed, q = 200L, e_knots = 3L) {
  stopifnot(is.numeric(t_max_fixed), t_max_fixed > 0, q >= 2L)

  fi <- nguyen_fixed_intervals(t_max_fixed, q)
  intervals <- fi$intervals
  stacked <- stack_survival_data(train_data, intervals)
  actual_K <- q

  rhs <- reformulate(attr(terms(cox_formula), "term.labels"))
  mm_tr  <- model.matrix(rhs, data = train_data)[, -1, drop = FALSE]
  mm_stk <- model.matrix(rhs, data = stacked)[, -1, drop = FALSE]
  mm_te  <- model.matrix(rhs, data = test_data)[, -1, drop = FALSE]
  stopifnot(identical(colnames(mm_tr), colnames(mm_stk)),
            identical(colnames(mm_tr), colnames(mm_te)))

  cn <- colnames(mm_tr)
  missing_b <- setdiff(cn, names(bounds))
  if (length(missing_b) > 0)
    stop("fixed bounds missing for: ", paste(missing_b, collapse = ", "))
  lo <- vapply(cn, function(v) bounds[[v]][1], numeric(1))
  hi <- vapply(cn, function(v) bounds[[v]][2], numeric(1))
  stopifnot(all(hi > lo))
  ctr <- (lo + hi) / 2
  half <- (hi - lo) / 2
  p <- length(cn)

  box_norm <- function(M) {
    Z <- sweep(sweep(M, 2, ctr, "-"), 2, half, "/")
    Z[Z >  1] <-  1
    Z[Z < -1] <- -1
    Z / sqrt(p)
  }
  Z_raw <- sweep(sweep(mm_tr, 2, ctr, "-"), 2, half, "/")
  clip_rate <- mean(abs(Z_raw) > 1)

  Xcov      <- box_norm(mm_stk)
  Xcov_test <- box_norm(mm_te)
  stopifnot(max(sqrt(rowSums(Xcov^2))) <= 1 + 1e-9,
            max(sqrt(rowSums(Xcov_test^2))) <= 1 + 1e-9)

  t_s <- fi$t_s
  A_rows <- nguyen_basis(t_s[stacked$interval_id], e_knots)
  X      <- cbind(A_rows, Xcov)
  X_orig <- cbind(A_rows, sweep(Xcov * sqrt(p), 2, half, "*"))
  yr     <- ifelse(stacked$y_ik == 1L, 1, -1)

  stopifnot(nrow(X) == length(yr), !anyNA(X))
  list(X = X, X_orig = X_orig, yr = yr, y01 = stacked$y_ik,
       X_test_cov = Xcov_test, t_s = t_s,
       n = nrow(train_data), d = ncol(X), e = e_knots,
       actual_K = actual_K, rows = nrow(X),
       scale_unit = sqrt(p), sd_vec = half, clip_rate = clip_rate,
       ctr = ctr,
       formal = TRUE)
}

run_nguyen_iteration <- function(data, iteration, specs, cox_formula, dataset_name,
                                 epsilon_values, lambda_grid,
                                 base_seed, split_base_seed,
                                 test_ratio = 0.3, e_knots = 3L,
                                 seed_stride = 1000L) {
  split_seed <- split_base_seed + iteration
  sp <- stratified_train_test_split(data, test_ratio = test_ratio, seed = split_seed)
  train_data <- set_reference_levels(sp$train, dataset_name)
  test_data  <- align_factor_levels(train_data, sp$test, dataset_name)
  surv_test  <- Surv(test_data$time, test_data$status)

  n_lam <- length(lambda_grid); n_eps <- length(epsilon_values)
  out <- vector("list", length(specs) * n_lam * n_eps)
  k <- 0L

  for (si in seq_along(specs)) {
    spec <- specs[[si]]
    dsg <- if (identical(spec$type, "formal")) {
      build_nguyen_design_formal(train_data, test_data, cox_formula,
                                 bounds = spec$bounds, t_max_fixed = spec$t_max,
                                 q = spec$q, e_knots = e_knots)
    } else {
      build_nguyen_design_traintest(train_data, test_data, spec$K, cox_formula,
                                    standardize = isTRUE(spec$standardize),
                                    e_knots = e_knots,
                                    fixed_time = spec$fixed_time)
    }
    S <- nguyen_S(dsg$t_s, e_knots)$S

    fs <- fit_nguyen_f_star(dsg)
    c_ref   <- nguyen_c_index_test(dsg, fs$par, surv_test)
    nrm_ref <- sqrt(sum(fs$par^2))

    lam_desc <- sort(lambda_grid, decreasing = TRUE)
    sols <- list(); prev <- NULL
    for (lam in lam_desc) {
      fl <- fit_nguyen_erm(dsg$X, dsg$yr, dsg$n, lam, init = prev)
      sols[[sprintf("%.10e", lam)]] <- fl
      prev <- fl$par
    }

    for (li in seq_len(n_lam)) {
      lam  <- lambda_grid[li]
      fl   <- sols[[sprintf("%.10e", lam)]]
      sens <- nguyen_sensitivity(S, dsg$n, lam)
      c_lam <- nguyen_c_index_test(dsg, fl$par, surv_test)
      for (ei in seq_len(n_eps)) {
        eps <- epsilon_values[ei]
        seed <- base_seed +
          (((si - 1L) * n_lam + (li - 1L)) * n_eps + (ei - 1L)) * seed_stride + iteration
        set.seed(seed)
        b <- draw_nguyen_noise(dsg$d, sens, eps)
        f_priv <- fl$par + b
        k <- k + 1L
        out[[k]] <- data.frame(
          iteration = iteration, spec = spec$name, formal = identical(spec$type, "formal"),
          lambda = lam, epsilon = eps,
          c_index_test        = nguyen_c_index_test(dsg, f_priv, surv_test),
          c_index_test_lambda = c_lam,
          c_index_test_ref    = c_ref,
          mre         = sqrt(sum((f_priv - fs$par)^2)) / nrm_ref,
          mre_lambda  = sqrt(sum((fl$par - fs$par)^2)) / nrm_ref,
          beta_norm_ratio = sqrt(sum(f_priv[(dsg$e + 1L):dsg$d]^2)) /
                            sqrt(sum(fs$par[(dsg$e + 1L):dsg$d]^2)),
          sensitivity = sens, S = S, d = dsg$d,
          converged   = fl$converged, grad_norm = fl$grad_norm,
          actual_K    = dsg$actual_K, stacked_rows = dsg$rows,
          clip_rate   = if (is.null(dsg$clip_rate)) NA_real_ else dsg$clip_rate,
          n_train = nrow(train_data), n_test = nrow(test_data),
          event_rate_train = mean(train_data$status),
          event_rate_test  = mean(test_data$status),
          seed = seed, split_seed = split_seed,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, out)
}
