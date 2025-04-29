#' Predict Aboveground Biomass Using RSYC models
#'
#' This function generates aboveground biomass (AGB) predictions using remote sensing-based yield curves (RSYC) for a given species, stand age, and tile.
#' It retrieves the model parameters associated with the specified tile and species and applies a four-parameter Chapman-Richards growth function.
#'
#' @param tile_id A character string specifying the tile ID. Must match a tile for which RSYC models are available.
#' @param age A numeric vector of stand ages (in years) at which to predict biomass. All values must be positive.
#' @param species A character string specifying the species code (e.g., `"PICE.MAR"` for black spruce).
#'
#' @return A numeric vector of predicted AGB values (e.g., in tonnes per hectare) corresponding to the input ages.
#'
#' @details
#' The RSYC models were developed using data from 0 to 150 years. If any ages provided exceed 150, a warning is issued because predictions represent extrapolations beyond the model's calibration range and may be unreliable.
#'
#' @examples
#' predict_rsyc(tile_id = "J11", age = 1:100, species = "PICE.MAR")
#'
#' @export


predict_rsyc <- function(tile_id, age, species) {
  
  #check inputs
  assert_is_character(tile_id)
  assert_is_character(species)
  assert_is_numeric(age)
  assert_all_are_positive(age)

  
  #get params
  P <- RSYC::RSYC_params %>% dplyr::filter(TileID == tile_id, SpeciesCode == species)
  
  #check if params is one row 
  if(nrow(P)==0) stop(glue::glue("No models for provided inputs"), call. = FALSE)
  
  #check if there is more than one row
  if(nrow(P) != 1) stop(glue::glue("Error! More than one model found. This cannot happen. Please submit a github issue"), call. = FALSE)

  # if age is > 150 then throw a warning
  if (any(age > 150, na.rm = TRUE)) {
    warning("Stand age exceeds the model's calibration range (0–150 years). Predictions beyond this range involve extrapolation and may be unreliable.", call. = FALSE)
  }
  
    
  #get yc
  RSYC:::CRdeclining2(age = age, b1 = P$b1, b2 = P$b2, b3 = P$b3, b4 = P$b4)
  
}


