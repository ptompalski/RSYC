#' List Tiles Available for a Species
#'
#' @param species A single species code or model group. Matching is
#'   case-insensitive.
#' @param response Response variable: `"agb"` or `"volume"`.
#'
#' @return A character vector of tile IDs.
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
