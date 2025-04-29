#' List Available Species Codes and Names
#'
#' This function returns a data frame of species codes and their corresponding species names
#' used in the RSYC model set. It arranges species codes alphabetically, but promotes the
#' meta-categories `"Generic"`, `"Broadleaf"`, and `"Coniferous"` to the top of the list.
#'
#' @return A tibble with two columns: `SpeciesCode` and `SpeciesName`.
#'
#' @examples
#' species_codes()
#'
#' @export

species_codes <- function() {
  df <- RSYC_params %>% dplyr::distinct(SpeciesCode, SpeciesName) %>% dplyr::arrange(SpeciesCode)
  
  promoteToTop <- c("Generic", "Broadleaf", "Coniferous")
  
  df <- df %>%
    dplyr::mutate(
      SpeciesCode = factor(
        SpeciesCode,
        levels = c(promoteToTop, setdiff(unique(SpeciesCode), promoteToTop))
      )
    ) %>%
    dplyr::arrange(SpeciesCode)
  
  return(df)
  
}
