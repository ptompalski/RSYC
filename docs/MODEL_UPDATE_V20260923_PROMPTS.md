# Copy-ready prompts for the RSYC v20260923 update

These prompts split `MODEL_UPDATE_V20260923_PLAN.md` into bounded tasks
suitable for separate chats. Use them in order because later tasks
assume earlier changes are present in the working tree or branch
history.

General rules for every task:

- Repository: `K:\_PROJECTS\RSYC`
- Keep `main` unchanged until the paper is published.
- Use `dev` as the integration branch.
- Perform implementation work on `model-v20260923` unless the prompt
  explicitly concerns merging `local-calibration` into `dev`.
- Preserve unrelated user changes and the untracked
  `RSYC_package_description.md` file.
- Read `MODEL_UPDATE_V20260923_PLAN.md` before acting.
- Inspect the current Git status and branch before modifying files.
- Do not rely on the stale `selected` column in
  `outputs/summaries/model_status/selection/v20260923/selection_vs_v20260709_coverage.csv`.
- Treat the current product `selection_report.csv` and
  `rsyc_models_rpackage.rds` as authoritative.
- Do not merge into `main`.

## Prompt 1: prepare the Git branches

``` text
Work in K:\_PROJECTS\RSYC. Read MODEL_UPDATE_V20260923_PLAN.md, then perform only
the Git branch preparation for the model update.

First inspect git status, branch tracking, and the relationship between dev and
local-calibration. Preserve all unrelated and untracked files. Confirm that
local-calibration is a direct descendant of dev and that a fast-forward is
still possible. Run the relevant existing tests for the local-calibration work
before merging.

If validation passes, fast-forward local-calibration into dev without changing
main. Create an annotated pre-model-v20260923 tag at the updated dev commit, and
create a new model-v20260923 branch from that dev commit. Do not delete the
local-calibration branch. Do not make model or package-data changes in this
task. Do not push or create a pull request unless I explicitly authorize the
remote operation in this chat.

At the end, report the resulting commit graph, active branch, test result, tag,
and git status.
```

## Prompt 2: centralize the model-release contract

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md and inspect the current import, export, boundary,
and model-data tests.

Perform only this task: create one internal release-contract source for the
v20260923 package update and refactor the data-raw model import/export scripts
to read their release-specific constants from it. The contract must include the
model version, upstream Git commit, source path convention, source checksum,
expected dimensions, exact column names and types, and boundary version/source
metadata. Preserve support for the RSYC_MODELS_SOURCE environment variable.

Use the current files under
K:\_PROJECTS\RSYC-Canada\outputs\products\models\versions\v20260923 as the
authoritative inputs. Recompute their checksums rather than copying an old
value. Do not yet replace data/RSYC_models.rda, export the ZIP, rebuild
boundaries, modify the public R API, or regenerate documentation.

Add focused tests or executable validation for the centralized contract. Run
only the checks necessary for this refactor and report all files changed,
recorded checksums, and validation results. Do not commit unless I ask.
```

## Prompt 3: update the model importer and packaged dataset

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md and the centralized release contract created in
the previous task.

Perform only this task: update the model importer for v20260923 and rebuild
data/RSYC_models.rda from the authoritative rsyc_models_rpackage.rds.

Remove or bypass the v20260709-specific Latin-1 repair and model-ID regeneration
for the new release. Preserve the upstream model_id values. Validate the source
checksum, model version, 28,043 rows, 42 columns, exact names and types, unique
model IDs and lookup keys, response units, scales, strata levels, equation,
publish_ok, finite coefficients, and positive finite national calibration
variances. Do not incorrectly require ecozone_id to be unique: IDs 5, 6, and 10
have documented one-to-many name mappings.

Replace only the packaged model dataset and directly related import code/tests.
Do not rebuild exports or boundaries, implement selection by numeric eco-strata
IDs, change public functions, regenerate pkgdown, or edit main.

Run the importer twice if practical to demonstrate deterministic packaged data,
then run the focused model-data tests. Report the source checksum, resulting
artifact size, model dimensions, invariant results, and git diff summary. Do
not commit unless I ask.
```

## Prompt 4: rebuild the downloadable model export and provenance

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md. Assume data/RSYC_models.rda has already been
rebuilt from the authoritative v20260923 source.

Perform only this task: update the model export pipeline and regenerate
data-raw/RSYC_models.zip and data-raw/RSYC_models_manifest.csv.

The export must validate the v20260923 version, 28,043 rows, 42-column schema,
unique model IDs, and finite curve coefficients. Verify a UTF-8 CSV round trip,
including exact IDs/version/schema and coefficient equality within the existing
strict tolerance. Expand provenance to record the upstream Git commit, source
RDS SHA-256, output ZIP SHA-256, archive member, dimensions, and build time.

