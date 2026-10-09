test_that("calibrate_rsyc returns the expected structure", {
  res <- calibrate_rsyc(
    response = "agb",
    species = "PICE.MAR",
    strata_level = "tile",
    strata_id = "H14",
    obs_age = c(45, 70),
    obs_response = c(120, 165)
  )

  expect_type(res, "list")
  expect_named(
    res,
    c(
      "predictions",
      "ratio_blup",
      "b_pixel",
      "shrinkage_factor",
      "n_obs",
      "random_effect_limited",
      "ratio_limited",
      "value_limited",
      "model_id"
    )
  )
  expect_s3_class(res$predictions, "tbl_df")
  expect_named(res$predictions, c("age", "value", "value_uncalibrated"))
  expect_identical(res$predictions$age, c(45, 70))
  expect_equal(res$n_obs, 2L)
  expect_true(res$shrinkage_factor >= 0 && res$shrinkage_factor <= 1)
})

test_that("calibration matches the BLUP shrinkage formula by hand", {
  model <- subset(
    RSYC_models,
    response == "agb" &
      scale == "national" &
      strata_level == "tile" &
      strata_id == "H14" &
      species == "PICE.MAR"
  )
  b1 <- model$b1[[1L]]
  b2 <- model$b2[[1L]]
  b3 <- model$b3[[1L]]
  b4 <- model$b4[[1L]]
  a_i <- b1
  pixel_var <- model$local_b1_var[[1L]]
  residual_var <- model$residual_var[[1L]]

  obs_age <- c(45, 70)
  obs_response <- c(120, 165)
  g <- exp(-b4 * obs_age) * (1 - exp(-b2 * obs_age))^b3
  base <- a_i * g
  denom <- sum(g^2) + residual_var / pixel_var
  b_pixel_raw <- sum(g * (obs_response - base)) / denom
  cap <- 3 * sqrt(pixel_var)
  b_pixel <- max(min(b_pixel_raw, cap), -cap)
  ratio <- (a_i + b_pixel) / a_i

  res <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = obs_age,
    obs_response = obs_response
  )

  expect_equal(res$b_pixel, b_pixel)
  expect_equal(res$ratio_blup, ratio)
  expect_equal(res$shrinkage_factor, sum(g^2) / denom)
  expect_false(res$ratio_limited)
})

test_that("`b1` is the stratum asymptote, not the bare fixed effect", {
  # b1 - parent_b1_random_effect is constant within a strata_level, which shows
  # the published b1 already contains the area random effect.
  tiles <- subset(
    RSYC_models,
    response == "agb" &
      scale == "national" &
      strata_level == "tile" &
      species == "PICE.MAR"
  )
  fixed <- tiles$b1 - tiles$parent_b1_random_effect
  expect_equal(length(unique(round(fixed, 8))), 1L)
})

test_that("observations on the published curve give no level adjustment", {
  # The uncalibrated trajectory is b1 * g(age) (paper Eq. 3).
  model <- subset(
    RSYC_models,
    response == "agb" &
      scale == "national" &
      strata_level == "tile" &
      strata_id == "H14" &
      species == "PICE.MAR"
  )
  a_i <- model$b1[[1L]]
  g <- exp(-model$b4[[1L]] * c(40, 80)) *
    (1 - exp(-model$b2[[1L]] * c(40, 80)))^model$b3[[1L]]

  res <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = c(40, 80),
    obs_response = a_i * g
  )
  expect_equal(res$b_pixel, 0, tolerance = 1e-6)
  expect_equal(res$ratio_blup, 1, tolerance = 1e-6)
  expect_equal(res$predictions$value, res$predictions$value_uncalibrated)
})

test_that("calibrated curve substitutes b into the asymptote", {
  res <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = 60,
    obs_response = 83.8,
    predict_age = c(30, 60, 120)
  )
  model <- subset(
    RSYC_models,
    response == "agb" &
      scale == "national" &
      strata_level == "tile" &
      strata_id == "H14" &
      species == "PICE.MAR"
  )
  shape <- exp(-model$b4[[1L]] * c(30, 60, 120)) *
    (1 - exp(-model$b2[[1L]] * c(30, 60, 120)))^model$b3[[1L]]

  # paper Eq. 6
  expect_equal(res$predictions$value, (model$b1[[1L]] + res$b_pixel) * shape)
  expect_equal(res$predictions$value_uncalibrated, model$b1[[1L]] * shape)
})

