library(tidyverse)
library(rgdal)
library(sf)

##########################################################################
# import chemical data 
##########################################################################
# read the minimal, cleaned, post-treatment data from `02_get_treated_water.R`
# begins 2017-01-01
chem_tp_min_2017 <- read_rds("/Users/richpauloo/Desktop/ca_water_datathon/chem_tp_min_2017.rds")

##########################################################################
# import contact information
# scraped from https://sdwis.waterboards.ca.gov/PDWW/JSP/SearchDispatch?number=&name=&county=&WaterSystemType=All&WaterSystemStatus=A&SourceWaterType=All&action=Search+For+Water+Systems
# by Linsday Porrier
##########################################################################

# Lindsay's scraped data
psid_contact <- read_csv("/Users/richpauloo/Github/cawdc_2019/data/PWS_Info.csv")

# clean it up for the reports
extract_zip <- function(x){
  str_remove_all(x, "\n|\t") %>% 
    str_replace_all("            ", " ") %>% 
    str_extract_all("[:digit:]{5}$", simplify=TRUE) %>% 
    as.vector()
}
extract_address <- function(x){
  str_remove_all(x, "\n|\t") %>% 
    str_replace_all("[:space:]{2,}", " ") %>% 
    str_replace_all("[:digit:]{5}$", "") %>% 
    as.vector()
}

psid_contact$ac_zip <- extract_zip(psid_contact$ac_address)
psid_contact$health_zip <- extract_zip(psid_contact$healthDistrictAddress)
psid_contact$ac_address <- extract_address(psid_contact$ac_address)
psid_contact$healthDistrictAddress <- extract_address(psid_contact$healthDistrictAddress)
psid_contact$ac_address <- paste(psid_contact$ac_address, psid_contact$ac_zip)
psid_contact$healthDistrictAddress <- paste(psid_contact$healthDistrictAddress, psid_contact$health_zip)

psid_contact$ac_address <- str_replace_all(psid_contact$ac_address,
                                           ",CA", ", CA ")
psid_contact$healthDistrictAddress <- str_replace_all(psid_contact$healthDistrictAddress,
                                           " CA", ", CA")

psid_contact <- psid_contact %>% 
  select(PWSID, ac_address, ac_addressURL, ac_phone1, 
         starts_with("healthDistrict")) %>% 
  mutate_all(str_remove_all, pattern = "\n|\t") %>% 
  mutate_all(str_trim) %>% 
  mutate_at("healthDistrictAddress", str_replace, "  ", " ")

colnames(psid_contact) <- c("PRIM_STA_C", "WS_ADDRESS", "WS_URL",
                            "WS_PHONE", "HEALTH_DISTRICT", "HD_PHONE",
                            "HD_EMAIL","HD_ADDRESS")

psid_contact$WS_ADDRESS <- ifelse(is.na(psid_contact$WS_ADDRESS),
                                  NA, 
                                  paste0("<b><a href='", psid_contact$WS_URL, 
                                  "' target='_blank'>",
                                  psid_contact$WS_ADDRESS,
                                  "</a></b>")
)

psid_contact$WS_URL <- NULL


psid_contact$HD_EMAIL <- ifelse(is.na(psid_contact$HD_EMAIL), 
                                NA, 
                                paste0("<a href='mailto:", psid_contact$HD_EMAIL, 
                                "' target='_blank'>", psid_contact$HD_EMAIL, "</a>")
)

psid_contact$HD_ADDRESS <- ifelse(is.na(psid_contact$HD_ADDRESS),
                                  NA, 
                                  paste0("<b><a href='http://maps.google.com/maps?q=", 
                                         psid_contact$HD_ADDRESS, 
                                         "' target='_blank'>",
                                         psid_contact$HD_ADDRESS,
                                         "</a></b>")
)

psid_contact$HD_PHONE <- ifelse(is.na(psid_contact$HD_PHONE), 
                                NA, 
                                paste0("<a href='tel:1-", psid_contact$HD_PHONE, 
                                       "' target='_blank'>", psid_contact$HD_PHONE, "</a>")
)

psid_contact$WS_PHONE <- ifelse(is.na(psid_contact$WS_PHONE), 
                                NA, 
                                paste0("<a href='tel:1-", psid_contact$WS_PHONE, 
                                       "' target='_blank'>", psid_contact$WS_PHONE, "</a>")
)

psid_contact$PRIM_STA_C <- substr(psid_contact$PRIM_STA_C, 3, 9)

