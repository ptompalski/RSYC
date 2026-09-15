# Understanding the yield-curve data

`RSYC_models` contains all published RSYC yield curves. Each row
describes one curve for a forest measure, species, area, and source.

``` r

library(RSYC)
head(RSYC_models[c(
  "model_id", "response", "response_units", "strata_level", "strata_id",
  "scale", "species", "b1", "b2", "b3", "b4"
)])
#>                                                                                 model_id
#> 1  rsyc_agb_national_ecoprovince_abie_ama_montane_cordillera_northern_montane_cordillera
#> 2  rsyc_agb_national_ecoprovince_abie_ama_montane_cordillera_southern_montane_cordillera
#> 3             rsyc_agb_national_ecoprovince_abie_ama_pacific_maritime_georgia_depression
#> 4     rsyc_agb_national_ecoprovince_abie_ama_pacific_maritime_southern_coastal_mountains
#> 5    rsyc_agb_national_ecoprovince_abie_ama_pacific_maritime_southern_montane_cordillera
#> 6 rsyc_agb_national_ecoprovince_abie_bal_atlantic_maritime_appalachian_acadian_highlands
#>   response response_units strata_level
#> 1      agb          Mg/ha  ecoprovince
#> 2      agb          Mg/ha  ecoprovince
#> 3      agb          Mg/ha  ecoprovince
#> 4      agb          Mg/ha  ecoprovince
#> 5      agb          Mg/ha  ecoprovince
#> 6      agb          Mg/ha  ecoprovince
#>                                         strata_id    scale  species       b1
#> 1  Montane Cordillera/Northern Montane Cordillera national ABIE.AMA 206.1421
#> 2  Montane Cordillera/Southern Montane Cordillera national ABIE.AMA 204.1896
#> 3             Pacific Maritime/Georgia Depression national ABIE.AMA 217.6907
#> 4     Pacific Maritime/Southern Coastal Mountains national ABIE.AMA 200.2202
#> 5    Pacific Maritime/Southern Montane Cordillera national ABIE.AMA 210.7439
#> 6 Atlantic Maritime/Appalachian-Acadian Highlands national ABIE.BAL 113.8290
#>           b2        b3           b4
#> 1 0.01933888 0.5227571 0.0007966375
#> 2 0.01933888 0.5227571 0.0007966375
#> 3 0.01933888 0.5227571 0.0007966375
#> 4 0.01933888 0.5227571 0.0007966375
#> 5 0.01933888 0.5227571 0.0007966375
#> 6 0.03246564 1.0935260 0.0007825237
```

The `response` column describes the forest measure: `agb` is aboveground
biomass in Mg/ha, and `volume` is total volume in m3/ha. Areas can be
tiles, ecozones, ecoprovinces, ecoregions, or ecodistricts. The table
includes curves fitted across Canada and curves fitted within individual
regions. The package functions currently use only the Canada-wide
curves.

For ecological areas, `strata_id` gives the full sequence of names from
the ecozone down to the selected level, separated by `/`.
[`predict_rsyc()`](https://ptompalski.github.io/RSYC/reference/predict_rsyc.md)
also accepts the shorter `strata_name` when that name occurs only once
for the chosen forest measure, species, and ecological level:

``` r

rsyc_strata(
  response = "agb",
  species = "PICE.MAR",
  strata_level = "ecoregion"
)
#> # A tibble: 204 × 3
#>    strata_level strata_name              strata_id                              
#>    <chr>        <chr>                    <chr>                                  
#>  1 ecoregion    Abitibi Plains           Boreal Shield East/Mid-Boreal Shield/A…
#>  2 ecoregion    Abitibi Plains           Boreal Shield West/Mid-Boreal Shield/A…
#>  3 ecoregion    Abitibi Plains           Hudson Plains/Mid-Boreal Shield/Abitib…
#>  4 ecoregion    Algonquin-Lake Nipissing Boreal Shield East/Southern Boreal Shi…
#>  5 ecoregion    Annapolis-Minas Lowlands Atlantic Maritime/Fundy Uplands/Annapo…
#>  6 ecoregion    Anticosti Island         Boreal Shield East/Eastern Boreal Shie…
#>  7 ecoregion    Appalachians             Atlantic Maritime/Appalachian-Acadian …
#>  8 ecoregion    Aspen Parkland           Boreal Plains/Parkland Prairies/Aspen …
#>  9 ecoregion    Athabasca Plain          Boreal Plains/Western Boreal Shield/At…
#> 10 ecoregion    Athabasca Plain          Boreal Shield West/Western Boreal Shie…
#> # ℹ 194 more rows
```

Use
[`available_rsyc_models()`](https://ptompalski.github.io/RSYC/reference/available_rsyc_models.md)
to see which curves are available without viewing all of the fields used
to fit and check the curves:

``` r

available_rsyc_models(
  response = "volume",
  species = "PICE.MAR",
  strata_level = "tile"
)
#> # A tibble: 324 × 10
#>    model_id         response response_units strata_type strata_level strata_name
#>    <chr>            <chr>    <chr>          <chr>       <chr>        <chr>      
#>  1 rsyc_volume_nat… volume   m3/ha          tile        tile         A24        
#>  2 rsyc_volume_nat… volume   m3/ha          tile        tile         A25        
#>  3 rsyc_volume_nat… volume   m3/ha          tile        tile         B21        
#>  4 rsyc_volume_nat… volume   m3/ha          tile        tile         B22        
#>  5 rsyc_volume_nat… volume   m3/ha          tile        tile         B23        
#>  6 rsyc_volume_nat… volume   m3/ha          tile        tile         B24        
#>  7 rsyc_volume_nat… volume   m3/ha          tile        tile         B25        
#>  8 rsyc_volume_nat… volume   m3/ha          tile        tile         B26        
#>  9 rsyc_volume_nat… volume   m3/ha          tile        tile         C15        
#> 10 rsyc_volume_nat… volume   m3/ha          tile        tile         C16        
#> # ℹ 314 more rows
#> # ℹ 4 more variables: strata_id <chr>, species <chr>, model_group <chr>,
#> #   model_version <chr>
```

`RSYC_models` also contains measures of uncertainty and variation. These
values may support adjustment with local observations in a future
version, but
[`predict_rsyc()`](https://ptompalski.github.io/RSYC/reference/predict_rsyc.md)
does not currently use them.
