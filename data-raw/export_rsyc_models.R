# Export the packaged model table for people who do not use R.
#
# Run from the RSYC package root after rebuilding data/RSYC_models.rda.

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.")
}

data_path <- file.path("data", "RSYC_models.rda")
if (!file.exists(data_path)) {
  stop("Packaged model data does not exist: ", data_path)
}

environment <- new.env(parent = emptyenv())
loaded <- load(data_path, envir = environment)
stopifnot(identical(loaded, "RSYC_models"))
RSYC_models <- environment$RSYC_models

expected_names <- c(
  "model_id", "model_version", "response", "response_units", "strata_type",
  "strata_level", "strata_id", "scale", "region_id", "species",
  "model_group", "equation", "age_min", "age_max", "b1", "b2", "b3",
  "b4", "b1_se", "b2_se", "b3_se", "b4_se", "sigma",
  "parent_b1_random_effect", "parent_b1_var", "local_b1_var", "residual_var",
  "has_cor_struct", "has_var_struct", "component_ok", "component_message",
  "n_obs", "n_units", "converged", "singular_or_boundary", "fit_ok",
  "publish_ok", "model_message"
)
stopifnot(
  nrow(RSYC_models) == 28391L,
  identical(names(RSYC_models), expected_names),
  identical(unique(RSYC_models$model_version), "v20260709"),
  !anyDuplicated(RSYC_models$model_id),
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

round_trip <- utils::read.csv(
  csv_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = ""
)
stopifnot(
  nrow(round_trip) == nrow(RSYC_models),
  identical(names(round_trip), names(RSYC_models)),
  identical(round_trip$model_id, RSYC_models$model_id),
  identical(round_trip$model_version, RSYC_models$model_version),
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
  model_version = unique(RSYC_models$model_version),
  filename = basename(zip_path),
  archive_member = basename(csv_path),
  rows = nrow(RSYC_models),
  columns = ncol(RSYC_models),
  bytes = file.info(zip_path)$size,
  sha256 = digest::digest(zip_path, algo = "sha256", file = TRUE),
  stringsAsFactors = FALSE
)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Built: ", zip_path)
message("SHA-256: ", manifest$sha256)
