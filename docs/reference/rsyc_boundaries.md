# Read RSYC Boundary Maps

Read the tile boundaries or ecological boundaries used for the RSYC
yield curves. Tile boundaries are included with the package. Ecological
boundaries are read from the file saved by
[`download_rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/download_rsyc_boundaries.md).
This function never downloads data on its own.

## Usage

``` r
rsyc_boundaries(
  strata_level = "tile",
  cache_dir = tools::R_user_dir("RSYC", "data"),
  quiet = TRUE
)
```

## Arguments

- strata_level:

  Type of area: `"tile"`, `"ecozone"`, `"ecoprovince"`, `"ecoregion"`,
  or `"ecodistrict"`.

- cache_dir:

  Folder in which to save the GeoPackage. By default, RSYC uses its
  standard user data folder, returned by
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

- quiet:

  Hide messages produced while the map is read?

## Value

An `sf` map in the Canada Atlas Lambert projection (EPSG:3978). Tile
maps contain `strata_id` and geometry. Ecological maps additionally
contain canonical character `strata_code` and the hierarchy names and
source ID fields through the requested level.

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  tiles <- rsyc_boundaries("tile")
}
# \donttest{
if (requireNamespace("sf", quietly = TRUE)) {
  cache <- tempdir()
  if (!inherits(try(download_rsyc_boundaries(cache_dir = cache)), "try-error")) {
    districts <- rsyc_boundaries("ecodistrict", cache_dir = cache)
  }
}
# }
```
