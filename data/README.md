# README

This folder contains data to start working with.  

### Chemical data

`chem_sub.rds` : USE FOR TESTING PURPOSES (2000 rows by 55 columns) subset of the first five water systems from 2012-2019 (`PRIM_STA_C` is the unique identifier, and the same as PWSID or PSID)  
`chem_tp_min_2019.zip` : USE POST-TESTING (600,000 rows by 13 columns). subset of the chemical data for observations taken in 2019, and only including 13 relevant fields. Unzips to a 122 MB .rds file.  


### Other data

`psids_not_in_hrw_gis_data.csv`: 1 column data frame of PSIDs that we have chemical data for, but not compliance status for. These correspond to stations that are NOT listed in the [HWR GIS data - link 'Download GIS Map Shapfile'](https://www.waterboards.ca.gov/water_issues/programs/hr2w/), from which we currently obtain compliance status.  