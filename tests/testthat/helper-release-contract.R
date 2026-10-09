# The release contract lives in data-raw/, which is only available when tests
# run from the source tree (e.g. devtools::test()), not from R CMD check.
rsyc_release_contract_environment <- function() {
  path <- testthat::test_path("..", "..", "data-raw", "release_contract.R")
  if (!file.exists(path)) {
    return(NULL)
  }
  environment <- new.env(parent = baseenv())
  sys.source(path, envir = environment)
  environment
}

skip_if_no_release_contract <- function() {
  testthat::skip_if(
    is.null(rsyc_release_contract_environment()),
    "data-raw/release_contract.R is not available outside the source tree"
  )
}
