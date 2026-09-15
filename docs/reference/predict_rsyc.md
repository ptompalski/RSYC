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

  Tile ID or ecological area name. A single area name can be used when
  it occurs only once. If the name occurs in several places, use the
  full sequence of area names shown by
  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md).

## Value

One estimated value for each stand age. AGB is in Mg/ha and volume is in
m3/ha.

## Details

This function currently uses curves fitted across Canada. The curves
were fitted for stand ages 1 through 150 years. The function warns when
asked to estimate outside this age range; age 0 is also allowed as the
start of a curve. When a full ecological area sequence is needed, use
`/` between the ecozone, ecoprovince, ecoregion, and ecodistrict names.

## Examples

``` r
predict_rsyc("agb", "PICE.MAR", c(20, 60, 120), "tile", "H14")
#> [1] 27.49419 60.21335 74.19827
predict_rsyc(
  response = "volume",
  species = "PICE.MAR",
  age = c(20, 60, 120),
  strata_level = "ecozone",
  strata_id = "Boreal Shield East"
)
#> [1]  31.74320  82.23544 105.32608
```
