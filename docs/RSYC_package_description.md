# RSYC: Remote Sensing-Derived Yield Curves for Canada — Package Description

Reference document prepared for use by a writing assistant working on
the RSYC data paper. It describes the model catalogue, its structure and
coverage, the spatial units used for stratification, and the R package
that distributes the models.

Package version 0.1.0. Model release `v20260709`. Maintainer: Piotr
Tompalski (<piotr.tompalski@NRCan-RNCan.gc.ca>). Copyright: His Majesty
the King in Right of Canada, as represented by the Minister of Natural
Resources Canada. License: GPL (\>= 3). Source:
<https://github.com/ptompalski/RSYC>

------------------------------------------------------------------------

## 1. What the models are

RSYC (“Remote Sensing-derived Yield Curves”) is a catalogue of published
stand-level yield curves for Canadian forests, fitted to time series of
remote sensing-derived forest attributes rather than to conventional
permanent-sample-plot inventories. Two response variables are modelled:

| Response            | Code     | Units |
|---------------------|----------|-------|
| Aboveground biomass | `agb`    | Mg/ha |
| Total volume        | `volume` | m³/ha |

### 1.1 Curve form

All curves share a single functional form — a Chapman-Richards growth
function multiplied by an exponential decline term:

\\y = b_1\\e^{-b_4\\\text{Age}}\\\left(1 -
e^{-b_2\\\text{Age}}\right)^{b_3}\\

where \\y\\ is AGB (Mg/ha) or total volume (m³/ha) and Age is stand age
in years. The stored `equation` string in the catalogue is literally
`b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3`, identical for every
row, so curves differ only through their four coefficients. The \\b_4\\
decline term allows curves to peak and then decline, which is important
for the older age classes where remote sensing time series show biomass
loss.

### 1.2 Underlying mixed-effects structure

The published coefficients come from nonlinear mixed-effects models in
which the random effects act on the asymptote parameter:

\\y\_{ijk} = (\beta_1 + b_i + b\_{ij})\\g(\text{Age}\_{ijk}) +
\epsilon\_{ijk}\\

with the unit-scale shape function

\\g(\text{Age}) = e^{-b_4\\\text{Age}}\left(1 -
e^{-b_2\\\text{Age}}\right)^{b_3}\\

Here \\\beta_1\\ is the population-level asymptote, \\b_i\\ is the
stratum-level (e.g. tile or ecoregion) random effect, and \\b\_{ij}\\ is
a finer, pixel-level random effect nested within the stratum. The value
published as `b1` for each curve is the *stratum-level asymptote*,
i.e. \\\beta_1 + b_i\\ already combined, so a bare published curve is
simply `b1 * g(age)`. The shape parameters \\b_2, b_3, b_4\\ are fixed
effects shared within a model family.

This two-level random-effect structure is what makes local calibration
possible: the variance of the remaining pixel-level effect
(\\\sigma^2_b\\, stored as `local_b1_var`) and the residual variance
(\\\sigma^2\_\epsilon\\, stored as `residual_var`) are both distributed
with the curves, so a user with local field observations can estimate
\\b\_{ij}\\ for their own stand (Section 4).

### 1.3 Age domain

Curves were fitted over stand ages 1–150 years. The catalogue’s
`age_min` and `age_max` fields span a wider nominal range (up to 600
years), but predictions outside 1–150 are extrapolation and the package
emits a warning. Age 0 is permitted as the curve origin.

------------------------------------------------------------------------

## 2. Stratification and spatial units

Each curve is fitted for one *stratum* — a spatial unit — and one
species or species group. Two independent stratification systems are
used.

### 2.1 Tile grid

A regular grid of 150 × 150 km tiles covering forested Canada. Tile
identifiers are short alphanumeric codes (`H14`, `K10`, `U7`, …). There
are 385 tiles with at least one published model. Tile polygons ship with
the package as a GeoPackage (`inst/extdata/RSYC_tiles.gpkg`, ~276 KB).

The tile grid is an arbitrary, spatially regular partition. It is
appealing for wall-to-wall mapping because every tile is the same size
and the units are not confounded with ecological gradients, but tiles
have no ecological meaning and can straddle very different forest types.

### 2.2 Ecological land classification

Four nested levels of Canada’s National Ecological Framework, from
coarsest to finest:

| Level       | Strata with published models |
|-------------|------------------------------|
| Ecozone     | 12                           |
| Ecoprovince | 101                          |
| Ecoregion   | 257                          |
| Ecodistrict | 936                          |

