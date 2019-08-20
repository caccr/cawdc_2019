library(tidyverse)
library(rgdal)
library(sf)

# read the minimal, cleaned, post-treatment data from `02_get_treated_water.R`
chem_tp_min_2019 <- read_rds("/Users/richpauloo/Desktop/ca_water_datathon/chem_tp_min_2019.rds")


##########################################################################
# get spatial data: polygons
##########################################################################
sa <- geojsonio::geojson_read("https://data.ca.gov/sites/default/files/wsb_180622_oima.json", 
                              what = "sp")
sa@data <- select(sa@data, 
                  pwsid, address_city_name, 
                  addr_line_one_txt, addr_line_two_txt,
                  address_zip)
sa@data$addr_line_two_txt <- as.character(sa@data$addr_line_two_txt)
sa@data$addr_line_two_txt[is.na(sa@data$addr_line_two_txt)] <- ""
sa@data <- mutate(sa@data, 
                  address = paste0(addr_line_one_txt, ' ', addr_line_two_txt,
                                   address_city_name, ', CA ', address_zip)
                  )
sa@data <- select(sa@data, pwsid, address)
sa@data$pwsid <- substr(as.character(sa@data$pwsid), 3, 9)

# simplify for smaller file size, and onvert to sf
sa <- rmapshaper::ms_simplify(sa, keep_shapes = TRUE) %>%
  st_as_sf() 

# remove duplicate pwsids (analysis below shows that they're duplicates)
# sa %>% group_by(pwsid) %>% filter(n() > 1) %>% arrange(pwsid) %>% View()
sa <- sa %>% group_by(pwsid) %>% slice(1) %>% ungroup()


##########################################################################
# get spatial data: points
##########################################################################

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
  raster::shapefile() %>% 
  spTransform('+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs')

ep$WATER_SYST <- substr(ep$WATER_SYST, 3, 9)
ep$url <- paste0("<b><a href='https://caccr.github.io/ccrs/", 
                 ep$WATER_SYST,
                 "/' target='_blank'>CLICK TO VIEW CCR</a></b>")


##########################################################################
# subset for psids
##########################################################################
#psids <- unique(chem_tp_min$PRIM_STA_C)
psids <- unique(chem_tp_min_2019$PRIM_STA_C) # clean chemical data (2019)

# get variables for mapply to pass to .Rmd params
zz <- filter(chem_tp_min_2019, PRIM_STA_C %in% psids) %>% 
  group_by(PRIM_STA_C) %>% 
  slice(1)

# vars to pass to mapply that each .Rmd report needs as params
nams     <- zz$`Water System Name`
cities   <- zz$CITY
counties <- zz$`Principal County Served`

# create directories for files
#for(i in 1:length(psids)){
for(i in 1:20){
  dir.create(paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i]))
}

##########################################################################
# generate ccrs by first calling `03_psid_params` and passing this script
# a psid. `03_psid_params` depends on the object `chem_tp`, which is loaded
# in this script
##########################################################################
gen_reports <- function(x,y,w,k) {
  rmarkdown::render(input = "/Users/richpauloo/Desktop/ca_water_datathon/03_psid_params.Rmd", 
                    output_file = sprintf("/Users/richpauloo/Github/jmcglone.github.io/ccrs/%s/index.html", x),
                    params = list(psid = x, nam = y,
                                  city = w, county = k))
}

mapply(gen_reports, psids[1:20], nams[1:20], cities[1:20], counties[1:20])

# add navbar to each file by reading in each index.html, and splicing in
# the appropriate HTML, given in `nav_bar_sub_head`
navbar <- read_lines("/Users/richpauloo/Desktop/ca_water_datathon/nav_bar_sub_head")

# read in the HTML files, insert the navbar code, then re-write the files
#for(i in 1:length(psids)){
for(i in 1:20){
  index <- read_lines(paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], "/index.html"))
  index <- c(index[1:9], navbar, index[10:length(index)])
  write_lines(index, paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], "/index.html"))
}


##########################################################################
# write the master index.html file
##########################################################################
rmarkdown::render(input = "/Users/richpauloo/Desktop/ca_water_datathon/05_master_index.Rmd", 
                  output_file = "/Users/richpauloo/Github/jmcglone.github.io/index.html")


##########################################################################
# write the about index.html file and add the navbar
##########################################################################
rmarkdown::render(input = "/Users/richpauloo/Desktop/ca_water_datathon/06_about_index.Rmd", 
                  output_file = "/Users/richpauloo/Github/jmcglone.github.io/about/index.html")
index <- read_lines("/Users/richpauloo/Github/jmcglone.github.io/about/index.html")
index <- c(index[1:9], navbar, index[10:length(index)])
write_lines(index, "/Users/richpauloo/Github/jmcglone.github.io/about/index.html")


##########################################################################
# write the error 404 page
##########################################################################
rmarkdown::render(input = "/Users/richpauloo/Desktop/ca_water_datathon/07_error_404.Rmd", 
                  output_file = "/Users/richpauloo/Github/jmcglone.github.io/404.html")

# key for linking psid with name to use in master index.html
# select(chem_tp_min_2019, PRIM_STA_C, `Water System Name`) %>% 
#   distinct() %>% 
#   write_rds(., "/Users/richpauloo/Desktop/ca_water_datathon/psid_name_key.rds")
