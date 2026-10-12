PROJECT_DIR <- "/home/rstudio/project"
EVAL_DIR    <- file.path(PROJECT_DIR, "data/04_evaluation")
SIM_DIR     <- file.path(PROJECT_DIR, "data/03_simulation")
PREP_DIR    <- file.path(PROJECT_DIR, "data/01_prepared")
OUT_DIR     <- file.path(PROJECT_DIR, "main/06_report/output")

PAPER_ARTIFACTS <- c(
  "tab1_baseline", "tab2_lsr", "tab3_cindex_test", "tab4_threshold", "tab5_transition_zone",
  "tabS1_full_kpi", "tabS2_sim_params", "tabS3_fpr_summary",
  "fig1_lsr", "fig2_cindex_test", "fig3_hr_distribution", "fig4_hr_bias",
  "figS1_lsr_per_variable", "figS2_overfit_gap", "figS3_fpr", "figS4_fpr_by_variable",
  "fig3_beta_boxplot"
)

.artifact_origin <- function() {
  f <- tryCatch(knitr::current_input(), error = function(e) NULL)
  if (is.null(f) || !nzchar(f)) f <- Sys.getenv("ARTIFACT_ORIGIN", unset = "unknown")
  basename(f)
}

assert_artifact_name_unused <- function(name, out_dir = OUT_DIR) {
  ledger <- file.path(out_dir, ".artifact_names.txt")
  origin <- .artifact_origin()
  register <- !identical(origin, "unknown")
  if (file.exists(ledger)) {
    reg <- utils::read.table(ledger, sep = "\t", header = FALSE, quote = "",
                             comment.char = "", stringsAsFactors = FALSE,
                             col.names = c("name", "origin"))
    hit <- reg[reg$name == name & reg$origin != origin, , drop = FALSE]
    if (nrow(hit) > 0) {
      stop(sprintf(
        paste0("'%s' は既に %s が保存している名前である。",
               "成果物どうしで名前を取り合うと、後から保存したほうが警告なく上書きする",
               "。どちらかの名前を変えること。",
               "\n  台帳: %s（意図的に作り直す場合は削除してよい）"),
        name, paste(unique(hit$origin), collapse = " / "), ledger), call. = FALSE)
    }
    reg <- reg[!(reg$name == name & reg$origin == origin), , drop = FALSE]
  } else {
    reg <- data.frame(name = character(0), origin = character(0), stringsAsFactors = FALSE)
  }
  if (!register) return(invisible(TRUE))
  reg <- rbind(reg, data.frame(name = name, origin = origin, stringsAsFactors = FALSE))
  utils::write.table(reg, ledger, sep = "\t", row.names = FALSE, col.names = FALSE,
                     quote = FALSE, fileEncoding = "UTF-8")
  invisible(TRUE)
}

assert_not_paper_artifact <- function(name) {
  if (name %in% PAPER_ARTIFACTS) {
    stop(sprintf(
      paste0("'%s' は投稿版 paper_results.Rmd の成果物である。",
             "上書きしてはならない。新規の成果物は ",
             "tabS3_fpr_full / tabS4-S16 / figS5-S11 / fig5-fig6 の名前空間、",
             "または本文・応答書が名前で引く公開用の複製 fpr_mechanism_* / alpha_sensitivity_lsr_detail を使う。",
             "参照レベル修正アームによる**差し替え版**は、投稿版の名前に '_reffix' を付ける ",
             "（例: 'tab1_baseline_reffix'）。"),
      name), call. = FALSE)
  }
  invisible(TRUE)
}

DATASET_ORDER <- c("lung", "pbc", "colon", "rotterdam", "flchain")

Q_VALUES <- c(lung = 7L, pbc = 17L, colon = 11L, rotterdam = 9L, flchain = 7L)

PHASE_COLORS <- c(
  "Phase 1" = "#0072B2",
  "Phase 2" = "#E69F00",
  "Phase 3" = "#009E73",
  "Output"  = "#D55E00"
)

