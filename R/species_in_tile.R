#' List Species Available in a Tile
#'
#' @param tile_id One tile ID.
#' @param response Forest measure: `"agb"` for aboveground biomass or
#'   `"volume"` for total volume.
#'
#' @return The species codes and broad groups that have a published curve in
#'   the chosen tile.
#'
#' @examples
#' species_in_tile("H14")
#' species_in_tile("H14", response = "volume")
#'
#' @export
species_in_tile <- function(tile_id, response = "agb") {
  .rsyc_assert_scalar_character(tile_id, "tile_id")
  models <- .rsyc_filter_models(response, NULL, "tile", tile_id)
  species <- unique(models$species)

  if (!length(species)) {
    warning(
      glue::glue(
        "No species found for tile_id '{tile_id}', response='{tolower(response)}'."
      ),
      call. = FALSE
    )
  }
  species
}
