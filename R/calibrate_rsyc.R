#' Calibrate an RSYC Yield Curve with Local Observations
#'
#' Adjust a published RSYC curve to local field data using a best linear
#' unbiased predictor (BLUP) of the local level. Given one or more observed
#' values (aboveground biomass or total volume) at known stand ages, the
#' function estimates a shrinkage-based local level adjustment and applies it
#' as a multiplicative ratio to the selected national curve.
#'
#' @inheritParams predict_rsyc
#' @param obs_age Stand ages, in years, of the local observations.
#' @param obs_response Observed values at `obs_age`. Aboveground biomass in
#'   Mg/ha or total volume in m3/ha, matching `response`. Must be the same
#'   length as `obs_age`.
#' @param predict_age One or more stand ages at which to return calibrated
#'   predictions. Defaults to the sorted unique `obs_age`.
#' @param apply_limits When `TRUE` (the default), apply the safeguards that
#'   protect against implausible local adjustments: the random effect is
#'   constrained to `random_effect_limit_sd` standard deviations, an adjustment
#'   ratio above `ratio_limit` is discarded in favour of the bare curve, and
#'   any calibrated value above `value_limit` falls back to the bare curve.
#'   When `FALSE`, the raw shrunk BLUP adjustment is returned uncapped.
#' @param random_effect_limit_sd Number of standard deviations of the local
#'   random-effect distribution at which the estimate is constrained. The
#'   default of `3` corresponds to the central 99.7% of that distribution.
#'   Only used when `apply_limits` is `TRUE`.
#' @param ratio_limit Largest allowed calibration ratio before the adjustment
#'   is discarded. Only used when `apply_limits` is `TRUE`.
#' @param value_limit Largest allowed calibrated value before the prediction
#'   falls back to the bare curve. Only used when `apply_limits` is `TRUE`.
#'
#' @return A list with the components:
#'   \describe{
#'     \item{predictions}{A table of `age` and the calibrated `value` at each
#'     `predict_age`, together with the bare-curve `value_uncalibrated`.}
#'     \item{ratio_blup}{The multiplicative local adjustment applied to the
#'     curve.}
#'     \item{b_pixel}{The estimated local random effect (capped and shrunk when
#'     `apply_limits` is `TRUE`).}
#'     \item{shrinkage_factor}{The shrinkage weight in `[0, 1]`; values near 0
#'     mean weak local evidence pulled toward no adjustment.}
#'     \item{n_obs}{Number of observations used.}
#'     \item{random_effect_limited, ratio_limited, value_limited}{Flags
#'     indicating whether each safeguard altered the result.}
#'     \item{model_id}{Identifier of the national curve that was calibrated.}
#'   }
#'
#' @details
#' The RSYC models are nonlinear mixed-effects models in which the tile- and
#' pixel-level random effects act on the asymptote:
#' \deqn{AGB_{ijk} = (\beta_1 + b_i + b_{ij})\,g(age) + \epsilon_{ijk}}
#' The `b1` coefficient published in [RSYC_models] is the stratum-level
#' asymptote, already equal to \eqn{\beta_1 + b_i}, so the uncalibrated
#' trajectory is `b1 * g(age)`.
#'
#' Local calibration estimates the further pixel-level random effect
#' \eqn{b_{ij}} conditional on the fitted model:
#' \deqn{b = \frac{\sum_j g_j (y_j - b_1 g_j)}{\sum_j g_j^2 +
#'   \sigma^2_\epsilon / \sigma^2_b}}
#' where \eqn{g_j} is the unit-scale growth at age \eqn{j}, \eqn{\sigma^2_b} is
#' the pixel-level random-effect variance, and \eqn{\sigma^2_\epsilon} is the
#' residual variance. The \eqn{\sigma^2_\epsilon / \sigma^2_b} term shrinks weak
#' local evidence toward no adjustment. The calibrated curve substitutes the
#' adjusted asymptote into the same equation,
#' \deqn{(b_1 + b)\,g(age)}
#' which is equivalent to scaling the published curve by
#' \eqn{(b_1 + b) / b_1}, reported as `ratio_blup`.
#'
#' With a single observation this becomes a one-point level anchor. The result
#' should be read as a single-observation BLUP-anchored RSYC curve, not as a
#' local growth trajectory learned from the data.
#'
#' @references
#' Tompalski, P. et al. (2025). National remote sensing-derived aboveground
#' biomass yield curves for Canada.
#'
#' @examples
#' # One observation for a tile model selected by tile ID.
#' calibrate_rsyc(
#'   "agb", "PICE.MAR", "tile", "H14",
#'   obs_age = 45,
#'   obs_response = 65
#' )
#'
#' # Two observations for an ecoregion selected by numeric code.
#' calibrate_rsyc(
#'   "agb", "PICE.MAR", "ecoregion", 198,
#'   obs_age = c(45, 70),
#'   obs_response = c(52, 65)
#' )
#'
#' # Four observations for an ecodistrict selected by full hierarchy path.
#' calibrate_rsyc(
#'   "agb", "PICE.MAR", "ecodistrict",
#'   paste(
#'     "Atlantic Maritime", "Fundy Uplands", "Annapolis-Minas Lowlands",
#'     "Windsor Lowlands", sep = "/"
#'   ),
#'   obs_age = c(30, 50, 70, 90),
#'   obs_response = c(22, 31, 36, 39)
#' )
#'
#' @export
calibrate_rsyc <- function(
  response,
  species,
  strata_level,
  strata_id,
  obs_age,
  obs_response,
  predict_age = NULL,
  apply_limits = TRUE,
  random_effect_limit_sd = 3,
  ratio_limit = 5,
  value_limit = 1000
) {
  response <- .rsyc_match_choice(response, "response", c("agb", "volume"))
  species <- .rsyc_normalize_species(species)
  strata_level <- .rsyc_match_choice(
    strata_level,
    "strata_level",
    .rsyc_public_strata_levels
  )
  .rsyc_assert_flag(apply_limits, "apply_limits")

  .rsyc_assert_age(obs_age)
  if (!is.numeric(obs_response) || length(obs_response) != length(obs_age)) {
    stop(
      "`obs_response` must be numeric and the same length as `obs_age`.",
      call. = FALSE
    )
  }
  if (any(!is.finite(obs_response))) {
    stop("`obs_response` must contain only finite values.", call. = FALSE)
  }

  if (is.null(predict_age)) {
    predict_age <- sort(unique(obs_age))
  } else {
    .rsyc_assert_age(predict_age)
  }

  if (apply_limits) {
    .rsyc_assert_positive_scalar(
      random_effect_limit_sd,
      "random_effect_limit_sd"
    )
    .rsyc_assert_positive_scalar(ratio_limit, "ratio_limit")
    .rsyc_assert_positive_scalar(value_limit, "value_limit")
  }

  components <- .rsyc_blup_components(
    response,
    species,
    strata_level,
    strata_id
  )

  .rsyc_warn_age_extrapolation(obs_age)
  .rsyc_warn_age_extrapolation(predict_age)

  estimate <- .rsyc_blup_estimate(
    components = components,
    obs_age = obs_age,
    obs_response = obs_response,
    apply_limits = apply_limits,
    random_effect_limit_sd = random_effect_limit_sd,
    ratio_limit = ratio_limit
  )

  shape <- .rsyc_blup_g(
    predict_age,
    components$b2,
    components$b3,
    components$b4
  )
  # Equation 3: the uncalibrated trajectory is (beta1 + b_i) * g(age), and
  # `b1` in RSYC_models is already that stratum-level asymptote.
  bare <- components$b1 * shape
  # Equation 6: substitute the local random effect into the asymptote.
  calibrated <- (components$b1 + estimate$b_pixel) * shape

  value_limited <- FALSE
  if (apply_limits && any(calibrated > value_limit)) {
    over <- calibrated > value_limit
    calibrated[over] <- bare[over]
    value_limited <- TRUE
  }

  list(
    predictions = tibble::tibble(
      age = predict_age,
      value = calibrated,
      value_uncalibrated = bare
    ),
    ratio_blup = estimate$ratio_blup,
    b_pixel = estimate$b_pixel,
    shrinkage_factor = estimate$shrinkage_factor,
    n_obs = length(obs_age),
    random_effect_limited = estimate$random_effect_limited,
    ratio_limited = estimate$ratio_limited,
    value_limited = value_limited,
    model_id = components$model_id
  )
}

