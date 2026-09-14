test_that("published model contract satisfies its invariants", {
  expect_s3_class(RSYC_models, "data.frame")
  expect_equal(nrow(RSYC_models), 28391L)
  expect_equal(ncol(RSYC_models), 38L)
  expect_identical(unique(RSYC_models$model_version), "v20260709")
  expect_false(anyDuplicated(RSYC_models$model_id) > 0L)
  expect_true(all(RSYC_models$publish_ok))
  expect_true(all(validUTF8(RSYC_models$strata_id)))
  expect_setequal(RSYC_models$response, c("agb", "volume"))
  expect_setequal(RSYC_models$scale, c("national", "regional"))
  expect_setequal(
    RSYC_models$strata_level,
    c("tile", "tile_region", "ecozone", "ecoprovince", "ecoregion", "ecodistrict")
  )
  expect_true(all(vapply(
    RSYC_models[c("b1", "b2", "b3", "b4")],
    function(x) all(is.finite(x)),
    logical(1)
  )))
})

test_that("repaired accented strata have stable unique IDs", {
  id <- paste0(
    "rsyc_agb_national_ecodistrict_abie_bal_",
    "boreal_shield_east_eastern_boreal_shield_central_laurentians_",
    "lac_peribonka_hills"
  )
  expect_true(id %in% RSYC_models$model_id)
  expect_true(any(grepl("Peribonka", iconv(RSYC_models$strata_id, to = "ASCII//TRANSLIT"))))
})