PHASE_LABELS <- c(
  "Phase 1" = "Phase 1 (Covariates only)",
  "Phase 2" = "Phase 2 (Full input)",
  "Phase 3" = "Phase 3 (Discrete-time)",
  "Output"  = "Output (dfbeta, central model)"
)

DATASET_LABELS <- c(
  "lung"      = "Lung (n=168, q=7)",
  "pbc"       = "PBC (n=312, q=17)",
  "colon"     = "Colon (n=929, q=11)",
  "rotterdam" = "Rotterdam (n=2982, q=9)",
  "flchain"   = "FLChain (n=6524, q=7)"
)

EPSILON_COLORS <- c(
  "1"       = "#D55E00",
  "10"      = "#E69F00",
  "100"     = "#56B4E9",
  "1000"    = "#009E73",
  "\u221E"  = "#000000"
)
EPSILON_LEVELS <- c("1", "10", "100", "1000", "\u221E")

ALPHA_VALUES <- c(0.01, 0.05, 0.10)

ALPHA_COLORS <- c(
  "0.01" = "#0072B2",
  "0.05" = "#D55E00",
  "0.10" = "#009E73"
)

ALPHA_LABELS <- c(
  "0.01" = "α = 0.01",
  "0.05" = "α = 0.05 (paper)",
  "0.10" = "α = 0.10"
)

DATASET_COLORS <- c(
  "lung"      = "#0072B2",
  "pbc"       = "#E69F00",
  "colon"     = "#009E73",
  "rotterdam" = "#CC79A7",
  "flchain"   = "#000000"
)

DATASET_LABELS_SHORT <- c(
  "lung"      = "lung",
  "pbc"       = "pbc",
  "colon"     = "colon",
  "rotterdam" = "rotterdam",
  "flchain"   = "flchain"
)

MAIN_FIG_BASE_SIZE <- 15

theme_paper <- function(base_size = 11) {
  theme_bw(base_size = base_size, base_family = "Times New Roman") +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = rel(1.0)),
      legend.text = element_text(size = rel(0.95)),
      strip.background = element_rect(fill = "grey93"),
      strip.text = element_text(face = "bold", size = rel(1.0)),
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = rel(1.1)),
      axis.title = element_text(size = rel(1.0)),
      axis.text = element_text(size = rel(0.9))
    )
}

theme_main_fig <- function(base_size = MAIN_FIG_BASE_SIZE, main_line_size = 11 / 22) {
  theme_paper(base_size = base_size) +
    theme(line = element_line(linewidth = main_line_size),
          rect = element_rect(linewidth = main_line_size),
          axis.ticks.length = unit(11 / 4, "pt"),
          strip.text = element_text(size = rel(0.9)))
}

save_fig <- function(plot, name, width = 7.5, height = 4, dpi = 300, out_dir = OUT_DIR) {
  assert_not_paper_artifact(name)
  assert_artifact_name_unused(name, out_dir)
  ggsave(file.path(out_dir, paste0(name, ".png")), plot,
         device = ragg::agg_png, width = width, height = height, dpi = dpi,
         units = "in", bg = "white")
  ggsave(file.path(out_dir, paste0(name, ".svg")), plot,
         device = svglite::svglite, width = width, height = height,
         units = "in", bg = "white")
  ggsave(file.path(out_dir, paste0(name, ".pdf")), plot,
         device = cairo_pdf, width = width, height = height,
         units = "in")
  invisible(plot)
}

