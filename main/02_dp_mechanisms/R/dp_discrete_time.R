fit_discrete_cox <- function(stacked_data, covariate_names, spline_df = 3L) {
  stopifnot(
    is.data.frame(stacked_data),
    "y_ik" %in% names(stacked_data),
    "interval_id" %in% names(stacked_data),
    all(covariate_names %in% names(stacked_data)),
    is.numeric(spline_df), spline_df >= 1
  )

  stacked_data$interval_id <- as.numeric(stacked_data$interval_id)

  baseline_term <- sprintf("splines::ns(interval_id, df = %d)", as.integer(spline_df))
  rhs <- paste(c(baseline_term, covariate_names), collapse = " + ")
  fml <- as.formula(paste("y_ik ~", rhs))

  glm(fml, data = stacked_data, family = binomial(link = "logit"))
}

extract_covariate_coefs <- function(fit_glm) {
  smry <- summary(fit_glm)
  coef_tbl <- as.data.frame(smry$coefficients)

  keep <- !grepl("^\\(Intercept\\)|^factor\\(interval_id\\)|^splines::ns\\(interval_id|^ns\\(interval_id",
                  rownames(coef_tbl))
  coef_tbl <- coef_tbl[keep, , drop = FALSE]

  data.frame(
    variable = rownames(coef_tbl),
    beta     = coef_tbl[, "Estimate"],
    se       = coef_tbl[, "Std. Error"],
    z        = coef_tbl[, "z value"],
    p_value  = coef_tbl[, "Pr(>|z|)"],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
