# RSYC Tile Grid (150 x 150 km)

A model-aligned GeoPackage containing one polygon or multipolygon for
each of the 385 tile IDs used by the v20260923 national RSYC models. The
path can be obtained with
`system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")` and read
with
[`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html).
