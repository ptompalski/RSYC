# Build data/RSYC_models.rda from the stable RSYC-Canada package contract.
#
# Run from the RSYC package root. Override the default sibling-project path by
# setting RSYC_MODELS_SOURCE to a versioned rsyc_models_rpackage.rds file.

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.")
}
if (!requireNamespace("sf", quietly = TRUE)) {
  stop("Package `sf` is required.")
}

source(file.path("data-raw", "release_contract.R"), local = TRUE)
contract <- .rsyc_release_contract
source_path <- .rsyc_release_source_path("model", contract = contract)

if (!file.exists(source_path)) {
  stop("RSYC model source does not exist: ", source_path)
}
actual_sha256 <- digest::digest(source_path, algo = "sha256", file = TRUE)
if (!identical(actual_sha256, contract$model$source_sha256)) {
  stop(
    "RSYC model source failed checksum verification. Expected ",
    contract$model$source_sha256, "; got ", actual_sha256, "."
  )
}

RSYC_models <- readRDS(source_path)

expected_names <- names(contract$model$column_types)
stopifnot(
  nrow(RSYC_models) == contract$model$source_rows,
  ncol(RSYC_models) == contract$model$columns,
  identical(names(RSYC_models), expected_names),
  identical(vapply(RSYC_models, typeof, character(1)), contract$model$column_types),
  identical(unique(RSYC_models$model_version), contract$model_version)
)

forest_contract <- contract$forest_filter
forest_path <- Sys.getenv(
  forest_contract$source_environment_variable,
  unset = file.path("data-raw", forest_contract$source_filename)
)
if (!file.exists(forest_path)) {
  stop("Forested-ecozone source does not exist: ", forest_path)
}
forest_sha256 <- digest::digest(forest_path, algo = "sha256", file = TRUE)
if (!identical(forest_sha256, forest_contract$source_sha256)) {
  stop(
    "Forested-ecozone source failed checksum verification. Expected ",
    forest_contract$source_sha256, "; got ", forest_sha256, "."
  )
}
forest_map <- sf::st_read(
  forest_path,
  layer = forest_contract$layer,
  quiet = TRUE
)
forested_ecozones <- sort(unique(as.character(
  forest_map[[forest_contract$name_field]]
)))
stopifnot(identical(forested_ecozones, sort(forest_contract$ecozones)))

ecological_levels <- c("ecozone", "ecoprovince", "ecoregion", "ecodistrict")
is_ecological <- RSYC_models$strata_level %in% ecological_levels
model_ecozone <- sub("/.*$", "", RSYC_models$strata_id)
RSYC_models <- RSYC_models[
  !is_ecological | model_ecozone %in% forested_ecozones,
  , drop = FALSE
]
upstream_model_ids <- RSYC_models$model_id
stopifnot(nrow(RSYC_models) == contract$model$rows)
is_ecological <- RSYC_models$strata_level %in% ecological_levels
model_ecozone <- sub("/.*$", "", RSYC_models$strata_id)

is_character <- vapply(RSYC_models, is.character, logical(1))
stopifnot(all(vapply(RSYC_models[is_character], function(x) all(validUTF8(x)), logical(1))))

lookup_fields <- c(
  "response", "strata_level", "strata_id", "scale", "region_id", "species"
)
lookup <- RSYC_models[lookup_fields]
lookup$region_id[is.na(lookup$region_id)] <- "<NA>"

ecozone_mapping <- unique(RSYC_models[
  RSYC_models$strata_level == "ecozone",
  c("ecozone_id", "strata_id")
])
ecozone_mapping <- ecozone_mapping[order(
  ecozone_mapping$ecozone_id,
  ecozone_mapping$strata_id
), , drop = FALSE]
ambiguous_ecozones <- split(
  ecozone_mapping$strata_id,
  ecozone_mapping$ecozone_id
)
ambiguous_ecozones <- ambiguous_ecozones[lengths(ambiguous_ecozones) > 1L]
expected_ambiguous_ecozones <- list(
  `5` = c("Taiga Shield East", "Taiga Shield West"),
  `6` = c("Boreal Shield East", "Boreal Shield West")
)

equation <- "b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3"
stopifnot(
  !anyDuplicated(RSYC_models$model_id),
  !anyDuplicated(lookup),
  identical(ambiguous_ecozones, expected_ambiguous_ecozones),
  identical(sort(unique(RSYC_models$response)), c("agb", "volume")),
  identical(sort(unique(RSYC_models$scale)), c("national", "regional")),
  setequal(
    unique(RSYC_models$strata_level),
    c("tile", "tile_region", "ecozone", "ecoprovince", "ecoregion", "ecodistrict")
  ),
  all(RSYC_models$response_units[RSYC_models$response == "agb"] == "Mg/ha"),
  all(RSYC_models$response_units[RSYC_models$response == "volume"] == "m3/ha"),
  identical(unique(RSYC_models$equation), equation),
  all(RSYC_models$publish_ok %in% TRUE),
  all(model_ecozone[is_ecological] %in% forested_ecozones),
  identical(RSYC_models$model_id, upstream_model_ids),
  all(vapply(RSYC_models[c("b1", "b2", "b3", "b4")], function(x) all(is.finite(x)), logical(1))),
  all(vapply(
    RSYC_models[RSYC_models$scale == "national", c("local_b1_var", "residual_var")],
    function(x) all(is.finite(x) & x > 0),
    logical(1)
  ))
)

dir.create("data", showWarnings = FALSE)
output_path <- file.path("data", "RSYC_models.rda")
save(RSYC_models, file = output_path, compress = "xz", version = 2)

written <- new.env(parent = emptyenv())
loaded <- load(output_path, envir = written)
stopifnot(
  identical(loaded, "RSYC_models"),
  identical(written$RSYC_models$model_id, upstream_model_ids)
)