# Unit-scale Chapman-Richards growth (curve level b1 removed).
.rsyc_blup_g <- function(age, b2, b3, b4) {
  exp(-b4 * age) * (1 - exp(-b2 * age))^b3
}

# Replacement for the reference nlme model-loading layer: read the BLUP
# ingredients directly from the packaged RSYC_models row.
.rsyc_blup_components <- function(response, species, strata_level, strata_id) {
  model <- .rsyc_select_model(response, species, strata_level, strata_id)

  pixel_var <- model$local_b1_var[[1L]]
  residual_var <- model$residual_var[[1L]]

  if (
    !is.finite(pixel_var) ||
      pixel_var <= 0 ||
      !is.finite(residual_var) ||
      residual_var <= 0
  ) {
    stop(
      glue::glue(
        "The RSYC model '{model$model_id[[1L]]}' does not have valid variance ",
        "components for local calibration."
      ),
      call. = FALSE
    )
  }

  list(
    model_id = model$model_id[[1L]],
    # `b1` is the stratum-level asymptote, already equal to beta1 + b_area.
    b1 = model$b1[[1L]],
    b2 = model$b2[[1L]],
    b3 = model$b3[[1L]],
    b4 = model$b4[[1L]],
    pixel_var = pixel_var,
    residual_var = residual_var
  )
}

# Core shrinkage/BLUP math shared by the calibration entry point.
.rsyc_blup_estimate <- function(
  components,
  obs_age,
  obs_response,
  apply_limits,
  random_effect_limit_sd,
  ratio_limit
) {
  a_i <- components$b1
  g_obs <- .rsyc_blup_g(obs_age, components$b2, components$b3, components$b4)
  base_obs <- a_i * g_obs

  sum_gd <- sum(g_obs * (obs_response - base_obs))
  sum_g2 <- sum(g_obs^2)
  denom <- sum_g2 + components$residual_var / components$pixel_var

  shrinkage_factor <- sum_g2 / denom
  b_pixel <- sum_gd / denom

  random_effect_limited <- FALSE
  if (apply_limits) {
    cap <- random_effect_limit_sd * sqrt(components$pixel_var)
    if (is.finite(b_pixel) && (b_pixel < -cap || b_pixel > cap)) {
      b_pixel <- max(min(b_pixel, cap), -cap)
      random_effect_limited <- TRUE
    }
  }

  ratio_blup <- (a_i + b_pixel) / a_i

  ratio_limited <- FALSE
  if (apply_limits && (!is.finite(ratio_blup) || ratio_blup > ratio_limit)) {
    b_pixel <- 0
    ratio_blup <- 1
    ratio_limited <- TRUE
  }

  list(
    b_pixel = b_pixel,
    shrinkage_factor = shrinkage_factor,
    ratio_blup = ratio_blup,
    random_effect_limited = random_effect_limited,
    ratio_limited = ratio_limited
  )
}