Do not change boundaries, public R functions, numeric eco-strata selection,
vignettes, pkgdown output, or main. Run the export and focused round-trip
checks, then report artifact sizes, checksums, manifest contents, and git diff
summary. Do not commit unless I ask.
```

## Prompt 5: rebuild ecological boundaries as v2

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md and inspect R/ecostrat.R,
data-raw/build_ecostrat.R, boundary tests, and the authoritative
RSYC_ecosystem_model_package.gpkg.

Perform only this task: build and integrate the v20260923 ecological boundary
release as boundary version v2.

The expected model-aligned layers contain 17 ecozones, 44 ecoprovinces, 154
ecoregions, and 721 ecodistricts. Preserve the four hierarchy ID fields,
hierarchy names, join_key, EPSG:3978 geometries, and deterministic output.
Validate layer names, exact fields, feature counts, geometry validity, UTF-8,
unique join keys at each layer, and complete coverage of all national
ecological model strata_id values.

Use a versioned cache filename such as RSYC_ecostrat_v2.gpkg so existing cached
v1 files do not collide with the new checksum. Update the runtime filename,
checksum, manifest, cache/download tests, and source documentation directly
related to the boundary product. Prefer an immutable release/tag URL design;
if no immutable URL exists yet, make the temporary state explicit rather than
inventing one.

Do not update the tile boundary file, implement numeric-ID selection, regenerate
all package documentation, or touch main. Run focused boundary and
model-to-boundary join tests. Report the artifact checksum, size, layer counts,
join coverage, tests, and git diff summary. Do not commit unless I ask.
```

## Prompt 6: rebuild the bundled tile boundaries

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md and inspect the current tile boundary build/data
contract and the tiles layer in the authoritative v20260923 GeoPackage.

Perform only this task: rebuild inst/extdata/RSYC_tiles.gpkg as a model-aligned
v20260923 tile product.

The upstream layer has 649 feature rows but 385 distinct model join keys. Do not
copy it directly. Dissolve geometries by join_key, produce exactly one valid
EPSG:3978 feature for each of the 385 model tile IDs, and preserve the public
package field contract needed by rsyc_boundaries(). Confirm that retired tile
IDs D34, E35, P1, and R1 are no longer included and that every national tile
model has exactly one boundary.

Make the build reproducible, record source provenance and checksums, and update
only tile-boundary tests/documentation directly affected by the new 385-row
artifact. Do not alter ecological boundaries, public model-selection APIs,
numeric eco-strata selection, pkgdown output, or main.

Run focused tile geometry, uniqueness, CRS, and model-join tests. Report the
input/output counts, checksum, geometry validation, tests, and git diff summary.
Do not commit unless I ask.
```

## Prompt 7: remove obsolete release-specific model filtering

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md and inspect R/utils.R and all tests referencing
the known invalid ecodistrict model.

Perform only this task: remove the obsolete hard-coded filter for
"Taiga Shield West/Keewatin Lowlands/Dubawnt Lake Plain/Upland" if the current
v20260923 catalogue and tests confirm that no such invalid published row is
present. Replace release-specific behavior with a general catalogue invariant
where appropriate.

Do not change model artifacts, boundaries, public function signatures,
numeric-ID selection, general documentation, or main. Run the catalogue,
prediction, calibration, and dataset tests needed to prove that removal is
safe. Report evidence, changed files, and test results. Do not commit unless I
ask.
```

## Prompt 8: update the existing tests for the new model release

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md. Assume the v20260923 model data and both boundary
products have already been integrated.

Perform only this task: update and strengthen the existing automated tests for
the new model and boundary release, without implementing numeric eco-strata ID
selection yet.

Update fixed expectations for version v20260923, 28,043 model rows, 42 model
columns, revised boundary counts, changed ecological-name ambiguity, and the
four new raw hierarchy ID columns. Add exhaustive tests that every national
model strata_id joins to exactly one boundary at its level. Preserve and run
prediction and local-calibration formula tests against the new coefficients.
Remove or replace fixtures that depended on old model availability, but do not
weaken meaningful invariants merely to make tests pass.

