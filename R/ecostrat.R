.rsyc_boundaries_release <- "boundaries-v1"
.rsyc_ecostrat_filename <- "RSYC_ecostrat.gpkg"
.rsyc_ecostrat_url <- paste0(
  "https://github.com/ptompalski/RSYC/releases/download/",
  .rsyc_boundaries_release,
  "/",
  .rsyc_ecostrat_filename
)

.rsyc_require_namespace <- function(package) {
  requireNamespace(package, quietly = TRUE)
}

.rsyc_tile_boundaries_path <- function() {
  system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")
}

# Updated by data-raw/build_ecostrat.R when the downloadable boundary file is rebuilt.
.rsyc_ecostrat_sha256 <- paste0(
  "1f998c9ef4baa5565ac553505d78215c",
  "a90d3939e1444efa4f38200f293d0d2d"
)

#' Download RSYC Ecological Boundaries
#'
#' Download and save the ecological boundary maps used by RSYC. The file is
#' not downloaded when the package is installed or loaded. It contains maps of
#' ecozones, ecoprovinces, ecoregions, and ecodistricts, but no yield curves.
#' Tile boundaries are already included with RSYC.
#'
#' @param cache_dir Folder in which to save the GeoPackage. By default, RSYC
#'   uses its standard user data folder, returned by [tools::R_user_dir()].
#' @param overwrite Replace a previously downloaded file?
#' @param quiet Hide download progress?
#' @param url Web address of the boundary file. The default points to the copy
#'   published with RSYC. Organizations may instead provide the address of an
#'   approved copy. Its contents must match the published file.
#'
#' @return The full location of the saved GeoPackage. The function returns this
#'   location without printing it.
#' @seealso [rsyc_boundaries()]
#'
#' @examples
#' \dontrun{
#' download_rsyc_boundaries()
#' }
#'
#' @export
download_rsyc_boundaries <- function(
  cache_dir = tools::R_user_dir("RSYC", "data"),
  overwrite = FALSE,
  quiet = FALSE,
  url = getOption("RSYC.ecostrat_url", .rsyc_ecostrat_url)
) {
  .rsyc_assert_scalar_character(cache_dir, "cache_dir")
  .rsyc_assert_scalar_character(url, "url")
  .rsyc_assert_flag(overwrite, "overwrite")
  .rsyc_assert_flag(quiet, "quiet")

  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(cache_dir)) {
    stop("Could not create `cache_dir`: ", cache_dir, call. = FALSE)
  }

  destination <- file.path(cache_dir, .rsyc_ecostrat_filename)
  if (file.exists(destination) && !overwrite) {
    .rsyc_verify_ecostrat(destination)
    return(invisible(normalizePath(destination, winslash = "/")))
  }

  temporary <- tempfile(
    pattern = paste0(.rsyc_ecostrat_filename, "-"),
    tmpdir = cache_dir,
    fileext = ".download"
  )
  on.exit(unlink(temporary), add = TRUE)

  old_timeout <- getOption("timeout", 60)
  options(timeout = max(300, old_timeout))
  on.exit(options(timeout = old_timeout), add = TRUE)

  status <- tryCatch(
    utils::download.file(url, temporary, mode = "wb", quiet = quiet),
    error = function(error) {
      stop(
        "Could not download the RSYC ecological stratification from:\n",
        url,
        "\n",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )
  if (!isTRUE(status == 0L) || !file.exists(temporary)) {
    stop("The ecological-stratification download did not complete.", call. = FALSE)
  }

  .rsyc_verify_ecostrat(temporary)
  if (file.exists(destination)) {
    unlink(destination)
  }
  if (!file.rename(temporary, destination)) {
    stop("Could not move the downloaded file into the cache.", call. = FALSE)
  }

  if (!quiet) {
    message("Cached RSYC ecological stratification at: ", destination)
  }
  invisible(normalizePath(destination, winslash = "/"))
}

.rsyc_ecostrat_path <- function(
  cache_dir = tools::R_user_dir("RSYC", "data"),
  must_exist = TRUE
) {
  .rsyc_assert_scalar_character(cache_dir, "cache_dir")
  .rsyc_assert_flag(must_exist, "must_exist")

  path <- file.path(cache_dir, .rsyc_ecostrat_filename)
  if (!file.exists(path)) {
    if (must_exist) {
      stop(
        "The RSYC ecological stratification is not cached. Run ",
        "`download_rsyc_boundaries()` first.",
        call. = FALSE
      )
    }
    return(path)
  }
  normalizePath(path, winslash = "/")
}

#' Read RSYC Boundary Maps
#'
#' Read the tile boundaries or ecological boundaries used for the RSYC yield
#' curves. Tile boundaries are included with the package. Ecological boundaries
#' are read from the file saved by [download_rsyc_boundaries()]. This function
#' never downloads data on its own.
#'
#' @param strata_level Type of area: `"tile"`, `"ecozone"`, `"ecoprovince"`,
#'   `"ecoregion"`, or `"ecodistrict"`.
#' @inheritParams download_rsyc_boundaries
#' @param quiet Hide messages produced while the map is read?
#'
#' @return An `sf` map in the Canada Atlas Lambert projection (EPSG:3978). Every
#'   map contains `strata_id`, which links an area to its RSYC curves, and the
#'   area shape. Ecological maps also contain the names of the larger ecological
#'   areas in which each area lies.
#'
#' @examples
#' tiles <- rsyc_boundaries("tile")
#' \dontrun{
#' download_rsyc_boundaries()
#' districts <- rsyc_boundaries("ecodistrict")
#' }
#'
#' @export
rsyc_boundaries <- function(
  strata_level = "tile",
  cache_dir = tools::R_user_dir("RSYC", "data"),
  quiet = TRUE
) {
  if (!.rsyc_require_namespace("sf")) {
    stop("Package `sf` is required to read ecological-stratification layers.", call. = FALSE)
  }
  .rsyc_assert_flag(quiet, "quiet")
  strata_level <- .rsyc_match_choice(
    strata_level,
    "strata_level",
    .rsyc_public_strata_levels
  )

  if (identical(strata_level, "tile")) {
    path <- .rsyc_tile_boundaries_path()
    if (!nzchar(path)) {
      stop("The bundled RSYC tile boundaries could not be found.", call. = FALSE)
    }
    boundaries <- sf::st_read(path, quiet = quiet)
    boundaries$strata_id <- as.character(boundaries$TileID)
    hierarchy <- character()
  } else {
    path <- .rsyc_ecostrat_path(cache_dir = cache_dir)
    .rsyc_verify_ecostrat(path)
    layer <- paste0(strata_level, "s")
    boundaries <- sf::st_read(path, layer = layer, quiet = quiet)
    boundaries$strata_id <- as.character(boundaries$join_key)
    hierarchy_levels <- c("ecozone", "ecoprovince", "ecoregion", "ecodistrict")
    hierarchy <- hierarchy_levels[seq_len(match(strata_level, hierarchy_levels))]
  }

  geometry <- attr(boundaries, "sf_column")
  if (!identical(geometry, "geometry")) {
    names(boundaries)[names(boundaries) == geometry] <- "geometry"
    sf::st_geometry(boundaries) <- "geometry"
    geometry <- "geometry"
  }
  boundaries[c("strata_id", hierarchy, geometry)]
}

.rsyc_verify_ecostrat <- function(
  path,
  expected = .rsyc_ecostrat_sha256
) {
  if (!.rsyc_require_namespace("digest")) {
    stop("Package `digest` is required to verify the downloaded file.", call. = FALSE)
  }
  actual <- digest::digest(path, algo = "sha256", file = TRUE)
  if (!identical(tolower(actual), tolower(expected))) {
    stop(
      "The ecological-stratification file failed checksum verification. ",
      "Expected ", expected, ", received ", actual, ".",
      call. = FALSE
    )
  }
  invisible(path)
}
