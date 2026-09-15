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

A table with 28,391 rows and 38 columns:

- model_id, model_version:

  Unique name for the curve and the RSYC release in which it was
  published.

- response, response_units:

  Forest measure (`agb` or `volume`) and its units.

- strata_type, strata_level, strata_id:

  Type and name of the area represented by the curve.

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

  Values retained for possible future adjustment of curves with local
  data.

- has_cor_struct, has_var_struct, component_ok, component_message:

  Checks recorded while each curve was fitted.

- n_obs, n_units, converged, singular_or_boundary, fit_ok, publish_ok,
  model_message:

  Number of observations and forest units, together with checks used to
  decide whether the curve was suitable for publication.

## Source

RSYC-Canada model products, version `v20260709`.

## Examples

``` r
subset(
  RSYC_models,
  response == "volume" & strata_level == "ecozone" & species == "PICE.MAR"
)
#> # A tibble: 20 × 38
#>    model_id       model_version response response_units strata_type strata_level
#>    <chr>          <chr>         <chr>    <chr>          <chr>       <chr>       
#>  1 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  2 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  3 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  4 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  5 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  6 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  7 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  8 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#>  9 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 10 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 11 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 12 rsyc_volume_n… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 13 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 14 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 15 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 16 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 17 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 18 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 19 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> 20 rsyc_volume_r… v20260709     volume   m3/ha          eco_strata  ecozone     
#> # ℹ 32 more variables: strata_id <chr>, scale <chr>, region_id <chr>,
#> #   species <chr>, model_group <chr>, equation <chr>, age_min <int>,
#> #   age_max <int>, b1 <dbl>, b2 <dbl>, b3 <dbl>, b4 <dbl>, b1_se <dbl>,
#> #   b2_se <dbl>, b3_se <dbl>, b4_se <dbl>, sigma <dbl>,
#> #   parent_b1_random_effect <dbl>, parent_b1_var <dbl>, local_b1_var <dbl>,
#> #   residual_var <dbl>, has_cor_struct <lgl>, has_var_struct <lgl>,
#> #   component_ok <lgl>, component_message <chr>, n_obs <int>, n_units <int>, …
```
