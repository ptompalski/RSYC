#' Predict a Remote Sensing-Based Yield Curve
#'
#' Predict aboveground biomass or total volume from a published national RSYC
#' model selected by species and spatial stratum.
#'
#' @param response Response variable: `"agb"` or `"volume"`.
#' @param species A species code or model group. Matching is case-insensitive.
#' @param age Numeric vector of stand ages in years.
#' @param strata_level Spatial level: `"tile"`, `"ecozone"`,
#'   `"ecoprovince"`, `"ecoregion"`, or `"ecodistrict"`.
#' @param strata_id Published stratum name or full hierarchical path. A short
#'   ecosystem name is accepted when it identifies one matching model. If it is
#'   ambiguous, supply the full path shown by `rsyc_strata()`.
#'
#' @return A numeric vector. AGB is expressed in Mg/ha and volume in m3/ha.
#'
#' @details
#' The public prediction interface currently uses national models only.
#' Published models cover stand ages from 1 through 600 years. Values outside
#' this interval generate an extrapolation warning. Full ecosystem paths use
#' `/` to separate the hierarchy from ecozone down to the requested level.
#'
#' @examples
#' predict_rsyc("agb", "PICE.MAR", c(20, 60, 120), "tile", "H14")
#' predict_rsyc(
#'   response = "volume",
#'   species = "PICE.MAR",
#'   age = c(20, 60, 120),
#'   strata_level = "ecozone",
#'   strata_id = "Boreal Shield East"
#' )
#'
#' @export
predict_rsyc <- function(response, species, age, strata_level, strata_id) {
  response <- .rsyc_match_choice(response, "response", c("agb", "volume"))
  species <- .rsyc_normalize_species(species)
  strata_level <- .rsyc_match_choice(
    strata_level,
    "strata_level",
    .rsyc_public_strata_levels
  )
  .rsyc_assert_scalar_character(strata_id, "strata_id")
  .rsyc_assert_age(age)

  models <- RSYC::RSYC_models
  keep <-
    models$response == response &
    models$strata_level == strata_level &
    models$scale == "national" &
    .rsyc_normalize_species(models$species, scalar = FALSE) == species
  candidates <- models[keep, , drop = FALSE]

  exact_match <- candidates$strata_id == strata_id
  if (sum(exact_match) == 1L) {
    model <- candidates[exact_match, , drop = FALSE]
  } else {
    short_match <- .rsyc_strata_name(candidates$strata_id) == strata_id
    matched_paths <- sort(unique(candidates$strata_id[short_match]))

    if (length(matched_paths) > 1L) {
      entries <- paste0("  - ", matched_paths, collapse = "\n")
      stop(
        glue::glue(
          "The {strata_level} name '{strata_id}' is ambiguous for this model.\n",
          "Matching hierarchical paths:\n{entries}\n",
          "Use one of the full hierarchical paths as `strata_id`, for example:\n",
          "  strata_id = \"{matched_paths[[1L]]}\""
        ),
        call. = FALSE
      )
    }

    model <- candidates[short_match, , drop = FALSE]
  }

  if (nrow(model) == 0L) {
    stop(
      glue::glue(
        "No national RSYC model for response='{response}', species='{species}', ",
        "strata_level='{strata_level}', strata_id='{strata_id}'. ",
        "Use `rsyc_strata()` to list available names and hierarchical paths."
      ),
      call. = FALSE
    )
  }
  if (nrow(model) != 1L) {
    stop(
      "Multiple national RSYC models matched the supplied identifiers; the model data are invalid.",
      call. = FALSE
    )
  }

  if (any(age < model$age_min[[1L]] | age > model$age_max[[1L]])) {
    warning(
      glue::glue(
        "Stand age is outside this model's published range ",
        "({model$age_min[[1L]]}-{model$age_max[[1L]]} years); predictions are extrapolations."
      ),
      call. = FALSE
    )
  }

  CRdeclining2(
    age = age,
    b1 = model$b1[[1L]],
    b2 = model$b2[[1L]],
    b3 = model$b3[[1L]],
    b4 = model$b4[[1L]]
  )
}
