library(tidyverse)
library(sp)
library(raster)

# PSID to treatment objective code key from SWRCB.
# To the best of my knowledge, and from converations with people at
# the SWRCB (emails below), this data is not public.
# "Lichti, Betsy@Waterboards" <Betsy.Lichti@waterboards.ca.gov>,
# "Zarghami, Rassam@Waterboards" <Rassam.Zarghami@waterboards.ca.gov>,
# "Williams, Paul@Waterboards" <Paul.Williams@waterboards.ca.gov>,
# "Killou, Wendy@Waterboards" <Wendy.Killou@waterboards.ca.gov>
d  <- readxl::read_excel("/Users/richpauloo/Downloads/unit process objectives.xlsx")

# exceedance compliance points
# download, upzip, and read the spatial points
url  <- "https://www.waterboards.ca.gov/water_issues/programs/hr2w/docs/data/ec_summary_jun2019.zip"
temp <-tempfile()
download.file(url, temp)

# change exdir paths to a local working directory
unzip(temp, 
      exdir = "/Users/richpauloo/Desktop/ca_water_datathon/shp/")

rm(temp) # remove temp files

# read exceedance points 
ep <- list.files("/Users/richpauloo/Desktop/ca_water_datathon/shp/", 
                 pattern = ".shp$", full.names = TRUE) %>% 
  shapefile() %>% 
  spTransform('+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs')

ep$WATER_SYST <- substr(ep$WATER_SYST, 3, 9)
ep$url <- paste0("<b><a href='https://caccr.github.io/ccrs/", 
                 ep$WATER_SYST,
                 "/index.html'>CLICK TO VIEW CCR</a></b>")

# split into list for each set of circle markers
# epl <- sf::st_as_sf(ep) %>% 
#   sf::st_jitter() %>% 
#   as(., "Spatial") %>% 
#   split(., ep$GIS_STATUS)

# l <- leaflet()
# cols <- c("lightblue", "red", "orange")

# for(i in 1:3){
#   l <- l %>% addCircleMarkers(epl[[i]], 
#                         lng = coordinates(epl[[i]])[,1],
#                         lat = coordinates(epl[[i]])[,2],
#                         radius = 2,
#                         color = cols[i], 
#                         group = names(epl)[i],
#                         label = paste0(epl[[i]]$WATER_SY_1, 
#                                        " (PWSID: ", epl[[i]]$WATER_SYST, ")"),
#                         popup = paste0(epl[[i]]$WATER_SY_1, "<br>",
#                                        "PWSID: ",  epl[[i]]$WATER_SYST, "<br>",
#                                        "STATUS: ", epl[[i]]$GIS_STATUS, "<br>",
#                                        epl[[i]]$url)
#   )
# }
# 
# l %>% 
#   addProviderTiles(providers$CartoDB.DarkMatterNoLabels,  group = "Carto") %>% 
#   addProviderTiles(providers$Esri.WorldImagery, group = "World") %>% 
#   addProviderTiles(providers$OpenStreetMap,     group = "Street") %>% 
#   setView(-119, 37.5, 6) %>% 
#   addLayersControl(
#     overlayGroups = names(epl),
#     baseGroups = c("Carto", "World", "Street"),
#     options = layersControlOptions(collapsed = TRUE, 
#                                    position = "bottomright")
#   ) %>% 
#   # buttons
#   addEasyButton(easyButton(
#     icon="fa-crosshairs", title="Locate Me",
#     onClick=JS("function(btn, map){ map.locate({setView: true}); }"), 
#     position = "topleft")) %>% 
#   addEasyButton(easyButton(
#     icon="fa-globe", title="Zoom to Level 1",
#     onClick=JS("function(btn, map){ map.setZoom(6); }"),
#     position = "topleft")) %>% 
#   
#   # geocoding
#   leaflet.extras::addSearchOSM(options = list(position = "topright"))