##########################################################################
# get spatial data: polygons
# abandoned, because it only returns ~400 polygon fea
##########################################################################
# sa <- geojsonio::geojson_read("https://data.ca.gov/sites/default/files/wsb_180622_oima.json", 
#                               what = "sp")
# sa@data <- select(sa@data,
#                   pwsid, address_city_name,
#                   addr_line_one_txt, addr_line_two_txt,
#                   address_zip)
# sa@data$addr_line_two_txt <- as.character(sa@data$addr_line_two_txt)
# sa@data$addr_line_two_txt[is.na(sa@data$addr_line_two_txt)] <- ""
# sa@data <- mutate(sa@data,
#                   address = paste0(addr_line_one_txt, ' ', addr_line_two_txt,
#                                    address_city_name, ', CA ', address_zip)
#                   )
# sa@data <- select(sa@data, pwsid, address)
# sa@data$pwsid <- substr(as.character(sa@data$pwsid), 3, 9)
# 
# # simplify for smaller file size, and onvert to sf
# sa <- rmapshaper::ms_simplify(sa, keep_shapes = TRUE) %>%
#   st_as_sf()
# 
# # remove duplicate pwsids (analysis below shows that they're duplicates)
# sa %>% group_by(pwsid) %>% filter(n() > 1) %>% arrange(pwsid) %>% View()
# sa <- sa %>% group_by(pwsid) %>% slice(1) %>% ungroup()


##########################################################################
# get spatial data: points
##########################################################################

# exceedance compliance points
# download, upzip, and read the spatial points
url  <- "https://www.waterboards.ca.gov/water_issues/programs/hr2w/docs/data/ec_summary_jun2019.zip"
temp <- tempfile()
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


##########################################################################
# subset chemical data for psids
##########################################################################
#psids <- unique(chem_tp_min$PRIM_STA_C)
#psids <- unique(chem_tp_min_2019$PRIM_STA_C) # clean chemical data (2019)

# we've gone through different iterations... but we're settling on
# only considering the HRW data for this first step pilot.
psids_to_consider <- ep$WATER_SYST

# filter chem data to only psids in HWR: how do we describe this subset?
chem_tp_min_2017 <- filter(chem_tp_min_2017, PRIM_STA_C %in% psids_to_consider)

# get variables for mapply to pass to .Rmd params
zz <- group_by(chem_tp_min_2017, PRIM_STA_C) %>% 
  slice(1)

# vars to pass to mapply that each .Rmd report needs as params
psids    <- zz$PRIM_STA_C
nams     <- zz$`Water System Name`
cities   <- zz$CITY
counties <- zz$`Principal County Served`


##########################################################################
# psids from exceedance point data via Human Right to Water
# that have chemical data associated with them get a URL, and those
# without chemical data do not
##########################################################################
ep_with_chem_dat <- ep@data$WATER_SYST[ ep@data$WATER_SYST %in% psids ]

# eps with chemical data in the past 2 years, and thus a CCR, get a URL
# eps without chemical data, and no CCR don't get a URL
ep@data <- ep@data %>% 
  mutate(url = ifelse(WATER_SYST %in% ep_with_chem_dat,
                      paste0("<b><a href='https://caccr.github.io/ccrs/", 
                             ep$WATER_SYST, ".html'>VIEW CCR</a></b>"),
                      paste0("CRR unavailable.")))

##########################################################################
# make html and words ccrs by first calling `03_psid_params` 
# and passing this script a psid. `03_psid_params` depends on the object `chem_tp_min_2017`, which is loaded in this script
##########################################################################


##########################################################################
# write the ccrs docx files
##########################################################################
# function to generate CCR docx files
gen_word_reports <- function(x,y,w,k) {
  rmarkdown::render(input = "/Users/richpauloo/Github/cawdc_2019/R/09_psid_params_word.Rmd", 
                    output_file = sprintf("/Users/richpauloo/Github/jmcglone.github.io/word/%s.docx", x),
                    params = list(psid = x, nam = y,
                                  city = w, county = k))
}

# write the CCR docx files
mapply(gen_word_reports, 
       psids,
       nams,
       cities,
       counties
)




##########################################################################
# generate html ccrs 
##########################################################################
# function to generate CCR index.htmls  
gen_html_reports <- function(x,y,w,k) {
  rmarkdown::render(input = "/Users/richpauloo/Github/cawdc_2019/R/03_psid_params.Rmd", 
                    output_file = sprintf("/Users/richpauloo/Github/jmcglone.github.io/ccrs/%s.html", x),
                    params = list(psid = x, nam = y,
                                  city = w, county = k))
}

# write the CCR index.htmls  
mapply(gen_html_reports, 
       psids, 
       nams, 
       cities,
       counties
)

