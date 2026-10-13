# The ecological GeoPackage is excluded from the CRAN tarball (size limit) and
# is only present when testing from the source repository.
skip_if_no_bundled_ecostrat <- function() {
  path <- system.file("extdata", "RSYC_ecostrat.gpkg", package = "RSYC")
  if (!nzchar(path)) {
    testthat::skip("RSYC_ecostrat.gpkg is not bundled in this build.")
  }
  path
}
