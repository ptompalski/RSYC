#' List Tiles Available for a Species
#'
#' @param species One species code or broad group. Uppercase and lowercase
#'   letters are treated the same.
#' @param response Forest measure: `"agb"` for aboveground biomass or
#'   `"volume"` for total volume.
#'
#' @return The IDs of tiles with a published curve for the chosen species and
#'   forest measure.
#'
#' @examples
#' tiles_for_species("PINU.CON")
#' tiles_for_species("Coniferous", response = "volume")
#'
#' @export
tiles_for_species <- function(species, response = "agb") {
  species <- .rsyc_normalize_species(species)
  models <- .rsyc_filter_models(response, species, "tile", NULL)
  tiles <- unique(models$strata_id)

  if (!length(tiles)) {
    warning(
      glue::glue(
        "No tiles found for species '{species}', response='{tolower(response)}'."
      ),
      call. = FALSE
    )
  }
  tiles
}
