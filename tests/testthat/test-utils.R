test_that("package load hooks run without side effects", {
  force_runtime <- getFromNamespace(".rsyc_force_boundary_runtime", "RSYC")
  on_load <- getFromNamespace(".onLoad", "RSYC")
  expect_null(force_runtime())
  expect_null(on_load(libname = "", pkgname = "RSYC"))
})

test_that("strata code fields exist only for ecological levels", {
  code_field <- getFromNamespace(".rsyc_strata_code_field", "RSYC")
  expect_identical(code_field("ecoregion"), "ecoregion_id")
  expect_null(code_field("tile"))
})

test_that("single-selection strata validation rejects bad identifiers", {
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 50, "tile", c("H14", "F31")),
    "exactly one value"
  )
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 50, "ecoregion", Inf),
    "only finite values"
  )
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 50, "tile", factor("H14")),
    "one non-missing numeric code"
  )
})

test_that("numeric-looking character tile IDs are rejected as codes", {
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 50, "tile", "198"),
    "Ecological codes cannot be used for `strata_level = \"tile\"`"
  )
})

test_that("strata code normalization guards invalid input", {
  normalize <- getFromNamespace(".rsyc_normalize_strata_code", "RSYC")
  expect_error(normalize("1", "tile"), "character tile ID")
  expect_error(normalize("not-a-code", "ecoregion"), "not a valid ecological code")
  expect_error(normalize(1.5, "ecoregion"), "must be integers")
  expect_identical(normalize("198.0", "ecoregion"), "198")
  expect_identical(normalize(6.1, "ecoprovince"), "6.1")
  expect_identical(normalize("6.1", "ecoprovince"), "6.1")
})

test_that("single selection reports codes shared by several areas", {
  resolve <- getFromNamespace(".rsyc_resolve_strata", "RSYC")
  models <- data.frame(
    strata_id = c("Zone A/Province/Region X", "Zone B/Province/Region Y"),
    ecoregion_id = c(999L, 999L)
  )
  expect_error(
    resolve(models, 999, "ecoregion", mode = "single"),
    "The ecoregion code '999' is ambiguous.\nMatching names:\n  - Region X\n  - Region Y",
    fixed = TRUE
  )
  expect_setequal(
    resolve(models, 999, "ecoregion", mode = "catalog"),
    models$strata_id
  )
})
