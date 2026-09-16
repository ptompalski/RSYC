test_that("a tile dataset contains normalized spatial and curve components", {
  skip_if_not_installed("sf")
  dataset <- build_rsyc_dataset(
    response = "agb",
    species = c("PICE.MAR", "POPU.TRE"),
    age = c(50, 100),
    strata_level = "tile",
    strata_id = "H14"
  )

  expect_type(dataset, "list")
  expect_identical(names(dataset), c("spatial", "curves", "metadata"))
  expect_s3_class(dataset$spatial, "sf")
  expect_equal(nrow(dataset$spatial), 1L)
  expect_identical(dataset$spatial$strata_id, "H14")
  expect_equal(nrow(dataset$curves), 4L)
  expect_identical(
    names(dataset$curves),
    c("model_id", "strata_id", "species", "age", "prediction")
  )
  expect_setequal(dataset$curves$species, c("PICE.MAR", "POPU.TRE"))
  expect_setequal(dataset$curves$age, c(50, 100))
  expect_equal(
    dataset$curves$prediction[dataset$curves$species == "PICE.MAR"],
    predict_rsyc("agb", "PICE.MAR", c(50, 100), "tile", "H14")
  )
  expect_equal(dataset$metadata$n_models, 2L)
  expect_equal(dataset$metadata$n_strata, 1L)
  expect_true("model_version" %in% names(dataset$metadata))
  expect_false("model_version" %in% names(dataset$curves))
})

test_that("dataset defaults to ages 1 through 150", {
  skip_if_not_installed("sf")
  dataset <- build_rsyc_dataset("agb", "PICE.MAR", strata_id = "H14")
  expect_identical(range(dataset$curves$age), c(1L, 150L))
  expect_equal(nrow(dataset$curves), 150L)
})

test_that("dataset warns outside the published calibration range", {
  skip_if_not_installed("sf")
  expect_no_warning(
    build_rsyc_dataset("agb", "PICE.MAR", c(0, 1, 150), strata_id = "H14")
  )
  expect_warning(
    build_rsyc_dataset("agb", "PICE.MAR", 151, strata_id = "H14"),
    "published calibration range \\(1-150 years\\)"
  )
})

test_that("dataset strata selection reports unavailable and ambiguous names", {
  expect_error(
    build_rsyc_dataset("agb", "PICE.MAR", 50, "tile", "not-a-tile"),
    "No requested tile model"
  )
  expect_error(
    build_rsyc_dataset("agb", "PICE.MAR", 50, "ecodistrict", "Muskwa"),
    "Matching hierarchical paths"
  )
})

test_that("dataset validation and empty selections are reported", {
  expect_error(build_rsyc_dataset("agb", character(), 50), "non-empty")
  expect_error(build_rsyc_dataset("agb", "PICE.MAR", numeric()), "non-empty numeric")
  expect_error(build_rsyc_dataset("agb", "PICE.MAR", 50, strata_id = character()), "non-empty")
  expect_error(build_rsyc_dataset("agb", "NOT.A.SPECIES", 50), "No national RSYC models")
  expect_error(build_rsyc_dataset("agb", "PICE.MAR", 50, overwrite = NA), "TRUE.*FALSE")
  expect_error(build_rsyc_dataset("agb", "PICE.MAR", 50, quiet = NA), "TRUE.*FALSE")
})

test_that("dataset strata resolver accepts full paths and removes duplicates", {
  resolve <- getFromNamespace(".rsyc_resolve_dataset_strata", "RSYC")
  models <- RSYC_models[
    RSYC_models$response == "agb" & RSYC_models$species == "PICE.MAR" &
      RSYC_models$strata_level == "ecodistrict" & RSYC_models$scale == "national",
    , drop = FALSE
  ]
  path <- models$strata_id[[1L]]
  expect_identical(resolve(models, c(path, path), "ecodistrict"), path)

  names <- sub("^.*/", "", models$strata_id)
  unique_name <- names[!duplicated(names) & !duplicated(names, fromLast = TRUE)][[1L]]
  expected <- models$strata_id[names == unique_name]
  expect_identical(resolve(models, unique_name, "ecodistrict"), expected)
})

test_that("dataset reports model strata without boundary geometry", {
  skip_if_not_installed("sf")
  empty <- sf::st_sf(
    strata_id = character(),
    geometry = sf::st_sfc(crs = 3978)
  )
  testthat::local_mocked_bindings(
    rsyc_boundaries = function(...) empty,
    .package = "RSYC"
  )
  expect_error(
    build_rsyc_dataset("agb", "PICE.MAR", 50, "tile", "H14"),
    "No boundary geometry was found"
  )
})

test_that("datasets can be written as normalized GeoPackages", {
  skip_if_not_installed("sf")
  output <- tempfile(fileext = ".gpkg")
  dataset <- build_rsyc_dataset(
    "volume", "PICE.MAR", c(50, 100), "tile", "H14",
    output = output
  )

  layers <- sf::st_layers(output)
  expect_identical(layers$name, c("spatial", "curves", "metadata"))
  expect_equal(nrow(sf::st_read(output, layer = "spatial", quiet = TRUE)), 1L)
  expect_equal(nrow(sf::st_read(output, layer = "curves", quiet = TRUE)), 2L)
  expect_equal(nrow(sf::st_read(output, layer = "metadata", quiet = TRUE)), 1L)
  expect_error(
    build_rsyc_dataset(
      "volume", "PICE.MAR", 50, "tile", "H14", output = output
    ),
    "already exists"
  )
  expect_no_error(
    build_rsyc_dataset(
      "volume", "PICE.MAR", 50, "tile", "H14",
      output = output, overwrite = TRUE
    )
  )
  expect_identical(dataset$metadata$response, "volume")
})

test_that("dataset output paths are validated", {
  write_dataset <- getFromNamespace(".rsyc_write_dataset", "RSYC")
  dataset <- list()
  expect_error(write_dataset(dataset, NA_character_, FALSE, TRUE), "one non-empty")
  expect_error(write_dataset(dataset, tempfile(fileext = ".txt"), FALSE, TRUE), "gpkg")
  missing_parent <- file.path(tempfile(), "dataset.gpkg")
  expect_error(write_dataset(dataset, missing_parent, FALSE, TRUE), "parent directory")
})