# read in the header  (navbar) and footer (social links) HTML templates
navbar <- read_lines("/Users/richpauloo/Github/cawdc_2019/R/etc/nav_bar_sub_head")
foot   <- read_lines("/Users/richpauloo/Github/cawdc_2019/R/etc/foot.html")

# read in the HTML files
# insert the navbar code and the footer with social links
# then re-write the files

# first get ordered compliance status of all psids
status <- left_join(data.frame(WATER_SYST = psids), 
                    select(filter(ep@data, ep@data$WATER_SYST %in% ep_with_chem_dat),
                           WATER_SYST, GIS_STATUS)) %>% 
  pull(GIS_STATUS)

for(i in 1:length(psids)){
# for(i in 1){
  
  # read in HTML files for individual CCRs
  index <- read_lines(paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], ".html"))
  
  # inset navbar
  index <- c(index[1:9], navbar, index[10:length(index)])
  
  # add the social footer and format social links specific to the ith psid
  
  # facebook
  foot[35] <- paste0('<a href = "https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fcaccr.github.io%2Fccrs%2F', 
                     psids[i], 
                     '.html" target = "_blank" class="fa fa-facebook"></a>')
  
  # twitter
  foot[36] <- paste0('<a href="https://twitter.com/intent/tweet?text=🚰+ Water+quality+in+',
                     nams[i], ', ', counties[i],' CO.', ' Status: ', status[i], 
                     '. ', '+ https://caccr.github.io/ccrs/', psids[i], 
                     '.html" target = "_blank"  class="fa fa-twitter"></a>')
  
  # locate where in the html to insert the footer, then insert it
  j <- str_which(index,"Download this report") 
  index <- c(index[1:j], foot, index[(j+3):length(index)])
  
  # save
  write_lines(index, paste0("/Users/richpauloo/Github/jmcglone.github.io/ccrs/", psids[i], ".html"))
}


##########################################################################
# write the master index.html file
##########################################################################
rmarkdown::render(input = "/Users/richpauloo/Github/cawdc_2019/R/05_master_index.Rmd", 
                  output_file = "/Users/richpauloo/Github/jmcglone.github.io/index.html")

# adjust navbar-logo margin-top from 1px to 4px
# by reading in index.html, making the change, then overwriting index.html
il <- readr::read_lines("/Users/richpauloo/Github/jmcglone.github.io/index.html")
il[stringr::str_which(il, "  margin-top: 1px;")] <- "  margin-top: 4px;"
readr::write_lines(il, "/Users/richpauloo/Github/jmcglone.github.io/index.html")

##########################################################################
# write the about index.html file and add the navbar
##########################################################################
rmarkdown::render(input = "/Users/richpauloo/Github/cawdc_2019/R/06_about_index.Rmd", 
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

##########################################################################
# write the faq index.html file and add the navbar
##########################################################################
rmarkdown::render(input = "/Users/richpauloo/Github/cawdc_2019/R/08_faq.Rmd", 
                  output_file = "/Users/richpauloo/Github/jmcglone.github.io/faq/index.html")
index <- read_lines("/Users/richpauloo/Github/jmcglone.github.io/faq/index.html")
index <- c(index[1:9], navbar, index[10:length(index)])
write_lines(index, "/Users/richpauloo/Github/jmcglone.github.io/faq/index.html")

##########################################################################
# EDIT: this is a quick fix for now. The code needs to be refactored in 
# the future. Basically, I want to change the navbar in all ccr pages 
# and on the about and faq. In the future, everything above that depends 
# on `navbar_sub_head` should be changed to what is inserted below:  
##########################################################################

# ccrs
n <- readr::read_lines("~/Github/cawdc_2019/R/etc/navbar_with_logo.html")
f <- list.files("~/Github/jmcglone.github.io/ccrs", full.names = TRUE)
l <- vector("list", length = length(f))
for(i in 1:length(f)) {
  l[[i]] <- readr::read_lines(f[[i]])
  l[[i]] <- c(l[[i]][1:10], n, l[[i]][55:length(l[[i]])])
  readr::write_lines(l[[i]], f[[i]])
}

# about
about <- readr::read_lines("~/Github/jmcglone.github.io/about/index.html")
about <- c(about[1:10], n, about[55:length(about)])
readr::write_lines(about, "~/Github/jmcglone.github.io/about/index.html")

# faq
faq <- readr::read_lines("~/Github/jmcglone.github.io/faq/index.html")
faq <- c(faq[1:10], n, faq[55:length(faq)])
readr::write_lines(faq, "~/Github/jmcglone.github.io/faq/index.html")


