# List Species Available in a Tile

List Species Available in a Tile

## Usage

``` r
species_in_tile(tile_id, response = "agb")
```

## Arguments

- tile_id:

  One tile ID.

- response:

  Forest measure: `"agb"` for aboveground biomass or `"volume"` for
  total volume.

## Value

The species codes and broad groups that have a published curve in the
chosen tile.

## Examples

``` r
species_in_tile("H14")
#> [1] "PICE.MAR"   "PINU.BAN"   "POPU.TRE"   "broadleaf"  "coniferous"
#> [6] "generic"   
species_in_tile("H14", response = "volume")
#> [1] "PICE.MAR"   "PINU.BAN"   "POPU.TRE"   "broadleaf"  "coniferous"
#> [6] "generic"   
```
