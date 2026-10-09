# Understanding the yield-curve data

`RSYC_models` contains all published RSYC yield curves from model
release `v20260923`. It has 27,208 rows and 42 columns; each row
describes one curve for a forest measure, species, area, and source. The
release was built from upstream Git commit
`c799aba24b5d99a6a7953a4dcab1dd73b0925c2c`.

``` r

library(RSYC)
head(RSYC_models[c(
  "model_id", "response", "response_units", "strata_level", "strata_id",
  "ecozone_id", "ecoprovince_id", "ecoregion_id", "ecodistrict_id",
  "scale", "species", "b1", "b2", "b3", "b4"
)])
#>                                                                                 model_id
#> 1  rsyc_agb_national_ecoprovince_abie_ama_montane_cordillera_northern_montane_cordillera
#> 2  rsyc_agb_national_ecoprovince_abie_ama_montane_cordillera_southern_montane_cordillera
#> 3             rsyc_agb_national_ecoprovince_abie_ama_pacific_maritime_georgia_depression
#> 4     rsyc_agb_national_ecoprovince_abie_ama_pacific_maritime_southern_coastal_mountains
#> 5 rsyc_agb_national_ecoprovince_abie_bal_atlantic_maritime_appalachian_acadian_highlands
#> 6                 rsyc_agb_national_ecoprovince_abie_bal_atlantic_maritime_fundy_uplands
#>   response response_units strata_level
#> 1      agb          Mg/ha  ecoprovince
#> 2      agb          Mg/ha  ecoprovince
#> 3      agb          Mg/ha  ecoprovince
#> 4      agb          Mg/ha  ecoprovince
#> 5      agb          Mg/ha  ecoprovince
#> 6      agb          Mg/ha  ecoprovince
#>                                         strata_id ecozone_id ecoprovince_id
#> 1  Montane Cordillera/Northern Montane Cordillera         14           14.1
#> 2  Montane Cordillera/Southern Montane Cordillera         14           14.3
#> 3             Pacific Maritime/Georgia Depression         13           13.1
#> 4     Pacific Maritime/Southern Coastal Mountains         13           13.2
#> 5 Atlantic Maritime/Appalachian-Acadian Highlands          7            7.1
#> 6                 Atlantic Maritime/Fundy Uplands          7            7.3
#>   ecoregion_id ecodistrict_id    scale  species        b1         b2        b3
#> 1           NA             NA national ABIE.AMA 198.34020 0.02067093 0.5337509
#> 2           NA             NA national ABIE.AMA 197.14596 0.02067093 0.5337509
#> 3           NA             NA national ABIE.AMA 207.42776 0.02067093 0.5337509
#> 4           NA             NA national ABIE.AMA 195.03203 0.02067093 0.5337509
#> 5           NA             NA national ABIE.BAL 113.89957 0.03236021 1.0845434
#> 6           NA             NA national ABIE.BAL  79.34187 0.03236021 1.0845434
#>             b4
#> 1 0.0007561084
#> 2 0.0007561084
#> 3 0.0007561084
#> 4 0.0007561084
#> 5 0.0007334860
#> 6 0.0007334860
```

The `response` column describes the forest measure: `agb` is aboveground
biomass in Mg/ha, and `volume` is total volume in m3/ha. Areas can be
tiles, ecozones, ecoprovinces, ecoregions, or ecodistricts. The table
includes curves fitted across Canada and curves fitted within individual
regions. The package functions currently use only the Canada-wide
curves.

The four raw hierarchy identifier fields retain upstream codes for
ecological areas. `ecozone_id`, `ecoregion_id`, and `ecodistrict_id` are
integers; `ecoprovince_id` is character so codes such as `"10.1"` retain
their source representation. These fields provide data provenance in
this release. Ecological model selection uses `strata_id`, which accepts
a numeric/code identifier, an unambiguous short name, or a full
hierarchical path. Quote ecoprovince codes such as `"10.1"` to retain
their source representation.

