# Internal release contract for the v20260923 model-package update.
#
# This file is sourced by data-raw scripts and focused tests. It is deliberately
# kept outside R/ because it is build-time metadata, not part of the public API.

.rsyc_release_contract <- local({
  model_version <- "v20260923"
  source_directory <- file.path(
    "..", "RSYC-Canada", "outputs", "products", "models", "versions",
    model_version
  )

  input_sha256 <- c(
    rsyc_models_rpackage.rds =
      "193ebfc1f3279ffc278d84c917d206b4b4bcaeae95f38acf25d9c84a040bd1d5",
    selection_report.csv =
      "cdae883c87f169d8da3ea34fb1f07108f244c8b7eb525a774bb5cd48c01092ad",
    model_selection_manifest.csv =
      "18495931f7ad9a1380f01ce89fa353de04c1cbd659040fc7011f7ff15a3c9e56",
    model_version_manifest.json =
      "e557f4c5ddb10ee89dfb1378a971e51b62d0a911ee967ba887a5801bf9ab40d2",
    RSYC_ecosystem_model_package.gpkg =
      "739a3c3c0aeb8ef235a567bc01220ce94ebea7b9c3c92b70c822e9f08ef4c858"
  )

  forested_ecozones <- c(
    "Atlantic Maritime",
    "Boreal Cordillera",
    "Boreal Plains",
    "Boreal Shield East",
    "Boreal Shield West",
    "Hudson Plains",
    "Montane Cordillera",
    "Pacific Maritime",
    "Taiga Cordillera",
    "Taiga Plains",
    "Taiga Shield East",
    "Taiga Shield West"
  )

  column_types <- c(
    model_id = "character",
    model_version = "character",
    response = "character",
    response_units = "character",
    strata_type = "character",
    strata_level = "character",
    strata_id = "character",
    ecozone_id = "integer",
    ecoprovince_id = "character",
    ecoregion_id = "integer",
    ecodistrict_id = "integer",
    scale = "character",
    region_id = "character",
    species = "character",
    model_group = "character",
    equation = "character",
    age_min = "integer",
    age_max = "integer",
    b1 = "double",
    b2 = "double",
    b3 = "double",
    b4 = "double",
    b1_se = "double",
    b2_se = "double",
    b3_se = "double",
    b4_se = "double",
    sigma = "double",
    parent_b1_random_effect = "double",
    parent_b1_var = "double",
    local_b1_var = "double",
    residual_var = "double",
    has_cor_struct = "logical",
    has_var_struct = "logical",
    component_ok = "logical",
    component_message = "character",
    n_obs = "integer",
    n_units = "integer",
    converged = "logical",
    singular_or_boundary = "logical",
    fit_ok = "logical",
    publish_ok = "logical",
    model_message = "character"
  )

  list(
    model_version = model_version,
    upstream_git_commit = "c799aba24b5d99a6a7953a4dcab1dd73b0925c2c",
    source_directory = source_directory,
    inputs = list(
      filenames = names(input_sha256),
      sha256 = input_sha256
    ),
    model = list(
      source_environment_variable = "RSYC_MODELS_SOURCE",
      source_filename = "rsyc_models_rpackage.rds",
      source_sha256 = unname(input_sha256[["rsyc_models_rpackage.rds"]]),
      source_rows = 28043L,
      rows = 27208L,
      columns = 42L,
      column_types = column_types
    ),
    forest_filter = list(
      source_environment_variable = "RSYC_FORESTED_ECOZONES_SOURCE",
      source_filename = "forested_ecozones.gpkg",
      source_sha256 =
        "f8b51550f6a741878ae55c9aac1fda5c62a452d47b0c594055792e80c2697b60",
      layer = "forested_ecozones",
      name_field = "ECOZONE_NA",
      ecozones = forested_ecozones
    ),
    boundary = list(
      version = "v2",
      source_model_version = model_version,
      source_environment_variable = "RSYC_ECOSTRAT_SOURCE",
      source_filename = "RSYC_ecosystem_model_package.gpkg",
      source_sha256 = unname(
        input_sha256[["RSYC_ecosystem_model_package.gpkg"]]
      ),
      source_manifest_filename = "model_version_manifest.json",
      source_manifest_sha256 = unname(
        input_sha256[["model_version_manifest.json"]]
      ),
      output_filename = "RSYC_ecostrat.gpkg",
      layers = c("ecozones", "ecoprovinces", "ecoregions", "ecodistricts"),
      feature_counts = c(
        ecozones = 12L,
        ecoprovinces = 36L,
        ecoregions = 138L,
        ecodistricts = 672L
      ),
      fields = c(
        "parameter_level", "ecozone", "ecoprovince", "ecoregion",
        "ecodistrict", "ecozone_id", "ecoprovince_id", "ecoregion_id",
        "ecodistrict_id", "join_key", "geometry"
      ),
      field_types = c(
        parameter_level = "character",
        ecozone = "character",
        ecoprovince = "character",
        ecoregion = "character",
        ecodistrict = "character",
        ecozone_id = "integer",
        ecoprovince_id = "character",
        ecoregion_id = "integer",
        ecodistrict_id = "integer",
        join_key = "character"
      )
    ),
    tile_boundary = list(
      source_model_version = model_version,
      source_environment_variable = "RSYC_ECOSTRAT_SOURCE",
      source_filename = "RSYC_ecosystem_model_package.gpkg",
      source_sha256 = unname(
        input_sha256[["RSYC_ecosystem_model_package.gpkg"]]
      ),
      source_layer = "tiles",
      source_features = 649L,
      source_parameter_levels = c("tile", "tile_region"),
      source_fields = c(
        "parameter_level", "tile_id", "join_key", "geometry"
      ),
      source_field_types = c(
        parameter_level = "character",
        tile_id = "character",
        join_key = "character"
      ),
      output_filename = "RSYC_tiles.gpkg",
      output_layer = "RSYC_tiles",
      output_features = 385L,
      output_fields = c("TileID", "geometry"),
      retired_ids = c("D34", "E35", "P1", "R1")
    )
  )
})

.rsyc_release_source_path <- function(
  kind = c("model", "boundary"),
  environment = Sys.getenv(),
  contract = .rsyc_release_contract
) {
  kind <- match.arg(kind)
  source_contract <- contract[[kind]]
  variable <- source_contract$source_environment_variable
  override <- unname(environment[variable])

  if (length(override) == 1L && !is.na(override) && nzchar(override)) {
    return(override)
  }

  file.path(contract$source_directory, source_contract$source_filename)
}
