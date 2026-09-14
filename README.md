# RSYC: Remote Sensing-Based Yield Curves for Canada

RSYC provides published yield curves for aboveground biomass (AGB, Mg/ha) and
total volume (m3/ha). Curves are available for individual species and the
`generic`, `coniferous`, and `broadleaf` model groups.

Version 0.1.0 contains 28,391 curves from model release `v20260709`. Models are
available for 150 x 150 km tiles and four nested ecological levels: ecozone,
ecoprovince, ecoregion, and ecodistrict. The public prediction and discovery
interfaces currently use national models.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("ptompalski/RSYC")
```

## Prediction

Predict national tile AGB with the required response-first signature:

``` r
library(RSYC)
predict_rsyc("agb", "PICE.MAR", c(20, 60, 120), "tile", "H14")
```

Select total volume with `response = "volume"`:

``` r
predict_rsyc(
  response = "volume",
  species = "PICE.MAR",
  age = c(20, 60, 120),
  strata_level = "tile",
  strata_id = "H14"
)
```

For ecosystem models, a short name is sufficient when it identifies one
matching stratum:

``` r
predict_rsyc(
  response = "agb",
  species = "PICE.MAR",
  age = c(20, 60, 120),
  strata_level = "ecodistrict",
  strata_id = "Windsor Lowlands"
)
```

Some names occur under multiple parent strata. In those cases,
`predict_rsyc()` reports every match and asks for one of the full hierarchical
paths returned by `rsyc_strata()`.

Scale is intentionally not exposed by these functions; all selections are
restricted to national models.

### Compare species and tiles

Build a tibble containing one prediction request per row, then use
`purrr::pmap_dbl()` to pass its columns to `predict_rsyc()`. The combinations
below are all present in the published model catalog.

``` r
tile_inputs <- tidyr::crossing(
  response = c("agb", "volume"),
  species = c("PICE.MAR", "POPU.TRE", "coniferous"),
  age = c(20, 60, 120),
  strata_level = "tile",
  strata_id = c("H14", "F31")
) |>
  dplyr::mutate(
    prediction = purrr::pmap_dbl(
      list(response, species, age, strata_level, strata_id),
      predict_rsyc
    )
  )

tile_inputs
```

### Compare nested ecosystem levels

Use the name at the requested ecosystem level when it is unambiguous.

``` r
eco_inputs <- tibble::tribble(
  ~response, ~species,   ~age, ~strata_level, ~strata_id,
  "agb",     "PICE.MAR", 80,  "ecozone",
    "Atlantic Maritime",
  "agb",     "PICE.MAR", 80,  "ecoprovince",
    "Appalachian-Acadian Highlands",
  "agb",     "PICE.MAR", 80,  "ecoregion",
    "Appalachians",
  "agb",     "PICE.MAR", 80,  "ecodistrict",
    "Windsor Lowlands"
)

eco_inputs <- eco_inputs |>
  dplyr::mutate(
    prediction = purrr::pmap_dbl(
      list(response, species, age, strata_level, strata_id),
      predict_rsyc
    )
  )

eco_inputs
```

If a name is duplicated, inspect the alternatives and use the canonical path:

``` r
rsyc_strata("agb", "PICE.MAR", "ecodistrict") |>
  dplyr::filter(strata_name == "Muskwa")

predict_rsyc(
  "agb", "PICE.MAR", 80, "ecodistrict",
  "Boreal Cordillera/Hay-Slave Lowlands/Muskwa Plateau/Muskwa"
)
```

### Generate complete curves from a tibble

Use list-columns when each row represents a model and should return predictions
for several ages:

``` r
curve_inputs <- tibble::tribble(
  ~response, ~species,    ~strata_level, ~strata_id,
  "agb",     "PICE.MAR",  "tile",       "H14",
  "agb",     "POPU.TRE",  "tile",       "F31",
  "volume",  "coniferous", "tile",       "N3"
)
curve_inputs <- curve_inputs |>
  dplyr::mutate(
    age = list(1:200),
    prediction = purrr::pmap(
      list(response, species, age, strata_level, strata_id),
      predict_rsyc
    )
  )

curve_inputs

curve_predictions <- curve_inputs |>
  tidyr::unnest(c(age, prediction))
```

See [Prediction examples](vignettes/articles/Prediction-examples.Rmd) for a
longer walkthrough, including model-availability checks.

## Finding available models

``` r
available_rsyc_models(
  response = "volume",
  species = "PICE.MAR",
  strata_level = "ecozone"
)

rsyc_species(response = "agb", strata_level = "ecoregion")
rsyc_strata(response = "volume", species = "PICE.MAR", strata_level = "ecozone")
```

The complete, cleaned package-facing contract is exported as `RSYC_models`.
It retains regional rows for provenance and future development, although the
current public functions operate only on national rows. The earlier
`RSYC_params` tile-only dataset has been removed. The tile grid is still
available at:

``` r
system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")
```

## Model equation

All predictions use the four-parameter declining Chapman-Richards equation:

$$
y = b_1 e^{-b_4 \mathrm{Age}} (1 - e^{-b_2 \mathrm{Age}})^{b_3}.
$$

The published calibration range is 1-600 years. Predictions outside this range
produce an extrapolation warning.

## References

Tompalski, P., Hermosilla, T., Baral, S.K., Wulder, M.A., White, J.C. 2025.
National remote sensing-derived aboveground biomass yield curves for Canada.
*Forestry: An International Journal of Forest Research*.
<https://doi.org/10.1093/forestry/cpaf067>

Tompalski, P., Wulder, M.A., White, J.C., Hermosilla, T., Riofrio, J., Kurz,
W.A. 2024. Developing aboveground biomass yield curves for dominant boreal
tree species from time series remote sensing data. *Forest Ecology and
Management* 561, 121894. <https://doi.org/10.1016/j.foreco.2024.121894>
