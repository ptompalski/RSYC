#' Build an RSYC Spatial Yield-Curve Dataset
#'
#' Estimate yield for one or more species across a set of tiles or ecological
#' areas. The boundary map is kept separate from the curve table so that each
#' area shape is stored only once.
#'
#' @param response Forest measure to estimate: `"agb"` for aboveground biomass
#'   or `"volume"` for total volume.
#' @param species One or more species codes or broad groups. Uppercase and
#'   lowercase letters are treated the same.
#' @param age One or more stand ages in years.
#' @param strata_level Type of area: `"tile"`, `"ecozone"`,
#'   `"ecoprovince"`, `"ecoregion"`, or `"ecodistrict"`.
#' @param strata_id One or more tile IDs, ecological area names, or full
#'   sequences of ecological area names. By default, every area with a matching
#'   published curve is included. If an area name occurs in several places,
#'   the function asks for the full sequence of area names.
#' @param output Location of an optional GeoPackage file. When supplied, the
#'   file contains a boundary map named `spatial`, a yield table named `curves`,
#'   and a summary table named `metadata`.
#' @param overwrite Replace an existing GeoPackage at `output`?
#' @inheritParams download_rsyc_boundaries
#'
#' @return Three named results: `spatial`, an `sf` boundary map; `curves`, a
#'   table of yield estimates; and `metadata`, a one-row summary of the data and
#'   choices used.
#'
#' @details
#' The function currently uses only curves fitted across Canada. It does not
#' substitute a curve from another type of area or from a regional fit.
#' Ecological boundaries must first be downloaded with
#' [download_rsyc_boundaries()]; tile boundaries are included with RSYC.
#'
#' @examples
#' tile_dataset <- build_rsyc_dataset(
#'   response = "agb",
#'   species = c("PICE.MAR", "POPU.TRE"),
#'   age = c(50, 100, 150),
#'   strata_level = "tile",
#'   strata_id = c("H14", "F31")
#' )
#' tile_dataset$spatial
#' tile_dataset$curves
#'
#' @export
build_rsyc_dataset <- function(
  response,
  species,
  age = 1:150,
  strata_level = "tile",
  strata_id = NULL,
  output = NULL,
  overwrite = FALSE,
  cache_dir = tools::R_user_dir("RSYC", "data"),
  quiet = TRUE
) {
  response <- .rsyc_match_choice(response, "response", c("agb", "volume"))
  species <- .rsyc_normalize_species_filter(species)
  .rsyc_assert_age(age)
  strata_level <- .rsyc_match_choice(
    strata_level,
    "strata_level",
    .rsyc_public_strata_levels
  )
  .rsyc_assert_flag(overwrite, "overwrite")
  .rsyc_assert_flag(quiet, "quiet")

  models <- .rsyc_model_catalog()
  keep <-
    models$scale == "national" &
    models$response == response &
    models$strata_level == strata_level &
    .rsyc_normalize_species(models$species, scalar = FALSE) %in% species
  models <- models[keep, , drop = FALSE]

  if (!is.null(strata_id)) {
    resolved <- .rsyc_resolve_dataset_strata(models, strata_id, strata_level)
    models <- models[models$strata_id %in% resolved, , drop = FALSE]
  }
  if (!nrow(models)) {
    stop(
      "No national RSYC models match the requested dataset. Use ",
      "`available_rsyc_models()` to inspect model availability.",
      call. = FALSE
    )
  }

  models <- models[order(models$strata_id, models$species), , drop = FALSE]
  .rsyc_warn_age_extrapolation(age)

  model_row <- rep(seq_len(nrow(models)), each = length(age))
  curve_age <- rep(age, times = nrow(models))
  curves <- tibble::tibble(
    model_id = models$model_id[model_row],
    strata_id = models$strata_id[model_row],
    species = models$species[model_row],
    age = curve_age,
    prediction = unname(CRdeclining2(
      curve_age,
      models$b1[model_row],
      models$b2[model_row],
      models$b3[model_row],
      models$b4[model_row]
    ))
  )

  boundaries <- rsyc_boundaries(
    strata_level = strata_level,
    cache_dir = cache_dir,
    quiet = quiet
  )
  wanted <- unique(models$strata_id)
  missing_geometry <- setdiff(wanted, boundaries$strata_id)
  if (length(missing_geometry)) {
    stop(
      "No boundary geometry was found for: ",
      paste(missing_geometry, collapse = ", "),
      call. = FALSE
    )
  }
  spatial <- boundaries[boundaries$strata_id %in% wanted, , drop = FALSE]
  spatial <- spatial[match(wanted, spatial$strata_id), , drop = FALSE]

  metadata <- tibble::tibble(
    model_version = unique(models$model_version)[[1L]],
    response = response,
    response_units = paste(sort(unique(models$response_units)), collapse = ", "),
    species = paste(sort(unique(models$species)), collapse = ", "),
    strata_level = strata_level,
    age_min = min(age),
    age_max = max(age),
    n_models = nrow(models),
    n_strata = length(wanted),
    equation = paste(sort(unique(models$equation)), collapse = ", "),
    crs_epsg = sf::st_crs(spatial)$epsg,
    created_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )

  dataset <- list(spatial = spatial, curves = curves, metadata = metadata)

  if (!is.null(output)) {
    .rsyc_write_dataset(dataset, output, overwrite = overwrite, quiet = quiet)
  }
  dataset
}

.rsyc_resolve_dataset_strata <- function(models, strata_id, strata_level) {
  if (!is.character(strata_id) || !length(strata_id) ||
      anyNA(strata_id) || any(!nzchar(strata_id))) {
    stop("`strata_id` must contain non-empty character values.", call. = FALSE)
  }

  available <- unique(models$strata_id)
  resolved <- character()
  for (id in strata_id) {
    if (id %in% available) {
      resolved <- c(resolved, id)
      next
    }
    matches <- sort(available[.rsyc_strata_name(available) == id])
    if (length(matches) > 1L) {
      entries <- paste0("  - ", matches, collapse = "\n")
      stop(
        "The ", strata_level, " name '", id, "' is ambiguous.\n",
        "Matching hierarchical paths:\n", entries, "\n",
        "Use one of the full hierarchical paths as `strata_id`.",
        call. = FALSE
      )
    }
    if (!length(matches)) {
      stop(
        "No requested ", strata_level, " model was found for `strata_id = \"",
        id, "\"` and the selected response/species.",
        call. = FALSE
      )
    }
    resolved <- c(resolved, matches)
  }
  unique(resolved)
}

.rsyc_write_dataset <- function(dataset, output, overwrite, quiet) {
  .rsyc_assert_scalar_character(output, "output")
  if (tolower(tools::file_ext(output)) != "gpkg") {
    stop("`output` must have a `.gpkg` extension.", call. = FALSE)
  }
  if (file.exists(output) && !overwrite) {
    stop("`output` already exists; use `overwrite = TRUE` to replace it.", call. = FALSE)
  }
  output_dir <- dirname(output)
  if (!dir.exists(output_dir)) {
    stop("The parent directory of `output` does not exist.", call. = FALSE)
  }

  sf::st_write(
    dataset$spatial,
    output,
    layer = "spatial",
    delete_dsn = file.exists(output),
    quiet = quiet
  )
  sf::st_write(dataset$curves, output, layer = "curves", append = TRUE, quiet = quiet)
  sf::st_write(dataset$metadata, output, layer = "metadata", append = TRUE, quiet = quiet)
  invisible(output)
}