save_tbl <- function(df, name, label = NULL, digits = 3, col.names = NULL, out_dir = OUT_DIR,
                     longtable = FALSE, caption = NULL,
                     display = NULL, sanitize_text = NULL, tex_transform = NULL) {
  assert_not_paper_artifact(name)
  assert_artifact_name_unused(name, out_dir)
  write.csv(df, file.path(out_dir, paste0(name, ".csv")), row.names = FALSE)
  write.xlsx(df, file.path(out_dir, paste0(name, ".xlsx")), overwrite = TRUE)
  df_tex <- df
  if (!is.null(tex_transform)) {
    df_tex <- tex_transform(df_tex)
    stopifnot(is.data.frame(df_tex), nrow(df_tex) == nrow(df), ncol(df_tex) == ncol(df))
  }
  if (!is.null(col.names)) {
    names(df_tex) <- col.names
  }
  tex <- xtable(df_tex, digits = digits, display = display, label = label, caption = caption)
  san_col <- if (!is.null(col.names)) identity else function(x) gsub("_", "\\\\_", x)
  san_txt <- if (is.null(sanitize_text)) function(x) gsub("_", "\\\\_", x) else sanitize_text
  if (longtable) {
    hdr <- paste(san_col(names(df_tex)), collapse = " & ")
    add_to_row <- list(
      pos = list(0L),
      command = paste0("\\midrule\n\\endfirsthead\n",
                       "\\toprule\n", hdr, " \\\\\n\\midrule\n\\endhead\n",
                       "\\midrule\n\\multicolumn{", ncol(df_tex),
                       "}{r}{\\textit{continued on next page}} \\\\\n\\endfoot\n",
                       "\\bottomrule\n\\endlastfoot\n")
    )
    print(tex,
          file = file.path(out_dir, paste0(name, ".tex")),
          include.rownames = FALSE,
          booktabs = TRUE,
          floating = FALSE,
          tabular.environment = "longtable",
          sanitize.text.function = san_txt,
          sanitize.colnames.function = san_col,
          comment = FALSE,
          add.to.row = add_to_row,
          hline.after = c(-1))
  } else {
    print(tex,
          file = file.path(out_dir, paste0(name, ".tex")),
          include.rownames = FALSE,
          booktabs = TRUE,
          floating = FALSE,
          sanitize.text.function = san_txt,
          sanitize.colnames.function = san_col,
          comment = FALSE,
          hline.after = c(-1, 0, nrow(df_tex)))
  }
  invisible(df)
}

save_csv_copy <- function(src, name, out_dir = OUT_DIR) {
  assert_not_paper_artifact(name)
  assert_artifact_name_unused(name, out_dir)
  stopifnot(length(src) == 1L, file.exists(src))
  dst <- file.path(out_dir, paste0(name, ".csv"))
  stopifnot(file.copy(src, dst, overwrite = TRUE))
  if (!identical(unname(tools::md5sum(src)), unname(tools::md5sum(dst)))) {
    stop(sprintf("save_csv_copy(): the copy '%s' does not match its source %s", dst, src),
         call. = FALSE)
  }
  invisible(dst)
}

read_record_doc <- function(rel_path, project_dir = PROJECT_DIR) {
  path <- file.path(project_dir, rel_path)
  if (file.exists(path)) return(readLines(path, warn = FALSE))
  if (FALSE) {
    stop(sprintf(paste0("%s が無い。作業リポジトリでは記録文書との照合を必ず行う",
                        "。"), rel_path), call. = FALSE)
  }
  cat(sprintf("Note: %s is not part of this copy; the cross-check against it is skipped.\n",
              rel_path))
  NULL
}

rmd_chunk <- function(path, label) {
  ln  <- readLines(path, warn = FALSE)
  beg <- grep(sprintf("^```\\{r %s[,}]", label), ln)
  if (length(beg) != 1L) {
    stop(sprintf("チャンク '%s' が %s に %d 個ある（1 個でなければならない）",
                 label, path, length(beg)), call. = FALSE)
  }
  rest <- ln[(beg + 1L):length(ln)]
  end  <- beg + which(startsWith(rest, "```"))[1]
  ln[beg:end]
}

assert_chunk_verbatim <- function(a, b, labels) {
  for (lab in labels) {
    x <- rmd_chunk(a, lab); y <- rmd_chunk(b, lab)
    if (identical(x, y)) next
    n <- min(length(x), length(y))
    d <- which(x[seq_len(n)] != y[seq_len(n)])
    stop(paste(c(
      sprintf("チャンク '%s' が切り出し元と一致しない（%s と %s）。", lab, a, b),
      sprintf("  行数: 切り出し元 %d / こちら %d", length(x), length(y)),
      if (length(d)) sprintf("  最初の差 (行 %d):\n    元  : %s\n    こちら: %s",
                             d[1], x[d[1]], y[d[1]])),
      collapse = "\n"), call. = FALSE)
  }
  invisible(TRUE)
}

