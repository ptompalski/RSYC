#' Published RSYC Model Contract
#'
#' A model table containing one row per published remote sensing-based yield
#' curve. It includes aboveground biomass and total-volume models at national
#' and regional scales for tiles and nested Canadian ecosystem strata.
#'
#' @format A tibble with 28,391 rows and 38 columns:
#' \describe{
#'   \item{model_id, model_version}{Unique model identifier and source version.}
#'   \item{response, response_units}{Response (`agb` or `volume`) and units.}
#'   \item{strata_type, strata_level, strata_id}{Spatial model identifiers.}
#'   \item{scale, region_id}{National or regional model source.}
#'   \item{species, model_group}{Species or broad model-group identifiers.}
#'   \item{equation, age_min, age_max}{Curve equation and published age range.}
#'   \item{b1, b2, b3, b4}{Chapman-Richards curve coefficients.}
#'   \item{b1_se, b2_se, b3_se, b4_se, sigma}{Fixed-effect uncertainty and
#'   residual standard deviation.}
#'   \item{parent_b1_random_effect, parent_b1_var, local_b1_var, residual_var}{
#'   Variance components retained for future local calibration.}
#'   \item{has_cor_struct, has_var_struct, component_ok, component_message}{
#'   Model component diagnostics.}
#'   \item{n_obs, n_units, converged, singular_or_boundary, fit_ok, publish_ok,
#'   model_message}{Fit, publication, and sample-size metadata.}
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
