#' List Species Available in a Tile
#'
#' @param tile_id A single tile ID.
#' @param response Response variable: `"agb"` or `"volume"`.
#'
#' @return A character vector of canonical species codes and model groups.
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
