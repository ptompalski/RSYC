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
  expect_true("strata_code" %in% names(models))
  expect_true(all(is.na(models$strata_code)))
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
  expect_identical(
    names(strata),
    c("strata_level", "strata_name", "strata_id", "strata_code")
  )
})

test_that("internal catalog exposes the complete published model dataset", {
  catalog <- getFromNamespace(".rsyc_model_catalog", "RSYC")()

  expect_identical(catalog, RSYC_models)
  expect_true(all(catalog$publish_ok %in% TRUE))
  expect_false(anyDuplicated(catalog$model_id) > 0L)
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

test_that("species codes include broad model groups", {
  expect_true(all(c("SpeciesCode", "SpeciesName") %in% names(species_codes())))
  expect_identical(species_codes()$SpeciesCode[1:3], c("generic", "coniferous", "broadleaf"))
})

test_that("scale is not exposed by discovery helpers", {
  expect_error(available_rsyc_models(scale = "regional"), "unused argument")
  expect_error(rsyc_species(scale = "regional"), "unused argument")
  expect_error(rsyc_strata(scale = "regional"), "unused argument")
})

test_that("unavailable discovery combinations are empty and reported", {
  expect_warning(
    empty <- available_rsyc_models(strata_id = "NOT_A_STRATUM"),
    "No published national RSYC model matches `strata_id` value\\(s\\): 'NOT_A_STRATUM'"
  )
  expect_equal(nrow(empty), 0L)
  expect_warning(
    empty <- rsyc_species(strata_level = "tile", strata_id = "NOT_A_TILE"),
    "'NOT_A_TILE'"
  )
  expect_equal(nrow(empty), 0L)
  expect_warning(
    empty <- rsyc_strata(species = "NOT.A.SPECIES", strata_level = "tile"),
    "Unknown species code\\(s\\): 'NOT.A.SPECIES'"
  )
  expect_equal(nrow(empty), 0L)
})

test_that("discovery warns only about unmatched strata values", {
  expect_warning(
    found <- available_rsyc_models(
      "agb", "PICE.MAR", "tile", c("H14", "NOT_A_TILE")
    ),
    "'NOT_A_TILE'"
  )
  expect_identical(unique(found$strata_id), "H14")
  expect_no_warning(available_rsyc_models("agb", "PICE.MAR", "tile", "H14"))
  expect_no_warning(available_rsyc_models(species = "pice.mar"))
})

test_that("catalog strata names, paths, and tile IDs ignore case", {
  path <- "Atlantic Maritime/Fundy Uplands/Annapolis-Minas Lowlands/Windsor Lowlands"
  expected <- available_rsyc_models("agb", "PICE.MAR", "ecodistrict", path)
  expect_identical(
    available_rsyc_models("agb", "PICE.MAR", "ecodistrict", "windsor LOWLANDS"),
    expected
  )
  expect_identical(
    available_rsyc_models("agb", "PICE.MAR", "ecodistrict", toupper(path)),
    expected
  )
  expect_identical(
    available_rsyc_models("agb", "PICE.MAR", "tile", "h14"),
    available_rsyc_models("agb", "PICE.MAR", "tile", "H14")
  )
})

test_that("catalog filters validate vector inputs", {
  expect_error(available_rsyc_models(strata_id = NA_character_), "non-empty")
  expect_error(available_rsyc_models(response = character()), "non-empty")
  expect_error(available_rsyc_models(response = "height"), "contain only")
  expect_error(available_rsyc_models(species = 1), "non-empty")

  models <- available_rsyc_models(response = c("AGB", "agb"))
  expect_true(nrow(models) > 0L)
  expect_true(all(models$response == "agb"))
})

test_that("internal species normalization rejects non-character vectors", {
  normalize <- getFromNamespace(".rsyc_normalize_species", "RSYC")
  expect_error(normalize(1, scalar = FALSE), "must be character")
})

test_that("catalog filters accept ecological codes", {
  province <- RSYC_models[
    RSYC_models$scale == "national" & RSYC_models$response == "agb" &
      RSYC_models$species == "PICE.MAR" &
      RSYC_models$strata_level == "ecoprovince",
    , drop = FALSE
  ][1L, ]
  quoted <- available_rsyc_models(
    "agb", "PICE.MAR", "ecoprovince", as.character(province$ecoprovince_id)
  )
  numeric <- available_rsyc_models(
    "agb", "PICE.MAR", "ecoprovince", as.numeric(province$ecoprovince_id)
  )
  expect_identical(quoted, numeric)
  expect_true(all(quoted$strata_code == province$ecoprovince_id))
  expect_identical(
    rsyc_species(
      "agb", "ecoprovince", as.numeric(province$ecoprovince_id)
    ),
    rsyc_species("agb", "ecoprovince", province$strata_id)
  )

  for (code in c(5, 6)) {
    found <- available_rsyc_models("agb", "PICE.MAR", "ecozone", code)
    expect_identical(unique(found$strata_code), as.character(code))
    expect_length(unique(found$strata_id), 2L)
    expect_identical(unique(found$strata_id), sort(unique(found$strata_id)))
  }
})

test_that("catalog code filters require one ecological level", {
  expect_error(available_rsyc_models(strata_id = 198), "exactly one ecological")
  expect_error(
    available_rsyc_models(
      strata_level = c("ecoregion", "ecodistrict"), strata_id = "198"
    ),
    "exactly one ecological"
  )
  expect_error(
    available_rsyc_models(strata_level = "tile", strata_id = 198),
    "character tile ID"
  )
  expect_error(
    available_rsyc_models(strata_level = "ecoregion", strata_id = 999999),
    "No ecoregion uses"
  )
  expect_error(
    available_rsyc_models(strata_level = "ecozone", strata_id = 10),
    "no published national RSYC model"
  )
})

test_that("numeric code support does not add public arguments", {
  expect_identical(
    names(formals(available_rsyc_models)),
    c("response", "species", "strata_level", "strata_id")
  )
  expect_identical(
    names(formals(rsyc_species)),
    c("response", "strata_level", "strata_id")
  )
  expect_identical(
    names(formals(rsyc_strata)),
    c("response", "species", "strata_level")
  )
  expect_false("strata_code" %in% names(formals(build_rsyc_dataset)))
  expect_false("strata_code" %in% names(formals(calibrate_rsyc)))
})
