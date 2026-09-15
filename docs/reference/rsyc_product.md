# Combine RSYC Yield Curves with a Boundary Map

Estimate yield for one or more species across a set of tiles or
ecological areas. The boundary map is kept separate from the curve table
so that each area shape is stored only once.

## Usage

``` r
rsyc_product(
  response,
  species,
  age = 1:150,
  strata_level = "tile",
  strata_id = NULL,
  output = NULL,
  overwrite = FALSE,
  cache_dir = tools::R_user_dir("RSYC", "data"),
  quiet = TRUE
)
```

## Arguments

- response:

  Forest measure to estimate: `"agb"` for aboveground biomass or
  `"volume"` for total volume.

- species:

  One or more species codes or broad groups. Uppercase and lowercase
  letters are treated the same.

- age:

  One or more stand ages in years.

- strata_level:

  Type of area: `"tile"`, `"ecozone"`, `"ecoprovince"`, `"ecoregion"`,
  or `"ecodistrict"`.

- strata_id:

  One or more tile IDs, ecological area names, or full sequences of
  ecological area names. By default, every area with a matching
  published curve is included. If an area name occurs in several places,
  the function asks for the full sequence of area names.

- output:

  Location of an optional GeoPackage file. When supplied, the file
  contains a boundary map named `spatial`, a yield table named `curves`,
  and a summary table named `metadata`.

- overwrite:

  Replace an existing GeoPackage at `output`?

- cache_dir:

  Folder in which to save the GeoPackage. By default, RSYC uses its
  standard user data folder, returned by
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

- quiet:

  Hide download progress?

## Value

Three named results: `spatial`, an `sf` boundary map; `curves`, a table
of yield estimates; and `metadata`, a one-row summary of the data and
choices used.

## Details

The function currently uses only curves fitted across Canada. It does
not substitute a curve from another type of area or from a regional fit.
Ecological boundaries must first be downloaded with
[`download_rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/download_rsyc_boundaries.md);
tile boundaries are included with RSYC.

## Examples

``` r
tile_product <- rsyc_product(
  response = "agb",
  species = c("PICE.MAR", "POPU.TRE"),
  age = c(50, 100, 150),
  strata_level = "tile",
  strata_id = c("H14", "F31")
)
tile_product$spatial
#> Simple feature collection with 2 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -410910.5 ymin: 348648.1 xmax: 2289089 ymax: 798648.1
#> Projected CRS: NAD83 / Canada Atlas Lambert
#>     strata_id                       geometry
#> 106       F31 POLYGON ((2169089 348648.1,...
#> 156       H14 POLYGON ((-380910.5 648648....
tile_product$curves
#> # A tibble: 12 × 5
#>    model_id                            strata_id species    age prediction
#>    <chr>                               <chr>     <chr>    <dbl>      <dbl>
#>  1 rsyc_agb_national_tile_pice_mar_f31 F31       PICE.MAR    50       68.6
#>  2 rsyc_agb_national_tile_pice_mar_f31 F31       PICE.MAR   100       89.3
#>  3 rsyc_agb_national_tile_pice_mar_f31 F31       PICE.MAR   150       95.9
#>  4 rsyc_agb_national_tile_popu_tre_f31 F31       POPU.TRE    50       87.9
#>  5 rsyc_agb_national_tile_popu_tre_f31 F31       POPU.TRE   100      106. 
#>  6 rsyc_agb_national_tile_popu_tre_f31 F31       POPU.TRE   150      105. 
#>  7 rsyc_agb_national_tile_pice_mar_h14 H14       PICE.MAR    50       54.9
#>  8 rsyc_agb_national_tile_pice_mar_h14 H14       PICE.MAR   100       71.5
#>  9 rsyc_agb_national_tile_pice_mar_h14 H14       PICE.MAR   150       76.8
#> 10 rsyc_agb_national_tile_popu_tre_h14 H14       POPU.TRE    50       68.7
#> 11 rsyc_agb_national_tile_popu_tre_h14 H14       POPU.TRE   100       82.6
#> 12 rsyc_agb_national_tile_popu_tre_h14 H14       POPU.TRE   150       82.5
```
