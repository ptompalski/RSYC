test_that("tile boundaries contain only the common join key and geometry", {
  skip_if_not_installed("sf")
  tiles <- rsyc_boundaries("tile")

  expect_s3_class(tiles, "sf")
  expect_equal(nrow(tiles), 385L)
  expect_identical(
    names(tiles),
    c("strata_id", "geometry")
  )
  expect_true("H14" %in% tiles$strata_id)
  expect_false(any(c("D34", "E35", "P1", "R1") %in% tiles$strata_id))
  expect_false(anyDuplicated(tiles$strata_id) > 0L)
  model_tile_ids <- unique(RSYC_models$strata_id[
    RSYC_models$scale == "national" & RSYC_models$strata_level == "tile"
  ])
  expect_setequal(tiles$strata_id, model_tile_ids)
  expect_true(all(sf::st_is_valid(tiles)))
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
    ecozone_id = 6L,
    ecoprovince_id = NA_character_,
    ecoregion_id = NA_integer_,
    ecodistrict_id = NA_integer_,
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
  expect_identical(result$strata_code, "6")
  expect_named(
    result,
    c("strata_id", "strata_code", "ecozone", "ecozone_id", "geometry")
  )
})

test_that("boundary v2 layers satisfy their release and model-join contract", {
  skip_if_not_installed("sf")
  path <- system.file("extdata", "RSYC_ecostrat.gpkg", package = "RSYC")
  expect_true(nzchar(path))
  verify <- getFromNamespace(".rsyc_verify_ecostrat", "RSYC")
  expect_invisible(verify(path))

  layers <- c("ecozones", "ecoprovinces", "ecoregions", "ecodistricts")
  counts <- c(12L, 36L, 138L, 672L)
  fields <- c(
    "parameter_level", "ecozone", "ecoprovince", "ecoregion",
    "ecodistrict", "ecozone_id", "ecoprovince_id", "ecoregion_id",
    "ecodistrict_id", "join_key", "geometry"
  )
  field_types <- c(
    parameter_level = "character", ecozone = "character",
    ecoprovince = "character", ecoregion = "character",
    ecodistrict = "character", ecozone_id = "integer",
    ecoprovince_id = "character", ecoregion_id = "integer",
    ecodistrict_id = "integer", join_key = "character"
  )
  info <- sf::st_layers(path)
  expect_identical(info$name, layers)
  expect_identical(as.integer(info$features), counts)

  for (i in seq_along(layers)) {
    layer <- layers[[i]]
    level <- sub("s$", "", layer)
    x <- sf::st_read(path, layer = layer, quiet = TRUE)
    geometry <- attr(x, "sf_column")
    names(x)[names(x) == geometry] <- "geometry"
    sf::st_geometry(x) <- "geometry"
    model_keys <- unique(RSYC_models$strata_id[
      RSYC_models$scale == "national" & RSYC_models$strata_level == level
    ])

    expect_identical(names(x), fields)
    expect_identical(
      vapply(sf::st_drop_geometry(x), typeof, character(1)),
      field_types
    )
    expect_equal(nrow(x), counts[[i]])
    expect_equal(sf::st_crs(x)$epsg, 3978L)
    expect_true(all(sf::st_is_valid(x)))
    character_fields <- vapply(sf::st_drop_geometry(x), is.character, logical(1))
    expect_true(all(vapply(
      sf::st_drop_geometry(x)[character_fields],
      function(value) all(validUTF8(value)),
      logical(1)
    )))
    expect_false(anyNA(x$join_key))
    expect_true(all(nzchar(x$join_key)))
    expect_false(anyDuplicated(x$join_key) > 0L)
    expect_setequal(x$join_key, model_keys)
  }
})

test_that("every national model stratum joins to exactly one boundary", {
  skip_if_not_installed("sf")
  tile_path <- system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")
  ecological_path <- system.file(
    "extdata", "RSYC_ecostrat.gpkg", package = "RSYC"
  )
  expect_true(nzchar(tile_path))
  expect_true(nzchar(ecological_path))

  levels <- c("tile", "ecozone", "ecoprovince", "ecoregion", "ecodistrict")
  for (level in levels) {
    if (identical(level, "tile")) {
      boundaries <- sf::st_read(tile_path, layer = "RSYC_tiles", quiet = TRUE)
      boundary_keys <- as.character(boundaries$TileID)
    } else {
      boundaries <- sf::st_read(
        ecological_path,
        layer = paste0(level, "s"),
        quiet = TRUE
      )
      boundary_keys <- as.character(boundaries$join_key)
    }
    model_keys <- unique(RSYC_models$strata_id[
      RSYC_models$scale == "national" & RSYC_models$strata_level == level
    ])
    match_counts <- vapply(
      model_keys,
      function(key) sum(boundary_keys == key),
      integer(1)
    )

    expect_true(all(match_counts == 1L), info = level)
    expect_setequal(boundary_keys, model_keys)
  }
})

test_that("public ecological boundary codes agree with national models", {
  skip_if_not_installed("sf")
  source <- system.file("extdata", "RSYC_ecostrat.gpkg", package = "RSYC")
  expect_true(nzchar(source))
  cache <- tempfile("rsyc-ecostrat-cache-")
  dir.create(cache)
  expect_true(file.copy(source, file.path(cache, "RSYC_ecostrat.gpkg")))

  for (level in c("ecozone", "ecoprovince", "ecoregion", "ecodistrict")) {
    boundaries <- rsyc_boundaries(level, cache_dir = cache)
    field <- paste0(level, "_id")
    hierarchy <- c("ecozone", "ecoprovince", "ecoregion", "ecodistrict")
    hierarchy <- hierarchy[seq_len(match(level, hierarchy))]
    expect_named(
      boundaries,
      c("strata_id", "strata_code", hierarchy, paste0(hierarchy, "_id"), "geometry"),
      info = level
    )
    models <- unique(RSYC_models[
      RSYC_models$scale == "national" & RSYC_models$strata_level == level,
      c("strata_id", field)
    ])
    matched <- match(models$strata_id, boundaries$strata_id)
    expect_false(anyNA(matched), info = level)
    expect_identical(
      as.character(models[[field]]),
      boundaries$strata_code[matched],
      info = level
    )
    expect_identical(
      models[[field]], boundaries[[field]][matched], info = level
    )
  }
})
