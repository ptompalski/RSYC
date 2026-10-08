contract_environment <- new.env(parent = baseenv())
sys.source(
  testthat::test_path("..", "..", "data-raw", "release_contract.R"),
  envir = contract_environment
)
release_contract <- contract_environment$.rsyc_release_contract
release_source_path <- contract_environment$.rsyc_release_source_path

test_that("v20260923 release contract is complete and internally consistent", {
  expect_identical(release_contract$model_version, "v20260923")
  expect_match(release_contract$upstream_git_commit, "^[0-9a-f]{40}$")

  expect_identical(release_contract$model$source_rows, 28043L)
  expect_identical(release_contract$model$rows, 27208L)
  expect_identical(release_contract$model$columns, 42L)
  expect_length(release_contract$model$column_types, 42L)
  expect_identical(
    names(release_contract$model$column_types),
    c(
      "model_id", "model_version", "response", "response_units",
      "strata_type", "strata_level", "strata_id", "ecozone_id",
      "ecoprovince_id", "ecoregion_id", "ecodistrict_id", "scale",
      "region_id", "species", "model_group", "equation", "age_min",
      "age_max", "b1", "b2", "b3", "b4", "b1_se", "b2_se", "b3_se",
      "b4_se", "sigma", "parent_b1_random_effect", "parent_b1_var",
      "local_b1_var", "residual_var", "has_cor_struct", "has_var_struct",
      "component_ok", "component_message", "n_obs", "n_units",
      "converged", "singular_or_boundary", "fit_ok", "publish_ok",
      "model_message"
    )
  )
  expect_identical(
    unname(release_contract$model$column_types[c(
      "ecozone_id", "ecoprovince_id", "ecoregion_id", "ecodistrict_id"
    )]),
    c("integer", "character", "integer", "integer")
  )

  expect_identical(release_contract$boundary$version, "v2")
  expect_identical(
    release_contract$boundary$source_model_version,
    release_contract$model_version
  )
  expect_match(release_contract$model$source_sha256, "^[0-9a-f]{64}$")
  expect_match(release_contract$forest_filter$source_sha256, "^[0-9a-f]{64}$")
  expect_length(release_contract$forest_filter$ecozones, 12L)
  expect_match(release_contract$boundary$source_sha256, "^[0-9a-f]{64}$")
  expect_match(
    release_contract$boundary$source_manifest_sha256,
    "^[0-9a-f]{64}$"
  )
  expect_setequal(
    release_contract$inputs$filenames,
    names(release_contract$inputs$sha256)
  )
})

test_that("release source paths support defaults and environment overrides", {
  default <- release_source_path("model", environment = character())
  expect_match(
    gsub("\\\\", "/", default),
    "RSYC-Canada/outputs/products/models/versions/v20260923/rsyc_models_rpackage\\.rds$"
  )

  override <- file.path("controlled", "model-source.rds")
  expect_identical(
    release_source_path(
      "model",
      environment = c(RSYC_MODELS_SOURCE = override)
    ),
    override
  )
})
