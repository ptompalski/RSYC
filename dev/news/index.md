# Changelog

## RSYC 0.2.0

### Model release v20260923

- Updated the packaged catalogue from model release `v20260709` to
  `v20260923`. After limiting ecological models to the 12 forested
  ecozones, the catalogue contains 27,208 rows and 42 columns. Curve
  coefficients and model availability changed, so predictions and local
  calibration results can differ from the previous package release.
- Added the raw ecological hierarchy fields `ecozone_id`,
  `ecoprovince_id`, `ecoregion_id`, and `ecodistrict_id`. They preserve
  upstream identifiers and provenance. Ecological selection through
  `strata_id` now accepts these codes as well as existing names and
  hierarchical paths; quoted ecoprovince codes preserve values such as
  `"10.1"`.
- Added canonical character `strata_code` columns to model and strata
  discovery, generated curve tables, and ecological spatial results.
  Ambiguous ecozone codes 5, 6, and 10 are reported explicitly in
  single-selection workflows rather than silently choosing a named
  subdivision.
- Relative to `v20260709`, national coverage was lost for 10
  combinations: ecological AGB for `ALNU.INC`, `LARI.LAR`, and
  `QUER.RUB`; ecological volume for `ALNU.INC`, `FRAX.NIG`, `LARI.LAR`,
  and `QUER.RUB`; tile AGB for `LARI.LAR`; and tile volume for
  `FRAX.NIG` and `LARI.LAR`. These species had relatively limited
  spatial coverage and their models had frequently caused fitting
  problems in earlier model-development runs.
- Fixed an upstream sampling bug in which a small number of samples were
  drawn from the wrong ecodistricts. This issue affected
  ecological-strata models only; tile models were unaffected.

### Interface changes

- Tile IDs, ecological area names, and hierarchical paths supplied
  through `strata_id` are now matched ignoring case.
- [`available_rsyc_models()`](https://ptompalski.github.io/RSYC/dev/reference/available_rsyc_models.md),
  [`rsyc_species()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_species.md),
  and
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_strata.md)
  now warn when a `strata_id` value matches no published curve or when a
  species code is unknown, instead of silently returning an empty table.
- [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/dev/reference/build_rsyc_dataset.md)
  now warns when requested species are omitted because they are unknown
  or have no published curve for the selected response and areas.
- [`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/dev/reference/calibrate_rsyc.md)
  now rejects negative `obs_response` values, which could previously
  produce negative calibrated curves.

### Spatial products

- Added ecological boundary release v2, aligned exactly to the
  `v20260923` national model catalogue. It contains 12 forested
  ecozones, 36 ecoprovinces, 138 ecoregions, and 672 ecodistricts in
  EPSG:3978, with hierarchy names and raw hierarchy identifiers
  preserved.
- Boundary builds now record source and output checksums and validate
  complete, one-to-one coverage of published national model strata.
- [`download_rsyc_boundaries()`](https://ptompalski.github.io/RSYC/dev/reference/download_rsyc_boundaries.md)
  now downloads from the immutable GitHub release asset `ecostrat-v2`
  instead of a development-branch file.

### Documentation

- Added a “Model validation” article summarizing how RSYC yield curves
  compare with independent ground plots, grouped by age class.
- Added an interactive “Yield curve explorer” to the package website for
  browsing published RSYC yield curves together with their validation
  results.

## RSYC 0.1.0

This is a significant update to both the published RSYC models and the
package interface. Almost all user-facing functions have been redesigned
to work with the expanded, versioned model catalogue.

### Models

- RSYC model releases are now versioned. This package version includes
  model release `v20260709`; the release is recorded in the
  `model_version` field of the model catalogue and in generated dataset
  metadata.
- Replaced the former parameter data with `RSYC_models`, a unified
  catalogue of published aboveground biomass (`agb`) and total-volume
  (`volume`) curves.
- Models can now be selected for either 150 km tiles or polygons from
  four nested levels of Canada’s ecological land classification:
  ecozone, ecoprovince, ecoregion, and ecodistrict.
- Added stable model identifiers and supporting metadata describing
  response units, model groups, geographic strata, and model releases.
- Added a downloadable CSV archive and checksum manifest so the complete
  model catalogue can be used without installing the package.

### Redesigned interface

- Redesigned
  [`predict_rsyc()`](https://ptompalski.github.io/RSYC/dev/reference/predict_rsyc.md)
  around a consistent `response`, `species`, `age`, `strata_level`, and
  `strata_id` interface. It now predicts both AGB and volume for tile
  and ecological-strata models, resolves ecological names and paths, and
  warns when ages are outside the fitted range.
- Redesigned the model-discovery workflow.
  [`available_rsyc_models()`](https://ptompalski.github.io/RSYC/dev/reference/available_rsyc_models.md),
  [`rsyc_species()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_species.md),
  and
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_strata.md)
  now query the versioned catalogue by response and geographic level.
- Updated
  [`species_codes()`](https://ptompalski.github.io/RSYC/dev/reference/species_codes.md)
  for the expanded model metadata. Removed the legacy tile-only
  `species_in_tile()` and `tiles_for_species()` helpers; use
  [`rsyc_species()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_species.md)
  and
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_strata.md)
  for both tiles and ecological strata.
- Added
  [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/dev/reference/build_rsyc_dataset.md)
  to return predictions together with the model parameters and
  provenance metadata needed to reproduce them.
- Added
  [`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/dev/reference/calibrate_rsyc.md)
  for local BLUP-based calibration of a published curve to field
  observations of AGB or volume at known stand ages. The local random
  effect is estimated conditional on the fitted model and substituted
  into the curve’s asymptote, following Tompalski et al. The adjustment
  is a shrinkage-based local level anchor, with optional safeguards
  (`apply_limits`) against implausible ratios and values.

### Spatial data and documentation

- Added
  [`rsyc_boundaries()`](https://ptompalski.github.io/RSYC/dev/reference/rsyc_boundaries.md)
  and
  [`download_rsyc_boundaries()`](https://ptompalski.github.io/RSYC/dev/reference/download_rsyc_boundaries.md)
  for obtaining the ecological polygons associated with published
  curves. Boundary downloads are cached and independently versioned.
- Updated the bundled 150 km tile grid and documented the optional
  ecological boundary data, its source, licence, and attribution
  requirements.
- Expanded examples and reference documentation for model discovery,
  prediction, mapping, downloads, citation, and licensing.
