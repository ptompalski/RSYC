#' Estimate Biomass or Volume from an RSYC Yield Curve
#'
#' Estimate aboveground biomass or total volume at one or more stand ages. The
#' curve is selected by species and area.
#'
#' @param response Forest measure to estimate: `"agb"` for aboveground biomass
#'   or `"volume"` for total volume.
#' @param species A species code or broad group such as `"coniferous"`.
#'   Uppercase and lowercase letters are treated the same.
#' @param age One or more stand ages in years.
#' @param strata_level Type of area: `"tile"`, `"ecozone"`,
#'   `"ecoprovince"`, `"ecoregion"`, or `"ecodistrict"`.
#' @param strata_id Tile ID, ecological area name or path, or ecological code.
#'   Tile IDs, names, and paths are matched ignoring case.
#'   A single area name can be used when it occurs only once. If the name occurs
#'   in several places, use the full sequence of area names shown by
#'   `rsyc_strata()`. Numeric values are interpreted as codes for the selected
#'   ecological `strata_level`; quote ecoprovince codes such as `"10.1"`.
#'
#' @return One estimated value for each stand age. AGB is in Mg/ha and volume
#'   is in m3/ha.
#'
#' @details
#' This function currently uses curves fitted across Canada. The curves were
#' fitted for stand ages 1 through 150 years. The function warns when asked to
#' estimate outside this age range; age 0 is also allowed as the start of a
#' curve. When a full ecological area sequence is needed, use `/` between the
#' ecozone, ecoprovince, ecoregion, and ecodistrict names.
#'
#' Ecological codes are resolved only within the selected `strata_level`.
#' Ecozone codes 5, 6, and 10 each identify two named package subdivisions and
#' therefore cannot select a single curve; use the desired subdivision name.
#'
#' @examples
#' # Select a tile model with its tile ID.
#' predict_rsyc("agb", "PICE.MAR", c(20, 60, 120), "tile", "H14")
#'
#' # Select an ecozone model with its unique name.
#' predict_rsyc(
#'   response = "volume",
#'   species = "PICE.MAR",
#'   age = c(20, 60, 120),
#'   strata_level = "ecozone",
#'   strata_id = "Boreal Shield East"
#' )
#'
#' # Select an ecoregion model with its numeric ecological code.
#' predict_rsyc(
#'   "agb", "PICE.MAR", c(40, 80), "ecoregion", 198
#' )
#'
#' # A full hierarchy path is an unambiguous ecological selector.
#' predict_rsyc(
#'   "agb", "PICE.MAR", 80, "ecodistrict",
#'   paste(
#'     "Atlantic Maritime", "Fundy Uplands", "Annapolis-Minas Lowlands",
#'     "Windsor Lowlands", sep = "/"
#'   )
#' )
#'
#' @export
predict_rsyc <- function(response, species, age, strata_level, strata_id) {
  response <- .rsyc_match_choice(response, "response", c("agb", "volume"))
  species <- .rsyc_normalize_species(species)
  strata_level <- .rsyc_match_choice(
    strata_level,
    "strata_level",
    .rsyc_public_strata_levels
  )
  .rsyc_assert_age(age)

  model <- .rsyc_select_model(response, species, strata_level, strata_id)

  .rsyc_warn_age_extrapolation(age)

  CRdeclining2(
    age = age,
    b1 = model$b1[[1L]],
    b2 = model$b2[[1L]],
    b3 = model$b3[[1L]],
    b4 = model$b4[[1L]]
  )
}
