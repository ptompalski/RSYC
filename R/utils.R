.rsyc_public_strata_levels <- c(
  "tile",
  "ecozone",
  "ecoprovince",
  "ecoregion",
  "ecodistrict"
)

.rsyc_published_age_range <- c(1, 150)

.rsyc_model_catalog <- function() {
  .rsyc_drop_known_invalid_models(RSYC::RSYC_models)
}

.rsyc_drop_known_invalid_models <- function(models) {
  invalid <- (
    models$scale == "national" &
      models$strata_level == "ecodistrict" &
      models$strata_id %in% .rsyc_known_invalid_ecodistrict_strata
  )
  models[!invalid, , drop = FALSE]
}

.rsyc_known_invalid_ecodistrict_strata <- c(
  "Taiga Shield West/Keewatin Lowlands/Dubawnt Lake Plain/Upland"
)

CRdeclining2 <- function(age, b1, b2, b3, b4) {
  b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3
}

.rsyc_assert_scalar_character <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop(
      glue::glue("`{arg}` must be one non-empty character value."),
      call. = FALSE
    )
  }
  invisible(x)
}

.rsyc_assert_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(glue::glue("`{arg}` must be `TRUE` or `FALSE`."), call. = FALSE)
  }
  invisible(x)
}

.rsyc_assert_positive_scalar <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0) {
    stop(glue::glue("`{arg}` must be a single positive number."), call. = FALSE)
  }
  invisible(x)
}

.rsyc_assert_prob <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0 || x >= 1) {
    stop(
      glue::glue("`{arg}` must be a single number between 0 and 1."),
      call. = FALSE
    )
  }
  invisible(x)
}

.rsyc_assert_age <- function(age) {
  if (!is.numeric(age) || length(age) == 0L) {
    stop("`age` must be a non-empty numeric vector.", call. = FALSE)
  }
  if (any(!is.finite(age))) {
    stop("`age` must contain only finite values.", call. = FALSE)
  }
  if (any(age < 0)) {
    stop("`age` cannot contain negative values.", call. = FALSE)
  }
  invisible(age)
}

.rsyc_warn_age_extrapolation <- function(age) {
  if (any(age > .rsyc_published_age_range[[2L]])) {
    warning(
      glue::glue(
        "Stand age is outside the published calibration range ",
        "({.rsyc_published_age_range[[1L]]}-",
        "{.rsyc_published_age_range[[2L]]} years); ",
        "predictions are extrapolations."
      ),
      call. = FALSE
    )
  }
  invisible(age)
}

.rsyc_match_choice <- function(x, arg, choices) {
  .rsyc_assert_scalar_character(x, arg)
  value <- tolower(x)
  if (!(value %in% choices)) {
    stop(
      glue::glue("`{arg}` must be one of: {paste(choices, collapse = ', ')}."),
      call. = FALSE
    )
  }
  value
}

.rsyc_normalize_species <- function(species, scalar = TRUE) {
  if (scalar) {
    .rsyc_assert_scalar_character(species, "species")
  } else if (!is.character(species)) {
    stop("`species` must be character.", call. = FALSE)
  }

  lower <- tolower(species)
  ifelse(
    lower %in% c("generic", "coniferous", "broadleaf"),
    lower,
    toupper(species)
  )
}

.rsyc_strata_name <- function(strata_id) {
  sub("^.*/", "", strata_id)
}

# Select the single national model row matching response/species/strata.
# Shared by predict_rsyc() and calibrate_rsyc(). Returns a one-row data frame
# or stops with an informative error.
.rsyc_select_model <- function(response, species, strata_level, strata_id) {
  models <- .rsyc_model_catalog()
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

  model
}
