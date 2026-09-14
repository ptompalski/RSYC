.rsyc_species_names <- c(
  generic = "Generic",
  coniferous = "Coniferous",
  broadleaf = "Broadleaf",
  "ABIE.AMA" = "Amabilis fir",
  "ABIE.BAL" = "Balsam fir",
  "ABIE.LAS" = "Subalpine fir",
  "ACER.RUB" = "Red maple",
  "ACER.SAH" = "Sugar maple",
  "ALNU.RUB" = "Red alder",
  "BETU.ALL" = "Yellow birch",
  "BETU.PAP" = "White birch",
  "FRAX.NIG" = "Black ash",
  "LARI.LAR" = "Tamarack",
  "LARI.OCC" = "Western larch",
  "PICE.ABI" = "Norway spruce",
  "PICE.ENG" = "Engelmann spruce",
  "PICE.GLA" = "White spruce",
  "PICE.MAR" = "Black spruce",
  "PICE.RUB" = "Red spruce",
  "PICE.SIT" = "Sitka spruce",
  "PINU.BAN" = "Jack pine",
  "PINU.CON" = "Lodgepole pine",
  "PINU.PON" = "Ponderosa pine",
  "PINU.RES" = "Red pine",
  "PINU.STR" = "Eastern white pine",
  "POPU.BAL" = "Balsam poplar",
  "POPU.GRA" = "Largetooth aspen",
  "POPU.TRE" = "Trembling aspen",
  "PSEU.MEN" = "Douglas-fir",
  "THUJ.OCC" = "Eastern white-cedar",
  "THUJ.PLI" = "Western redcedar",
  "TSUG.HET" = "Western hemlock",
  "TSUG.MER" = "Mountain hemlock"
)

#' List Available Species Codes and Names
#'
#' List species codes and common names represented in the published RSYC model
#' set. Model groups are listed first, followed by species codes.
#'
#' @param response Optional response filter: `"agb"` or `"volume"`.
#' @param strata_level Optional public spatial-level filter.
#'
#' @return A tibble with columns `SpeciesCode` and `SpeciesName`.
#'
#' @examples
#' species_codes()
#' species_codes(response = "volume", strata_level = "ecoregion")
#'
#' @export
species_codes <- function(response = NULL, strata_level = NULL) {
  species <- .rsyc_filter_models(response, NULL, strata_level, NULL)$species
  species <- unique(species)
  species <- species[order(
    match(species, c("generic", "coniferous", "broadleaf"), nomatch = 4L),
    species
  )]
  tibble::tibble(
    SpeciesCode = species,
    SpeciesName = unname(.rsyc_species_names[species])
  )
}
