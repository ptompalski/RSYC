.rsyc_force_boundary_runtime <- function() {
  force(.rsyc_ecostrat_filename)
  force(.rsyc_ecostrat_url)
  force(.rsyc_ecostrat_sha256)
  force(.rsyc_public_strata_levels)

  force(download_rsyc_boundaries)
  force(rsyc_boundaries)

  force(.rsyc_assert_flag)
  force(.rsyc_assert_scalar_character)
  force(.rsyc_ecostrat_path)
  force(.rsyc_match_choice)
  force(.rsyc_require_namespace)
  force(.rsyc_tile_boundaries_path)
  force(.rsyc_verify_ecostrat)

  invisible()
}

.onLoad <- function(libname, pkgname) {
  .rsyc_force_boundary_runtime()
  invisible()
}
