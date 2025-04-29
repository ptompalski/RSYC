#' List Available Species for a Given Tile
#'
#' This function returns the species codes for which RSYC models are available within a specified tile.
#'
#' @param tile_id A character string specifying the tile ID.
#'
#' @return A character vector of species codes available for the given tile.
#'
#' @examples
#' species_in_tile("B22")
#'
#' @export
species_in_tile <- function(tile_id) {
  
  # Check inputs
  assert_is_character(tile_id)
  
  # Filter RSYC parameters
  D <- RSYC::RSYC_params %>%
    dplyr::filter(TileID == tile_id) %>%
    # dplyr::distinct(SpeciesCode) %>%
    dplyr::pull(SpeciesCode)
  
  # If no species found, give informative warning
  if (length(D) == 0) {
    warning(glue::glue("No species found for tile_id '{tile_id}'."), call. = FALSE)
  }
  
  return(D)
}