For ecological areas, `strata_id` gives the full sequence of names from
the ecozone down to the selected level, separated by `/`.
[`predict_rsyc()`](https://ptompalski.github.io/RSYC/dev/reference/predict_rsyc.md)
also accepts the shorter `strata_name` when that name occurs only once
for the chosen forest measure, species, and ecological level:

``` r

rsyc_strata(
  response = "agb",
  species = "PICE.MAR",
  strata_level = "ecoregion"
)
#> # A tibble: 116 × 4
#>    strata_level strata_name                   strata_id              strata_code
#>    <chr>        <chr>                         <chr>                  <chr>      
#>  1 ecoregion    Abitibi Plains                Boreal Shield East/Mi… 96         
#>  2 ecoregion    Algonquin-Lake Nipissing      Boreal Shield East/So… 98         
#>  3 ecoregion    Annapolis-Minas Lowlands      Atlantic Maritime/Fun… 126        
#>  4 ecoregion    Anticosti Island              Boreal Shield East/Ea… 102        
#>  5 ecoregion    Appalachians                  Atlantic Maritime/App… 117        
#>  6 ecoregion    Athabasca Plain               Boreal Shield West/We… 87         
#>  7 ecoregion    Atlantic Coast                Atlantic Maritime/Fun… 125        
#>  8 ecoregion    Avalon Forest                 Boreal Shield East/Ne… 115        
#>  9 ecoregion    Big Trout Lake                Boreal Shield West/We… 95         
#> 10 ecoregion    Boreal Mountains and Plateaus Boreal Cordillera/Sou… 180        
#> # ℹ 106 more rows
```

The discovery result includes the canonical character `strata_code`. The
same value can be supplied through `strata_id` when exactly one
ecological level is selected:

``` r

available_rsyc_models(
  response = "agb",
  species = "PICE.MAR",
  strata_level = "ecoprovince",
  strata_id = "7.1"
)
#> # A tibble: 1 × 11
#>   model_id          response response_units strata_type strata_level strata_name
#>   <chr>             <chr>    <chr>          <chr>       <chr>        <chr>      
#> 1 rsyc_agb_nationa… agb      Mg/ha          eco_strata  ecoprovince  Appalachia…
#> # ℹ 5 more variables: strata_id <chr>, strata_code <chr>, species <chr>,
#> #   model_group <chr>, model_version <chr>
```

Ecozone codes 5, 6, and 10 each correspond to two named subdivisions.
Use the desired name for prediction, calibration, or dataset
construction; catalogue discovery returns all published matches.

Use
[`available_rsyc_models()`](https://ptompalski.github.io/RSYC/dev/reference/available_rsyc_models.md)
to see which curves are available without viewing all of the fields used
to fit and check the curves:

``` r

available_rsyc_models(
  response = "volume",
  species = "PICE.MAR",
  strata_level = "tile"
)
#> # A tibble: 344 × 11
#>    model_id         response response_units strata_type strata_level strata_name
#>    <chr>            <chr>    <chr>          <chr>       <chr>        <chr>      
#>  1 rsyc_volume_nat… volume   m3/ha          tile        tile         A24        
#>  2 rsyc_volume_nat… volume   m3/ha          tile        tile         A25        
#>  3 rsyc_volume_nat… volume   m3/ha          tile        tile         A26        
#>  4 rsyc_volume_nat… volume   m3/ha          tile        tile         B21        
#>  5 rsyc_volume_nat… volume   m3/ha          tile        tile         B22        
#>  6 rsyc_volume_nat… volume   m3/ha          tile        tile         B23        
#>  7 rsyc_volume_nat… volume   m3/ha          tile        tile         B24        
#>  8 rsyc_volume_nat… volume   m3/ha          tile        tile         B25        
#>  9 rsyc_volume_nat… volume   m3/ha          tile        tile         B26        
#> 10 rsyc_volume_nat… volume   m3/ha          tile        tile         B27        
#> # ℹ 334 more rows
#> # ℹ 5 more variables: strata_id <chr>, strata_code <chr>, species <chr>,
#> #   model_group <chr>, model_version <chr>
```

`RSYC_models` also contains measures of uncertainty and variation.
`local_b1_var` and `residual_var` support local calibration with
[`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/dev/reference/calibrate_rsyc.md);
[`predict_rsyc()`](https://ptompalski.github.io/RSYC/dev/reference/predict_rsyc.md)
itself applies the published coefficients without local adjustment.
Because the `v20260923` coefficients differ from the previous model
release, rendered predictions and calibration examples have been
regenerated for this catalogue.
