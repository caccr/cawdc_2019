# Created by Rich Pauloo (richpauloo@gmail.com) on 2019-07-01
# The purpose of this script is to provide a script to download 
# relevant datasets, combine them, and write them for additional 
# processing. 

# necessary packages
library(tidyverse)    # general purpose data science toolkit
library(foreign)      # for reading .dbf files

# download, upzip, and read most recent data and chemical storet info
urls <- c("https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/edtlibrary/chemical.zip",
          "https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/edtlibrary/storet.zip")
temp1 <- temp2 <- tempfile()
download.file(urls[1], temp1)
download.file(urls[2], temp2)

# change exdir paths to a local working directory
unzip(temp1, 
      exdir = "/Users/richpauloo/Desktop/ca_water_datathon/")
unzip(temp2,
      exdir = "/Users/richpauloo/Desktop/ca_water_datathon/")

rm(temp1, temp2) # remove temp files

# read chem and storet data into R
# sometimes, R fails to unzip `chem`. unsure why, but manual download/unzip works
chem  <- read.dbf("/Users/richpauloo/Desktop/ca_water_datathon/chemical.dbf")
stor  <- read.dbf("/Users/richpauloo/Desktop/ca_water_datathon/storet.dbf")
# sdwis <- read_csv("https://data.ca.gov/sites/default/files/Public%20Potable%20Water%20Systems%20FINAL%2006-22-2018_0.csv")

# SDWIS data updates periodically, breaking the csv in url:
# https://data.ca.gov/dataset/drinking-water-public-water-system-information
sdwis <- read_csv("https://data.ca.gov/dataset/d6d3beac-6735-4127-9324-4e70f61698d9/resource/9dca2f92-4630-4bee-a9f9-69d2085b57e3/download/drinking-water-watch-public-water-system-facilities.csv")

# make equivalent water system identifers 
sdwis$`Water System No` <- str_sub(sdwis$`Water System No`, 3, 9)
chem$PRIM_STA_C <- str_sub(chem$PRIM_STA_C, 1, 7)

# join chem and stor data
chem <- left_join(chem, stor, by = "STORE_NUM")
chem <- left_join(chem, sdwis, by = c("PRIM_STA_C" = "Water System No"))

# write the joined data
#write_rds(chem, "/Users/richpauloo/Desktop/ca_water_datathon/chem.rds")
write_csv(chem, "/Users/richpauloo/Desktop/ca_water_datathon/chem.csv")

# unique public water systems
# pws_id <- unique(chem$PRIM_STA_C)
# length(pws_id)

# subset of chem data for prototyping (first 10 unique PWS)
# chem_sub <- filter(chem, PRIM_STA_C %in% pws_id[1:10])
# write_rds(chem_sub, "/Users/richpauloo/Desktop/ca_water_datathon/chem_sub.rds")

# save vector of unique public water systems
#write_rds(pws_id, "/Users/richpauloo/Desktop/ca_water_datathon/pws_id.rds")








# # violations
# chem <- mutate(chem, violation = ifelse(FINDING >= MCL, TRUE, FALSE))
# temp <- filter(chem, violation == TRUE & MCL > 0) 
# table(temp$violation)
# 
# # violations per year
# temp %>% mutate(year = lubridate::year(SAMP_DATE)) %>% count(year, `Primary Water Source Type`) %>% ggplot(aes(year, n, fill = `Primary Water Source Type`)) + geom_col(position = "fill")
# 
# temp %>% mutate(year = lubridate::year(SAMP_DATE)) %>% count(year, CHEMICAL__) %>% top_n(n = 10, wt = n) %>% ggplot(aes(fct_reorder(CHEMICAL__, n), n)) + geom_col() + coord_flip() + facet_wrap(~year)
# 
# p <- temp %>% mutate(year = lubridate::year(SAMP_DATE)) %>% filter(year == 2018) %>% count(`Principal County Served`, CHEMICAL__) %>% top_n(n = 25, wt = n) %>% ggplot(aes(CHEMICAL__, n, fill = `Principal County Served`)) + geom_col() + coord_flip() + scale_fill_viridis_d() + labs(title = "Top 10 Contaminant Violations in 2018", y = "Number of Violations in 2018", x = "", fill = "Principal County") + scale_y_continuous(label=scales::comma)
# 
# write_rds(p,"/Users/richpauloo/Desktop/ca_water_datathon/p.rds")
# 
# plotly::ggplotly(p)