These are strictly nested, and `strata_id` encodes the full hierarchical
path separated by forward slashes, e.g.
`Boreal Shield East/Newfoundland/Southwestern Newfoundland/Cornerbrook`.
A short `strata_name` (the last element) is also available through the
discovery functions. Using the full hierarchical ID avoids ambiguity
when short names repeat across parents.

The ecological levels let a user trade spatial resolution against sample
size: an ecozone curve is fitted from many observations and is stable
but broad, while an ecodistrict curve is locally specific but supported
by fewer observations. Ecological boundary polygons are distributed
separately (`RSYC_ecostrat.gpkg`, ~28 MB) because of their size, and are
downloaded on demand into a user cache with SHA-256 integrity
verification.

### 2.3 National versus regional fits

The catalogue additionally distinguishes a `scale` field:

| Scale | Rows | Description |
|----|----|----|
| `national` | 19,150 | Fitted across all of Canada; stratum enters as a random effect |
| `regional` | 9,241 | Fitted within a region, with `region_id` naming the region |

Regional fits appear at the ecological levels and at a `tile_region`
level. The public package functions currently serve only the `national`
curves; the regional set is retained in the distributed table for users
and analysts who want it.

------------------------------------------------------------------------

## 3. Catalogue contents and coverage

`RSYC_models` is a table with **28,391 rows × 38 columns**, one row per
published curve. All rows have `converged`, `fit_ok`, and `publish_ok`
TRUE — curves that failed fitting or quality screening are not
distributed.

### 3.1 Coverage by response and stratification

| Response | ecozone | ecoprovince | ecoregion | ecodistrict | tile  | tile_region |
|----------|---------|-------------|-----------|-------------|-------|-------------|
| AGB      | 190     | 794         | 1,973     | 6,804       | 2,026 | 673         |
| Volume   | 230     | 1,071       | 2,623     | 9,416       | 2,030 | 561         |

Volume curves are somewhat more numerous than AGB curves at the
ecological levels, and the two are near-identical in tile coverage.

### 3.2 Species and species groups

Curves are fitted for three generic groups plus 30 individual species:

| Group                          | Rows   |
|--------------------------------|--------|
| `species` (individual species) | 17,150 |
| `generic` (all species pooled) | 5,246  |
| `coniferous`                   | 3,769  |
| `broadleaf`                    | 2,226  |

Species codes follow a four-letter genus / three-letter species
convention (`GENU.SPE`):

| Code     | Common name      | Code     | Common name         |
|----------|------------------|----------|---------------------|
| ABIE.AMA | Amabilis fir     | PICE.SIT | Sitka spruce        |
| ABIE.BAL | Balsam fir       | PINU.BAN | Jack pine           |
| ABIE.LAS | Subalpine fir    | PINU.CON | Lodgepole pine      |
| ACER.RUB | Red maple        | PINU.PON | Ponderosa pine      |
| ACER.SAH | Sugar maple      | PINU.RES | Red pine            |
| ALNU.RUB | Red alder        | PINU.STR | Eastern white pine  |
| BETU.ALL | Yellow birch     | POPU.BAL | Balsam poplar       |
| BETU.PAP | White birch      | POPU.GRA | Largetooth aspen    |
| FRAX.NIG | Black ash        | POPU.TRE | Trembling aspen     |
| LARI.LAR | Tamarack         | PSEU.MEN | Douglas-fir         |
| LARI.OCC | Western larch    | THUJ.OCC | Eastern white-cedar |
| PICE.ABI | Norway spruce    | THUJ.PLI | Western redcedar    |
| PICE.ENG | Engelmann spruce | TSUG.HET | Western hemlock     |
| PICE.GLA | White spruce     | TSUG.MER | Mountain hemlock    |
| PICE.MAR | Black spruce     |          |                     |
| PICE.RUB | Red spruce       |          |                     |

Coverage is uneven and follows species abundance: within the tile
stratification, `generic` (770 curves), `coniferous` (732), black spruce
(648), `broadleaf` (414), and trembling aspen (318) are the best
represented, while restricted-range species such as ponderosa pine or
Norway spruce are available for only a handful of strata. This is an
important caveat for the paper — a species-by-stratum combination is
published only where the underlying observations supported a converged,
screened fit, so users must query availability rather than assume it.

Sample sizes behind individual curves span several orders of magnitude:
`n_obs` ranges from 410 to about 106 million observations, and `n_units`
(distinct forest units contributing) from 10 to about 2.6 million.

### 3.3 Column groups in `RSYC_models`

