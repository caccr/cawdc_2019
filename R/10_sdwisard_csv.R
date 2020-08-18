library(tidyverse)
library(dtplyr)

# 10 mil rows x 55 cols from 2013-01-01 to 2019-09-27
d <- fread("~/Desktop/ca_water_datathon/chem.csv")
colnames(d)[c(1, 13, 25)] <- c("PWSID", "CHEMICAL", "CHEM_SORT")

# create a temp folder
dir <- "~/Desktop/s3/"
if(!dir.exists(dir)) { dir.create(dir) }

# only a 7% reduction in observations if non community water
# systems are excluded, so keep them
d2 <- d %>% split(.$PWSID)

for(i in 1:length(d2)){
  write_csv( d2[[i]], paste0(dir, d2[[i]]$PWSID[1], ".csv") )
}

names(d2) %>%
  walk(
    ~ write_csv(
      d2[[.]],
      paste0(dir, d2[[.]]$PWSID[1], ".csv")
    )
  )

# ------------------------------------------------------------------------
# convert all csv to gz for S3
# ------------------------------------------------------------------------

f  <- list.files("~/Desktop/s3")
ff <- list.files("~/Desktop/s3", full.names = TRUE)
l  <- vector("list", length=length(f))
for(i in seq_along(l)) {
  l[[i]] <- data.table::fread(ff[i])
}

pth <- paste0("~/Desktop/gz/", f, ".gz")
for(i in seq_along(f)){
  gz <- gzfile(pth[i], "w")
  readr::write_csv(l[[i]], gz)
  close(gz)
}



