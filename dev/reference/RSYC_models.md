# Published RSYC Yield-Curve Data

A table containing one row for each published remote sensing-based yield
curve. It includes aboveground biomass and total-volume curves fitted
across Canada and within individual regions. Curves are available for
tiles and four levels of Canada's ecological land classification.

## Usage

``` r
RSYC_models
```

## Format

A table with 27,208 rows and 42 columns:

- model_id, model_version:

  Unique name for the curve and the RSYC release in which it was
  published.

- response, response_units:

  Forest measure (`agb` or `volume`) and its units.

- strata_type, strata_level, strata_id:

  Type and name of the area represented by the curve.

- ecozone_id, ecoprovince_id, ecoregion_id, ecodistrict_id:

  Raw identifiers for the four levels of the ecological hierarchy.
  `ecoprovince_id` is stored as character; the other three are integers.
  Fields above the row's ecological level, and all four fields for tile
  rows, may be missing.

- scale, region_id:

  Whether the curve was fitted across Canada or within a region, and the
  region name where applicable.

- species, model_group:

  Species code or broad species group.

- equation, age_min, age_max:

  Curve equation and age range. Published RSYC curves were fitted for
  stand ages 1 to 150 years.

- b1, b2, b3, b4:

  Chapman-Richards curve coefficients.

- b1_se, b2_se, b3_se, b4_se, sigma:

  Measures of uncertainty around the fitted curve.

- parent_b1_random_effect, parent_b1_var, local_b1_var, residual_var:

  Variance components and parent effects used by local calibration and
  retained for model provenance.

- has_cor_struct, has_var_struct, component_ok, component_message:

  Checks recorded while each curve was fitted.

- n_obs, n_units, converged, singular_or_boundary, fit_ok, publish_ok,
  model_message:

  Number of observations and forest units, together with checks used to
  decide whether the curve was suitable for publication.

## Source

RSYC-Canada model products, version `v20260923`, upstream Git commit
`c799aba24b5d99a6a7953a4dcab1dd73b0925c2c`; source RDS SHA-256
`193ebfc1f3279ffc278d84c917d206b4b4bcaeae95f38acf25d9c84a040bd1d5`.

## Examples

``` r
subset(
  RSYC_models,
  response == "volume" & strata_level == "ecozone" & species == "PICE.MAR"
)
#> # A tibble: 16 × 42
#>    model_id       model_version response response_units strata_type strata_level
#>    <chr>          <chr>         <chr>    <chr>          <chr>       <chr>       
#>  1 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  2 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  3 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  4 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  5 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  6 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  7 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  8 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#>  9 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 10 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 11 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 12 rsyc_volume_n… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 13 rsyc_volume_r… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 14 rsyc_volume_r… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 15 rsyc_volume_r… v20260923     volume   m3/ha          eco_strata  ecozone     
#> 16 rsyc_volume_r… v20260923     volume   m3/ha          eco_strata  ecozone     
#> # ℹ 36 more variables: strata_id <chr>, ecozone_id <int>, ecoprovince_id <chr>,
#> #   ecoregion_id <int>, ecodistrict_id <int>, scale <chr>, region_id <chr>,
#> #   species <chr>, model_group <chr>, equation <chr>, age_min <int>,
#> #   age_max <int>, b1 <dbl>, b2 <dbl>, b3 <dbl>, b4 <dbl>, b1_se <dbl>,
#> #   b2_se <dbl>, b3_se <dbl>, b4_se <dbl>, sigma <dbl>,
#> #   parent_b1_random_effect <dbl>, parent_b1_var <dbl>, local_b1_var <dbl>,
#> #   residual_var <dbl>, has_cor_struct <lgl>, has_var_struct <lgl>, …
```
