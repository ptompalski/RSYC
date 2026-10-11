# Calibrate an RSYC Yield Curve with Local Observations

**\[experimental\]**

Adjust a published RSYC curve to local field data using a best linear
unbiased predictor (BLUP) of the local level. Given one or more observed
values (aboveground biomass or total volume) at known stand ages, the
function estimates a shrinkage-based local level adjustment and applies
it as a multiplicative ratio to the selected national curve.

## Usage

``` r
calibrate_rsyc(
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
)
```

## Arguments

- response:

  Forest measure to estimate: `"agb"` for aboveground biomass or
  `"volume"` for total volume.

- species:

  A species code or broad group such as `"coniferous"`. Uppercase and
  lowercase letters are treated the same.

- strata_level:

  Type of area: `"tile"`, `"ecozone"`, `"ecoprovince"`, `"ecoregion"`,
  or `"ecodistrict"`.

- strata_id:

  Tile ID, ecological area name or path, or ecological code. Tile IDs,
  names, and paths are matched ignoring case. A single area name can be
  used when it occurs only once. If the name occurs in several places,
  use the full sequence of area names shown by
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md).
  Numeric values are interpreted as codes for the selected ecological
  `strata_level`; quote ecoprovince codes such as `"10.1"`.

- obs_age:

  Stand ages, in years, of the local observations.

- obs_response:

  Observed non-negative values at `obs_age`. Aboveground biomass in
  Mg/ha or total volume in m3/ha, matching `response`. Must be the same
  length as `obs_age`.

- predict_age:

  One or more stand ages at which to return calibrated predictions.
  Defaults to the sorted unique `obs_age`.

- apply_limits:

  When `TRUE` (the default), apply the safeguards that protect against
  implausible local adjustments: the random effect is constrained to
  `random_effect_limit_sd` standard deviations, an adjustment ratio
  above `ratio_limit` is discarded in favour of the bare curve, and any
  calibrated value above `value_limit` falls back to the bare curve.
  When `FALSE`, the raw shrunk BLUP adjustment is returned uncapped.

- random_effect_limit_sd:

  Number of standard deviations of the local random-effect distribution
  at which the estimate is constrained. The default of `3` corresponds
  to the central 99.7% of that distribution. Only used when
  `apply_limits` is `TRUE`.

- ratio_limit:

  Largest allowed calibration ratio before the adjustment is discarded.
  Only used when `apply_limits` is `TRUE`.

- value_limit:

  Largest allowed calibrated value before the prediction falls back to
  the bare curve. Only used when `apply_limits` is `TRUE`.

## Value

A list with the components:

- predictions:

  A table of `age` and the calibrated `value` at each `predict_age`,
  together with the bare-curve `value_uncalibrated`.

- ratio_blup:

  The multiplicative local adjustment applied to the curve.

- b_pixel:

  The estimated local random effect (capped and shrunk when
  `apply_limits` is `TRUE`).

- shrinkage_factor:

  The shrinkage weight in `[0, 1]`; values near 0 mean weak local
  evidence pulled toward no adjustment.

- n_obs:

  Number of observations used.

- random_effect_limited, ratio_limited, value_limited:

  Flags indicating whether each safeguard altered the result.

- model_id:

  Identifier of the national curve that was calibrated.

## Details

