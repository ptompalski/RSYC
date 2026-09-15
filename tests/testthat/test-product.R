test_that("a tile product contains normalized spatial and curve components", {
  skip_if_not_installed("sf")
  product <- rsyc_product(
    response = "agb",
    species = c("PICE.MAR", "POPU.TRE"),
    age = c(50, 100),
    strata_level = "tile",
    strata_id = "H14"
  )

  expect_type(product, "list")
  expect_identical(names(product), c("spatial", "curves", "metadata"))
  expect_s3_class(product$spatial, "sf")
  expect_equal(nrow(product$spatial), 1L)
  expect_identical(product$spatial$strata_id, "H14")
  expect_equal(nrow(product$curves), 4L)
  expect_identical(
    names(product$curves),
    c("model_id", "strata_id", "species", "age", "prediction")
  )
  expect_setequal(product$curves$species, c("PICE.MAR", "POPU.TRE"))
  expect_setequal(product$curves$age, c(50, 100))
  expect_equal(
    product$curves$prediction[product$curves$species == "PICE.MAR"],
    predict_rsyc("agb", "PICE.MAR", c(50, 100), "tile", "H14")
  )
  expect_equal(product$metadata$n_models, 2L)
  expect_equal(product$metadata$n_strata, 1L)
  expect_true("model_version" %in% names(product$metadata))
  expect_false("model_version" %in% names(product$curves))
})

test_that("product defaults to ages 1 through 150", {
  skip_if_not_installed("sf")
  product <- rsyc_product("agb", "PICE.MAR", strata_id = "H14")
  expect_identical(range(product$curves$age), c(1L, 150L))
  expect_equal(nrow(product$curves), 150L)
})

test_that("product warns outside the published calibration range", {
  skip_if_not_installed("sf")
  expect_no_warning(
    rsyc_product("agb", "PICE.MAR", c(0, 1, 150), strata_id = "H14")
  )
  expect_warning(
    rsyc_product("agb", "PICE.MAR", 151, strata_id = "H14"),
    "published calibration range \\(1-150 years\\)"
  )
})

test_that("product strata selection reports unavailable and ambiguous names", {
  expect_error(
    rsyc_product("agb", "PICE.MAR", 50, "tile", "not-a-tile"),
    "No requested tile model"
  )
  expect_error(
    rsyc_product("agb", "PICE.MAR", 50, "ecodistrict", "Muskwa"),
    "Matching hierarchical paths"
  )
})

test_that("product validation and empty selections are reported", {
  expect_error(rsyc_product("agb", character(), 50), "non-empty")
  expect_error(rsyc_product("agb", "PICE.MAR", numeric()), "non-empty numeric")
  expect_error(rsyc_product("agb", "PICE.MAR", 50, strata_id = character()), "non-empty")
  expect_error(rsyc_product("agb", "NOT.A.SPECIES", 50), "No national RSYC models")
  expect_error(rsyc_product("agb", "PICE.MAR", 50, overwrite = NA), "TRUE.*FALSE")
  expect_error(rsyc_product("agb", "PICE.MAR", 50, quiet = NA), "TRUE.*FALSE")
})

test_that("product strata resolver accepts full paths and removes duplicates", {
  resolve <- getFromNamespace(".rsyc_resolve_product_strata", "RSYC")
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

test_that("product reports model strata without boundary geometry", {
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
    rsyc_product("agb", "PICE.MAR", 50, "tile", "H14"),
    "No boundary geometry was found"
  )
})

test_that("products can be written as normalized GeoPackages", {
  skip_if_not_installed("sf")
  output <- tempfile(fileext = ".gpkg")
  product <- rsyc_product(
    "volume", "PICE.MAR", c(50, 100), "tile", "H14",
    output = output
  )

  layers <- sf::st_layers(output)
  expect_identical(layers$name, c("spatial", "curves", "metadata"))
  expect_equal(nrow(sf::st_read(output, layer = "spatial", quiet = TRUE)), 1L)
  expect_equal(nrow(sf::st_read(output, layer = "curves", quiet = TRUE)), 2L)
  expect_equal(nrow(sf::st_read(output, layer = "metadata", quiet = TRUE)), 1L)
  expect_error(
    rsyc_product(
      "volume", "PICE.MAR", 50, "tile", "H14", output = output
    ),
    "already exists"
  )
  expect_no_error(
    rsyc_product(
      "volume", "PICE.MAR", 50, "tile", "H14",
      output = output, overwrite = TRUE
    )
  )
  expect_identical(product$metadata$response, "volume")
})

test_that("product output paths are validated", {
  write_product <- getFromNamespace(".rsyc_write_product", "RSYC")
  product <- list()
  expect_error(write_product(product, NA_character_, FALSE, TRUE), "one non-empty")
  expect_error(write_product(product, tempfile(fileext = ".txt"), FALSE, TRUE), "gpkg")
  missing_parent <- file.path(tempfile(), "product.gpkg")
  expect_error(write_product(product, missing_parent, FALSE, TRUE), "parent directory")
})
