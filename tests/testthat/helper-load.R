# Sourced automatically by testthat::test_dir() before any test file runs.
# Loads R/ without requiring the project to be an installed package, and without
# depending on the working directory testthat happens to choose.

find_dir_upwards <- function(name, start = getwd()) {
  dir <- normalizePath(start, mustWork = TRUE)
  repeat {
    candidate <- file.path(dir, name)
    if (dir.exists(candidate)) {
      return(candidate)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      stop(sprintf("could not find %s/ at or above %s", name, start), call. = FALSE)
    }
    dir <- parent
  }
}

for (f in list.files(find_dir_upwards("R"), pattern = "[.][Rr]$", full.names = TRUE)) {
  source(f)
}
