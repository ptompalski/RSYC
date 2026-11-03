# Build the bundled, model-aligned v20260923 tile boundary product.
#
# Run from the RSYC package root. RSYC_ECOSTRAT_SOURCE may override the
# authoritative GeoPackage. RSYC_TILES_OUTPUT and RSYC_TILES_MANIFEST may
# override the output and manifest paths.

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
tile_contract <- contract$tile_boundary

source_path <- .rsyc_release_source_path("boundary", contract = contract)
output_path <- Sys.getenv(
  "RSYC_TILES_OUTPUT",
  unset = file.path("inst", "extdata", tile_contract$output_filename)
)
manifest_path <- Sys.getenv(
  "RSYC_TILES_MANIFEST",
  unset = file.path("data-raw", "tiles-manifest.csv")
)

if (!file.exists(source_path)) {
  stop("RSYC tile-boundary source does not exist: ", source_path)
}
source_sha256 <- digest::digest(source_path, algo = "sha256", file = TRUE)
if (!identical(source_sha256, tile_contract$source_sha256)) {
  stop(
    "RSYC tile-boundary source failed checksum verification. Expected ",
    tile_contract$source_sha256, "; got ", source_sha256, "."
  )
}

source_layers <- sf::st_layers(source_path)
stopifnot(tile_contract$source_layer %in% source_layers$name)
tiles <- sf::st_read(
  source_path,
  layer = tile_contract$source_layer,
  quiet = TRUE
)
names(tiles)[names(tiles) == attr(tiles, "sf_column")] <- "geometry"
sf::st_geometry(tiles) <- "geometry"

character_fields <- vapply(sf::st_drop_geometry(tiles), is.character, logical(1))
stopifnot(
  nrow(tiles) == tile_contract$source_features,
  identical(names(tiles), tile_contract$source_fields),
  identical(
    vapply(sf::st_drop_geometry(tiles), typeof, character(1)),
    tile_contract$source_field_types
  ),
  sf::st_crs(tiles)$epsg == 3978L,
  all(sf::st_is_valid(tiles)),
  all(vapply(
    sf::st_drop_geometry(tiles)[character_fields],
    function(value) all(validUTF8(value)),
    logical(1)
  )),
  setequal(tiles$parameter_level, tile_contract$source_parameter_levels),
  !anyNA(tiles$join_key),
  all(nzchar(tiles$join_key)),
  all(tiles$tile_id == tiles$join_key),
  length(unique(tiles$join_key)) == tile_contract$output_features
)

model_environment <- new.env(parent = emptyenv())
loaded <- load(file.path("data", "RSYC_models.rda"), envir = model_environment)
stopifnot(identical(loaded, "RSYC_models"))
models <- model_environment$RSYC_models
model_tile_ids <- sort(unique(models$strata_id[
  models$scale == "national" & models$strata_level == "tile"
]))
tile_ids <- sort(unique(tiles$join_key))
stopifnot(
  length(model_tile_ids) == tile_contract$output_features,
  identical(tile_ids, model_tile_ids),
  !any(tile_contract$retired_ids %in% tile_ids)
)

dissolved_geometry <- lapply(tile_ids, function(tile_id) {
  geometry <- sf::st_geometry(tiles[tiles$join_key == tile_id, , drop = FALSE])
  sf::st_union(geometry)[[1L]]
})
dissolved <- sf::st_sf(
  TileID = tile_ids,
  geometry = sf::st_sfc(dissolved_geometry, crs = sf::st_crs(tiles))
)
stopifnot(
  nrow(dissolved) == tile_contract$output_features,
  identical(names(dissolved), tile_contract$output_fields),
  !anyDuplicated(dissolved$TileID),
  identical(dissolved$TileID, model_tile_ids),
  sf::st_crs(dissolved)$epsg == 3978L,
  all(sf::st_is_valid(dissolved))
)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
if (file.exists(output_path)) {
  unlink(output_path)
}
sf::st_write(
  dissolved,
  output_path,
  layer = tile_contract$output_layer,
  quiet = TRUE
)

written_layers <- sf::st_layers(output_path)
written <- sf::st_read(
  output_path,
  layer = tile_contract$output_layer,
  quiet = TRUE
)
names(written)[names(written) == attr(written, "sf_column")] <- "geometry"
sf::st_geometry(written) <- "geometry"
stopifnot(
  identical(written_layers$name, tile_contract$output_layer),
  identical(as.integer(written_layers$features), tile_contract$output_features),
  identical(names(written), tile_contract$output_fields),
  identical(written$TileID, model_tile_ids),
  !anyDuplicated(written$TileID),
  !any(tile_contract$retired_ids %in% written$TileID),
  sf::st_crs(written)$epsg == 3978L,
  all(sf::st_is_valid(written))
)

# GeoPackage writes otherwise embed the current time. Pin it so rebuilding the
# same spatial contract produces the same release checksum.
connection <- DBI::dbConnect(RSQLite::SQLite(), output_path)
invisible(DBI::dbExecute(
  connection,
  "UPDATE gpkg_contents SET last_change = '2026-09-23T00:00:00.000Z'"
))
invisible(DBI::dbExecute(connection, "VACUUM"))
DBI::dbDisconnect(connection)

checksum <- digest::digest(output_path, algo = "sha256", file = TRUE)
manifest <- data.frame(
  source_model_version = tile_contract$source_model_version,
  upstream_git_commit = contract$upstream_git_commit,
  filename = basename(output_path),
  layer = tile_contract$output_layer,
  source_filename = tile_contract$source_filename,
  source_layer = tile_contract$source_layer,
  source_features = tile_contract$source_features,
  source_join_keys = length(unique(tiles$join_key)),
  output_features = nrow(written),
  bytes = file.info(output_path)$size,
  sha256 = checksum,
  source_sha256 = tile_contract$source_sha256,
  built_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Built: ", normalizePath(output_path, winslash = "/"))
message("SHA-256: ", checksum)
