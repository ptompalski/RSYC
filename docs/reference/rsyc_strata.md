# List Areas Available in RSYC Models

List Areas Available in RSYC Models

## Usage

``` r
rsyc_strata(response = NULL, species = NULL, strata_level = NULL)
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

## Value

A table with the short area name (`strata_name`) and its full location
within Canada's ecological classification (`strata_id`).

## Examples

``` r
rsyc_strata(
  response = "volume", species = "PICE.MAR", strata_level = "ecozone"
)
#> # A tibble: 12 × 3
#>    strata_level strata_name        strata_id         
#>    <chr>        <chr>              <chr>             
#>  1 ecozone      Atlantic Maritime  Atlantic Maritime 
#>  2 ecozone      Boreal Cordillera  Boreal Cordillera 
#>  3 ecozone      Boreal Plains      Boreal Plains     
#>  4 ecozone      Boreal Shield East Boreal Shield East
#>  5 ecozone      Boreal Shield West Boreal Shield West
#>  6 ecozone      Hudson Plains      Hudson Plains     
#>  7 ecozone      Montane Cordillera Montane Cordillera
#>  8 ecozone      Pacific Maritime   Pacific Maritime  
#>  9 ecozone      Taiga Cordillera   Taiga Cordillera  
#> 10 ecozone      Taiga Plains       Taiga Plains      
#> 11 ecozone      Taiga Shield East  Taiga Shield East 
#> 12 ecozone      Taiga Shield West  Taiga Shield West 
```
