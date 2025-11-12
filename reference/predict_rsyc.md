# Predict Aboveground Biomass Using RSYC models

This function generates aboveground biomass (AGB) predictions using
remote sensing-based yield curves (RSYC) for a given species, stand age,
and tile. It retrieves the model parameters associated with the
specified tile and species and applies a four-parameter Chapman-Richards
growth function.

## Usage

``` r
predict_rsyc(tile_id, age, species)
```

## Arguments

- tile_id:

  A character string specifying the tile ID. Must match a tile for which
  RSYC models are available.

- age:

  A numeric vector of stand ages (in years) at which to predict biomass.
  All values must be positive.

- species:

  A character string specifying the species code (e.g., `"PICE.MAR"` for
  black spruce). Use
  [`species_codes()`](https://ptompalski.github.io/RSYC/reference/species_codes.md)
  for a full list of species names and codes.

## Value

A numeric vector of predicted AGB values (e.g., in tonnes per hectare)
corresponding to the input ages.

## Details

The RSYC models were developed using data from 0 to 150 years. If any
ages provided exceed 150, a warning is issued because predictions
represent extrapolations beyond the model's calibration range and may be
unreliable.

## Examples

``` r
predict_rsyc(tile_id = "J11", age = 1:100, species = "PICE.MAR")
#>   [1]  0.2935077  0.7604127  1.3107991  1.9126710  2.5475918  3.2033215
#>   [7]  3.8711329  4.5445389  5.2185913  5.8894551  6.5541293  7.2102561
#>  [13]  7.8559829  8.4898609  9.1107676  9.7178472 10.3104626 10.8881580
#>  [19] 11.4506277 11.9976910 12.5292714 13.0453791 13.5460963 14.0315654
#>  [25] 14.5019779 14.9575665 15.3985967 15.8253610 16.2381732 16.6373638
#>  [31] 17.0232759 17.3962618 17.7566802 18.1048935 18.4412657 18.7661606
#>  [37] 19.0799403 19.3829638 19.6755859 19.9581563 20.2310188 20.4945108
#>  [43] 20.7489626 20.9946970 21.2320292 21.4612663 21.6827072 21.8966425
#>  [49] 22.1033547 22.3031174 22.4961965 22.6828490 22.8633239 23.0378622
#>  [55] 23.2066967 23.3700522 23.5281461 23.6811879 23.8293799 23.9729171
#>  [61] 24.1119875 24.2467720 24.3774452 24.5041750 24.6271229 24.7464445
#>  [67] 24.8622895 24.9748017 25.0841194 25.1903757 25.2936983 25.3942101
#>  [73] 25.4920290 25.5872683 25.6800368 25.7704391 25.8585755 25.9445421
#>  [79] 26.0284315 26.1103323 26.1903297 26.2685052 26.3449372 26.4197007
#>  [85] 26.4928680 26.5645079 26.6346869 26.7034684 26.7709134 26.8370802
#>  [91] 26.9020249 26.9658011 27.0284602 27.0900516 27.1506225 27.2102181
#>  [97] 27.2688820 27.3266556 27.3835788 27.4396898
```
