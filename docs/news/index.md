# Changelog

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
  [`predict_rsyc()`](https://ptompalski.github.io/RSYC/reference/predict_rsyc.md)
  around a consistent `response`, `species`, `age`, `strata_level`, and
  `strata_id` interface. It now predicts both AGB and volume for tile
  and ecological-strata models, resolves ecological names and paths, and
  warns when ages are outside the fitted range.
- Redesigned the model-discovery workflow.
  [`available_rsyc_models()`](https://ptompalski.github.io/RSYC/reference/available_rsyc_models.md),
  [`rsyc_species()`](https://ptompalski.github.io/RSYC/reference/rsyc_species.md),
  and
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md)
  now query the versioned catalogue by response and geographic level.
- Updated
  [`species_codes()`](https://ptompalski.github.io/RSYC/reference/species_codes.md)
  for the expanded model metadata. Removed the legacy tile-only
  `species_in_tile()` and `tiles_for_species()` helpers; use
  [`rsyc_species()`](https://ptompalski.github.io/RSYC/reference/rsyc_species.md)
  and
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md)
  for both tiles and ecological strata.
- Added
  [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md)
  to return predictions together with the model parameters and
  provenance metadata needed to reproduce them.

### Spatial data and documentation

- Added
  [`rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/rsyc_boundaries.md)
  and
  [`download_rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/download_rsyc_boundaries.md)
  for obtaining the ecological polygons associated with published
  curves. Boundary downloads are cached and independently versioned.
- Updated the bundled 150 km tile grid and documented the optional
  ecological boundary data, its source, licence, and attribution
  requirements.
- Expanded examples and reference documentation for model discovery,
  prediction, mapping, downloads, citation, and licensing.
