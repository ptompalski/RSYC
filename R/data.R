#' Published RSYC Yield-Curve Data
#'
#' A table containing one row for each published remote sensing-based yield
#' curve. It includes aboveground biomass and total-volume curves fitted across
#' Canada and within individual regions. Curves are available for tiles and
#' four levels of Canada's ecological land classification.
#'
#' @format A table with 28,391 rows and 38 columns:
#' \describe{
#'   \item{model_id, model_version}{Unique name for the curve and the RSYC
#'   release in which it was published.}
#'   \item{response, response_units}{Forest measure (`agb` or `volume`) and its
#'   units.}
#'   \item{strata_type, strata_level, strata_id}{Type and name of the area
#'   represented by the curve.}
#'   \item{scale, region_id}{Whether the curve was fitted across Canada or
#'   within a region, and the region name where applicable.}
#'   \item{species, model_group}{Species code or broad species group.}
#'   \item{equation, age_min, age_max}{Curve equation and age range. Published
#'   RSYC curves were fitted for stand ages 1 to 150 years.}
#'   \item{b1, b2, b3, b4}{Chapman-Richards curve coefficients.}
#'   \item{b1_se, b2_se, b3_se, b4_se, sigma}{Measures of uncertainty around
#'   the fitted curve.}
#'   \item{parent_b1_random_effect, parent_b1_var, local_b1_var, residual_var}{
#'   Values retained for possible future adjustment of curves with local data.}
#'   \item{has_cor_struct, has_var_struct, component_ok, component_message}{
#'   Checks recorded while each curve was fitted.}
#'   \item{n_obs, n_units, converged, singular_or_boundary, fit_ok, publish_ok,
#'   model_message}{Number of observations and forest units, together with
#'   checks used to decide whether the curve was suitable for publication.}
#' }
#'
#' @source RSYC-Canada model products, version `v20260709`.
#'
#' @examples
#' subset(
#'   RSYC_models,
#'   response == "volume" & strata_level == "ecozone" & species == "PICE.MAR"
#' )
"RSYC_models"

#' RSYC Tile Grid (150 x 150 km)
#'
#' A GeoPackage containing the tile polygons used by the RSYC models. The path
#' can be obtained with `system.file("extdata", "RSYC_tiles.gpkg", package =
#' "RSYC")` and read with `sf::st_read()`.
#'
#' @name RSYC_tiles
NULL
