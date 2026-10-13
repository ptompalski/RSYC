## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Notes for CRAN

* The ecological-boundary GeoPackage (~15 MB) is not included in the package.
  Users download it on demand with `download_rsyc_boundaries()`, which saves to
  `tools::R_user_dir("RSYC", "data")` by default and verifies a SHA-256
  checksum. Examples write only to `tempdir()`.

## Test environments

* local Windows 11, R 4.5.1
