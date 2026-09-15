
# RSYC: Remote Sensing-Based Yield Curves for Canada

RSYC provides published yield curves for aboveground biomass (AGB,
Mg/ha) and total volume (m3/ha). Curves are available for individual
species and the `generic`, `coniferous`, and `broadleaf` model groups.

Version 0.1.0 contains 28,391 curves from model release `v20260709`.
Models are available for 150 x 150 km tiles and four nested ecological
levels: ecozone, ecoprovince, ecoregion, and ecodistrict. The package
functions currently use curves fitted across Canada rather than curves
fitted for individual regions.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("ptompalski/RSYC")
```

## Estimate biomass or volume

Estimate AGB for black spruce (`PICE.MAR`) in tile H14 at stand ages 20,
60, and 120 years:

``` r
library(RSYC)
predict_rsyc("agb", "PICE.MAR", c(20, 60, 120), "tile", "H14")
```

To estimate total volume instead, set `response = "volume"`:

``` r
predict_rsyc(
  response = "volume",
  species = "PICE.MAR",
  age = c(20, 60, 120),
  strata_level = "tile",
  strata_id = "H14"
)
```

For ecological areas, the area name is enough when it occurs only once
at the chosen level:

``` r
predict_rsyc(
  response = "agb",
  species = "PICE.MAR",
  age = c(20, 60, 120),
  strata_level = "ecodistrict",
  strata_id = "Windsor Lowlands"
)
```

Some area names occur in more than one part of Canada. In those cases,
`predict_rsyc()` lists every match. Choose the intended area using the
full sequence of ecological areas shown by `rsyc_strata()`.

### Compare species and tiles

The following example estimates AGB and volume for several species,
stand ages, and tiles. Each row of `tile_inputs` describes one estimate.
All combinations shown below have a published RSYC curve.

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

### Compare ecological levels

Use the area name at the chosen ecological level when that name occurs
only once.

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

If a name occurs in several places, list the alternatives and use the
full sequence from ecozone to the selected level:

``` r
rsyc_strata("agb", "PICE.MAR", "ecodistrict") |>
  dplyr::filter(strata_name == "Muskwa")

predict_rsyc(
  "agb", "PICE.MAR", 80, "ecodistrict",
  "Boreal Cordillera/Hay-Slave Lowlands/Muskwa Plateau/Muskwa"
)
```

### Generate several complete curves

The following example produces a complete set of estimates for ages 1 to
150 for each species and area listed in `curve_inputs`:

``` r
curve_inputs <- tibble::tribble(
  ~response, ~species,    ~strata_level, ~strata_id,
  "agb",     "PICE.MAR",  "tile",       "H14",
  "agb",     "POPU.TRE",  "tile",       "F31",
  "volume",  "coniferous", "tile",       "N3"
)
curve_inputs <- curve_inputs |>
  dplyr::mutate(
    age = list(1:150),
    prediction = purrr::pmap(
      list(response, species, age, strata_level, strata_id),
      predict_rsyc
    )
  )

curve_inputs

curve_predictions <- curve_inputs |>
  tidyr::unnest(c(age, prediction))
```

See [Prediction examples](vignettes/articles/Prediction-examples.Rmd)
for a longer walkthrough, including model-availability checks.

## Find available curves

Three functions are provided to help identify which model to use:

- `available_rsyc_models()` lists individual published curves that match a
  response, species, type of area, or area name. For example, list the volume
  curves for black spruce at the ecozone level:

``` r
available_rsyc_models(
  response = "volume",
  species = "PICE.MAR",
  strata_level = "ecozone"
)
```

- `rsyc_species()` lists the species available for a selected response and
  area. It also gives each species' common name and model group. For example,
  list the AGB species available in tile H14:

``` r
rsyc_species(response = "agb", strata_level = "tile", strata_id = "H14")
```

- `rsyc_strata()` lists the areas for which models are available for a
  selected response and species. It gives both the short area name and the
  full hierarchical area identifier, which can distinguish repeated area
  names. For example, list the ecozones with volume models for black spruce:

``` r
rsyc_strata(
  response = "volume",
  species = "PICE.MAR",
  strata_level = "ecozone"
)
```

`RSYC_models` contains all 28,391 published curves and their supporting
model details. It includes curves fitted across Canada and curves fitted
for individual regions. The package functions currently use only the
Canada-wide curves. The earlier tile-only data set, `RSYC_params`, has
been removed. The tile map is still available at:

``` r
system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")
```

## Optional ecological boundary maps

The National Ecological Framework boundary maps come from a separate
source and are not included in the main package. Download them once,
then read the ecological level you need:

``` r
download_rsyc_boundaries()

tiles <- rsyc_boundaries("tile")
ecodistricts <- rsyc_boundaries("ecodistrict")
```

RSYC saves the downloaded file in its user data folder and checks that
the file is complete and unchanged. The file contains boundary maps
only, not yield curves. It is never downloaded when RSYC is installed or
loaded. Organizations that keep an approved copy elsewhere can provide
its address through the `RSYC.ecostrat_url` option.

The ecological framework was developed independently of RSYC and is
published by Agriculture and Agri-Food Canada. Contains information
licensed under the [Open Government Licence –
Canada](https://open.canada.ca/en/open-government-licence-canada).

## Combine yield curves with a map

`rsyc_product()` prepares yield estimates and the matching area
boundaries. The boundaries are stored separately so the same map shape
is not repeated for every species and stand age. By default, the
function estimates ages 1 through 150:

``` r
product <- rsyc_product(
  response = "volume",
  species = c("PICE.MAR", "POPU.TRE"),
  age = 1:200,
  strata_level = "ecodistrict"
)

product$spatial
product$curves
product$metadata
```

The `spatial` map contains `strata_id`, the ecological area names, and
the area shapes. For tiles, it contains only `strata_id` and the tile
shapes. The `curves` table records the model, area, species, stand age,
and estimated yield. The `metadata` table summarizes the units, model
version, equation, and choices used to create the results.

Use `output = "rsyc_volume.gpkg"` to save the map, yield curves, and
summary information together in one GeoPackage file.

## Model equation

All yield estimates use this form of the Chapman-Richards equation:

$$
y = b_1 e^{-b_4 \mathrm{Age}} (1 - e^{-b_2 \mathrm{Age}})^{b_3}.
$$

The curves were fitted for stand ages 1 to 150 years. RSYC warns when
asked to estimate outside this age range. Age 0 is also allowed as the
starting point of a curve.

## References

Tompalski, P., Hermosilla, T., Baral, S.K., Wulder, M.A., White, J.C.
2025. National remote sensing-derived aboveground biomass yield curves
for Canada. *Forestry: An International Journal of Forest Research*.
<https://doi.org/10.1093/forestry/cpaf067>

Tompalski, P., Wulder, M.A., White, J.C., Hermosilla, T., Riofrio, J.,
Kurz, W.A. 2024. Developing aboveground biomass yield curves for
dominant boreal tree species from time series remote sensing data.
*Forest Ecology and Management* 561, 121894.
<https://doi.org/10.1016/j.foreco.2024.121894>
