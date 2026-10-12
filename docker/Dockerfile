# Digest pinned on 2026-03-04 for full reproducibility
FROM rocker/rstudio:4.4.1@sha256:051c070473e7e29508673daf64d10d78f44506fd0c84e83e9471a1900c885c4b

# System dependencies for R packages, graphics, and document rendering
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcairo2-dev \
    libxt-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    cmake \
    pandoc \
    libgit2-dev \
    zlib1g-dev \
    curl \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Japanese fonts for ggplot2 figures
RUN apt-get update \
    && apt-get install -y --no-install-recommends fonts-noto-cjk \
    && fc-cache -f -v \
    && rm -rf /var/lib/apt/lists/*

# Microsoft core fonts (Times New Roman, Arial, etc.)
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
      | debconf-set-selections \
    && apt-get update \
    && apt-get install -y --no-install-recommends ttf-mscorefonts-installer \
    && fc-cache -f -v \
    && rm -rf /var/lib/apt/lists/*

# Rust toolchain (needed for opendp compilation)
# Version pinned for reproducibility (tested with 1.85.0)
# SECURITY NOTE: rustup.rs is fetched over TLS but without checksum verification.
# This is accepted for local research use. For CI/CD or shared environments,
# download the installer separately and verify its SHA-256 checksum, or use
# a multi-stage build with the official rust:1.85.0 Docker image.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.85.0 \
    && mv /root/.cargo /home/rstudio/.cargo \
    && mv /root/.rustup /home/rstudio/.rustup \
    && chown -R rstudio:rstudio /home/rstudio/.cargo /home/rstudio/.rustup

# Make cargo/rustc available in PATH for both users
ENV PATH="/home/rstudio/.cargo/bin:${PATH}"
ENV CARGO_HOME="/home/rstudio/.cargo"
ENV RUSTUP_HOME="/home/rstudio/.rustup"

# Configure Posit Package Manager for binary R packages
# Snapshot date pinned to 2024-10-01 for R 4.4.1 compatibility
# (latest ggrepel requires R >= 4.5.0)
RUN echo 'options(repos = c(RSPM = "https://packagemanager.posit.co/cran/__linux__/jammy/2024-10-01", opendp = "https://opendp.r-universe.dev"))' \
      >> /usr/local/lib/R/etc/Rprofile.site \
    && echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))' \
      >> /usr/local/lib/R/etc/Rprofile.site

# Install pak
RUN R -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))'

# Install R packages
COPY scripts/install_packages.R /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R && rm /tmp/install_packages.R

# Fix cargo/rustup ownership (opendp compilation as root may have changed ownership)
RUN chown -R rstudio:rstudio /home/rstudio/.cargo /home/rstudio/.rustup

# Install TinyTeX for PDF report rendering (bookdown/rmarkdown)
RUN R -e 'tinytex::install_tinytex(force = TRUE)' \
    && mv /root/.TinyTeX /home/rstudio/.TinyTeX \
    && chown -R rstudio:rstudio /home/rstudio/.TinyTeX
# TinyTeX bin ディレクトリを動的に PATH へ追加（x86_64/aarch64 両対応）
# シンボリックリンクで固定パスを提供し、ENV PATH で参照可能にする
RUN TINYTEX_ARCH=$(ls /home/rstudio/.TinyTeX/bin/) \
    && ln -s /home/rstudio/.TinyTeX/bin/$TINYTEX_ARCH /home/rstudio/.TinyTeX/bin/current \
    && echo "export PATH=\"/home/rstudio/.TinyTeX/bin/current:\$PATH\"" >> /etc/profile.d/tinytex.sh
ENV PATH="/home/rstudio/.TinyTeX/bin/current:${PATH}"

# Working directory
WORKDIR /home/rstudio/project
