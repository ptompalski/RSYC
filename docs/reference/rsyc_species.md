# List Species Available in RSYC Models

List Species Available in RSYC Models

## Usage

``` r
rsyc_species(response = NULL, strata_level = NULL, strata_id = NULL)
```

## Arguments

- response:

  One or both forest measures: `"agb"` for aboveground biomass and
  `"volume"` for total volume. The default includes both.

- strata_level:

  One or more types of area: `"tile"`, `"ecozone"`, `"ecoprovince"`,
  `"ecoregion"`, or `"ecodistrict"`. The default includes all types.

- strata_id:

  One or more tile IDs, ecological area names, or full sequences of
  ecological area names. The default includes all areas.

## Value

A table giving each species code, common name, and broad model group.

## Examples

``` r
rsyc_species(response = "agb", strata_level = "ecoregion")
#> # A tibble: 29 × 3
#>    species    species_name  model_group
#>    <chr>      <chr>         <chr>      
#>  1 generic    Generic       generic    
#>  2 coniferous Coniferous    coniferous 
#>  3 ABIE.AMA   Amabilis fir  species    
#>  4 ABIE.BAL   Balsam fir    species    
#>  5 ABIE.LAS   Subalpine fir species    
#>  6 ACER.RUB   Red maple     species    
#>  7 ACER.SAH   Sugar maple   species    
#>  8 ALNU.RUB   Red alder     species    
#>  9 BETU.ALL   Yellow birch  species    
#> 10 BETU.PAP   White birch   species    
#> # ℹ 19 more rows
```
