# Estimate Biomass or Volume from an RSYC Yield Curve

Estimate aboveground biomass or total volume at one or more stand ages.
The curve is selected by species and area.

## Usage

``` r
predict_rsyc(response, species, age, strata_level, strata_id)
```

## Arguments

- response:

  Forest measure to estimate: `"agb"` for aboveground biomass or
  `"volume"` for total volume.

- species:

  A species code or broad group such as `"coniferous"`. Uppercase and
  lowercase letters are treated the same.

- age:

  One or more stand ages in years.

- strata_level:

  Type of area: `"tile"`, `"ecozone"`, `"ecoprovince"`, `"ecoregion"`,
  or `"ecodistrict"`.

- strata_id:

  Tile ID, ecological area name or path, or ecological code. Tile IDs,
  names, and paths are matched ignoring case. A single area name can be
  used when it occurs only once. If the name occurs in several places,
  use the full sequence of area names shown by
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md).
  Numeric values are interpreted as codes for the selected ecological
  `strata_level`; quote ecoprovince codes such as `"10.1"`.

## Value

One estimated value for each stand age. AGB is in Mg/ha and volume is in
m3/ha.

## Details

This function currently uses curves fitted across Canada. The curves
were fitted for stand ages 1 through 150 years. The function warns when
asked to estimate outside this age range; age 0 is also allowed as the
start of a curve. When a full ecological area sequence is needed, use
`/` between the ecozone, ecoprovince, ecoregion, and ecodistrict names.

Ecological codes are resolved only within the selected `strata_level`.
Ecozone codes 5, 6, and 10 each identify two named package subdivisions
and therefore cannot select a single curve; use the desired subdivision
name.

## Examples

``` r
# Select a tile model with its tile ID.
predict_rsyc("agb", "PICE.MAR", c(20, 60, 120), "tile", "H14")
#> [1] 26.85001 58.32616 71.92139

# Select an ecozone model with its unique name.
predict_rsyc(
  response = "volume",
  species = "PICE.MAR",
  age = c(20, 60, 120),
  strata_level = "ecozone",
  strata_id = "Boreal Shield East"
)
#> [1]  35.39177  91.53735 117.30550

# Select an ecoregion model with its numeric ecological code.
predict_rsyc(
  "agb", "PICE.MAR", c(40, 80), "ecoregion", 198
)
#> [1] 39.69784 56.18245

# A full hierarchy path is an unambiguous ecological selector.
predict_rsyc(
  "agb", "PICE.MAR", 80, "ecodistrict",
  paste(
    "Atlantic Maritime", "Fundy Uplands", "Annapolis-Minas Lowlands",
    "Windsor Lowlands", sep = "/"
  )
)
#> [1] 50.13418
```
