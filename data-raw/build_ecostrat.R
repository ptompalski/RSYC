# Build the spatial-only, model-aligned ecological-stratification release file.
#
# Usage:
# RSYC_ECOSTRAT_SOURCE=/path/to/RSYC_ecosystem_model_package.gpkg \
# RSYC_ECOSTRAT_OUTPUT=/path/to/release-directory \
# RSYC_ECOSTRAT_MANIFEST=/path/to/ecostrat-manifest.csv \
# Rscript data-raw/build_ecostrat.R

if (!requireNamespace("sf", quietly = TRUE)) {
  stop("Package `sf` is required.")
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.")
}
if (!requireNamespace("DBI", quietly = TRUE) ||
    !requireNamespace("RSQLite", quietly = TRUE)) {
  stop("Packages `DBI` and `RSQLite` are required.")
}

source(file.path("data-raw", "release_contract.R"), local = TRUE)
contract <- .rsyc_release_contract
boundary <- contract$boundary
layers <- boundary$layers
expected_features <- boundary$feature_counts
expected_fields <- boundary$fields

source <- .rsyc_release_source_path("boundary", contract = contract)
output_dir <- Sys.getenv("RSYC_ECOSTRAT_OUTPUT", unset = tempdir())
manifest_path <- Sys.getenv(
  "RSYC_ECOSTRAT_MANIFEST",
  unset = file.path("data-raw", "ecostrat-manifest.csv")
)
if (!file.exists(source)) {
  stop("RSYC ecological-boundary source does not exist: ", source)
}
source_sha256 <- digest::digest(source, algo = "sha256", file = TRUE)
if (!identical(source_sha256, boundary$source_sha256)) {
  stop(
    "RSYC ecological-boundary source failed checksum verification. Expected ",
    boundary$source_sha256, "; got ", source_sha256, "."
  )
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output <- file.path(output_dir, boundary$output_filename)
if (file.exists(output)) {
  unlink(output)
  if (file.exists(output)) {
    stop(
      "Could not replace the existing ecological-boundary output. ",
      "Close any application using it: ", output
    )
  }
}

model_environment <- new.env(parent = emptyenv())
loaded <- load(file.path("data", "RSYC_models.rda"), envir = model_environment)
stopifnot(identical(loaded, "RSYC_models"))
models <- model_environment$RSYC_models

validate_layer <- function(x, layer) {
  names(x)[names(x) == attr(x, "sf_column")] <- "geometry"
  sf::st_geometry(x) <- "geometry"
  character_fields <- vapply(sf::st_drop_geometry(x), is.character, logical(1))
  level <- sub("s$", "", layer)
  model_keys <- unique(models$strata_id[
    models$scale == "national" & models$strata_level == level
  ])

  stopifnot(
    nrow(x) == expected_features[[layer]],
    identical(names(x), expected_fields),
    identical(
      vapply(sf::st_drop_geometry(x), typeof, character(1)),
      boundary$field_types
    ),
    sf::st_crs(x)$epsg == 3978L,
    all(sf::st_is_valid(x)),
    all(vapply(
      sf::st_drop_geometry(x)[character_fields],
      function(value) all(validUTF8(value)),
      logical(1)
    )),
    !anyNA(x$join_key),
    all(nzchar(x$join_key)),
    !anyDuplicated(x$join_key),
    setequal(x$join_key, model_keys)
  )
  x
}

for (layer in layers) {
  x <- sf::st_read(source, layer = layer, quiet = TRUE)
  level <- sub("s$", "", layer)
  model_keys <- unique(models$strata_id[
    models$scale == "national" & models$strata_level == level
  ])
  x <- x[x$join_key %in% model_keys, , drop = FALSE]
  x <- validate_layer(x, layer)
  sf::st_write(x, output, layer = layer, append = file.exists(output), quiet = TRUE)
}

written <- sf::st_layers(output)
stopifnot(
  identical(written$name, layers),
  identical(as.integer(written$features), unname(expected_features))
)
for (layer in layers) {
  validate_layer(sf::st_read(output, layer = layer, quiet = TRUE), layer)
}

# GeoPackage writes otherwise embed the current time. Pin it so rebuilding the
# same spatial contract produces the same release checksum.
connection <- DBI::dbConnect(RSQLite::SQLite(), output)
invisible(DBI::dbExecute(
  connection,
  "UPDATE gpkg_contents SET last_change = '2026-09-23T00:00:00.000Z'"
))
invisible(DBI::dbExecute(connection, "VACUUM"))
DBI::dbDisconnect(connection)

checksum <- digest::digest(output, algo = "sha256", file = TRUE)
manifest <- data.frame(
  boundary_version = boundary$version,
  source_model_version = boundary$source_model_version,
  upstream_git_commit = contract$upstream_git_commit,
  filename = basename(output),
  bytes = file.info(output)$size,
  sha256 = checksum,
  source_filename = boundary$source_filename,
  source_sha256 = boundary$source_sha256,
  forest_filter_filename = contract$forest_filter$source_filename,
  forest_filter_sha256 = contract$forest_filter$source_sha256,
  built_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Built: ", normalizePath(output, winslash = "/"))
message("SHA-256: ", checksum)
