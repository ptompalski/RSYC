# Export the packaged model table for people who do not use R.
#
# Run from the RSYC package root after rebuilding data/RSYC_models.rda.

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.")
}

source(file.path("data-raw", "release_contract.R"), local = TRUE)
contract <- .rsyc_release_contract

data_path <- file.path("data", "RSYC_models.rda")
if (!file.exists(data_path)) {
  stop("Packaged model data does not exist: ", data_path)
}

environment <- new.env(parent = emptyenv())
loaded <- load(data_path, envir = environment)
stopifnot(identical(loaded, "RSYC_models"))
RSYC_models <- environment$RSYC_models

expected_names <- names(contract$model$column_types)
character_fields <- names(
  contract$model$column_types[contract$model$column_types == "character"]
)
stopifnot(
  nrow(RSYC_models) == contract$model$rows,
  ncol(RSYC_models) == contract$model$columns,
  identical(names(RSYC_models), expected_names),
  identical(vapply(RSYC_models, typeof, character(1)), contract$model$column_types),
  identical(unique(RSYC_models$model_version), contract$model_version),
  !anyDuplicated(RSYC_models$model_id),
  all(vapply(
    RSYC_models[character_fields],
    function(x) all(validUTF8(x)),
    logical(1)
  )),
  all(vapply(RSYC_models[c("b1", "b2", "b3", "b4")],
    function(x) all(is.finite(x)), logical(1)))
)

output_dir <- normalizePath("data-raw", winslash = "/")
zip_path <- file.path(output_dir, "RSYC_models.zip")
manifest_path <- file.path(output_dir, "RSYC_models_manifest.csv")
staging_dir <- tempfile("rsyc-model-export-")
dir.create(staging_dir)
on.exit(unlink(staging_dir, recursive = TRUE), add = TRUE)

csv_path <- file.path(staging_dir, "RSYC_models.csv")
utils::write.csv(
  RSYC_models,
  csv_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
# ZIP archives otherwise embed the staging file's current modification time.
# Pin it so an unchanged filtered catalogue produces the same release checksum.
Sys.setFileTime(
  csv_path,
  as.POSIXct("2026-09-23 00:00:00", tz = "UTC")
)

round_trip <- utils::read.csv(
  csv_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = "",
  fileEncoding = "UTF-8",
  colClasses = unname(c(
    character = "character",
    integer = "integer",
    double = "numeric",
    logical = "logical"
  )[contract$model$column_types])
)
stopifnot(
  nrow(round_trip) == nrow(RSYC_models),
  identical(names(round_trip), names(RSYC_models)),
  identical(vapply(round_trip, typeof, character(1)), contract$model$column_types),
  all(vapply(
    round_trip[character_fields],
    function(x) all(validUTF8(x)),
    logical(1)
  )),
  all(vapply(
    character_fields,
    function(field) identical(round_trip[[field]], RSYC_models[[field]]),
    logical(1)
  )),
  identical(round_trip$model_id, RSYC_models$model_id),
  identical(round_trip$model_version, RSYC_models$model_version),
  identical(round_trip$ecozone_id, RSYC_models$ecozone_id),
  identical(round_trip$ecoprovince_id, RSYC_models$ecoprovince_id),
  identical(round_trip$ecoregion_id, RSYC_models$ecoregion_id),
  identical(round_trip$ecodistrict_id, RSYC_models$ecodistrict_id),
  all(vapply(c("b1", "b2", "b3", "b4"), function(field) {
    isTRUE(all.equal(
      round_trip[[field]], RSYC_models[[field]],
      tolerance = 1e-14,
      check.attributes = FALSE
    ))
  }, logical(1)))
)

old_directory <- setwd(staging_dir)
on.exit(setwd(old_directory), add = TRUE)
if (file.exists(zip_path)) {
  unlink(zip_path)
}
status <- utils::zip(
  zipfile = zip_path,
  files = "RSYC_models.csv",
  flags = "-9 -X"
)
stopifnot(identical(status, 0L), file.exists(zip_path))

manifest <- data.frame(
  model_version = contract$model_version,
  upstream_git_commit = contract$upstream_git_commit,
  source_rds_sha256 = contract$model$source_sha256,
  forest_filter_filename = contract$forest_filter$source_filename,
  forest_filter_sha256 = contract$forest_filter$source_sha256,
  filename = basename(zip_path),
  archive_member = basename(csv_path),
  rows = nrow(RSYC_models),
  columns = ncol(RSYC_models),
  bytes = file.info(zip_path)$size,
  output_zip_sha256 = digest::digest(zip_path, algo = "sha256", file = TRUE),
  built_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Built: ", zip_path)
message("SHA-256: ", manifest$output_zip_sha256)
