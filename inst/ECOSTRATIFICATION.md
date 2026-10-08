# RSYC ecological-stratification data

The optional `RSYC_ecostrat.gpkg` file contains the parts of the National
Ecological Framework for Canada used by RSYC. It includes maps of ecozones,
ecoprovinces, ecoregions, and ecodistricts used by model release `v20260923`.
This model-aligned boundary release is version `v2` and contains boundary maps
only, not yield curves.

The four layers contain 12 forested ecozones, 36 ecoprovinces, 138 ecoregions,
and 672 ecodistricts. Every feature corresponds to exactly one national model
`strata_id`. The v2 GeoPackage SHA-256 is
`e425818f3c1db682f21a6eec6bebf4397761db46b08b13b8c4d3c780dc0d87a4`;
its authoritative source GeoPackage SHA-256 is
`739a3c3c0aeb8ef235a567bc01220ce94ebea7b9c3c92b70c822e9f08ef4c858`.

Source: Agriculture and Agri-Food Canada, *National Ecological Framework for
Canada*:
https://open.canada.ca/data/dataset/3ef8e8a9-8d05-4fea-a8bf-7f5023d2b6e1

Original GIS downloads:
https://sis.agr.gc.ca/cansis/nsdb/ecostrat/gis_data.html

Source and licence pages accessed 2026-09-13. The distributed boundaries were
taken from the mapping files supplied with RSYC-Canada model release
`v20260923` at upstream Git commit
`c799aba24b5d99a6a7953a4dcab1dd73b0925c2c`.

Licence: Open Government Licence - Canada:
https://open.canada.ca/en/open-government-licence-canada

Attribution: Contains information licensed under the Open Government Licence
– Canada.

RSYC and its authors did not develop the National Ecological Framework for
Canada. The presence or use of these data does not imply endorsement by the
Government of Canada.

The downloadable file contains only ecological areas within the forested
ecozones that have published RSYC curves. The maps use the Canada Atlas Lambert
projection (EPSG:3978) and retain the four hierarchy names, `ecozone_id`,
`ecoprovince_id`, `ecoregion_id`,
`ecodistrict_id`, and `join_key` used to link boundaries to curves. Area shapes
were not simplified. See `data-raw/build_ecostrat.R` in the RSYC source
repository for details on how the file was prepared and checked.

Until boundary v2 is published as an immutable release asset, the package's
default download URL temporarily points to the versioned file on the `dev`
branch. The SHA-256 check still pins the exact accepted content.
