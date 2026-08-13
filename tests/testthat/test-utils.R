# Mutation-check anything you add here: break the function on purpose, confirm
# the test fails, restore, then commit. See CONVENTIONS.md#tests.
#
# Uses only testthat and base R on purpose - a test suite with a long dependency
# list is a test suite that stops running.

# tempfile() returns a fresh path each call, and R removes tempdir() on exit.
new_tempdir <- function() {
  path <- tempfile("t")
  dir.create(path, recursive = TRUE)
  path
}

test_that("results_dir is dated and created", {
  root <- new_tempdir()
  out <- results_dir(root, as.Date("2026-08-13"))
  expect_true(dir.exists(out))
  expect_equal(basename(out), "results-2026-08-13")
})

test_that("results_dir defaults to today", {
  root <- new_tempdir()
  out <- results_dir(root)
  expect_equal(basename(out), paste0("results-", format(Sys.Date(), "%Y-%m-%d")))
})

test_that("freeze refuses to overwrite an existing file", {
  root <- new_tempdir()
  target <- file.path(root, "metrics.csv")
  writeLines("already,here", target)
  expect_error(freeze(target), "never overwritten")
})

test_that("freeze allows a new path and creates its parent", {
  root <- new_tempdir()
  target <- file.path(root, "results-2026-08-13", "metrics.csv")
  expect_silent(freeze(target))
  expect_true(dir.exists(dirname(target)))
  expect_false(file.exists(target))
})

test_that("require_columns names every missing column at once", {
  df <- data.frame(person_id = 1:2, age = c(40, 50))
  expect_true(require_columns(df, c("person_id", "age")))
  expect_error(require_columns(df, c("person_id", "sex", "bmi")), "sex, bmi")
})
