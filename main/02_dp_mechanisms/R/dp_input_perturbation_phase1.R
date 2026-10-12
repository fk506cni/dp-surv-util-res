CLIPPING_BOUNDS <- list(
  lung = list(
    age      = c(39, 82),
    sex      = c(1, 2),
    ph.ecog  = c(0, 3),
    ph.karno = c(50, 100),
    pat.karno = c(30, 100),
    meal.cal = c(96, 2600),
    wt.loss  = c(-24, 68)
  ),
  pbc = list(
    age      = c(26.28, 78.44),
    sex      = c("f", "m"),
    trt      = c(1, 2),
    ascites  = c(0, 1),
    hepato   = c(0, 1),
    spiders  = c(0, 1),
    edema    = c(0, 0.5, 1),
    bili     = c(0.3, 28),
    chol     = c(120, 1775),
    albumin  = c(1.96, 4.64),
    copper   = c(4, 588),
    alk.phos = c(289, 13862.4),
    ast      = c(26.35, 457.25),
    trig     = c(33, 598),
    platelet = c(62, 563),
    protime  = c(9, 17.1),
    stage    = c(1, 2, 3, 4)
  ),
  colon = list(
    sex      = c(0, 1),
    age      = c(18, 85),
    obstruct = c(0, 1),
    perfor   = c(0, 1),
    adhere   = c(0, 1),
    nodes    = c(0, 33),
    differ   = c(1, 2, 3),
    extent   = c(1, 2, 3, 4),
    surg     = c(0, 1),
    node4    = c(0, 1),
    rx       = c("Obs", "Lev", "Lev+5FU")
  ),
  rotterdam = list(
    age    = c(24, 90),
    meno   = c(0, 1),
    size   = c("<=20", "20-50", ">50"),
    grade  = c(2, 3),
    nodes  = c(0, 34),
    pgr    = c(0, 5004),
    er     = c(0, 3275),
    hormon = c(0, 1),
    chemo  = c(0, 1)
  ),
  flchain = list(
    age        = c(50, 101),
    sex        = c("F", "M"),
    sample.yr  = c(1995, 2003),
    kappa      = c(0.01, 20.50),
    lambda     = c(0.04, 26.60),
    creatinine = c(0.4, 10.8),
    mgus       = c(0, 1)
  )
)

COVARIATE_TYPES <- list(
  lung = list(
    age       = "continuous",
    sex       = "categorical",
    ph.ecog   = "continuous",
    ph.karno  = "continuous",
    pat.karno = "continuous",
    meal.cal  = "continuous",
    wt.loss   = "continuous"
  ),
  pbc = list(
    age      = "continuous",
    sex      = "categorical",
    trt      = "categorical",
    ascites  = "binary",
    hepato   = "binary",
    spiders  = "binary",
    edema    = "categorical",
    bili     = "continuous",
    chol     = "continuous",
    albumin  = "continuous",
    copper   = "continuous",
    alk.phos = "continuous",
    ast      = "continuous",
    trig     = "continuous",
    platelet = "continuous",
    protime  = "continuous",
    stage    = "categorical"
  ),
  colon = list(
    sex      = "binary",
    age      = "continuous",
    obstruct = "binary",
    perfor   = "binary",
    adhere   = "binary",
    nodes    = "continuous",
    differ   = "categorical",
    extent   = "categorical",
    surg     = "binary",
    node4    = "binary",
    rx       = "categorical"
  ),
  rotterdam = list(
    age    = "continuous",
    meno   = "binary",
    size   = "categorical",
    grade  = "categorical",
    nodes  = "continuous",
    pgr    = "continuous",
    er     = "continuous",
    hormon = "binary",
    chemo  = "binary"
  ),
  flchain = list(
    age        = "continuous",
    sex        = "categorical",
    sample.yr  = "continuous",
    kappa      = "continuous",
    lambda     = "continuous",
    creatinine = "continuous",
    mgus       = "binary"
  )
)

SURV_COLS <- c("time", "status")

allocate_budget <- function(total_epsilon, n_covariates) {
  stopifnot(
    is.numeric(total_epsilon), length(total_epsilon) == 1,
    total_epsilon > 0,
    is.numeric(n_covariates), length(n_covariates) == 1,
    n_covariates >= 1
  )
  total_epsilon / n_covariates
}

perturb_covariates_phase1 <- function(data,
                                       clipping_bounds,
                                       epsilon,
                                       covariate_types,
                                       mechanism = "laplace",
                                       delta_dp = 1e-5) {
  stopifnot(
    is.data.frame(data),
    is.list(clipping_bounds),
    is.numeric(epsilon), length(epsilon) == 1, epsilon > 0,
    is.list(covariate_types),
    mechanism %in% c("laplace", "gaussian")
  )

  covariate_names <- setdiff(names(data), SURV_COLS)

  missing_types <- setdiff(covariate_names, names(covariate_types))
  if (length(missing_types) > 0) {
    stop("Missing covariate types for: ", paste(missing_types, collapse = ", "))
  }
  missing_bounds <- setdiff(covariate_names, names(clipping_bounds))
  if (length(missing_bounds) > 0) {
    stop("Missing clipping bounds for: ", paste(missing_bounds, collapse = ", "))
  }

  n_cov <- length(covariate_names)
  eps_j <- allocate_budget(epsilon, n_cov)

  result <- data

  for (col in covariate_names) {
    cov_type <- covariate_types[[col]]
    bounds <- clipping_bounds[[col]]

    result[[col]] <- switch(cov_type,
      "continuous" = {
        lower <- bounds[1]
        upper <- bounds[2]
        if (mechanism == "laplace") {
          dp_laplace(data[[col]], lower, upper, eps_j)
        } else {
          dp_gaussian(data[[col]], lower, upper, eps_j, delta_dp)
        }
      },
      "binary" = {
        dp_randomized_response_binary(data[[col]], eps_j)
      },
      "categorical" = {
        dp_randomized_response_categorical(data[[col]], bounds, eps_j)
      },
      stop("Unknown covariate type '", cov_type, "' for column '", col, "'")
    )
  }

  result
}
