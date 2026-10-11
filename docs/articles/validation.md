# Model validation

RSYC yield curves were validated against independent ground plots from
MAGPlot (weighted plot means). Each curve was compared with the plots
located in its tile or ecological unit. Plots were grouped into 20-year
age classes, and plots older than 150 years were excluded. For each age
class, the weighted mean of the plot observations and its 95% confidence
interval (CI) were compared with the mean RSYC prediction for the same
plots.

These results describe model release **v20260923**: 6,434 of 28,043
published curves had enough plots to validate. The remaining curves
could not be validated because too few suitable plots were available in
their area.

This page summarises the validation results and shows scatterplots for
each response, model scale, and spatial level. The [Validation
explorer](https://ptompalski.github.io/RSYC/articles/validation-explorer.md)
maps the results and shows the validation data for individual curves.

## Summary statistics

Statistics are calculated for each curve from its age-class means and
then summarised across curves. Bias is the mean difference between the
RSYC prediction and the observed plot mean, so positive values mean the
curve overestimates the plots.

- AGB – National
- AGB – Regional
- Volume – National
- Volume – Regional

| Level       | Model group   | Models | Median R² | Median bias% | Median RMSE% |
|:------------|:--------------|-------:|----------:|-------------:|-------------:|
| Tile        | Generic       |    142 |      0.63 |        -15.4 |         42.1 |
| Tile        | Species group |    170 |      0.60 |        -15.2 |         44.7 |
| Tile        | Species       |    327 |      0.59 |         -9.7 |         45.1 |
| Ecozone     | Generic       |      8 |      0.79 |        -30.5 |         35.7 |
| Ecozone     | Species group |     15 |      0.76 |        -31.4 |         36.7 |
| Ecozone     | Species       |     55 |      0.66 |        -23.3 |         36.7 |
| Ecoprovince | Generic       |     20 |      0.72 |        -21.4 |         36.4 |
| Ecoprovince | Species group |     33 |      0.73 |        -20.0 |         35.9 |
| Ecoprovince | Species       |     96 |      0.62 |        -21.6 |         42.4 |
| Ecoregion   | Generic       |     63 |      0.73 |        -31.0 |         47.5 |
| Ecoregion   | Species group |     81 |      0.67 |        -27.0 |         50.1 |
| Ecoregion   | Species       |    176 |      0.60 |        -22.3 |         46.9 |
| Ecodistrict | Generic       |    175 |      0.67 |        -15.2 |         46.5 |
| Ecodistrict | Species group |    174 |      0.61 |        -11.8 |         45.5 |
| Ecodistrict | Species       |    329 |      0.61 |         -6.8 |         44.5 |

| Level       | Model group   | Models | Median R² | Median bias% | Median RMSE% |
|:------------|:--------------|-------:|----------:|-------------:|-------------:|
| Tile        | Generic       |     89 |      0.64 |        -15.1 |         41.8 |
| Tile        | Species group |    108 |      0.64 |        -15.2 |         44.0 |
| Tile        | Species       |    188 |      0.59 |          0.2 |         44.8 |
| Ecozone     | Generic       |      6 |      0.80 |        -28.4 |         32.2 |
| Ecozone     | Species group |     11 |      0.67 |        -28.4 |         35.5 |
| Ecozone     | Species       |     44 |      0.66 |        -23.2 |         38.2 |
| Ecoprovince | Generic       |     17 |      0.73 |        -19.9 |         36.4 |
| Ecoprovince | Species group |     27 |      0.71 |        -19.3 |         35.1 |
| Ecoprovince | Species       |     75 |      0.63 |        -21.1 |         42.2 |
| Ecoregion   | Generic       |     57 |      0.74 |        -29.5 |         45.2 |
| Ecoregion   | Species group |     65 |      0.66 |        -27.3 |         46.4 |
| Ecoregion   | Species       |    136 |      0.64 |        -21.9 |         47.6 |
| Ecodistrict | Generic       |    167 |      0.65 |        -17.0 |         46.6 |
| Ecodistrict | Species group |    138 |      0.62 |        -10.7 |         43.6 |
| Ecodistrict | Species       |    236 |      0.60 |         -6.7 |         45.3 |

| Level       | Model group   | Models | Median R² | Median bias% | Median RMSE% |
|:------------|:--------------|-------:|----------:|-------------:|-------------:|
| Tile        | Generic       |    145 |      0.61 |         -8.0 |         48.7 |
| Tile        | Species group |    170 |      0.58 |         -7.1 |         48.1 |
| Tile        | Species       |    329 |      0.57 |         -1.0 |         48.4 |
| Ecozone     | Generic       |      8 |      0.80 |        -22.9 |         31.3 |
| Ecozone     | Species group |     15 |      0.73 |        -20.0 |         34.5 |
| Ecozone     | Species       |     57 |      0.66 |        -18.9 |         37.4 |
| Ecoprovince | Generic       |     21 |      0.74 |        -16.1 |         36.4 |
| Ecoprovince | Species group |     34 |      0.70 |        -13.1 |         37.4 |
| Ecoprovince | Species       |     94 |      0.64 |        -15.3 |         41.6 |
| Ecoregion   | Generic       |     64 |      0.72 |        -25.9 |         45.5 |
| Ecoregion   | Species group |     80 |      0.64 |        -18.5 |         51.3 |
| Ecoregion   | Species       |    177 |      0.62 |        -14.4 |         45.6 |
| Ecodistrict | Generic       |    179 |      0.64 |         -7.7 |         50.0 |
| Ecodistrict | Species group |    176 |      0.58 |         -6.3 |         49.1 |
| Ecodistrict | Species       |    331 |      0.60 |          1.9 |         48.4 |

| Level       | Model group   | Models | Median R² | Median bias% | Median RMSE% |
|:------------|:--------------|-------:|----------:|-------------:|-------------:|
| Tile        | Generic       |     86 |      0.60 |         -3.1 |         48.0 |
| Tile        | Species group |     90 |      0.60 |         -5.0 |         45.3 |
| Tile        | Species       |    165 |      0.58 |          9.3 |         48.2 |
| Ecozone     | Generic       |      7 |      0.78 |        -20.6 |         33.1 |
| Ecozone     | Species group |     11 |      0.67 |        -22.1 |         37.4 |
| Ecozone     | Species       |     47 |      0.63 |        -16.4 |         40.6 |
| Ecoprovince | Generic       |     19 |      0.73 |        -16.4 |         35.9 |
| Ecoprovince | Species group |     25 |      0.67 |        -15.6 |         37.1 |
| Ecoprovince | Species       |     77 |      0.64 |        -15.5 |         40.8 |
| Ecoregion   | Generic       |     59 |      0.73 |        -21.0 |         44.8 |
| Ecoregion   | Species group |     53 |      0.64 |        -14.8 |         49.5 |
| Ecoregion   | Species       |    148 |      0.62 |        -15.2 |         46.6 |
| Ecodistrict | Generic       |    171 |      0.63 |         -9.5 |         50.1 |
| Ecodistrict | Species group |    105 |      0.58 |         -5.8 |         53.3 |
| Ecodistrict | Species       |    263 |      0.59 |         -1.7 |         50.5 |

## Observed vs predicted

Each point is one age class of one curve: the weighted mean of the plot
observations (x axis) against the mean RSYC prediction for the same
plots (y axis). Panels show the generic model, the coniferous and
broadleaf models, and the species models. Species are ordered by number
of points. AGB points with plot means of 400 Mg/ha or more are excluded,
and panels with fewer than three points are omitted.

### AGB

#### National models

- Tile
- Ecozone
- Ecoprovince
- Ecoregion
- Ecodistrict

4,109 age-class points from 636 curves.

![Scatterplots of AGB RSYC predictions against plot means for national
tile models, one panel per
model.](validation_files/figure-html/unnamed-chunk-4-1.png)

539 age-class points from 77 curves.

![Scatterplots of AGB RSYC predictions against plot means for national
ecozone models, one panel per
model.](validation_files/figure-html/unnamed-chunk-5-1.png)

1,038 age-class points from 148 curves.

![Scatterplots of AGB RSYC predictions against plot means for national
ecoprovince models, one panel per
model.](validation_files/figure-html/unnamed-chunk-6-1.png)

2,116 age-class points from 319 curves.

![Scatterplots of AGB RSYC predictions against plot means for national
ecoregion models, one panel per
model.](validation_files/figure-html/unnamed-chunk-7-1.png)

4,226 age-class points from 677 curves.

![Scatterplots of AGB RSYC predictions against plot means for national
ecodistrict models, one panel per
model.](validation_files/figure-html/unnamed-chunk-8-1.png)

#### Regional models

- Tile
- Ecozone
- Ecoprovince
- Ecoregion
- Ecodistrict

2,498 age-class points from 384 curves.

![Scatterplots of AGB RSYC predictions against plot means for regional
tile models, one panel per
model.](validation_files/figure-html/unnamed-chunk-9-1.png)

422 age-class points from 60 curves.

![Scatterplots of AGB RSYC predictions against plot means for regional
ecozone models, one panel per
model.](validation_files/figure-html/unnamed-chunk-10-1.png)

837 age-class points from 118 curves.

![Scatterplots of AGB RSYC predictions against plot means for regional
ecoprovince models, one panel per
model.](validation_files/figure-html/unnamed-chunk-11-1.png)

1,727 age-class points from 257 curves.

![Scatterplots of AGB RSYC predictions against plot means for regional
ecoregion models, one panel per
model.](validation_files/figure-html/unnamed-chunk-12-1.png)

3,414 age-class points from 540 curves.

![Scatterplots of AGB RSYC predictions against plot means for regional
ecodistrict models, one panel per
model.](validation_files/figure-html/unnamed-chunk-13-1.png)

### Volume

#### National models

- Tile
- Ecozone
- Ecoprovince
- Ecoregion
- Ecodistrict

4,274 age-class points from 644 curves.

![Scatterplots of Volume RSYC predictions against plot means for
national tile models, one panel per
model.](validation_files/figure-html/unnamed-chunk-14-1.png)

588 age-class points from 80 curves.

![Scatterplots of Volume RSYC predictions against plot means for
national ecozone models, one panel per
model.](validation_files/figure-html/unnamed-chunk-15-1.png)

1,090 age-class points from 149 curves.

![Scatterplots of Volume RSYC predictions against plot means for
national ecoprovince models, one panel per
model.](validation_files/figure-html/unnamed-chunk-16-1.png)

2,232 age-class points from 321 curves.

![Scatterplots of Volume RSYC predictions against plot means for
national ecoregion models, one panel per
model.](validation_files/figure-html/unnamed-chunk-17-1.png)

4,429 age-class points from 686 curves.

![Scatterplots of Volume RSYC predictions against plot means for
national ecodistrict models, one panel per
model.](validation_files/figure-html/unnamed-chunk-18-1.png)

#### Regional models

- Tile
- Ecozone
- Ecoprovince
- Ecoregion
- Ecodistrict

2,243 age-class points from 341 curves.

![Scatterplots of Volume RSYC predictions against plot means for
regional tile models, one panel per
model.](validation_files/figure-html/unnamed-chunk-19-1.png)

481 age-class points from 65 curves.

![Scatterplots of Volume RSYC predictions against plot means for
regional ecozone models, one panel per
model.](validation_files/figure-html/unnamed-chunk-20-1.png)

895 age-class points from 121 curves.

![Scatterplots of Volume RSYC predictions against plot means for
regional ecoprovince models, one panel per
model.](validation_files/figure-html/unnamed-chunk-21-1.png)

1,830 age-class points from 260 curves.

![Scatterplots of Volume RSYC predictions against plot means for
regional ecoregion models, one panel per
model.](validation_files/figure-html/unnamed-chunk-22-1.png)

3,490 age-class points from 539 curves.

![Scatterplots of Volume RSYC predictions against plot means for
regional ecodistrict models, one panel per
model.](validation_files/figure-html/unnamed-chunk-23-1.png)
