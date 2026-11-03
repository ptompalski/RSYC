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
#'   Unknown species codes produce a warning.
#' @param strata_level One or more types of area: `"tile"`, `"ecozone"`,
#'   `"ecoprovince"`, `"ecoregion"`, or `"ecodistrict"`. The default includes
#'   all types.
#' @param strata_id One or more tile IDs, ecological area names or paths, or
#'   ecological codes. Tile IDs, names, and paths are matched ignoring case.
#'   Numeric values and numeric-looking character values are
#'   interpreted as codes when no name or path matches. Code searches require
#'   exactly one ecological `strata_level`. Quote ecoprovince codes such as
#'   `"10.1"`. Values that match no published curve produce a warning. The
#'   default includes all areas.
#' @return A table with one row for each published curve that matches the
#'   choices. `strata_code` is the canonical character code for ecological
#'   rows and `NA` for tiles.
#' @details Character `strata_id` values are matched as names or paths before
#'   numeric-looking values are interpreted as ecological codes. Ecozone codes
#'   5 and 6 return both published named subdivisions. Ecozone code 10 is also
#'   ambiguous, but currently has no published national model rows.
#'
#' @examples
#' available_rsyc_models(
#'   response = "volume", species = "PICE.MAR", strata_level = "tile"
#' )
#' available_rsyc_models(
#'   response = "agb", strata_level = "ecoprovince", strata_id = "7.1"
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
  out$strata_code <- .rsyc_strata_codes(models)
  out$strata_name <- .rsyc_strata_name(out$strata_id)
  out <- out[c(
    "model_id", "response", "response_units", "strata_type",
    "strata_level", "strata_name", "strata_id", "strata_code", "species",
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
#' @return A table with the short area name (`strata_name`), its full location
#'   within Canada's ecological classification (`strata_id`), and its canonical
#'   character `strata_code`. Tile rows have `NA` codes.
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
  models$strata_code <- .rsyc_strata_codes(models)
  out <- unique(models[c("strata_level", "strata_id", "strata_code")])
  out$strata_name <- .rsyc_strata_name(out$strata_id)
  out <- out[c("strata_level", "strata_name", "strata_id", "strata_code")]
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
    .rsyc_warn_unknown_species(species)
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
  models <- models[keep, , drop = FALSE]
  if (!is.null(strata_id)) {
    requested_levels <- if (is.null(strata_level)) {
      .rsyc_public_strata_levels
    } else {
      levels
    }
    resolved <- .rsyc_resolve_strata(
      models,
      strata_id,
      requested_levels,
      mode = "catalog"
    )
    models <- models[models$strata_id %in% resolved, , drop = FALSE]
  }

  models
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