| Group | Columns | Meaning |
|----|----|----|
| Identity | `model_id`, `model_version` | Unique curve name; RSYC release |
| Response | `response`, `response_units` | `agb` (Mg/ha) or `volume` (m³/ha) |
| Stratum | `strata_type`, `strata_level`, `strata_id` | Stratification system, level, and hierarchical ID |
| Scale | `scale`, `region_id` | National vs regional fit; region name |
| Species | `species`, `model_group` | Species code; `generic`/`coniferous`/`broadleaf`/`species` |
| Curve | `equation`, `age_min`, `age_max` | Functional form and valid age range |
| Coefficients | `b1`, `b2`, `b3`, `b4` | Chapman-Richards parameters; `b1` is the stratum-level asymptote |
| Uncertainty | `b1_se`–`b4_se`, `sigma` | Coefficient standard errors; residual SD |
| Variance components | `parent_b1_random_effect`, `parent_b1_var`, `local_b1_var`, `residual_var` | Stratum random effect and its variance; pixel-level random-effect variance; residual variance — the ingredients for local calibration |
| Fit diagnostics | `has_cor_struct`, `has_var_struct`, `component_ok`, `component_message` | Correlation/variance structures used; component extraction checks |
| Screening | `n_obs`, `n_units`, `converged`, `singular_or_boundary`, `fit_ok`, `publish_ok`, `model_message` | Sample sizes and the quality gates applied before publication |

All published curves have finite, strictly positive `local_b1_var` and
`residual_var`, so every distributed curve is eligible for local
calibration.

Asymptote magnitudes differ greatly across strata and species, as
expected: `b1` ranges from 0.03 to about 1,160 for AGB and from 7.8 to
about 3,507 for volume. The extreme low values correspond to sparse,
marginal strata and are a reminder that individual curves should be
screened for plausibility by the user.

------------------------------------------------------------------------

## 4. The R package

The package’s role is to make the catalogue usable without requiring the
user to re-derive the models: it bundles the parameter table, provides a
consistent prediction interface, exposes the spatial boundary
geometries, and implements the local calibration procedure.

Dependencies are deliberately light — `digest`, `glue`, `magrittr`, and
`tibble` are the only imports; `sf`, `dplyr`, `ggplot2` and others are
suggested and needed only for the spatial and plotting workflows.

Installation:

``` r
remotes::install_github("ptompalski/RSYC")
```

Model parameters are also downloadable as plain CSV (`RSYC_models.zip`)
with a checksum manifest, so the models can be used outside R entirely.

### 4.1 Prediction

**`predict_rsyc(response, species, age, strata_level, strata_id)`** is
the main entry point. It selects the single national curve matching the
requested response, species, and stratum, and evaluates it at the
supplied ages. It returns a numeric vector in Mg/ha or m³/ha. Ages
outside the 1–150 fitted range trigger an extrapolation warning. Because
the signature is uniform across all stratifications, the same call
pattern works for a tile or any of the four ecological levels — only
`strata_level` and `strata_id` change. This makes it straightforward to
compare, for one species and location, how the estimated trajectory
changes as the stratification is refined from ecozone to ecodistrict.

**`build_rsyc_dataset(response, species, age = 1:150, strata_level, strata_id, output, overwrite, cache_dir, quiet)`**
generates complete curve datasets joined to the corresponding boundary
geometry. It returns three components: `spatial` (an `sf` object of
boundaries), `curves` (a long table of `model_id`, `strata_id`,
`species`, `age`, `prediction`), and `metadata` (a summary of what was
produced). Optionally it writes the result directly to a GeoPackage.
This is the function to reference when describing how the curves can be
turned into mappable, wall-to-wall products.

### 4.2 Discovery

Because coverage is incomplete and uneven, the package provides four
query functions so that users determine availability empirically rather
than guessing:

| Function | Purpose |
|----|----|
| `available_rsyc_models(response, species, strata_level, strata_id)` | Filter the catalogue on any combination of criteria; returns the matching curve records with `model_id`, units, stratum fields, species, group, and version |
| `rsyc_species(response, strata_level, strata_id)` | Which species have curves for a given response and area; returns code, common name, and model group |
| `rsyc_strata(response, species, strata_level)` | Which areas have curves for a given response and species; returns level, short name, and full hierarchical ID |
| `species_codes(response, strata_level)` | The species code / common-name lookup table (33 entries including the three generic groups) |

All arguments are optional and default to NULL (no filtering), so these
compose naturally into an availability-checking workflow.

### 4.3 Spatial boundaries