assert_defs_match <- function(src, own, names) {
  def_expr <- function(path, nm) {
    ln  <- readLines(path, warn = FALSE)
    hit <- grep(sprintf("^%s[ \t]*<-", gsub("([.\\[\\]()])", "\\\\\\1", nm)), ln)
    if (length(hit) != 1L) {
      stop(sprintf("定義 '%s <- ...' が %s に %d 個ある（1 個でなければならない）",
                   nm, path, length(hit)), call. = FALSE)
    }
    for (last in seq(hit, min(length(ln), hit + 200L))) {
      e <- tryCatch(parse(text = paste(ln[hit:last], collapse = "\n")),
                    error = function(err) NULL)
      if (!is.null(e) && length(e) == 1L) return(e[[1]])
    }
    stop(sprintf("定義 '%s' を %s から読み取れなかった", nm, path), call. = FALSE)
  }
  for (nm in names) {
    x <- deparse(def_expr(src, nm)); y <- deparse(def_expr(own, nm))
    if (identical(x, y)) next
    stop(paste(c(sprintf("定義 '%s' が出どころと一致しない（%s と %s）。", nm, src, own),
                 "  出どころ:", paste0("    ", x),
                 "  こちら:",   paste0("    ", y)), collapse = "\n"), call. = FALSE)
  }
  invisible(TRUE)
}

md_cells <- function(line) {
  s <- trimws(line)
  s <- sub("^\\|", "", s); s <- sub("\\|$", "", s)
  trimws(gsub("\\*\\*", "", strsplit(s, "|", fixed = TRUE)[[1]]))
}

md_table <- function(lines, head1, head2) {
  if (is.null(lines)) return(NULL)
  is_row <- startsWith(trimws(lines), "|")
  hit <- which(is_row & vapply(lines, function(x) {
    cc <- md_cells(x); length(cc) >= 2L && cc[1] == head1 && cc[2] == head2
  }, logical(1), USE.NAMES = FALSE))
  stopifnot(length(hit) == 1L)
  i <- hit + 2L
  out <- list()
  while (i <= length(lines) && is_row[i]) { out[[length(out) + 1L]] <- md_cells(lines[i]); i <- i + 1L }
  stopifnot(length(out) > 0L, length(unique(lengths(out))) == 1L)
  do.call(rbind, out)
}

md_check <- function(actual, expected, label,
                     doc = "internal-record.md", src = "tabS6") {
  if (is.null(actual)) return(invisible(TRUE))
  if (identical(dim(actual), dim(expected)) && identical(actual, expected)) return(invisible(TRUE))
  detail <- if (identical(dim(actual), dim(expected))) {
    bad <- which(actual != expected, arr.ind = TRUE)
    c("  differing cells (row, column, in document -> expected):",
      sprintf("    [%d, %d] %s -> %s", bad[, 1], bad[, 2],
              actual[cbind(bad[, 1], bad[, 2])], expected[cbind(bad[, 1], bad[, 2])]))
  } else {
    sprintf("  shape: document %s, expected %s",
            paste(dim(actual), collapse = " x "), paste(dim(expected), collapse = " x "))
  }
  stop(paste(c(
    sprintf("%s %s no longer matches %s.", doc, label, src),
    detail,
    "  expected body (paste over the rows of that table):",
    paste0("| ", apply(expected, 1, paste, collapse = " | "), " |")), collapse = "\n"),
    call. = FALSE)
}

fmt_g <- function(x) trimws(formatC(x, format = "g", digits = 4))

unify_output <- function(df) {
  df %>%
    filter(!phase %in% c("Output", "Output (Std)")) %>%
    mutate(phase = ifelse(phase == "Output (dfbeta)", "Output", phase))
}

get_kpi <- function(df, ds, eps, ph, metric, default = NA_real_) {
  row <- df %>% filter(dataset == ds, epsilon == eps, phase == ph)
  if (nrow(row) == 0) return(default)
  val <- row[[metric]][1]
  if (is.na(val)) return(default)
  val
}
