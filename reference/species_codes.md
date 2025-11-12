# List Available Species Codes and Names

This function returns a data frame of species codes and their
corresponding species names used in the RSYC model set. It arranges
species codes alphabetically, but promotes the meta-categories
`"Generic"`, `"Broadleaf"`, and `"Coniferous"` to the top of the list.

## Usage

``` r
species_codes()
```

## Value

A tibble with two columns: `SpeciesCode` and `SpeciesName`.

## Examples

``` r
species_codes()
#> # A tibble: 30 × 2
#>    SpeciesCode SpeciesName  
#>    <fct>       <chr>        
#>  1 Generic     Generic      
#>  2 Broadleaf   Broadleaf    
#>  3 Coniferous  Coniferous   
#>  4 ABIE.AMA    Amabilis fir 
#>  5 ABIE.BAL    Balsam fir   
#>  6 ABIE.LAS    Subalpine fir
#>  7 ACER.RUB    Red maple    
#>  8 ACER.SAH    Sugar maple  
#>  9 BETU.ALL    Yellow birch 
#> 10 BETU.PAP    White birch  
#> # ℹ 20 more rows
```
