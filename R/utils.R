.rsyc_public_strata_levels <- c(
  "tile", "ecozone", "ecoprovince", "ecoregion", "ecodistrict"
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
    stop(glue::glue("`{arg}` must be one non-empty character value."), call. = FALSE)
  }
  invisible(x)
}

.rsyc_assert_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(glue::glue("`{arg}` must be `TRUE` or `FALSE`."), call. = FALSE)
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
  ifelse(lower %in% c("generic", "coniferous", "broadleaf"), lower, toupper(species))
}

.rsyc_strata_name <- function(strata_id) {
  sub("^.*/", "", strata_id)
}
