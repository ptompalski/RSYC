#' Parameters for the RSYC models
#'
#'
#' A data frame with 1892 rows and 97 columns:
#' \describe{
#'   \item{TileID}{Tile identified}
#'   \item{SpeciesCode, SpeciesName}{Species}
#'   \item{b1, b2, b3, b4}{model parameters}
#'   ...
#' }

"RSYC_params"


#' RSYC Tile Grid (150 × 150 km)
#'
#' A spatial layer defining the 150 × 150 km tiles used in the development of
#' the Remote Sensing Yield Curves (RSYC). Each polygon represents one tile
#' for which yield curves were developed. The layer can be used to identify the
#' models to use in given location.
#'
#' @format An `sf` object with one feature per tile and the following attribute:
#' \describe{
#'   \item{TileID}{Unique identifier of the 150 × 150 km tile (character).}
#' }
#'
#' @examples
#' \dontrun{
#'   # Path to the RSYC_tiles within the installed package
#'   gpkg <- system.file("extdata", "RSYC_tiles.gpkg", package = "RSYC")
#'
#'   # Read with sf
#'   library(sf)
#'   RSYC_tiles <- st_read(gpkg, quiet = TRUE)
#'   plot(st_geometry(RSYC_tiles))
#' }
#'
#' @name RSYC_tiles
NULL
