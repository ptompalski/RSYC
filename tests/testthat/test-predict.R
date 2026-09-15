test_that("prediction has the requested public signature", {
  expect_identical(
    names(formals(predict_rsyc)),
    c("response", "species", "age", "strata_level", "strata_id")
  )
})

test_that("AGB and volume predictions exactly apply national coefficients", {
  for (response in c("agb", "volume")) {
    model <- RSYC_models[
      RSYC_models$response == response & RSYC_models$strata_level == "tile" &
        RSYC_models$strata_id == "H14" & RSYC_models$scale == "national" &
        RSYC_models$species == "PICE.MAR",
      , drop = FALSE
    ]
    age <- c(10, 100, 150)
    expected <- with(model, b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3)
    actual <- predict_rsyc(response, "PICE.MAR", age, "tile", "H14")
    expect_equal(actual, expected)
  }
})

test_that("all public strata levels select national models", {
  for (level in c("tile", "ecozone", "ecoprovince", "ecoregion", "ecodistrict")) {
    model <- RSYC_models[
      RSYC_models$strata_level == level & RSYC_models$scale == "national",
      , drop = FALSE
    ][1L, , drop = FALSE]
    expected <- unname(with(model, b1 * exp(-b4 * 75) * (1 - exp(-b2 * 75))^b3))
    actual <- predict_rsyc(model$response, model$species, 75, level, model$strata_id)
    expect_equal(actual, expected)
  }
})

test_that("unique short ecosystem names resolve to hierarchical paths", {
  path <- "Atlantic Maritime/Fundy Uplands/Annapolis-Minas Lowlands/Windsor Lowlands"
  expect_equal(
    predict_rsyc("agb", "PICE.MAR", 80, "ecodistrict", "Windsor Lowlands"),
    predict_rsyc("agb", "PICE.MAR", 80, "ecodistrict", path)
  )
})

test_that("ambiguous short ecosystem names list hierarchical solutions", {
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 80, "ecodistrict", "Muskwa"),
    paste0(
      "ambiguous.*",
      "Boreal Cordillera/Hay-Slave Lowlands/Muskwa Plateau/Muskwa.*",
      "Taiga Plains/Hay-Slave Lowlands/Muskwa Plateau/Muskwa.*",
      "full hierarchical paths"
    )
  )
})

test_that("species matching is case-insensitive", {
  expect_equal(
    predict_rsyc("agb", "Coniferous", 50, "tile", "H14"),
    predict_rsyc("agb", "coniferous", 50, "tile", "H14")
  )
  expect_equal(
    predict_rsyc("agb", "pice.mar", 50, "tile", "H14"),
    predict_rsyc("agb", "PICE.MAR", 50, "tile", "H14")
  )
})

test_that("invalid inputs and extrapolation are reported", {
  expect_no_warning(
    predict_rsyc("agb", "PICE.MAR", c(0, 1, 150), "tile", "H14")
  )
  expect_warning(
    predict_rsyc("agb", "PICE.MAR", 151, "tile", "H14"),
    "published calibration range \\(1-150 years\\)"
  )
  expect_error(predict_rsyc("agb", "PICE.MAR", -1, "tile", "H14"), "negative")
  expect_error(predict_rsyc("agb", "PICE.MAR", character(), "tile", "H14"), "non-empty numeric")
  expect_error(predict_rsyc("agb", "PICE.MAR", Inf, "tile", "H14"), "finite")
  expect_error(predict_rsyc("agb", "PICE.MAR", NA_real_, "tile", "H14"), "finite")
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 20, "tile", "NOT_A_TILE"),
    "No national RSYC model"
  )
})

test_that("scalar prediction arguments are validated", {
  expect_error(predict_rsyc(character(), "PICE.MAR", 20, "tile", "H14"), "one non-empty")
  expect_error(predict_rsyc("height", "PICE.MAR", 20, "tile", "H14"), "must be one of")
  expect_error(predict_rsyc("agb", c("PICE.MAR", "POPU.TRE"), 20, "tile", "H14"), "one non-empty")
  expect_error(predict_rsyc("agb", "PICE.MAR", 20, "tile", NA_character_), "one non-empty")
})

test_that("duplicate model rows are rejected", {
  original <- RSYC_models
  models <- rbind(original, original[1L, , drop = FALSE])
  models[nrow(models), ] <- original[
    original$response == "agb" & original$species == "PICE.MAR" &
      original$strata_level == "tile" & original$strata_id == "H14" &
      original$scale == "national",
    , drop = FALSE
  ][1L, ]
  testthat::local_mocked_bindings(
    .rsyc_model_catalog = function() models,
    .package = "RSYC"
  )

  expect_error(
    predict_rsyc("agb", "PICE.MAR", 20, "tile", "H14"),
    "Multiple national RSYC models"
  )
})

test_that("regional scale is not exposed by prediction", {
  expect_error(
    predict_rsyc("agb", "PICE.MAR", 20, "tile", "H14", scale = "regional"),
    "unused argument"
  )
})

test_that("documented tibble application patterns work", {
  inputs <- tibble::tribble(
    ~response, ~species,     ~age, ~strata_level, ~strata_id,
    "agb",     "PICE.MAR",    20, "tile",        "H14",
    "volume",  "POPU.TRE",    60, "tile",        "F31",
    "agb",     "coniferous", 120, "tile",        "N3"
  ) |>
    dplyr::mutate(
      prediction = purrr::pmap_dbl(
        list(response, species, age, strata_level, strata_id),
        predict_rsyc
      )
    )
  expect_length(inputs$prediction, nrow(inputs))
  expect_true(all(is.finite(inputs$prediction)))

  inputs <- inputs |>
    dplyr::select(-prediction) |>
    dplyr::mutate(
      age = list(1:20),
      prediction = purrr::pmap(
        list(response, species, age, strata_level, strata_id),
        predict_rsyc
      )
    )
  expect_true(all(lengths(inputs$prediction) == 20L))
})
