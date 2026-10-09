.rsyc_public_strata_levels <- c(
  "tile",
  "ecozone",
  "ecoprovince",
  "ecoregion",
  "ecodistrict"
)

.rsyc_published_age_range <- c(1, 150)

.rsyc_model_catalog <- function() {
  RSYC::RSYC_models
}

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

.rsyc_unknown_species <- function(species) {
  models <- .rsyc_model_catalog()
  known <- .rsyc_normalize_species(
    unique(models$species[models$scale == "national"]),
    scalar = FALSE
  )
  setdiff(species, known)
}

.rsyc_warn_unknown_species <- function(species) {
  unknown <- .rsyc_unknown_species(species)
  if (length(unknown)) {
    warning(
      "Unknown species code(s): ",
      paste0("'", unknown, "'", collapse = ", "),
      ". Use `species_codes()` or `rsyc_species()` to list valid codes.",
      call. = FALSE
    )
  }
  invisible(unknown)
}

.rsyc_strata_code_field <- function(strata_level) {
  switch(
    strata_level,
    ecozone = "ecozone_id",
    ecoprovince = "ecoprovince_id",
    ecoregion = "ecoregion_id",
    ecodistrict = "ecodistrict_id",
    NULL
  )
}

.rsyc_strata_codes <- function(models) {
  codes <- rep(NA_character_, nrow(models))
  for (level in setdiff(.rsyc_public_strata_levels, "tile")) {
    rows <- models$strata_level == level
    field <- .rsyc_strata_code_field(level)
    codes[rows] <- as.character(models[[field]][rows])
  }
  codes
}

.rsyc_ambiguous_ecozone_codes <- list(
  `5` = c("Taiga Shield East", "Taiga Shield West"),
  `6` = c("Boreal Shield East", "Boreal Shield West"),
  `10` = c("Subhumid Prairies", "Semiarid Prairies")
)

.rsyc_validate_strata_id <- function(strata_id, scalar = FALSE) {
  valid_type <- is.character(strata_id) ||
    (is.numeric(strata_id) && !is.factor(strata_id))
  if (!valid_type || !length(strata_id) || anyNA(strata_id)) {
    if (scalar) {
      stop(
        "`strata_id` must be one non-missing numeric code or one non-empty character value.",
        call. = FALSE
      )
    }
    stop(
      "`strata_id` must contain non-missing numeric codes or non-empty character values.",
      call. = FALSE
    )
  }
  if (scalar && length(strata_id) != 1L) {
    stop("`strata_id` must contain exactly one value.", call. = FALSE)
  }
  if (is.numeric(strata_id) && any(!is.finite(strata_id))) {
    stop("Numeric `strata_id` codes must contain only finite values.", call. = FALSE)
  }
  if (is.character(strata_id) && any(!nzchar(strata_id) | !nzchar(trimws(strata_id)))) {
    stop("Character `strata_id` values must not be empty or whitespace-only.", call. = FALSE)
  }
  invisible(strata_id)
}

.rsyc_is_numeric_code <- function(x) {
  grepl("^[+]?(?:[0-9]+(?:[.][0-9]+)?|[.][0-9]+)$", x, perl = TRUE)
}

.rsyc_normalize_strata_code <- function(code, strata_level) {
  field <- .rsyc_strata_code_field(strata_level)
  if (is.null(field)) {
    stop(
      "Numeric ecological codes cannot be used for `strata_level = \"tile\"`; use a character tile ID.",
      call. = FALSE
    )
  }

  numeric_code <- if (is.numeric(code)) code else suppressWarnings(as.numeric(code))
  if (!is.finite(numeric_code)) {
    stop("`strata_id` is not a valid ecological code.", call. = FALSE)
  }

  if (!identical(strata_level, "ecoprovince")) {
    if (numeric_code != floor(numeric_code)) {
      stop(
        glue::glue("Codes for `strata_level = \"{strata_level}\"` must be integers."),
        call. = FALSE
      )
    }
    return(format(numeric_code, scientific = FALSE, trim = TRUE, digits = 15))
  }

  if (is.character(code)) {
    code
  } else {
    format(numeric_code, scientific = FALSE, trim = TRUE, digits = 15)
  }
}

.rsyc_code_error <- function(code, strata_level, kind = c("unknown", "unavailable")) {
  kind <- match.arg(kind)
  if (identical(kind, "unknown")) {
    message <- glue::glue(
      "No {strata_level} uses the ecological code '{code}'. Use `rsyc_strata()` to list available codes."
    )
  } else {
    message <- glue::glue(
      "The {strata_level} code '{code}' is valid, but no published national RSYC model is available for the selected response/species."
    )
  }
  stop(message, call. = FALSE)
}

