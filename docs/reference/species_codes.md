# List Available Species Codes and Names

List the species codes and common names represented in the published
RSYC curves. Broad groups are listed first, followed by individual
species.

## Usage

``` r
species_codes(response = NULL, strata_level = NULL)
```

## Arguments

- response:

  Forest measure to include: `"agb"` for aboveground biomass or
  `"volume"` for total volume. By default, both are included.

- strata_level:

  Type of area to include. By default, all types are included.

## Value

A table with the species code and common name.

## Examples

``` r
species_codes()
#> # A tibble: 33 × 2
#>    SpeciesCode SpeciesName  
#>    <chr>       <chr>        
#>  1 generic     Generic      
#>  2 coniferous  Coniferous   
#>  3 broadleaf   Broadleaf    
#>  4 ABIE.AMA    Amabilis fir 
#>  5 ABIE.BAL    Balsam fir   
#>  6 ABIE.LAS    Subalpine fir
#>  7 ACER.RUB    Red maple    
#>  8 ACER.SAH    Sugar maple  
#>  9 ALNU.RUB    Red alder    
#> 10 BETU.ALL    Yellow birch 
#> # ℹ 23 more rows
species_codes(response = "volume", strata_level = "ecoregion")
#> # A tibble: 32 × 2
#>    SpeciesCode SpeciesName  
#>    <chr>       <chr>        
#>  1 generic     Generic      
#>  2 coniferous  Coniferous   
#>  3 broadleaf   Broadleaf    
#>  4 ABIE.AMA    Amabilis fir 
#>  5 ABIE.BAL    Balsam fir   
#>  6 ABIE.LAS    Subalpine fir
#>  7 ACER.RUB    Red maple    
#>  8 ACER.SAH    Sugar maple  
#>  9 ALNU.RUB    Red alder    
#> 10 BETU.ALL    Yellow birch 
#> # ℹ 22 more rows
```
