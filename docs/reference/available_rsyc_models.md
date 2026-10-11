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
  Unknown species codes produce a warning.

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

A table with one row for each published curve that matches the choices.
`strata_code` is the canonical character code for ecological rows and
`NA` for tiles.

## Details

Character `strata_id` values are matched as names or paths before
numeric-looking values are interpreted as ecological codes. Ecozone
codes 5 and 6 return both published named subdivisions. Ecozone code 10
is also ambiguous, but currently has no published national model rows.

## Examples

``` r
available_rsyc_models(
  response = "volume", species = "PICE.MAR", strata_level = "tile"
)
#> # A tibble: 344 × 11
#>    model_id         response response_units strata_type strata_level strata_name
#>    <chr>            <chr>    <chr>          <chr>       <chr>        <chr>      
#>  1 rsyc_volume_nat… volume   m3/ha          tile        tile         A24        
#>  2 rsyc_volume_nat… volume   m3/ha          tile        tile         A25        
#>  3 rsyc_volume_nat… volume   m3/ha          tile        tile         A26        
#>  4 rsyc_volume_nat… volume   m3/ha          tile        tile         B21        
#>  5 rsyc_volume_nat… volume   m3/ha          tile        tile         B22        
#>  6 rsyc_volume_nat… volume   m3/ha          tile        tile         B23        
#>  7 rsyc_volume_nat… volume   m3/ha          tile        tile         B24        
#>  8 rsyc_volume_nat… volume   m3/ha          tile        tile         B25        
#>  9 rsyc_volume_nat… volume   m3/ha          tile        tile         B26        
#> 10 rsyc_volume_nat… volume   m3/ha          tile        tile         B27        
#> # ℹ 334 more rows
#> # ℹ 5 more variables: strata_id <chr>, strata_code <chr>, species <chr>,
#> #   model_group <chr>, model_version <chr>
available_rsyc_models(
  response = "agb", strata_level = "ecoprovince", strata_id = "7.1"
)
#> # A tibble: 15 × 11
#>    model_id         response response_units strata_type strata_level strata_name
#>    <chr>            <chr>    <chr>          <chr>       <chr>        <chr>      
#>  1 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  2 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  3 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  4 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  5 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  6 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  7 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  8 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#>  9 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> 10 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> 11 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> 12 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> 13 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> 14 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> 15 rsyc_agb_nation… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> # ℹ 5 more variables: strata_id <chr>, strata_code <chr>, species <chr>,
#> #   model_group <chr>, model_version <chr>
```
