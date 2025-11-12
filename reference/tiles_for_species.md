# List Available Tiles for a Given Species

This function returns the tile IDs where RSYC models are available for a
specified species.

## Usage

``` r
tiles_for_species(species)
```

## Arguments

- species:

  A character string specifying the species code (e.g., "PICE.MAR" for
  black spruce).

## Value

A character vector of tile IDs where the specified species is available.

## Examples

``` r
tiles_for_species("PINU.CON")
#>  [1] "Q4" "P5" "P4" "P3" "O6" "O5" "O4" "O3" "N7" "N6" "N5" "N4" "N3" "M7" "M6"
#> [16] "M5" "M4" "M3" "L7" "L6" "L5" "L4" "K7" "K6" "K5" "K4" "K3" "J6" "J5" "J4"
#> [31] "J3" "I8" "I7" "I6" "I5" "I4" "I3" "H7" "H6" "H5" "H4" "H3" "G8" "G7" "G6"
#> [46] "G5" "G4" "F7" "F6" "F5" "F4" "E7" "E6" "E5"
```
