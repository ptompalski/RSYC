## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Resubmission

* Replaced the relative file link `vignettes/articles/Prediction-examples.Rmd`
  in README.md with the full pkgdown URL, since the article is not included in
  the package tarball.

## Notes for CRAN

* The ecological-boundary GeoPackage (~15 MB) is not included in the package.
  Users download it on demand with `download_rsyc_boundaries()`, which saves to
  `tools::R_user_dir("RSYC", "data")` by default and verifies a SHA-256
  checksum. Examples and tests write only to `tempdir()`; download examples are
  wrapped in `\donttest{}` and `try()` so they fail gracefully when offline.

## Test environments

* local Windows 11, R 4.6.1
* win-builder (R-devel and R-release)
* macOS builder (R-release)
* GitHub Actions: macOS, Windows, Ubuntu (R-devel, release, oldrel-1, 4.1)
