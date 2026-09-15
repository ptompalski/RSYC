# RSYC ecological-stratification data

The optional `RSYC_ecostrat.gpkg` file contains the parts of the National
Ecological Framework for Canada used by RSYC. It includes maps of ecozones,
ecoprovinces, ecoregions, and ecodistricts. These boundaries remain the same
across RSYC model releases. The file contains boundary maps only, not yield
curves.

Source: Agriculture and Agri-Food Canada, *National Ecological Framework for
Canada*:
https://open.canada.ca/data/dataset/3ef8e8a9-8d05-4fea-a8bf-7f5023d2b6e1

Original GIS downloads:
https://sis.agr.gc.ca/cansis/nsdb/ecostrat/gis_data.html

Source and licence pages accessed 2026-09-13. The distributed boundaries were
taken from the mapping files supplied with RSYC-Canada model release
`v20260709`. The boundaries themselves are not specific to that model release.

Licence: Open Government Licence - Canada:
https://open.canada.ca/en/open-government-licence-canada

Attribution: Contains information licensed under the Open Government Licence
– Canada.

RSYC and its authors did not develop the National Ecological Framework for
Canada. The presence or use of these data does not imply endorsement by the
Government of Canada.

The downloadable file contains only ecological areas with published RSYC
curves. The maps use the Canada Atlas Lambert projection (EPSG:3978) and retain
the English area names and `strata_id` used to link boundaries to curves. Area
shapes were not simplified. See `data-raw/build_ecostrat.R` in the RSYC source
repository for details on how the file was prepared and checked.
