# List Published RSYC Models

List the published Canada-wide curves that match a forest measure,
species, type of area, or area name. Leave a choice as `NULL` to include
all of its available values.

## Usage

``` r
available_rsyc_models(
  response = NULL,
  species = NULL,
  strata_level = NULL,
  strata_id = NULL
)
```

## Arguments

- response:

  One or both forest measures: `"agb"` for aboveground biomass and
  `"volume"` for total volume. The default includes both.

- species:

  One or more species codes or broad groups. Uppercase and lowercase
  letters are treated the same. The default includes all species.

- strata_level:

  One or more types of area: `"tile"`, `"ecozone"`, `"ecoprovince"`,
  `"ecoregion"`, or `"ecodistrict"`. The default includes all types.

- strata_id:

  One or more tile IDs, ecological area names, or full sequences of
  ecological area names. The default includes all areas.

## Value

A table with one row for each published curve that matches the choices.

## Examples

``` r
available_rsyc_models(
  response = "volume", species = "PICE.MAR", strata_level = "tile"
)
#> # A tibble: 324 × 10
#>    model_id         response response_units strata_type strata_level strata_name
#>    <chr>            <chr>    <chr>          <chr>       <chr>        <chr>      
#>  1 rsyc_volume_nat… volume   m3/ha          tile        tile         A24        
#>  2 rsyc_volume_nat… volume   m3/ha          tile        tile         A25        
#>  3 rsyc_volume_nat… volume   m3/ha          tile        tile         B21        
#>  4 rsyc_volume_nat… volume   m3/ha          tile        tile         B22        
#>  5 rsyc_volume_nat… volume   m3/ha          tile        tile         B23        
#>  6 rsyc_volume_nat… volume   m3/ha          tile        tile         B24        
#>  7 rsyc_volume_nat… volume   m3/ha          tile        tile         B25        
#>  8 rsyc_volume_nat… volume   m3/ha          tile        tile         B26        
#>  9 rsyc_volume_nat… volume   m3/ha          tile        tile         C15        
#> 10 rsyc_volume_nat… volume   m3/ha          tile        tile         C16        
#> # ℹ 314 more rows
#> # ℹ 4 more variables: strata_id <chr>, species <chr>, model_group <chr>,
#> #   model_version <chr>
```
