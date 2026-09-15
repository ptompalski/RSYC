# Build the spatial-only, model-aligned ecological-stratification release file.
#
# Usage:
# RSYC_ECOSTRAT_SOURCE=/path/to/RSYC_ecosystem_model_package.gpkg \
# RSYC_ECOSTRAT_OUTPUT=/path/to/release-directory Rscript data-raw/build_ecostrat.R

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

boundary_version <- "v1"
source_model_version <- "v20260709"
layers <- c("ecozones", "ecoprovinces", "ecoregions", "ecodistricts")
expected_features <- c(
  ecozones = 12L,
  ecoprovinces = 101L,
  ecoregions = 257L,
  ecodistricts = 936L
)
expected_fields <- c(
  "parameter_level", "ecozone", "ecoprovince", "ecoregion",
  "ecodistrict", "join_key", "geometry"
)

source <- Sys.getenv("RSYC_ECOSTRAT_SOURCE")
output_dir <- Sys.getenv("RSYC_ECOSTRAT_OUTPUT", unset = tempdir())
if (!nzchar(source) || !file.exists(source)) {
  stop("Set `RSYC_ECOSTRAT_SOURCE` to the versioned ecosystem model GeoPackage.")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output <- file.path(output_dir, "RSYC_ecostrat.gpkg")
if (file.exists(output)) {
  unlink(output)
}

for (layer in layers) {
  x <- sf::st_read(source, layer = layer, quiet = TRUE)
  names(x)[names(x) == attr(x, "sf_column")] <- "geometry"
  sf::st_geometry(x) <- "geometry"
  stopifnot(
    nrow(x) == expected_features[[layer]],
    identical(names(x), expected_fields),
    sf::st_crs(x)$epsg == 3978L,
    all(sf::st_is_valid(x)),
    all(validUTF8(unlist(sf::st_drop_geometry(x), use.names = FALSE)))
  )
  sf::st_write(x, output, layer = layer, append = file.exists(output), quiet = TRUE)
}

written <- sf::st_layers(output)
stopifnot(
  identical(written$name, layers),
  identical(as.integer(written$features), unname(expected_features))
)

# GeoPackage writes otherwise embed the current time. Pin it so rebuilding the
# same spatial contract produces the same release checksum.
connection <- DBI::dbConnect(RSQLite::SQLite(), output)
invisible(DBI::dbExecute(
  connection,
  "UPDATE gpkg_contents SET last_change = '2026-07-09T00:00:00.000Z'"
))
invisible(DBI::dbExecute(connection, "VACUUM"))
DBI::dbDisconnect(connection)

checksum <- digest::digest(output, algo = "sha256", file = TRUE)
manifest <- data.frame(
  boundary_version = boundary_version,
  source_model_version = source_model_version,
  filename = basename(output),
  bytes = file.info(output)$size,
  sha256 = checksum,
  source = normalizePath(source, winslash = "/"),
  built_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
utils::write.csv(
  manifest,
  file.path(output_dir, "RSYC_ecostrat_manifest.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Built: ", normalizePath(output, winslash = "/"))
message("SHA-256: ", checksum)