**`rsyc_boundaries(strata_level, cache_dir, must_exist)`** returns the
polygons for any stratification level as an `sf` object with `strata_id`
and geometry. Tile boundaries are bundled with the package; ecological
boundaries, being much larger, are fetched on demand.

**`download_rsyc_boundaries(cache_dir, overwrite, quiet, url)`**
downloads the ecological GeoPackage to a persistent user cache and
verifies it against a SHA-256 checksum. Boundary downloads are versioned
and cached independently of the model table, so boundaries and models
can be updated separately.

### 4.4 Local calibration — `calibrate_rsyc()`

This is the package’s most substantive methodological contribution
beyond simple parameter distribution, and warrants explicit treatment in
the paper.

**Motivation.** The published curves describe the *average* trajectory
for a stratum–species combination. A user with field measurements for a
particular stand will often find that the stand sits systematically
above or below that average. Local calibration adjusts the published
curve toward the local observations without discarding the information
in the national fit.

**Method.** The procedure estimates the remaining pixel-level random
effect \\b\_{ij}\\ on the asymptote, conditional on the already-fitted
model, as a best linear unbiased predictor (BLUP). Given observations
\\y_j\\ at ages with unit-scale shape values \\g_j = g(\text{age}\_j)\\:

\\b = \frac{\sum_j g_j\\(y_j - b_1 g_j)}{\sum_j g_j^2 +
\sigma^2\_\epsilon / \sigma^2_b}\\

where \\\sigma^2_b\\ is the pixel-level random-effect variance
(`local_b1_var`) and \\\sigma^2\_\epsilon\\ is the residual variance
(`residual_var`). The calibrated curve substitutes the adjusted
asymptote into the same equation,

\\y = (b_1 + b)\\g(\text{Age})\\

which is exactly equivalent to rescaling the published curve by the
multiplicative ratio

\\\text{ratio}\_{\text{BLUP}} = \frac{b_1 + b}{b_1}\\

The variance-ratio term \\\sigma^2\_\epsilon / \sigma^2_b\\ in the
denominator is the shrinkage penalty: when local evidence is weak — few
observations, or observations at ages where \\g\\ is small and the curve
is poorly identified — the estimate is pulled toward zero adjustment,
and the calibrated curve reverts toward the published one. The
accompanying

\\\text{shrinkage factor} = \frac{\sum_j g_j^2}{\sum_j g_j^2 +
\sigma^2\_\epsilon / \sigma^2_b} \in \[0, 1\]\\

is reported so users can see how much weight their data actually
carried; values near 0 indicate the adjustment was almost entirely
shrunk away.

**Interpretation caveat, important for the paper.** Only the asymptote
is adjusted; the shape parameters \\b_2, b_3, b_4\\ are untouched.
Calibration therefore rescales the *level* of the curve, not its shape
or the timing of culmination. With a single observation, the result
should be described as a *single-observation BLUP-anchored RSYC curve* —
a level anchor — and explicitly **not** as a local growth trajectory
learned from the data. This distinction should be preserved in the
paper’s wording.

**Safeguards.** Production experience (notably with tamarack, where
extreme variance ratios produced implausible adjustments) motivated
three optional limits, all active by default via `apply_limits = TRUE`:

| Safeguard | Default | Behaviour |
|----|----|----|
| `random_effect_limit_sd` | 3 | The estimated random effect is clipped to ±3 SD of the pixel-level random-effect distribution (central 99.7%) |
| `ratio_limit` | 5 | If the calibration ratio exceeds this, the adjustment is discarded entirely and the bare curve is returned |
| `value_limit` | 1000 | Any calibrated value exceeding this falls back to the bare curve at that age |

Setting `apply_limits = FALSE` returns the raw shrunk BLUP.

**Signature and return.**
`calibrate_rsyc(response, species, strata_level, strata_id, obs_age, obs_response, predict_age = NULL, apply_limits = TRUE, random_effect_limit_sd = 3, ratio_limit = 5, value_limit = 1000)`
returns a list containing `predictions` (a table of `age`, calibrated
`value`, and `value_uncalibrated` so the two can be compared directly),
`ratio_blup`, `b_pixel`, `shrinkage_factor`, `n_obs`, three flags
recording whether each safeguard was triggered (`random_effect_limited`,
`ratio_limited`, `value_limited`), and `model_id`. The transparency of
these diagnostics is deliberate: a user can always see whether their
calibration was meaningfully data-driven or was overridden by a
safeguard.

Example:

``` r
calibrate_rsyc(
  response     = "agb",
  species      = "PICE.MAR",
  strata_level = "tile",
  strata_id    = "H14",
  obs_age      = c(45, 70),
  obs_response = c(120, 165)
)
```

------------------------------------------------------------------------

## 5. Documentation and reference organisation

The pkgdown reference index groups the API into four sections, which
mirrors the intended workflow:

1.  **Predict yield and build datasets** —
    [`predict_rsyc()`](https://ptompalski.github.io/RSYC/reference/predict_rsyc.md),
    [`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/reference/calibrate_rsyc.md),
    [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md)
2.  **Discover available models** —
    [`available_rsyc_models()`](https://ptompalski.github.io/RSYC/reference/available_rsyc_models.md),
    [`rsyc_species()`](https://ptompalski.github.io/RSYC/reference/rsyc_species.md),
    [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md),
    [`species_codes()`](https://ptompalski.github.io/RSYC/reference/species_codes.md)
3.  **Access spatial boundaries** —
    [`rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/rsyc_boundaries.md),
    [`download_rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/download_rsyc_boundaries.md)
4.  **Package datasets** — `RSYC_models`, `RSYC_tiles`

Three long-form articles accompany the package:

| Article | Content |
|----|----|
| *Prediction examples* | Single and multi-species prediction; comparing across ecological levels; checking availability |
| *Model parameters* | Structure of the `RSYC_models` table; hierarchical `strata_id` vs short `strata_name`; coefficient and uncertainty interpretation |
| *Local calibration* | Rationale and derivation for [`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/reference/calibrate_rsyc.md); the BLUP and shrinkage mathematics; single- vs multiple-observation behaviour; interpretation as a level anchor |

------------------------------------------------------------------------

## 6. Version history relevant to the paper

Version 0.1.0 represents a substantial redesign accompanying the
expanded model catalogue. Relative to earlier internal versions:

- Model releases are now explicitly versioned (`v20260709`) and AGB and
  volume curves are unified in a single catalogue table.
- Stratification was extended from tiles alone to tiles plus four nested
  ecological levels.
- [`predict_rsyc()`](https://ptompalski.github.io/RSYC/reference/predict_rsyc.md)
  was given a consistent
  `(response, species, age, strata_level, strata_id)` signature that is
  independent of stratification system.
- The discovery functions
  ([`available_rsyc_models()`](https://ptompalski.github.io/RSYC/reference/available_rsyc_models.md),
  [`rsyc_species()`](https://ptompalski.github.io/RSYC/reference/rsyc_species.md),
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md))
  were introduced, replacing the older ad hoc helpers
  `species_in_tile()` and `tiles_for_species()`.
- [`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/reference/calibrate_rsyc.md)
  and
  [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md)
  are new.
- Boundary access and versioned, cached downloads were added.
- Parameters are additionally distributed as CSV with a checksum
  manifest for offline and non-R use.

------------------------------------------------------------------------

## 7. Key references

- Tompalski, P. et al. (2025). National remote sensing-derived
  aboveground biomass yield curves for Canada. *Forestry: An
  International Journal of Forest Research*.
  <https://doi.org/10.1093/forestry/cpaf067>
- Tompalski, P. et al. (2024). Developing aboveground biomass yield
  curves for dominant boreal tree species from time series remote
  sensing data. *Forest Ecology and Management* 561, 121894.
  <https://doi.org/10.1016/j.foreco.2024.121894>

------------------------------------------------------------------------

## 8. Points worth emphasising or checking when drafting

- **Coverage is conditional, not guaranteed.** A species–stratum curve
  exists only where the data supported a converged, screened fit. The
  paper should state the screening criteria (`converged`, `fit_ok`,
  `publish_ok`, plus `singular_or_boundary` checks) explicitly.
- **Two parallel stratifications with different logic.** Tiles are
  spatially regular but ecologically arbitrary; the ecological hierarchy
  is ecologically meaningful but spatially uneven. The paper should give
  guidance on which to use when.
- **`b1` is not \\\beta_1\\.** It is the stratum-level asymptote
  \\\beta_1 + b_i\\. Misreading this would propagate into any
  independent reimplementation.
- **Calibration adjusts level only.** See Section 4.4.
- **Regional fits are distributed but not exposed through the API.** If
  the paper documents the full table, this asymmetry should be
  mentioned.
- **The extreme `b1` values** (as low as 0.03 for AGB) suggest some
  published curves are near-degenerate; if the paper makes quality
  claims, this is worth investigating and characterising rather than
  leaving implicit.
