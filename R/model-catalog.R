#' List Published RSYC Models
#'
#' Return model metadata filtered by response, species, spatial level, stratum,
#' using the currently supported national models. `NULL` means that a field is
#' not filtered.
#'
#' @param response Optional character vector containing `"agb"` and/or
#'   `"volume"`.
#' @param species Optional character vector of species codes or model groups.
#'   Matching is case-insensitive.
#' @param strata_level Optional character vector containing public spatial
#'   levels: `"tile"`, `"ecozone"`, `"ecoprovince"`, `"ecoregion"`, or
#'   `"ecodistrict"`.
#' @param strata_id Optional character vector of short stratum names or full
#'   published hierarchical paths.
#' @return A tibble with one row per matching published curve.
#'
#' @examples
#' available_rsyc_models(
#'   response = "volume", species = "PICE.MAR", strata_level = "tile"
#' )
#'
#' @export
available_rsyc_models <- function(
  response = NULL,
  species = NULL,
  strata_level = NULL,
  strata_id = NULL
) {
  models <- .rsyc_filter_models(response, species, strata_level, strata_id)
  out <- models[c(
    "model_id", "response", "response_units", "strata_type",
    "strata_level", "strata_id", "species",
    "model_group", "model_version"
  )]
  out$strata_name <- .rsyc_strata_name(out$strata_id)
  out <- out[c(
    "model_id", "response", "response_units", "strata_type",
    "strata_level", "strata_name", "strata_id", "species",
    "model_group", "model_version"
  )]
  tibble::as_tibble(out)
}

#' List Species Available in RSYC Models
#'
#' @inheritParams available_rsyc_models
#' @return A tibble with columns `species`, `species_name`, and `model_group`.
#'
#' @examples
#' rsyc_species(response = "agb", strata_level = "ecoregion")
#'
#' @export
rsyc_species <- function(
  response = NULL,
  strata_level = NULL,
  strata_id = NULL
) {
  models <- .rsyc_filter_models(response, NULL, strata_level, strata_id)
  species <- unique(models[c("species", "model_group")])
  species$species_name <- unname(.rsyc_species_names[species$species])
  species <- species[c("species", "species_name", "model_group")]
  species <- species[order(
    match(species$species, c("generic", "coniferous", "broadleaf"), nomatch = 4L),
    species$species
  ), , drop = FALSE]
  rownames(species) <- NULL
  tibble::as_tibble(species)
}

#' List Spatial Strata Available in RSYC Models
#'
#' @inheritParams available_rsyc_models
#' @return A tibble with the short `strata_name` and canonical hierarchical
#'   `strata_id` for each matching national-model stratum.
#'
#' @examples
#' rsyc_strata(
#'   response = "volume", species = "PICE.MAR", strata_level = "ecozone"
#' )
#'
#' @export
rsyc_strata <- function(
  response = NULL,
  species = NULL,
  strata_level = NULL
) {
  models <- .rsyc_filter_models(response, species, strata_level, NULL)
  out <- unique(models[c("strata_level", "strata_id")])
  out$strata_name <- .rsyc_strata_name(out$strata_id)
  out <- out[c("strata_level", "strata_name", "strata_id")]
  out <- out[order(out$strata_level, out$strata_name, out$strata_id), , drop = FALSE]
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

.rsyc_filter_models <- function(
  response = NULL,
  species = NULL,
  strata_level = NULL,
  strata_id = NULL
) {
  models <- RSYC::RSYC_models
  keep <- models$scale == "national"

  if (!is.null(response)) {
    response <- .rsyc_normalize_filter(response, "response", c("agb", "volume"))
    keep <- keep & models$response %in% response
  }
  if (!is.null(species)) {
    species <- .rsyc_normalize_species_filter(species)
    keep <- keep & .rsyc_normalize_species(models$species, scalar = FALSE) %in% species
  }
  if (!is.null(strata_level)) {
    levels <- .rsyc_normalize_filter(
      strata_level,
      "strata_level",
      .rsyc_public_strata_levels
    )
    keep <- keep & models$strata_level %in% levels
  }
  if (!is.null(strata_id)) {
    if (!is.character(strata_id) || anyNA(strata_id) || any(!nzchar(strata_id))) {
      stop("`strata_id` must contain non-empty character values.", call. = FALSE)
    }
    keep <- keep & (
      models$strata_id %in% strata_id |
        .rsyc_strata_name(models$strata_id) %in% strata_id
    )
  }

  models[keep, , drop = FALSE]
}

.rsyc_normalize_filter <- function(x, arg, choices) {
  if (!is.character(x) || length(x) == 0L || anyNA(x) || any(!nzchar(x))) {
    stop(glue::glue("`{arg}` must contain non-empty character values."), call. = FALSE)
  }
  x <- tolower(x)
  invalid <- setdiff(x, choices)
  if (length(invalid)) {
    stop(
      glue::glue("`{arg}` must contain only: {paste(choices, collapse = ', ')}."),
      call. = FALSE
    )
  }
  unique(x)
}

.rsyc_normalize_species_filter <- function(x) {
  if (!is.character(x) || length(x) == 0L || anyNA(x) || any(!nzchar(x))) {
    stop("`species` must contain non-empty character values.", call. = FALSE)
  }
  unique(.rsyc_normalize_species(x, scalar = FALSE))
}
