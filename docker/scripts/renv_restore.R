options(Ncpus = parallel::detectCores())

cat("=== renv_restore.R ===\n")
cat(sprintf("R version: %s\n", paste(R.version$major, R.version$minor, sep = ".")))
cat(sprintf("Ncpus:     %d\n", getOption("Ncpus")))

lockfile <- renv::lockfile_read("/tmp/renv.lock")
packages <- lockfile$Packages
cat(sprintf("Packages in lockfile: %d\n\n", length(packages)))

all_installed <- installed.packages()
installed_map <- setNames(all_installed[, "Version"], all_installed[, "Package"])

rspm_pkgs <- character(0)
opendp_version <- NULL
skip_pkgs <- character(0)

expected_versions <- list()

for (pkg_name in names(packages)) {
  pkg <- packages[[pkg_name]]

  if (pkg_name %in% c("renv", "pak")) {
    if (pkg_name %in% names(installed_map) &&
        installed_map[[pkg_name]] != pkg$Version) {
      warning(sprintf("Infrastructure tool version mismatch: %s installed=%s, lockfile=%s",
                      pkg_name, installed_map[[pkg_name]], pkg$Version))
    }
    next
  }

  expected_versions[[pkg_name]] <- pkg$Version

  if (pkg_name %in% names(installed_map) &&
      installed_map[[pkg_name]] == pkg$Version) {
    skip_pkgs <- c(skip_pkgs, pkg_name)
    next
  }

  if (!is.null(pkg$Repository) && pkg$Repository == "https://opendp.r-universe.dev") {
    opendp_version <- pkg$Version
    next
  }

  rspm_pkgs <- c(rspm_pkgs, pkg_name)
}

cat(sprintf("Skip (already installed): %d\n", length(skip_pkgs)))
cat(sprintf("RSPM bulk install:        %d\n", length(rspm_pkgs)))
cat(sprintf("opendp (R-Universe):      %s\n",
            if (!is.null(opendp_version)) opendp_version else "N/A"))

if (length(rspm_pkgs) > 0) {
  cat(sprintf("\n--- Phase 1: Installing %d RSPM packages (parallel) ---\n",
              length(rspm_pkgs)))
  t_start <- proc.time()

  install.packages(
    rspm_pkgs,
    lib = "/usr/local/lib/R/site-library",
    repos = "https://packagemanager.posit.co/cran/__linux__/jammy/2024-10-01",
    Ncpus = parallel::detectCores()
  )

  elapsed <- (proc.time() - t_start)["elapsed"]
  cat(sprintf("Phase 1 done in %.1fs\n", elapsed))
}

if (!is.null(opendp_version)) {
  cat("\n--- Phase 2: Installing opendp from R-Universe ---\n")
  t_start <- proc.time()

  tryCatch({
    install.packages("opendp",
                     repos = "https://opendp.r-universe.dev",
                     lib = "/usr/local/lib/R/site-library")
  }, error = function(e) {
    cat(sprintf("  Binary failed (%s), trying source...\n", e$message))
    install.packages("opendp",
                     repos = "https://opendp.r-universe.dev",
                     type = "source",
                     lib = "/usr/local/lib/R/site-library")
  })

  elapsed <- (proc.time() - t_start)["elapsed"]
  cat(sprintf("Phase 2 done in %.1fs\n", elapsed))
}

cat("\n--- Phase 3: Version verification ---\n")
newly_installed <- installed.packages(lib.loc = c(
  "/usr/local/lib/R/site-library",
  "/usr/local/lib/R/library"
))
new_map <- setNames(newly_installed[, "Version"], newly_installed[, "Package"])

mismatches <- character(0)
missing <- character(0)

for (pkg_name in names(expected_versions)) {
  expected <- expected_versions[[pkg_name]]
  if (!(pkg_name %in% names(new_map))) {
    missing <- c(missing, sprintf("%s (%s)", pkg_name, expected))
  } else if (new_map[[pkg_name]] != expected) {
    mismatches <- c(mismatches,
                    sprintf("%s: want %s, got %s", pkg_name, expected, new_map[[pkg_name]]))
  }
}

if (length(missing) > 0) {
  cat(sprintf("MISSING (%d): %s\n", length(missing), paste(missing, collapse = ", ")))
}
if (length(mismatches) > 0) {
  cat(sprintf("MISMATCH (%d):\n", length(mismatches)))
  for (m in mismatches) cat(sprintf("  %s\n", m))
}
if (length(missing) == 0 && length(mismatches) == 0) {
  cat("All versions match.\n")
}

if (length(missing) > 0 || length(mismatches) > 0) {
  stop(sprintf("Version verification failed: %d missing, %d mismatches",
               length(missing), length(mismatches)))
}

if (requireNamespace("extrafont", quietly = TRUE)) {
  cat("\n--- Phase 4: Registering system fonts ---\n")
  extrafont::font_import(prompt = FALSE)
}

cat("\n=== renv_restore.R completed successfully ===\n")
