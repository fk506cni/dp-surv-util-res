options(Ncpus = parallel::detectCores())

options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/2024-10-01"))

library(pak)

cran_packages <- c(
  "survival",
  "survminer",

  "tidyverse",

  "future",
  "furrr",
  "progressr",

  "rmarkdown",
  "knitr",
  "bookdown",
  "tinytex",

  "gt",
  "gtsummary",

  "openxlsx",
  "arrow",

  "svglite",
  "ragg",
  "scales",
  "patchwork",
  "cowplot",

  "xtable",
  "stargazer",

  "extrafont",
  "systemfonts",

  "kableExtra",

  "callr",

  "here",
  "fs",
  "tictoc",
  "withr"
)

pak::pkg_install(cran_packages)

OPENDP_TARGET_VERSION <- "0.14.1"
tryCatch(
  {
    message("opendp: attempting binary install from R-Universe...")
    install.packages("opendp", repos = "https://opendp.r-universe.dev/")
  },
  error = function(e) {
    message("opendp binary install failed: ", e$message)
    message("opendp: retrying with source compilation (requires Rust toolchain)...")
    install.packages("opendp", repos = "https://opendp.r-universe.dev/", type = "source")
  }
)
if (!requireNamespace("opendp", quietly = TRUE)) {
  stop("opendp installation failed. Check Rust toolchain and R-Universe availability.")
}
installed_ver <- as.character(packageVersion("opendp"))
message("opendp version: ", installed_ver)
if (installed_ver != OPENDP_TARGET_VERSION) {
  warning(sprintf("opendp version mismatch: installed %s, expected %s. API incompatibility possible.",
                  installed_ver, OPENDP_TARGET_VERSION))
}

extrafont::font_import(prompt = FALSE)
