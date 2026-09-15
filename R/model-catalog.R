#' List Published RSYC Models
#'
#' List the published Canada-wide curves that match a forest measure, species,
#' type of area, or area name. Leave a choice as `NULL` to include all of its
#' available values.
#'
#' @param response One or both forest measures: `"agb"` for aboveground biomass
#'   and `"volume"` for total volume. The default includes both.
#' @param species One or more species codes or broad groups. Uppercase and
#'   lowercase letters are treated the same. The default includes all species.
#' @param strata_level One or more types of area: `"tile"`, `"ecozone"`,
#'   `"ecoprovince"`, `"ecoregion"`, or `"ecodistrict"`. The default includes
#'   all types.
#' @param strata_id One or more tile IDs, ecological area names, or full
#'   sequences of ecological area names. The default includes all areas.
#' @return A table with one row for each published curve that matches the
#'   choices.
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
#' @return A table giving each species code, common name, and broad model group.
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

#' List Areas Available in RSYC Models
#'
#' @inheritParams available_rsyc_models
#' @return A table with the short area name (`strata_name`) and its full
#'   location within Canada's ecological classification (`strata_id`).
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
  models <- .rsyc_model_catalog()
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