.rsyc_resolve_strata <- function(
  models,
  strata_id,
  strata_level,
  mode = c("single", "dataset", "catalog")
) {
  mode <- match.arg(mode)
  .rsyc_validate_strata_id(strata_id, scalar = identical(mode, "single"))

  if (is.numeric(strata_id) &&
      (length(strata_level) != 1L || identical(strata_level, "tile"))) {
    if (identical(strata_level, "tile")) {
      stop(
        "Numeric ecological codes cannot be used for `strata_level = \"tile\"`; use a character tile ID.",
        call. = FALSE
      )
    }
    stop(
      "Numeric ecological codes require exactly one ecological `strata_level`.",
      call. = FALSE
    )
  }

  available <- unique(models$strata_id)
  available_key <- tolower(available)
  available_name_key <- tolower(.rsyc_strata_name(available))
  resolved <- character()
  unmatched <- character()
  for (value in strata_id) {
    is_code <- is.numeric(strata_id)

    if (!is_code) {
      value_key <- tolower(value)
      exact <- available[available_key == value_key]
      if (length(exact)) {
        resolved <- c(resolved, exact)
        next
      }

      matches <- sort(available[available_name_key == value_key])
      if (length(matches)) {
        if (length(matches) > 1L && !identical(mode, "catalog")) {
          entries <- paste0("  - ", matches, collapse = "\n")
          stop(
            "The ecological area name '", value, "' is ambiguous.\n",
            "Matching hierarchical paths:\n", entries, "\n",
            "Use one of the full hierarchical paths as `strata_id`.",
            call. = FALSE
          )
        }
        resolved <- c(resolved, matches)
        next
      }

      is_code <- .rsyc_is_numeric_code(value)
      if (!is_code) {
        if (identical(mode, "catalog")) {
          unmatched <- c(unmatched, value)
          next
        }
        if (identical(mode, "single")) {
          next
        }
        stop(
          "No requested ", strata_level, " model was found for `strata_id = \"",
          value, "\"` and the selected response/species.",
          call. = FALSE
        )
      }
    }

    if (length(strata_level) != 1L || identical(strata_level, "tile")) {
      if (identical(strata_level, "tile")) {
        stop(
          "Ecological codes cannot be used for `strata_level = \"tile\"`; use a character tile ID.",
          call. = FALSE
        )
      }
      stop(
        "Ecological codes require exactly one ecological `strata_level`.",
        call. = FALSE
      )
    }

    code <- .rsyc_normalize_strata_code(value, strata_level)
    if (identical(strata_level, "ecozone") &&
        code %in% names(.rsyc_ambiguous_ecozone_codes) &&
        !identical(mode, "catalog")) {
      names <- .rsyc_ambiguous_ecozone_codes[[code]]
      entries <- paste0("  - ", names, collapse = "\n")
      stop(
        "Ecozone code '", code, "' is ambiguous.\n",
        "Matching ecozone names:\n", entries, "\n",
        "Select one by name using `strata_id`.",
        call. = FALSE
      )
    }

    field <- .rsyc_strata_code_field(strata_level)
    code_matches <- sort(unique(models$strata_id[as.character(models[[field]]) == code]))
    if (!length(code_matches)) {
      all_models <- .rsyc_model_catalog()
      all_models <- all_models[
        all_models$scale == "national" & all_models$strata_level == strata_level,
        ,
        drop = FALSE
      ]
      known <- any(as.character(all_models[[field]]) == code) ||
        (identical(strata_level, "ecozone") &&
          code %in% names(.rsyc_ambiguous_ecozone_codes))
      .rsyc_code_error(code, strata_level, if (known) "unavailable" else "unknown")
    }
    if (length(code_matches) > 1L && identical(mode, "single")) {
      names <- sort(unique(.rsyc_strata_name(code_matches)))
      entries <- paste0("  - ", names, collapse = "\n")
      stop(
        "The ", strata_level, " code '", code, "' is ambiguous.\n",
        "Matching names:\n", entries, "\n",
        "Select one by name or full hierarchical path using `strata_id`.",
        call. = FALSE
      )
    }
    resolved <- c(resolved, code_matches)
  }

  if (length(unmatched)) {
    warning(
      "No published national RSYC model matches `strata_id` value(s): ",
      paste0("'", unique(unmatched), "'", collapse = ", "),
      " for the selected response, species, and strata_level. ",
      "Use `rsyc_strata()` to list available names and hierarchical paths.",
      call. = FALSE
    )
  }

  unique(resolved)
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

  resolved <- .rsyc_resolve_strata(
    candidates,
    strata_id,
    strata_level,
    mode = "single"
  )
  model <- candidates[candidates$strata_id %in% resolved, , drop = FALSE]

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
