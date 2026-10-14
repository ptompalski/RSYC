# Build the strata_id -> strata_code lookup used by the curve explorer.
#
# The explorer bundle (pkgdown/assets/validation/<version>/) is produced
# upstream and identifies ecological areas only by their hierarchical name
# path. This script writes strata_codes.json next to it so the explorer can
# display the canonical codes from RSYC_models.
#
# Run from the package root: Rscript data-raw/build_explorer_strata_codes.R

devtools::load_all(quiet = TRUE)

version <- jsonlite::fromJSON("pkgdown/assets/validation/versions.json")$latest
bundle_dir <- file.path("pkgdown/assets/validation", version)

bundle <- jsonlite::fromJSON(file.path(bundle_dir, "models.json"))
bundle <- unique(data.frame(
  strata_level = bundle$parameter_level,
  strata_id = bundle$strata_id
))
bundle <- bundle[bundle$strata_level != "tile", ]

models <- RSYC_models
models$strata_code <- RSYC:::.rsyc_strata_codes(models)
codes <- unique(models[c("strata_level", "strata_id", "strata_code")])
codes <- codes[codes$strata_level != "tile", ]

if (any(duplicated(codes[c("strata_level", "strata_id")]))) {
  stop("Some ecological strata map to more than one code.", call. = FALSE)
}

lookup <- merge(bundle, codes, by = c("strata_level", "strata_id"), all.x = TRUE)
if (anyNA(lookup$strata_code)) {
  missing <- lookup$strata_id[is.na(lookup$strata_code)]
  stop(
    "Explorer strata without a code: ",
    paste(utils::head(missing, 10), collapse = ", "),
    call. = FALSE
  )
}

lookup <- lookup[order(lookup$strata_level, lookup$strata_id), ]
out <- split(
  stats::setNames(as.list(lookup$strata_code), lookup$strata_id),
  lookup$strata_level
)

jsonlite::write_json(
  out,
  file.path(bundle_dir, "strata_codes.json"),
  auto_unbox = TRUE,
  pretty = FALSE
)
message("Wrote ", nrow(lookup), " codes to ", file.path(bundle_dir, "strata_codes.json"))