Do not change public APIs, implement strata_code, regenerate documentation, or
touch main. Run the complete test suite and report failures, warnings, skips,
coverage gaps, and git diff summary. Do not commit unless I ask.
```

## Prompt 9: update package version and source documentation

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md. Assume model data, exports, boundaries, cleanup,
and non-ID tests are complete.

Perform only this task: update the package version and source documentation for
the v20260923 model release, excluding the numeric eco-strata selection feature.

Use development version 0.2.0.9000 unless the repository already follows a
different explicit convention. Update DESCRIPTION, NEWS.md, R/data.R,
inst/ECOSTRATIFICATION.md, README.Rmd where applicable, and the model-parameter
and local-calibration vignettes. Document the 42-column model contract, four raw
hierarchy ID fields, corrected model-coverage changes, boundary v2 product, tile
boundary update, provenance, and changed prediction/calibration results.

Regenerate roxygen documentation, README outputs when source-generated, and the
pkgdown site rather than hand-editing generated files. Do not implement or
document strata_code yet, do not merge branches, and do not touch main.

Run documentation examples, vignette builds, and relevant checks. Report all
generated files, warnings, rendered-example changes, and git diff summary. Do
not commit unless I ask.
```

## Prompt 10: validate the model-and-boundary update before the ID feature

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923. Read
MODEL_UPDATE_V20260923_PLAN.md. Perform only a validation and diagnosis pass for
the completed v20260923 model-and-boundary update. Do not implement numeric
eco-strata ID selection in this task.

Verify source checksums and upstream Git commit, exact schema/types, unique
model IDs and lookup keys, finite coefficients, positive national calibration
variances, complete one-to-one model/boundary joins, export round-trip fidelity,
and documented model coverage. Run the full test suite, devtools::document(),
vignette builds, pkgdown build, and R CMD check --as-cran as appropriate for the
environment. Smoke-test AGB and volume, tiles and ecological strata,
prediction, local calibration, and GeoPackage dataset export using important
species including PINU.BAN, ABIE.LAS, and PICE.MAR.

Do not make fixes unless they are trivial validation-fixture corrections. For
any substantive issue, diagnose it and report the exact recommended change for
a separate implementation task. Do not commit, merge, push, or touch main.

Return a release-gate checklist with pass/fail status and concrete evidence.
```

## Prompt 11: implement numeric eco-strata identifier selection

``` text
Work in K:\_PROJECTS\RSYC on model-v20260923 after the core v20260923 model and
boundary update has passed its validation gates. Read the "Numeric eco-strata
selection API" section of MODEL_UPDATE_V20260923_PLAN.md before changing code.

Perform only this feature: allow users to select ecological models by their new
numeric/code identifiers while preserving every existing name, full-path, and
tile-ID workflow.

Implement a new optional public argument named strata_code in predict_rsyc(),
calibrate_rsyc(), available_rsyc_models(), rsyc_species(), and
build_rsyc_dataset(). Keep strata_id backward compatible and require exactly one
of strata_id and strata_code in single-selection workflows. Both may be NULL in
catalogue workflows that intentionally apply no geographic filter. Reject
strata_code for tile selection.

Map levels to ecozone_id, ecoprovince_id, ecoregion_id, and ecodistrict_id with
one shared internal normalizer/resolver. Preserve ecoprovince codes as character
values such as "10.1", while accepting finite numeric input as a convenience.
Require exactly one ecological strata_level when filtering by code.

Handle non-unique ecozone codes explicitly:
- 5 maps to Taiga Shield East and Taiga Shield West.
- 6 maps to Boreal Shield East and Boreal Shield West.
- 10 maps to Subhumid Prairies and Semiarid Prairies.

Prediction, calibration, and dataset construction must error on these ambiguous
codes and list matching names. Catalogue discovery may return all matches
deterministically. Never silently select the first row.

Expose a canonical target-level strata_code in available_rsyc_models(),
rsyc_strata(), dataset curves, and ecological spatial outputs. Preserve the raw
four hierarchy ID fields in RSYC_models and the boundary data. Document the
public output-column contract.

Implement every identifier-specific test listed in the plan, including
equivalence between code and name/path predictions, quoted and numeric
ecoprovince inputs, vector dataset codes, unknown codes, both/neither argument
errors, tile rejection, ambiguous ecozones, catalogue multi-match behavior,
boundary/model mapping consistency, and regression coverage for all existing
selection methods.

Update roxygen, README/vignettes as appropriate, regenerate generated docs, and
run the full test suite, documentation examples, vignettes, pkgdown build, and
R CMD check. Repeat representative smoke tests once by name/path and once by
strata_code; model IDs and predictions must be identical.

Do not merge, push, or touch main. At the end, report the public API changes,
ambiguity behavior, output-column changes, tests/check results, and git diff
summary. Do not commit unless I ask.
```

## After all prompts

Once Prompt 11 passes, review the complete branch diff from `dev`,
decide on commit boundaries, push `model-v20260923`, and open a pull
request targeting `dev`. Keep `main` frozen until the paper is
published.