# human right to water ACTIVE data only shows MCL violations
# thus, it won't show all analytes for which we want information
# https://www.waterboards.ca.gov/water_issues/programs/hr2w/docs/data/hr2w_web_data_active.xlsx
url <- "https://www.waterboards.ca.gov/water_issues/programs/hr2w/docs/data/hr2w_web_data_active.xlsx"
dest <- "/Users/richpauloo/Downloads/hr2w_web_data_active.xlsx"
download.file(url, destfile = dest)
hrw <- readxl::read_xlsx(dest)

# clean psids
hrw$WATER_SYSTEM_NUMBER <- as.numeric(substr(hrw$WATER_SYSTEM_NUMBER, 3, 9))

# fix dates
hrw$VIOL_BEGIN_DATE       <- lubridate::ymd(hrw$VIOL_BEGIN_DATE)
hrw$VIOL_END_DATE         <- lubridate::ymd(hrw$VIOL_END_DATE)
hrw$ENF_ACTION_ISSUE_DATE <- lubridate::ymd(hrw$ENF_ACTION_ISSUE_DATE)

# filter for 2018
hrw_2018 <- filter(hrw, VIOL_BEGIN_DATE >= lubridate::ymd("2018-01-01"))


# SDWIS chemical data has it all (violations and no violations)
# however, there's no field indicating if the data is untreated 
# or treated water. We get that from the PSID key sent by Rassam.
# chem data is the ~ 4GB output of `00_downlad_clean.R`
# need to read the station codes in as character since leading zeros
# are dropped if read in as integers
chem <- data.table::fread("/Users/richpauloo/Desktop/ca_water_datathon/chem.csv",
                           colClasses = c(PRIM_STA_C = "character"))
# sanity check: are all station codes 7 digits?
table(nchar(chem$PRIM_STA_C)) 

# PSID goes by many names in different datasets.
# fundamentally, it is the station level unique ID
# Thus: hrw$WATER_SYSTEM_NUMBER = d$NUMBER0 = paste0("CA", chem$PRIM_STA_C)

# PSIDs of all treatment plants (that we know of, as data is incomplete)
tps <- filter(d, FACILITY_TYPE_CODE == "TP") %>% 
  pull(NUMBER0) %>% 
  unique()
table(nchar(tps))        # sanity check that all are 9 digits
tps <- substr(tps, 3, 9) # subset the leading "CA"

# filter for rows in chem that are treatment plants
chem_tp <- filter(chem, PRIM_STA_C %in% tps)

# this is the percentage of data retained, post-filter
nrow(chem_tp) / nrow(chem)

# save
#write_rds(chem_tp, "/Users/richpauloo/Desktop/ca_water_datathon/chem_tp.rds")
write_rds(filter(chem_tp, PRIM_STA_C %in% tps[1:5]),
          "/Users/richpauloo/Desktop/ca_water_datathon/chem_tp_sub.rds")

# write the minimal subset of data for an app 
z <- select(chem_tp, PRIM_STA_C, CHEMICAL__, MCL, RPT_UNIT, XMOD,
            FINDING, `Water System Name`, `Principal County Served`, 
            CITY, `Primary Water Source Type`, `Total Population`, 
            `Total Number of Service Connections`)
write_rds(z,
          "/Users/richpauloo/Desktop/ca_water_datathon/chem_tp_min.rds")

z2017 <- dplyr::select(chem_tp, SAMP_DATE, PRIM_STA_C, CHEMICAL__, MCL, RPT_UNIT,
                FINDING, `Water System Name`, `Principal County Served`, 
                CITY, `Primary Water Source Type`, `Total Population`, 
                `Total Number of Service Connections`, XMOD) %>% 
  mutate(SAMP_DATE = lubridate::ymd(SAMP_DATE)) %>% 
  filter(SAMP_DATE >= lubridate::ymd("2017-01-01"))

write_rds(z2017,
          "/Users/richpauloo/Desktop/ca_water_datathon/chem_tp_min_2017.rds")

