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

An `sf` map in the Canada Atlas Lambert projection (EPSG:3978). Every
map contains `strata_id`, which links an area to its RSYC curves, and
the area shape. Ecological maps also contain the names of the larger
ecological areas in which each area lies.

## Examples

``` r
tiles <- rsyc_boundaries("tile")
if (FALSE) { # \dontrun{
download_rsyc_boundaries()
districts <- rsyc_boundaries("ecodistrict")
} # }
```
