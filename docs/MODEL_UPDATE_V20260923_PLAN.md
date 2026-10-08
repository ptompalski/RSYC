# RSYC model update plan: v20260709 to v20260923

Copy-ready prompts for executing this plan in separate chats are
available in `MODEL_UPDATE_V20260923_PROMPTS.md`.

## Purpose

This document is a self-contained implementation handoff for updating
the RSYC R package from model release `v20260709` to `v20260923`.

The package repository is `K:\_PROJECTS\RSYC`. The authoritative model
products are under:

``` text
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923
```

The objective is to merge the existing local-calibration work into
`dev`, make the model update on a dedicated branch from `dev`, and leave
`main` unchanged until the associated paper is published.

## Git workflow

At the time this plan was written:

- `local-calibration` is exactly one commit ahead of `dev`.
- `local-calibration` and `dev` have not diverged, so a fast-forward
  merge is appropriate.
- `main` must remain frozen for the paper.
- `dev` is the integration branch containing current development work.
- `RSYC_package_description.md` is an untracked file and must be
  preserved or deliberately added/ignored before unrelated cleanup.

Merge local calibration into `dev`:

``` powershell
git switch dev
git merge --ff-only local-calibration
git push origin dev
```

Create a pre-update reference tag:

``` powershell
git tag -a pre-model-v20260923 -m "Dev with local calibration before v20260923 model update"
git push origin pre-model-v20260923
```

Create the model-update branch:

``` powershell
git switch -c model-v20260923 dev
git push -u origin model-v20260923
```

All model-update pull requests should target `dev`, not `main`. Keep
`main` protected from direct pushes and do not merge `dev` into `main`
until the paper is published.

Suggested implementation commits:

1.  `Update model import contract for v20260923`
2.  `Import v20260923 model catalogue`
3.  `Update ecological and tile boundaries`
4.  `Update tests and documentation for v20260923`

For scientific traceability, prefer a normal PR merge commit into `dev`
if the individual commits are clean.

## Authoritative inputs

Use these current product files:

``` text
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923\rsyc_models_rpackage.rds
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923\selection_report.csv
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923\model_selection_manifest.csv
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923\model_version_manifest.json
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923\RSYC_ecosystem_model_package.gpkg
```

The product `selection_report.csv` and package artifacts were
regenerated at 2026-10-07 15:32. The older comparison file below was
generated at 13:15 and is stale for at least `PINU.BAN` ecological AGB
and `ABIE.LAS` tile AGB:

``` text
K:\_PROJECTS\RSYC-Canada\outputs\summaries\model_status\selection\v20260923\selection_vs_v20260709_coverage.csv
```

Do not use the `selected` column in that stale comparison as
authoritative. Use the current product `selection_report.csv` to
determine v20260923 selection status. The older file can still supply
the v20260709 `previous` indicator when joined to the current selection
report.

The current upstream manifest records Git commit:

``` text
c799aba24b5d99a6a7953a4dcab1dd73b0925c2c
```

Confirm this commit and recompute source checksums immediately before
importing, in case the upstream products are regenerated again.

## Confirmed model contract changes

| Contract                                    |   v20260709 |   v20260923 |
|---------------------------------------------|------------:|------------:|
| Rows                                        |      28,391 |      28,043 |
| Columns                                     |          38 |          42 |
| Model version                               | `v20260709` | `v20260923` |
| Shared lookup keys                          |      21,999 |      21,999 |
| Shared keys with changed curve coefficients |          \- |      21,991 |
| Old-only lookup keys                        |          \- |       6,392 |
| New-only lookup keys                        |          \- |       6,044 |

The four new columns are:

``` text
ecozone_id
ecoprovince_id
ecoregion_id
ecodistrict_id
```

The curve equation remains:

``` text
b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3
```

The v20260923 source has:

- unique `model_id` values;
- valid UTF-8 character data;
- finite curve coefficients;
- `publish_ok == TRUE` for all included rows;
- positive finite `local_b1_var` and `residual_var` for all national
  rows;
