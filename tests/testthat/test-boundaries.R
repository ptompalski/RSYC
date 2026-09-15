test_that("tile boundaries contain only the common join key and geometry", {
  skip_if_not_installed("sf")
  tiles <- rsyc_boundaries("tile")

  expect_s3_class(tiles, "sf")
  expect_equal(nrow(tiles), 389L)
  expect_identical(
    names(tiles),
    c("strata_id", "geometry")
  )
  expect_true("H14" %in% tiles$strata_id)
  expect_equal(sf::st_crs(tiles)$epsg, 3978L)
})

test_that("ecological boundary cache paths are private and versioned", {
  cache <- file.path(tempdir(), "rsyc-empty-cache")
  expected <- file.path(cache, "RSYC_ecostrat.gpkg")
  path <- getFromNamespace(".rsyc_ecostrat_path", "RSYC")

  expect_identical(path(cache_dir = cache, must_exist = FALSE), expected)
  expect_error(path(cache_dir = cache), "download_rsyc_boundaries")
  expect_error(path(cache_dir = cache, must_exist = NA), "must be `TRUE` or `FALSE`")
  expect_error(
    download_rsyc_boundaries(cache_dir = cache, overwrite = NA),
    "`overwrite` must be `TRUE` or `FALSE`"
  )
})

test_that("boundary download uses and refreshes a verified cache", {
  source <- tempfile(fileext = ".gpkg")
  writeBin(charToRaw("deterministic boundary fixture"), source)
  expected <- digest::digest(source, "sha256", file = TRUE)
  url <- paste0("file:///", normalizePath(source, winslash = "/"))
  cache <- tempfile("rsyc-download-cache-")
  testthat::local_mocked_bindings(
    .rsyc_ecostrat_sha256 = expected,
    .package = "RSYC"
  )

  expect_message(
    first <- download_rsyc_boundaries(cache, quiet = FALSE, url = url),
    "Cached RSYC ecological stratification"
  )
  expect_true(file.exists(first))
  expect_invisible(download_rsyc_boundaries(cache, url = url))

  writeBin(charToRaw("stale"), first)
  expect_invisible(download_rsyc_boundaries(cache, overwrite = TRUE, quiet = TRUE, url = url))
  expect_identical(digest::digest(first, "sha256", file = TRUE), expected)
})

test_that("boundary download failures are informative", {
  blocker <- tempfile()
  writeLines("file blocks directory creation", blocker)
  expect_error(
    download_rsyc_boundaries(file.path(blocker, "child"), quiet = TRUE),
    "Could not create"
  )

  cache <- tempfile("rsyc-failed-download-")
  bad_url <- paste0("file:///", normalizePath(tempfile(), winslash = "/", mustWork = FALSE))
  expect_error(
    suppressWarnings(download_rsyc_boundaries(cache, quiet = TRUE, url = bad_url)),
    "Could not download"
  )

  status_cache <- tempfile("rsyc-status-failure-")
  testthat::local_mocked_bindings(
    download.file = function(...) 1L,
    .package = "utils"
  )
  expect_error(
    download_rsyc_boundaries(status_cache, quiet = TRUE, url = "unused"),
    "did not complete"
  )
})

test_that("boundary download reports a cache move failure", {
  source <- tempfile(fileext = ".gpkg")
  writeBin(charToRaw("download fixture"), source)
  url <- paste0("file:///", normalizePath(source, winslash = "/"))
  cache <- tempfile("rsyc-move-failure-")
  destination <- file.path(cache, "RSYC_ecostrat.gpkg")
  testthat::local_mocked_bindings(
    .rsyc_verify_ecostrat = function(path, ...) {
      dir.create(destination)
      writeLines("block replacement", file.path(destination, "child"))
      invisible(path)
    },
    .package = "RSYC"
  )
  expect_error(
    suppressWarnings(download_rsyc_boundaries(cache, quiet = TRUE, url = url)),
    "Could not move"
  )
})

test_that("checksum verification rejects altered files", {
  file <- tempfile()
  writeBin(charToRaw("not the published GeoPackage"), file)
  verify <- getFromNamespace(".rsyc_verify_ecostrat", "RSYC")

  expect_invisible(verify(file, digest::digest(file, "sha256", file = TRUE)))
  expect_error(verify(file, paste(rep("0", 64), collapse = "")), "failed checksum")
})

test_that("boundary helpers validate arguments", {
  path <- getFromNamespace(".rsyc_ecostrat_path", "RSYC")
  expect_error(path(NA_character_, FALSE), "one non-empty")
  expect_error(rsyc_boundaries("tile", quiet = NA), "TRUE.*FALSE")
  expect_error(rsyc_boundaries("not-a-level"), "must be one of")
})

test_that("missing optional dependencies and bundled data are reported", {
  testthat::local_mocked_bindings(
    .rsyc_require_namespace = function(package) FALSE,
    .package = "RSYC"
  )
  expect_error(rsyc_boundaries("tile"), "Package `sf` is required")

  file <- tempfile()
  writeLines("content", file)
  verify <- getFromNamespace(".rsyc_verify_ecostrat", "RSYC")
  expect_error(verify(file), "Package `digest` is required")
})

test_that("a missing bundled tile file is reported", {
  testthat::local_mocked_bindings(
    .rsyc_tile_boundaries_path = function() "",
    .package = "RSYC"
  )
  expect_error(rsyc_boundaries("tile"), "could not be found")
})

test_that("ecological levels retain only their relevant hierarchy", {
  skip_if_not_installed("sf")
  cache <- tempfile("rsyc-ecostrat-cache-")
  dir.create(cache)
  path_fun <- getFromNamespace(".rsyc_ecostrat_path", "RSYC")
  path <- path_fun(cache_dir = cache, must_exist = FALSE)
  x <- sf::st_sf(
    parameter_level = "ecozone",
    ecozone = "Boreal Shield",
    ecoprovince = NA_character_,
    ecoregion = NA_character_,
    ecodistrict = NA_character_,
    join_key = "Boreal Shield",
    geom = sf::st_sfc(sf::st_point(c(0, 0)), crs = 3978)
  )
  sf::st_write(x, path, layer = "ecozones", quiet = TRUE)
  checksum <- digest::digest(path, "sha256", file = TRUE)
  testthat::local_mocked_bindings(
    .rsyc_ecostrat_sha256 = checksum,
    .package = "RSYC"
  )

  result <- rsyc_boundaries("ecozone", cache_dir = cache)
  expect_s3_class(result, "sf")
  expect_identical(result$strata_id, "Boreal Shield")
  expect_named(result, c("strata_id", "ecozone", "geometry"))
})
