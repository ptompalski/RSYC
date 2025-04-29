#' List Available Tiles for a Given Species
#'
#' This function returns the tile IDs where RSYC models are available for a specified species.
#'
#' @param species A character string specifying the species code (e.g., "PICE.MAR" for black spruce).
#'
#' @return A character vector of tile IDs where the specified species is available.
#'
#' @examples
#' tiles_for_species("PINU.CON")
#'
#' @export
tiles_for_species <- function(species) {
  
  # Check input
  assert_is_character(species)
  
  # Filter RSYC parameters
  D <- RSYC::RSYC_params %>%
    dplyr::filter(SpeciesCode == species) %>%
    dplyr::distinct(TileID) %>%
    dplyr::pull(TileID)
  
  # If no tiles found, give informative warning
  if (length(D) == 0) {
    warning(glue::glue("No tiles found for species code '{species}'."), call. = FALSE)
  }
  
  return(D)
}
