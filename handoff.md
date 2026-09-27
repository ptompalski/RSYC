# Handoff: local BLUP calibration implementation

Use this note to guide implementation of the RSYC local BLUP-based calibration
in another project. The most important point is that the implementation lives
primarily in the BLUP helper script, not in the full curve-assignment pipeline.

## Primary files

- `K:/_PROJECTS/RSYC_curvePerPixel/R/9998_blupCalibration.R`
  - This is the main reference implementation.
  - Start here for the functions to port or adapt:
    - `RSYC_blup_load_model_components()` near line 84
    - `RSYC_blup_prepare_components()` near line 181
    - `RSYC_blup_assign_curve()` near line 364
    - `RSYC_blup_calibrate()` near line 704
  - The delivered calibrated value is assigned near line 1329:
    `AGB_RSYC_BLUP = blup_curve_value_assigned * ratio_BLUP`.

- `K:/_PROJECTS/RSYC_curvePerPixel/R/9999_curveAssign.R`
  - Use this as calling-context only, not as the main implementation to port.
  - It shows how the BLUP helper is wired into the broader RSYC curve assignment.
  - Relevant settings are near lines 68-99:
    `min_valid_AGB`, `use_blup_calibration`, `blup_model_dir`,
    `blup_response_col`, caps, and screening thresholds.
  - The actual call to `RSYC_blup_calibrate()` is near lines 836-864.
  - The older ratio-based local calibration is near lines 601-835; this is useful
    for comparison but is not the preferred single-measurement method.

## Useful examples and diagnostics

- `K:/_PROJECTS/RSYC_curvePerPixel/R/1100_test_blup_calibration_single_tile.R`
  - Prototype/test implementation for running BLUP calibration on one tile.
  - Useful if the new project needs a smaller, more explicit example than the
    full production helper.

- `K:/_PROJECTS/RSYC_curvePerPixel/R/1101_diagnose_blup_shrinkage_drivers.R`
  - Diagnostic script that recomputes the BLUP ingredients:
    `sum_gd`, `sum_g2`, `n_obs`, `A_i`, `residual_var / pixel_var`, and the
    shrinkage factor.
  - Useful for validating that a ported implementation produces the same
    shrinkage behavior.

- `K:/_PROJECTS/RSYC_curvePerPixel/R/1102_diagnose_rsyc_models.R`
  - Diagnostic script for checking model variance components and model health.

- `K:/_PROJECTS/RSYC_curvePerPixel/HANDOFF_blup_tamarack_fix.md`
  - Context for why caps and model screening were added.
  - Important if reproducing the robust production behavior rather than a bare
    BLUP formula.

## Behavior to reproduce

The BLUP calibration estimates a local pixel-level random effect for each
`IDpix, AgeClass, blup_model_species` group. It uses observed AGB at known age
to estimate a level adjustment, then applies that adjustment as a ratio to the
assigned RSYC curve.

For one observation, the estimate is still valid because `min_valid_AGB`
defaults to `1`, but the result should be treated as a shrinkage-based local
level anchor, not as a learned local growth trajectory.

Core coefficient logic in `RSYC_blup_calibrate()`:

```r
blup_sum_gd = sum(blup_g_obs * (blup_response - blup_base_obs), na.rm = TRUE)
blup_sum_g2 = sum(blup_g_obs^2, na.rm = TRUE)

blup_shrinkage_factor =
  blup_sum_g2 / (blup_sum_g2 + blup_residual_var / blup_pixel_var)

blup_b_pixel =
  blup_sum_gd / (blup_sum_g2 + blup_residual_var / blup_pixel_var)

ratio_BLUP = (blup_A_i + blup_b_pixel) / blup_A_i
AGB_RSYC_BLUP = blup_curve_value_assigned * ratio_BLUP
```

With a single plot measurement, this becomes a one-point adjustment:

```r
blup_b_pixel =
  g(age) * (AGB_observed - base_AGB_at_age) /
  (g(age)^2 + residual_var / pixel_var)
```

The `residual_var / pixel_var` term is what shrinks weak local evidence toward
no adjustment.

## Required input fields

The new project does not need to reproduce the entire tile pipeline, but it must
create an input table with the fields needed by `RSYC_blup_calibrate()` or an
adapted equivalent:

- `IDpix`: local pixel or stand identifier.
- `AgeClass`: segment identifier used with `IDpix`; in the original workflow this
  separates stand trajectory segments.
- `age`: plot or pixel age at the observation year.
- `AGB`: observed or externally supplied aboveground biomass response.
- `isTreed`: `1L` for observations eligible for calibration.
- `is_projected`: optional; projected observations are excluded by default.
- `species`: species code/name used to select a species-specific model when
  available.
- `type`: broad species group, with `"C"` for conifer and `"D"` for broadleaf.
- `AGB_RSYC_species`, `AGB_RSYC_coniferous`, `AGB_RSYC_broadleaf`,
  `AGB_RSYC_generic`: assigned RSYC curve values for the observation/prediction
  rows.
- `Case`: original workflow state; rows with `Case == 0L` or missing age are not
  assigned a BLUP model species.

The model components must provide fixed effects, tile random effect, pixel
random-effect variance, and residual variance. In the original implementation
these are loaded from `nlme` model `.rds` files via `RSYC_blup_load_model_components()`.

## Recommended implementation path

1. Port/adapt `RSYC_blup_g()`, `RSYC_blup_assign_curve()`,
   `RSYC_blup_prepare_components()`, and `RSYC_blup_calibrate()` from
   `K:/_PROJECTS/RSYC_curvePerPixel/R/9998_blupCalibration.R`.

2. If the new project cannot use the same `nlme` model `.rds` objects, replace
   only the component-loading layer. Preserve the downstream component columns:
   `blup_beta1`, `blup_beta2`, `blup_beta3`, `blup_beta4`, `blup_tile_b1`,
   `blup_pixel_var`, `blup_residual_var`, and `blup_component_ok`.

3. Keep the production safeguards unless there is a deliberate reason not to:
   random-effect cap, `blup_ratio_max`, AGB hard cap, and model health checks.

4. Validate the port using the diagnostic formulas in
   `K:/_PROJECTS/RSYC_curvePerPixel/R/1101_diagnose_blup_shrinkage_drivers.R`.
   The same inputs should produce the same `blup_sum_gd`, `blup_sum_g2`,
   `blup_shrinkage_factor`, `blup_b_pixel`, and `ratio_BLUP`.

5. For users with only one plot measurement, document the output as a
   "single-observation BLUP-anchored RSYC curve" or similar. Avoid saying that
   the local growth trajectory has been learned from one point.

## Short answer on which file to show first

Do not point the other assistant only at
`K:/_PROJECTS/RSYC_curvePerPixel/R/9999_curveAssign.R`. Point it first at
`K:/_PROJECTS/RSYC_curvePerPixel/R/9998_blupCalibration.R`, then use
`K:/_PROJECTS/RSYC_curvePerPixel/R/9999_curveAssign.R` to show how the helper
is called inside the full RSYC pipeline.
