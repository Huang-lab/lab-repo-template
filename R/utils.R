# Reusable, tested R helpers. Analysis scripts live in steps/ or analysis/ and
# source these; keep anything with a branch worth testing in here.

#' Path to a dated, frozen results directory
#'
#' A re-run writes a new directory. It does not overwrite an old one. See
#' CONVENTIONS.md for why: an overwritten CSV produces a diff that reads as a
#' code change when it was a rerun.
#'
#' @param root Parent directory, default "results".
#' @param date A Date, default today.
#' @return The directory path, created if needed.
results_dir <- function(root = "results", date = Sys.Date()) {
  path <- file.path(root, paste0("results-", format(date, "%Y-%m-%d")))
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

#' Refuse to overwrite an existing output file
#'
#' @param path Intended output path.
#' @return `path`, invisibly, if it does not exist.
freeze <- function(path) {
  if (file.exists(path)) {
    stop(sprintf(
      "%s exists and frozen results are never overwritten. Write to a new results-YYYY-MM-DD directory.",
      path
    ), call. = FALSE)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

#' Require that a data frame has the expected columns before using it
#'
#' Fails on the first missing column with all of them named, rather than
#' surfacing as a mystery NA twenty lines later.
#'
#' @param df A data frame.
#' @param cols Character vector of required column names.
require_columns <- function(df, cols) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0) {
    stop(sprintf("missing required columns: %s", paste(missing, collapse = ", ")), call. = FALSE)
  }
  invisible(TRUE)
}
