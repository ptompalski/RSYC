# Download RSYC Ecological Boundaries

Download and save the ecological boundary maps used by RSYC. The file is
not downloaded when the package is installed or loaded. It contains maps
of ecozones, ecoprovinces, ecoregions, and ecodistricts, but no yield
curves. Tile boundaries are already included with RSYC.

## Usage

``` r
download_rsyc_boundaries(
  cache_dir = tools::R_user_dir("RSYC", "data"),
  overwrite = FALSE,
  quiet = FALSE,
  url = getOption("RSYC.ecostrat_url", .rsyc_ecostrat_url)
)
```

## Arguments

- cache_dir:

  Folder in which to save the GeoPackage. By default, RSYC uses its
  standard user data folder, returned by
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

- overwrite:

  Replace a previously downloaded file?

- quiet:

  Hide download progress?

- url:

  Web address of the boundary file. The default points to the copy
  published with RSYC. Organizations may instead provide the address of
  an approved copy. Its contents must match the published file.

## Value

The full location of the saved GeoPackage. The function returns this
location without printing it.

## See also

[`rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/rsyc_boundaries.md)

## Examples

``` r
if (FALSE) { # \dontrun{
download_rsyc_boundaries()
} # }
```