The RSYC models are nonlinear mixed-effects models in which the tile-
and pixel-level random effects act on the asymptote: \$\$AGB\_{ijk} =
(\beta_1 + b_i + b\_{ij})\\g(age) + \epsilon\_{ijk}\$\$ The `b1`
coefficient published in
[RSYC_models](https://ptompalski.github.io/RSYC/reference/RSYC_models.md)
is the stratum-level asymptote, already equal to \\\beta_1 + b_i\\, so
the uncalibrated trajectory is `b1 * g(age)`.

Local calibration estimates the further pixel-level random effect
\\b\_{ij}\\ conditional on the fitted model: \$\$b = \frac{\sum_j g_j
(y_j - b_1 g_j)}{\sum_j g_j^2 + \sigma^2\_\epsilon / \sigma^2_b}\$\$
where \\g_j\\ is the unit-scale growth at age \\j\\, \\\sigma^2_b\\ is
the pixel-level random-effect variance, and \\\sigma^2\_\epsilon\\ is
the residual variance. The \\\sigma^2\_\epsilon / \sigma^2_b\\ term
shrinks weak local evidence toward no adjustment. The calibrated curve
substitutes the adjusted asymptote into the same equation, \$\$(b_1 +
b)\\g(age)\$\$ which is equivalent to scaling the published curve by
\\(b_1 + b) / b_1\\, reported as `ratio_blup`.

With a single observation this becomes a one-point level anchor. The
result should be read as a single-observation BLUP-anchored RSYC curve,
not as a local growth trajectory learned from the data.

## References

Tompalski, P. et al. (2025). National remote sensing-derived aboveground
biomass yield curves for Canada.

## Examples

``` r
# One observation for a tile model selected by tile ID.
calibrate_rsyc(
  "agb", "PICE.MAR", "tile", "H14",
  obs_age = 45,
  obs_response = 65
)
#> $predictions
#> # A tibble: 1 × 3
#>     age value value_uncalibrated
#>   <dbl> <dbl>              <dbl>
#> 1    45  62.6               50.2
#> 
#> $ratio_blup
#> [1] 1.248941
#> 
#> $b_pixel
#> [1] 16.9871
#> 
#> $shrinkage_factor
#> [1] 0.8415476
#> 
#> $n_obs
#> [1] 1
#> 
#> $random_effect_limited
#> [1] FALSE
#> 
#> $ratio_limited
#> [1] FALSE
#> 
#> $value_limited
#> [1] FALSE
#> 
#> $model_id
#> [1] "rsyc_agb_national_tile_pice_mar_h14"
#> 

# Two observations for an ecoregion selected by numeric code.
calibrate_rsyc(
  "agb", "PICE.MAR", "ecoregion", 198,
  obs_age = c(45, 70),
  obs_response = c(52, 65)
)
#> $predictions
#> # A tibble: 2 × 3
#>     age value value_uncalibrated
#>   <dbl> <dbl>              <dbl>
#> 1    45  51.4               42.8
#> 2    70  64.2               53.5
#> 
#> $ratio_blup
#> [1] 1.198789
#> 
#> $b_pixel
#> [1] 11.62953
#> 
#> $shrinkage_factor
#> [1] 0.9291395
#> 
#> $n_obs
#> [1] 2
#> 
#> $random_effect_limited
#> [1] FALSE
#> 
#> $ratio_limited
#> [1] FALSE
#> 
#> $value_limited
#> [1] FALSE
#> 
#> $model_id
#> [1] "rsyc_agb_national_ecoregion_pice_mar_montane_cordillera_northern_montane_cordillera_skeena_mountains"
#> 

# Four observations for an ecodistrict selected by full hierarchy path.
calibrate_rsyc(
  "agb", "PICE.MAR", "ecodistrict",
  paste(
    "Atlantic Maritime", "Fundy Uplands", "Annapolis-Minas Lowlands",
    "Windsor Lowlands", sep = "/"
  ),
  obs_age = c(30, 50, 70, 90),
  obs_response = c(22, 31, 36, 39)
)
#> $predictions
#> # A tibble: 4 × 3
#>     age value value_uncalibrated
#>   <dbl> <dbl>              <dbl>
#> 1    30  21.9               28.6
#> 2    50  31.1               40.7
#> 3    70  36.5               47.8
#> 4    90  39.8               52.0
#> 
#> $ratio_blup
#> [1] 0.7650299
#> 
#> $b_pixel
#> [1] -12.26633
#> 
#> $shrinkage_factor
#> [1] 0.9631163
#> 
#> $n_obs
#> [1] 4
#> 
#> $random_effect_limited
#> [1] FALSE
#> 
#> $ratio_limited
#> [1] FALSE
#> 
#> $value_limited
#> [1] FALSE
#> 
#> $model_id
#> [1] "rsyc_agb_national_ecodistrict_pice_mar_atlantic_maritime_fundy_uplands_annapolis_minas_lowlands_windsor_lowlands"
#> 
```
