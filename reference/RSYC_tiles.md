# RSYC Tile Grid (150 × 150 km)

A spatial layer defining the 150 × 150 km tiles used in the development
of the Remote Sensing Yield Curves (RSYC). Each polygon represents one
tile for which yield curves were developed. The layer can be used to
identify the models to use in given location.

## Format

An `sf` object with one feature per tile and the following attribute:

- TileID:

  Unique identifier of the 150 × 150 km tile (character).

## Examples

``` r
if (FALSE) { # \dontrun{
  # Path to the RSYC_tiles within the installed package
  gpkg <- system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")

  # Read with sf
  library(sf)
  RSYC_tiles <- st_read(gpkg, quiet = TRUE)
  plot(st_geometry(RSYC_tiles))
} # }
```