test_that("ratio_limit discards implausible adjustments", {
  # Without limits this input yields a ratio above 1.5; cap it below that.
  res <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = c(45, 70),
    obs_response = c(120, 165),
    ratio_limit = 1.5
  )
  expect_true(res$ratio_limited)
  expect_equal(res$ratio_blup, 1)
  expect_equal(res$predictions$value, res$predictions$value_uncalibrated)
})

test_that("random_effect_limit_sd constrains the estimate", {
  mild <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = 60,
    obs_response = 83.8
  )
  tight <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = 60,
    obs_response = 83.8,
    random_effect_limit_sd = 0.1
  )
  expect_false(mild$random_effect_limited)
  expect_true(tight$random_effect_limited)
  expect_lt(abs(tight$b_pixel), abs(mild$b_pixel))
})

test_that("apply_limits = FALSE disables all safeguards", {
  unlimited <- calibrate_rsyc(
    "agb",
    "PICE.MAR",
    "tile",
    "H14",
    obs_age = c(45, 70),
    obs_response = c(120, 165),
    apply_limits = FALSE
  )
  expect_false(unlimited$random_effect_limited)
  expect_false(unlimited$ratio_limited)
  expect_false(unlimited$value_limited)
})

test_that("calibration works for volume models", {
  res <- calibrate_rsyc(
    "volume",
    "PICE.MAR",
    "ecozone",
    "Boreal Shield East",
    obs_age = c(50, 90),
    obs_response = c(150, 260)
  )
  expect_type(res$ratio_blup, "double")
  expect_true(is.finite(res$ratio_blup))
})

test_that("calibrate_rsyc validates its inputs", {
  expect_error(
    calibrate_rsyc(
      "agb",
      "PICE.MAR",
      "tile",
      "H14",
      obs_age = c(45, 70),
      obs_response = 120
    ),
    "same length"
  )
  expect_error(
    calibrate_rsyc(
      "agb",
      "PICE.MAR",
      "tile",
      "H14",
      obs_age = c(45, -1),
      obs_response = c(120, 130)
    ),
    "negative"
  )
  expect_error(
    calibrate_rsyc(
      "agb",
      "PICE.MAR",
      "tile",
      "H14",
      obs_age = c(45, 70),
      obs_response = c(50, -1)
    ),
    "`obs_response` cannot contain negative values"
  )
  expect_no_error(
    calibrate_rsyc(
      "agb",
      "PICE.MAR",
      "tile",
      "H14",
      obs_age = c(45, 70),
      obs_response = c(0, 0)
    )
  )
  expect_error(
    calibrate_rsyc(
      "agb",
      "NOT.ASPECIES",
      "tile",
      "H14",
      obs_age = 45,
      obs_response = 120
    ),
    "No national RSYC model"
  )
  expect_error(
    calibrate_rsyc(
      "agb",
      "PICE.MAR",
      "tile",
      "H14",
      obs_age = 45,
      obs_response = 120,
      ratio_limit = -1
    ),
    "positive number"
  )
})

test_that("calibrate_rsyc accepts ecological codes", {
  model <- RSYC_models[
    RSYC_models$scale == "national" & RSYC_models$response == "agb" &
      RSYC_models$species == "PICE.MAR" &
      RSYC_models$strata_level == "ecodistrict",
    , drop = FALSE
  ][1L, ]
  args <- list(
    response = "agb", species = "PICE.MAR", strata_level = "ecodistrict",
    obs_age = c(45, 70), obs_response = c(120, 165)
  )
  by_path <- do.call(calibrate_rsyc, c(args, list(strata_id = model$strata_id)))
  by_code <- do.call(calibrate_rsyc, c(args, list(strata_id = model$ecodistrict_id)))
  expect_identical(by_code, by_path)

  expected <- list(
    `5` = c("Taiga Shield East", "Taiga Shield West"),
    `6` = c("Boreal Shield East", "Boreal Shield West"),
    `10` = c("Subhumid Prairies", "Semiarid Prairies")
  )
  for (code in names(expected)) {
    error <- tryCatch(
      calibrate_rsyc(
        "agb", "PICE.MAR", "ecozone", as.numeric(code),
        obs_age = 45, obs_response = 120
      ),
      error = identity
    )
    message <- conditionMessage(error)
    expect_match(message, expected[[code]][[1L]], fixed = TRUE)
    expect_match(message, expected[[code]][[2L]], fixed = TRUE)
  }
})
