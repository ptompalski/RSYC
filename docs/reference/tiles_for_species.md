# List Tiles Available for a Species

List Tiles Available for a Species

## Usage

``` r
tiles_for_species(species, response = "agb")
```

## Arguments

- species:

  One species code or broad group. Uppercase and lowercase letters are
  treated the same.

- response:

  Forest measure: `"agb"` for aboveground biomass or `"volume"` for
  total volume.

## Value

The IDs of tiles with a published curve for the chosen species and
forest measure.

## Examples

``` r
tiles_for_species("PINU.CON")
#>  [1] "E5" "E6" "E7" "F4" "F5" "F6" "F7" "G3" "G4" "G5" "G6" "G7" "G8" "H3" "H4"
#> [16] "H5" "H6" "H7" "H8" "I3" "I4" "I5" "I6" "I7" "I8" "J2" "J3" "J4" "J5" "J6"
#> [31] "K2" "K3" "K4" "K5" "K6" "K7" "L3" "L4" "L5" "L6" "L7" "M3" "M4" "M5" "M6"
#> [46] "M7" "N3" "N4" "N5" "N6" "N7" "O3" "O4" "O5" "O6" "P3" "P4" "P5" "P6" "Q3"
#> [61] "Q4" "R3"
tiles_for_species("Coniferous", response = "volume")
#>   [1] "A24" "A25" "A26" "B21" "B22" "B23" "B24" "B25" "B26" "B28" "C15" "C16"
#>  [13] "C17" "C18" "C19" "C20" "C21" "C22" "C23" "C24" "C25" "C26" "C27" "C28"
#>  [25] "C29" "C31" "C32" "D16" "D17" "D18" "D19" "D20" "D21" "D22" "D23" "D24"
#>  [37] "D25" "D26" "D27" "D28" "D29" "D30" "D31" "D32" "D33" "E13" "E14" "E15"
#>  [49] "E16" "E17" "E18" "E19" "E20" "E21" "E22" "E23" "E24" "E25" "E26" "E27"
#>  [61] "E28" "E29" "E30" "E31" "E32" "E33" "E5"  "E6"  "E7"  "F12" "F13" "F14"
#>  [73] "F15" "F16" "F17" "F18" "F19" "F2"  "F20" "F21" "F22" "F23" "F24" "F25"
#>  [85] "F26" "F27" "F28" "F29" "F3"  "F30" "F31" "F32" "F33" "F34" "F4"  "F5" 
#>  [97] "F6"  "F7"  "G10" "G11" "G12" "G13" "G14" "G15" "G16" "G17" "G18" "G19"
#> [109] "G2"  "G20" "G21" "G22" "G23" "G24" "G25" "G26" "G27" "G28" "G29" "G3" 
#> [121] "G30" "G31" "G32" "G33" "G34" "G4"  "G5"  "G6"  "G7"  "G8"  "H1"  "H10"
#> [133] "H11" "H12" "H13" "H14" "H15" "H16" "H17" "H18" "H19" "H2"  "H20" "H21"
#> [145] "H22" "H23" "H24" "H25" "H26" "H27" "H28" "H29" "H3"  "H30" "H31" "H32"
#> [157] "H33" "H34" "H35" "H36" "H4"  "H5"  "H6"  "H7"  "H8"  "H9"  "I10" "I11"
#> [169] "I12" "I13" "I14" "I15" "I16" "I17" "I18" "I19" "I2"  "I23" "I24" "I25"
#> [181] "I26" "I27" "I28" "I29" "I3"  "I30" "I31" "I32" "I33" "I34" "I35" "I36"
#> [193] "I4"  "I5"  "I6"  "I7"  "I8"  "I9"  "J1"  "J10" "J11" "J12" "J13" "J14"
#> [205] "J15" "J16" "J17" "J2"  "J23" "J24" "J25" "J26" "J27" "J28" "J29" "J3" 
#> [217] "J30" "J31" "J32" "J33" "J34" "J35" "J4"  "J5"  "J6"  "J7"  "J8"  "J9" 
#> [229] "K1"  "K10" "K11" "K12" "K13" "K14" "K15" "K16" "K2"  "K23" "K24" "K25"
#> [241] "K26" "K27" "K28" "K29" "K3"  "K30" "K31" "K32" "K33" "K4"  "K5"  "K6" 
#> [253] "K7"  "K8"  "K9"  "L1"  "L10" "L11" "L12" "L13" "L14" "L15" "L16" "L2" 
#> [265] "L25" "L26" "L27" "L28" "L29" "L3"  "L30" "L31" "L32" "L4"  "L5"  "L6" 
#> [277] "L7"  "L8"  "L9"  "M10" "M11" "M12" "M13" "M14" "M15" "M16" "M2"  "M27"
#> [289] "M28" "M29" "M3"  "M4"  "M5"  "M6"  "M7"  "M8"  "M9"  "N10" "N11" "N12"
#> [301] "N13" "N14" "N3"  "N4"  "N5"  "N6"  "N7"  "N8"  "N9"  "O10" "O11" "O12"
#> [313] "O3"  "O4"  "O5"  "O6"  "O7"  "O8"  "O9"  "P10" "P11" "P2"  "P3"  "P4" 
#> [325] "P5"  "P6"  "P7"  "P8"  "P9"  "Q10" "Q11" "Q2"  "Q3"  "Q4"  "Q5"  "Q6" 
#> [337] "Q7"  "Q8"  "Q9"  "R10" "R2"  "R3"  "R4"  "R5"  "R6"  "R7"  "R8"  "R9" 
#> [349] "S3"  "S4"  "S5"  "S6"  "S7"  "S8"  "T3"  "T4"  "T5"  "T6"  "T7"  "T8" 
#> [361] "U4"  "U5"  "U6"  "U7"  "V5"  "V6" 
```