- the same `b1` and parent-random-effect semantics required by
  [`calibrate_rsyc()`](https://ptompalski.github.io/RSYC/reference/calibrate_rsyc.md).

Prediction and local-calibration logic are therefore structurally
compatible with the new model table.

## Numeric eco-strata selection API

The v20260923 model table adds identifiers for every level of the
ecological hierarchy. Users should be able to select models using these
identifiers as an alternative to ecological names and full hierarchical
paths.

### Identifier characteristics

The identifiers are codes, not quantities. Preserve their source types
and do not perform arithmetic on them.

| Strata level | Source field | Source type | Unique within level? |
|----|----|----|----|
| Ecozone | `ecozone_id` | integer | No |
| Ecoprovince | `ecoprovince_id` | character codes such as `"10.1"` | Yes |
| Ecoregion | `ecoregion_id` | integer | Yes |
| Ecodistrict | `ecodistrict_id` | integer | Yes |

Ecoprovince identifiers should remain character codes internally and in
outputs. Accepting a numeric value such as `10.1` as input is a
convenience, but documentation should recommend the quoted form `"10.1"`
so formatting is preserved if the upstream coding scheme later gains
multi-digit or zero-padded components.

Ecozone IDs are not always unique because some official numeric zones
are represented by named package subdivisions:

| Ecozone ID | Matching names                             |
|-----------:|--------------------------------------------|
|          5 | `Taiga Shield East`, `Taiga Shield West`   |
|          6 | `Boreal Shield East`, `Boreal Shield West` |
|         10 | `Subhumid Prairies`, `Semiarid Prairies`   |

Calls requiring one model must report these as ambiguous rather than
silently choosing the first match. The error should list the matching
names and instruct the user to select by name or full path. Discovery
functions may return all matches for an ambiguous code, just as
catalogue filtering can return multiple models; this distinction should
be explicit and tested.

### Public API design

Add a new optional argument named `strata_code` rather than overloading
the existing `strata_id` argument. In the existing API, `strata_id`
means a tile ID, ecological name, or hierarchical name path. Keeping
numeric codes separate makes validation, documentation, and ambiguity
messages clearer.

Support `strata_code` in:

``` text
predict_rsyc()
calibrate_rsyc()
available_rsyc_models()
rsyc_species()
build_rsyc_dataset()
```

[`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md)
does not need a code filter initially, but it must return the code so
users can discover available values. A future code filter can be added
consistently if useful.

For backward compatibility:

- retain the position and meaning of `strata_id`;
- add `strata_code = NULL` at the end of public signatures where
  possible;
- where selection by code requires omitting a formerly required
  `strata_id`, make `strata_id = NULL` and require later arguments such
  as observations to be supplied by name;
- preserve all existing name- and path-based calls unchanged.

Require exactly one of `strata_id` and `strata_code` for functions that
select one or more specified strata. Reject calls supplying both. For
catalogue functions, both may remain `NULL` to mean no geographic
filter.

Examples of the intended interface:

``` r
predict_rsyc(
  response = "agb",
  species = "PICE.MAR",
  age = c(40, 80),
  strata_level = "ecoregion",
  strata_code = 198
)

calibrate_rsyc(
  response = "volume",
  species = "PICE.MAR",
  strata_level = "ecodistrict",
  strata_code = 134,
  obs_age = c(45, 70),
  obs_response = c(110, 145)
)

available_rsyc_models(
  response = "agb",
  strata_level = "ecoprovince",
  strata_code = "10.1"
)

build_rsyc_dataset(
  response = "agb",
  species = c("PICE.MAR", "POPU.TRE"),
  strata_level = "ecoregion",
  strata_code = c(198, 208),
  age = c(50, 100)
)
```

`strata_code` is not applicable to `strata_level = "tile"`; tile
selection continues to use `strata_id` and values such as `"H14"`.
Return an informative error if a code is supplied for tiles.

For functions where `strata_level` is optional, require exactly one
ecological level when `strata_code` is supplied. The same textual code
can occur at different ecological levels, so matching it across all
levels would be surprising and potentially unsafe.

### Internal representation and resolver

Add one internal helper that maps a level to its source identifier
column:

``` r
.rsyc_strata_code_field <- function(strata_level) {
  switch(
    strata_level,
    ecozone = "ecozone_id",
    ecoprovince = "ecoprovince_id",
    ecoregion = "ecoregion_id",
    ecodistrict = "ecodistrict_id",
    NULL
  )
}
```

Add a shared code normalizer and resolver used by prediction,
calibration, catalogue filtering, and dataset building. It should
support an explicit single-match versus multi-match mode and should:

1.  Accept non-missing finite numeric values or non-empty character
    codes.
2.  Convert values to a canonical character representation for
    comparison.
3.  Compare only against the identifier column for the requested level.
4.  Return the corresponding canonical name/path stored in `strata_id`.
5.  Report an unknown-code error when no matching stratum is available
    for the requested response/species context.
6.  In single-match mode, report an ambiguity error listing every
    matching name/path when a code maps to more than one available
    stratum.
7.  In multi-match discovery mode, return all matching strata
    deterministically.

Do not implement this as four independent code paths. The existing
`.rsyc_select_model()`, `.rsyc_filter_models()`, and
`.rsyc_resolve_dataset_strata()` logic should delegate to the same
resolver so selection behavior and error messages remain consistent.

### Discovery and output columns

Expose a level-specific canonical `strata_code` column in:

- [`available_rsyc_models()`](https://ptompalski.github.io/RSYC/reference/available_rsyc_models.md);
- [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md);
- the `curves` result from
  [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md);
- the spatial result from
  [`rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/rsyc_boundaries.md)
  and
  [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md).

For a row at a given `strata_level`, `strata_code` is drawn from the
matching source field. For example, an ecoregion row uses
`ecoregion_id`. Keep the four raw hierarchy ID fields in `RSYC_models`
for advanced users and provenance.

Ecological boundary layers should preserve all available hierarchy ID
fields.
[`rsyc_boundaries()`](https://ptompalski.github.io/RSYC/reference/rsyc_boundaries.md)
may return both the convenient target-level `strata_code` and the raw
ancestor/current ID fields, but the exact public column contract must be
documented and tested. Tile boundaries should return `strata_code = NA`
only if a uniform cross-level schema is considered valuable; otherwise
omit it for tiles and document that tile IDs remain in `strata_id`.

### Identifier API tests

Add tests covering:

1.  Numeric ecoregion and ecodistrict codes select the same model as the
    corresponding full path.
2.  Quoted ecoprovince codes such as `"10.1"` select the same model as
    its path.
3.  A numeric ecoprovince input such as `10.1` is normalized
    consistently.
4.  [`rsyc_strata()`](https://ptompalski.github.io/RSYC/reference/rsyc_strata.md)
    and
    [`available_rsyc_models()`](https://ptompalski.github.io/RSYC/reference/available_rsyc_models.md)
    expose the expected `strata_code` values.
5.  Vector codes work in
    [`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md)
    and preserve requested order or the package’s documented canonical
    order.
6.  Supplying both `strata_id` and `strata_code` errors.
7.  Supplying neither errors in single-model functions.
8.  Supplying `strata_code` for tiles errors.
9.  Supplying a code without exactly one ecological `strata_level`
    errors in catalogue filters.
10. Unknown codes produce an actionable message.
11. Ambiguous ecozone codes `5`, `6`, and `10` produce an error listing
    both matching names in prediction, calibration, and dataset
    construction.
12. A unique ecozone code resolves successfully.
13. Catalogue discovery with an ambiguous ecozone code returns both
    matching strata rather than silently dropping one.
14. Boundary and model `strata_code` values agree for every published
    national ecological stratum.
15. Existing name, short-name, full-path, and tile-ID behavior remains
    unchanged.

## Corrected national-model coverage findings

`PINU.BAN` and `ABIE.LAS` have selected national models in the current
v20260923 product for both responses and both geographic families:

- ecological-strata AGB;
- ecological-strata volume;
- tile AGB;
- tile volume.

They must not be listed as missing.

Using the v20260709 `previous` indicator joined to the current
authoritative v20260923 `selection_report.csv`, there are 10
national-model coverage losses:

| Geography         | Response | Species    | Current selection reason  |
|-------------------|----------|------------|---------------------------|
| Ecological strata | AGB      | `ALNU.INC` | All candidates ineligible |
| Ecological strata | AGB      | `LARI.LAR` | All candidates ineligible |
| Ecological strata | AGB      | `QUER.RUB` | All candidates ineligible |
| Ecological strata | Volume   | `ALNU.INC` | All candidates ineligible |
| Ecological strata | Volume   | `FRAX.NIG` | No candidate models       |
| Ecological strata | Volume   | `LARI.LAR` | All candidates ineligible |
| Ecological strata | Volume   | `QUER.RUB` | All candidates ineligible |
| Tiles             | AGB      | `LARI.LAR` | All candidates ineligible |
| Tiles             | Volume   | `FRAX.NIG` | All candidates ineligible |
| Tiles             | Volume   | `LARI.LAR` | All candidates ineligible |

These species are considered lower priority for this package update, but
the coverage changes should still be documented in `NEWS.md`.

The current package artifact contains the following examples of
confirmed national coverage:

- `ABIE.LAS`: 66 tile curve rows for AGB and 66 for volume, plus
  ecological curves at all four levels.
- `PINU.BAN`: 145 tile curve rows for AGB and 145 for volume, plus
  ecological curves at all four levels.

## Implementation steps

### 1. Centralize the release contract

Create one release configuration used by the import, export, tests, and
boundary-build scripts. It should contain at least:

- model version;
- upstream Git commit;
- source RDS path or environment-variable convention;
- source RDS SHA-256;
- expected row and column counts;
- expected column names and types;
- boundary version;
- boundary source and checksums.

This avoids repeating release-specific constants in multiple scripts.

Current hard-coded locations include:

``` text
data-raw/import_rsyc_models.R
data-raw/export_rsyc_models.R
data-raw/build_ecostrat.R
tests/testthat/test-data.R
R/data.R
NEWS.md
inst/ECOSTRATIFICATION.md
```

### 2. Update the model importer

Update `data-raw/import_rsyc_models.R` to use the v20260923 source.

The old importer contains a v20260709-specific Latin-1 repair and
regenerates 270 model IDs. Do not apply that workaround to v20260923.
The new source is valid UTF-8 and already contains unique stable IDs.

The importer should:

1.  Read the authoritative RDS.
2.  Verify its SHA-256 and upstream version.
3.  Verify 28,043 rows and 42 expected columns.
4.  Verify the expected column types.
5.  Verify unique `model_id` and lookup keys. Do not incorrectly require
    `ecozone_id` to be unique; instead validate the documented
    one-to-many mappings for IDs 5, 6, and 10.
6.  Verify responses, units, scale values, strata levels, and equation.
7.  Verify `publish_ok`, finite coefficients, and positive national
    calibration variances.
8.  Preserve upstream `model_id` values unchanged.
9.  Save `data/RSYC_models.rda` using the existing package data format.

The default source path may point to the sibling RSYC-Canada project,
while continuing to support `RSYC_MODELS_SOURCE` for reproducible
overrides.

### 3. Update the model export

Update `data-raw/export_rsyc_models.R` for the new version, dimensions,
and 42-column schema. Regenerate:

``` text
data/RSYC_models.rda
data-raw/RSYC_models.zip
data-raw/RSYC_models_manifest.csv
```

The manifest should record more than the output ZIP checksum. Prefer
including:

- model version;
- upstream Git commit;
- source RDS SHA-256;
- output ZIP SHA-256;
- archive member;
- row and column counts;
- build time.

Retain the CSV round-trip checks for IDs, version, schema, and
coefficients.

### 4. Rebuild ecological boundaries as a new boundary release

The current ecological boundary file is not sufficient for v20260923.

Current versus new model-aligned boundary counts are:

| Layer        | Current | v20260923 |
|--------------|--------:|----------:|
| Ecozones     |      12 |        17 |
| Ecoprovinces |     101 |        44 |
| Ecoregions   |     257 |       154 |
| Ecodistricts |     936 |       721 |

The current boundary file lacks geometry for model paths introduced in
the new catalogue, including 5 ecozones, 8 ecoprovince paths, 17
ecoregion paths, and 60 ecodistrict paths. Without rebuilding it,
[`build_rsyc_dataset()`](https://ptompalski.github.io/RSYC/reference/build_rsyc_dataset.md)
will fail for valid new models at its missing-geometry check.

Update `data-raw/build_ecostrat.R` to:

- use `v20260923` as the source model version;
- declare a new boundary version, recommended `v2`;
- expect the new layer counts;
- accept and preserve the four ecological ID fields;
- verify that model and boundary identifier mappings agree;
- validate EPSG:3978, geometry validity, UTF-8, layer names, fields, and
  join keys;
- write a deterministic artifact and checksum manifest.

Use a versioned cache filename such as:

``` text
RSYC_ecostrat_v2.gpkg
```

This prevents an existing cached v1 file from colliding with the new
checksum. Update `R/ecostrat.R`, tests, documentation, URL, and checksum
accordingly.

The published URL should eventually use an immutable release or tag
rather than the current `dev` branch URL.

### 5. Decide and document the tile-boundary policy

The current bundled tile file contains 389 tile IDs. It covers every
tile ID needed by the new national model catalogue but includes four IDs
no longer used by the new models:

``` text
D34
E35
P1
R1
```

The new upstream GeoPackage has 649 tile feature rows but only 385
distinct model join keys. Do not copy that layer directly into the
package: multiple features must be dissolved by `join_key` to obtain
model-aligned tile polygons.

Preferred approach:

1.  Extract the `tiles` layer from the v20260923 GeoPackage.
2.  Dissolve geometries by `join_key`.
3.  Validate 385 unique non-missing keys and EPSG:3978.
4.  Write a package-compatible `RSYC_tiles.gpkg` with one row per tile.
5.  Update boundary tests from 389 to 385 rows.

Alternatively, retain the current tile file after documenting that it
covers all new model keys. Rebuilding is preferred because it provides
clean v20260923 provenance and removes the four retired tiles.

### 6. Remove obsolete special handling

The v20260923 catalogue no longer contains the previously hidden invalid
ecodistrict path:

``` text
Taiga Shield West/Keewatin Lowlands/Dubawnt Lake Plain/Upland
```

Review and preferably remove the release-specific filter in `R/utils.R`
and its associated tests. General catalogue validation should replace a
hard-coded exception where possible.

### 7. Update package version and documentation

Recommended package version while developing:

``` text
0.2.0.9000
```

Use `0.2.0` for the eventual release. This update changes predictions,
model availability, the public model-table schema, and boundary
products, so a minor version is more appropriate than a patch.

Update source documentation:

``` text
DESCRIPTION
NEWS.md
R/data.R
inst/ECOSTRATIFICATION.md
README.Rmd, where applicable
vignettes/articles/Model-parameters.Rmd
vignettes/articles/Local-calibration.Rmd
```

Document the four new ID columns and the corrected coverage changes.
Re-render calibration examples because their numerical results will
change with the new coefficients.

Add user documentation and examples for selecting by `strata_code`,
including the ambiguous ecozone IDs and the recommendation to quote
ecoprovince codes.

Regenerate rather than hand-edit:

``` text
man/
docs/
README.md and README.html when generated from README.Rmd
```

### 8. Update tests

Update the model contract tests for:

- 28,043 rows;
- 42 columns;
- version `v20260923`;
- the four new ecological ID columns;
- unique IDs and lookup keys;
- valid UTF-8;
- finite coefficients and positive calibration variances.

Implement the identifier API tests listed in the numeric eco-strata
selection section. Update existing exact-column-name assertions for the
new `strata_code` discovery and dataset outputs.

The existing tests were run in memory against the new table. Prediction
and calibration logic were compatible. Expected fixture changes
included:

- the old row, column, and version assertions;
- tests expecting the short ecological name `Muskwa` to be ambiguous,
  which is no longer true for the relevant new catalogue subset.

Add an exhaustive boundary compatibility test for every public level:

``` text
all unique national model strata_id values must occur in the corresponding
boundary layer
```

Also test that boundary join keys are unique after any tile dissolve.

### 9. Validate the completed update

Required validation gates:

1.  Source checksum and upstream Git commit recorded.
2.  Exact schema and type contract passes.
3.  No duplicate model IDs or lookup keys.
4.  All published coefficients are finite.
5.  All national calibration variances are finite and positive.
6.  Every national model stratum joins to exactly one boundary geometry.
7.  Model, catalogue, and boundary code-to-path mappings agree.
8.  Exported CSV round-trips without meaningful coefficient changes.
9.  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
    completes.
10. [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
    passes.
11. `R CMD check --as-cran` passes.
12. Package site and vignettes build successfully.
13. Smoke tests cover AGB and volume, tiles and ecological strata,
    prediction, local calibration, and GeoPackage dataset export.

Representative smoke-test species should include `PINU.BAN`, `ABIE.LAS`,
`PICE.MAR`, and a broad species group. Each ecological smoke-test
workflow should be exercised once by name/path and once by
`strata_code`, with identical model IDs and predictions expected.

## Completion and merge

When all validation gates pass:

``` powershell
git push origin model-v20260923
```

Open a pull request from `model-v20260923` into `dev`. After merging:

``` powershell
git switch dev
git pull --ff-only origin dev
git branch -d model-v20260923
```

Keep `main` unchanged. When the paper is published, merge the validated
`dev` branch into `main`, create the formal package release, and add the
final version tag.

## Instructions for a future implementation chat

Start by reading this file, checking `git status`, confirming the active
branch, and rechecking the modification times and checksums of the
authoritative v20260923 inputs. Do not trust the stale summary
comparison’s `selected` field. Use the current product
`selection_report.csv` and the actual `rsyc_models_rpackage.rds` as the
primary model-selection and package-data sources. Implement the numeric
eco-strata API through the shared resolver described above; do not
assume ecozone IDs are unique.
