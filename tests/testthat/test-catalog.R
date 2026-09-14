test_that("model catalog filters national models", {
  models <- available_rsyc_models(
    response = "volume",
    species = "pice.mar",
    strata_level = "tile"
  )
  expect_gt(nrow(models), 0L)
  expect_true(all(models$response == "volume"))
  expect_true(all(models$species == "PICE.MAR"))
  expect_true(all(models$strata_level == "tile"))
  expect_false("scale" %in% names(models))
  expect_true(all(grepl("_national_", models$model_id, fixed = TRUE)))
  expect_true("strata_name" %in% names(models))
  expect_false(any(c("equation", "age_min", "age_max", "n_obs", "n_units") %in% names(models)))
  expect_identical(tail(names(models), 1L), "model_version")
})

test_that("species and strata discovery helpers reflect model availability", {
  species <- rsyc_species(
    response = "agb", strata_level = "tile", strata_id = "H14"
  )
  expect_true(all(c("species", "species_name", "model_group") %in% names(species)))
  expect_true("PICE.MAR" %in% species$species)

  strata <- rsyc_strata(
    response = "volume", species = "PICE.MAR", strata_level = "ecozone"
  )
  expect_true(all(strata$strata_level == "ecozone"))
  expect_true("Boreal Shield East" %in% strata$strata_name)
  expect_true(all(c("strata_level", "strata_name", "strata_id") %in% names(strata)))
})

test_that("catalog filters accept short or hierarchical stratum IDs", {
  path <- "Atlantic Maritime/Fundy Uplands/Annapolis-Minas Lowlands/Windsor Lowlands"
  short <- available_rsyc_models(
    response = "agb", species = "PICE.MAR", strata_level = "ecodistrict",
    strata_id = "Windsor Lowlands"
  )
  full <- available_rsyc_models(
    response = "agb", species = "PICE.MAR", strata_level = "ecodistrict",
    strata_id = path
  )
  expect_identical(short, full)
  expect_identical(short$strata_name, "Windsor Lowlands")
})

test_that("tile discovery helpers retain national AGB defaults", {
  expect_true("PICE.MAR" %in% species_in_tile("H14"))
  expect_true("H14" %in% tiles_for_species("PICE.MAR"))
  expect_true(all(c("SpeciesCode", "SpeciesName") %in% names(species_codes())))
  expect_identical(species_codes()$SpeciesCode[1:3], c("generic", "coniferous", "broadleaf"))
})

test_that("scale is not exposed by discovery helpers", {
  expect_error(available_rsyc_models(scale = "regional"), "unused argument")
  expect_error(rsyc_species(scale = "regional"), "unused argument")
  expect_error(rsyc_strata(scale = "regional"), "unused argument")
  expect_error(species_in_tile("H14", scale = "regional"), "unused argument")
  expect_error(tiles_for_species("PICE.MAR", scale = "regional"), "unused argument")
})

test_that("unavailable discovery combinations are empty or warn", {
  expect_equal(nrow(available_rsyc_models(strata_id = "NOT_A_STRATUM")), 0L)
  expect_warning(species_in_tile("NOT_A_TILE"), "No species")
  expect_warning(tiles_for_species("NOT.A.SPECIES"), "No tiles")
})
