model_contract_environment <- new.env(parent = baseenv())
sys.source(
  testthat::test_path("..", "..", "data-raw", "release_contract.R"),
  envir = model_contract_environment
)
model_contract <- model_contract_environment$.rsyc_release_contract

test_that("published model contract satisfies its invariants", {
  expect_s3_class(RSYC_models, "data.frame")
  expect_equal(nrow(RSYC_models), model_contract$model$rows)
  expect_equal(ncol(RSYC_models), model_contract$model$columns)
  expect_identical(names(RSYC_models), names(model_contract$model$column_types))
  expect_identical(
    vapply(RSYC_models, typeof, character(1)),
    model_contract$model$column_types
  )
  expect_identical(unique(RSYC_models$model_version), model_contract$model_version)
  expect_false(anyDuplicated(RSYC_models$model_id) > 0L)

  lookup <- RSYC_models[c(
    "response", "strata_level", "strata_id", "scale", "region_id", "species"
  )]
  lookup$region_id[is.na(lookup$region_id)] <- "<NA>"
  expect_false(anyDuplicated(lookup) > 0L)

  expect_true(all(RSYC_models$publish_ok))
  character_fields <- vapply(RSYC_models, is.character, logical(1))
  expect_true(all(vapply(
    RSYC_models[character_fields],
    function(x) all(validUTF8(x)),
    logical(1)
  )))
  expect_setequal(RSYC_models$response, c("agb", "volume"))
  expect_true(all(RSYC_models$response_units[RSYC_models$response == "agb"] == "Mg/ha"))
  expect_true(all(RSYC_models$response_units[RSYC_models$response == "volume"] == "m3/ha"))
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
  expect_identical(
    unique(RSYC_models$equation),
    "b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3"
  )

  national <- RSYC_models$scale == "national"
  expect_true(all(vapply(
    RSYC_models[national, c("local_b1_var", "residual_var")],
    function(x) all(is.finite(x) & x > 0),
    logical(1)
  )))
})

test_that("upstream model IDs and UTF-8 strata are preserved", {
  id <- paste0(
    "rsyc_agb_national_ecodistrict_abie_bal_",
    "boreal_shield_east_eastern_boreal_shield_central_laurentians_",
    "lac_peribonka_hills"
  )
  expect_true(id %in% RSYC_models$model_id)
  expect_true(any(grepl("Peribonka", iconv(RSYC_models$strata_id, to = "ASCII//TRANSLIT"))))
})

test_that("documented ecozone IDs retain one-to-many name mappings", {
  mapping <- unique(RSYC_models[
    RSYC_models$strata_level == "ecozone",
    c("ecozone_id", "strata_id")
  ])
  mapping <- mapping[order(mapping$ecozone_id, mapping$strata_id), , drop = FALSE]
  ambiguous <- split(mapping$strata_id, mapping$ecozone_id)
  ambiguous <- ambiguous[lengths(ambiguous) > 1L]

  expect_identical(
    ambiguous,
    list(
      `5` = c("Taiga Shield East", "Taiga Shield West"),
      `6` = c("Boreal Shield East", "Boreal Shield West")
    )
  )
})

test_that("ecological models are limited to forested ecozones", {
  ecological <- RSYC_models$strata_level %in%
    c("ecozone", "ecoprovince", "ecoregion", "ecodistrict")
  model_ecozones <- sub("/.*$", "", RSYC_models$strata_id[ecological])

  expect_setequal(model_ecozones, model_contract$forest_filter$ecozones)
})
