# List Available Species for a Given Tile

This function returns the species codes for which RSYC models are
available within a specified tile.

## Usage

``` r
species_in_tile(tile_id)
```

## Arguments

- tile_id:

  A character string specifying the tile ID.

## Value

A character vector of species codes available for the given tile.

## Examples

``` r
species_in_tile("B22")
#> [1] "Generic"    "Broadleaf"  "Coniferous" "PICE.MAR"   "POPU.TRE"  
#> [6] "PINU.BAN"   "ACER.SAH"   "PINU.STR"   "PINU.RES"  
```
