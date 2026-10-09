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

  One or more tile IDs, ecological area names or paths, or ecological
  codes. Tile IDs, names, and paths are matched ignoring case. Numeric
  values and numeric-looking character values are interpreted as codes
  when no name or path matches. Code searches require exactly one
  ecological `strata_level`. Quote ecoprovince codes such as `"10.1"`.
  Values that match no published curve produce a warning. The default
  includes all areas.

## Value

A table giving each species code, common name, and broad model group.

## Examples

``` r
rsyc_species(response = "agb", strata_level = "ecoregion")
#> # A tibble: 31 × 3
#>    species    species_name  model_group
#>    <chr>      <chr>         <chr>      
#>  1 generic    Generic       generic    
#>  2 coniferous Coniferous    coniferous 
#>  3 broadleaf  Broadleaf     broadleaf  
#>  4 ABIE.AMA   Amabilis fir  species    
#>  5 ABIE.BAL   Balsam fir    species    
#>  6 ABIE.LAS   Subalpine fir species    
#>  7 ACER.RUB   Red maple     species    
#>  8 ACER.SAH   Sugar maple   species    
#>  9 ALNU.RUB   Red alder     species    
#> 10 BETU.ALL   Yellow birch  species    
#> # ℹ 21 more rows
```
