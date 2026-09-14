# Build data/RSYC_models.rda from the stable RSYC-Canada package contract.
#
# Run from the RSYC package root. Override the default sibling-project path by
# setting RSYC_MODELS_SOURCE to a versioned rsyc_models_rpackage.rds file.

source_path <- Sys.getenv("RSYC_MODELS_SOURCE", unset = "")
if (!nzchar(source_path)) {
  source_path <- file.path(
    "..", "RSYC-Canada", "outputs", "products", "models", "versions",
    "v20260709", "rsyc_models_rpackage.rds"
  )
}
if (!file.exists(source_path)) {
  stop("RSYC model source does not exist: ", source_path)
}

RSYC_models <- readRDS(source_path)

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
  identical(unique(RSYC_models$model_version), "v20260709")
)

repair_latin1 <- function(x) {
  bad <- !is.na(x) & !validUTF8(x)
  x[bad] <- iconv(x[bad], from = "latin1", to = "UTF-8")
  x
}

is_character <- vapply(RSYC_models, is.character, logical(1))
invalid_utf8_count <- sum(vapply(
  RSYC_models[is_character],
  function(x) sum(!is.na(x) & !validUTF8(x)),
  integer(1)
))
stopifnot(invalid_utf8_count == 270L)

original_model_id <- RSYC_models$model_id
RSYC_models[is_character] <- lapply(RSYC_models[is_character], repair_latin1)
stopifnot(all(vapply(RSYC_models[is_character], function(x) all(validUTF8(x)), logical(1))))

slug <- function(x) {
  x <- as.character(x)
  x[is.na(x) | !nzchar(x)] <- "na"
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  x[!nzchar(x)] <- "na"
  x
}

RSYC_models$model_id <- paste(
  "rsyc",
  slug(RSYC_models$response),
  slug(RSYC_models$scale),
  slug(RSYC_models$strata_level),
  slug(RSYC_models$species),
  slug(RSYC_models$region_id),
  slug(RSYC_models$strata_id),
  sep = "_"
)
RSYC_models$model_id <- gsub("_na_", "_", RSYC_models$model_id)
stopifnot(sum(original_model_id != RSYC_models$model_id) == 270L)

lookup_fields <- c(
  "response", "strata_level", "strata_id", "scale", "region_id", "species"
)
lookup <- RSYC_models[lookup_fields]
lookup$region_id[is.na(lookup$region_id)] <- "<NA>"

equation <- "b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3"
stopifnot(
  !anyDuplicated(RSYC_models$model_id),
  !anyDuplicated(lookup),
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
  all(vapply(RSYC_models[c("b1", "b2", "b3", "b4")], function(x) all(is.finite(x)), logical(1)))
)

dir.create("data", showWarnings = FALSE)
save(RSYC_models, file = file.path("data", "RSYC_models.rda"), compress = "xz", version = 2)
