library(tidyverse)
library(dtplyr)

# 10 mil rows x 55 cols from 2013-01-01 to 2019-09-27
d <- data.table::fread("~/Desktop/ca_water_datathon/chem.csv")
colnames(d)[c(1, 13, 25)] <- c("PWSID", "CHEMICAL", "CHEM_SORT")


# data.frame of colnames = c(psid, water_system_name, county, zipcode)
# sdwisard::water_systems

water_systems <- d[, c("PWSID", "Water System Name",
                       "Principal County Served")] %>%
  distinct() %>%
  rename(psid = PWSID,
         water_system_name = `Water System Name`,
         county = `Principal County Served`)
write_rds(water_systems, "~/Github/sdwisard/data-raw/water_systems.rds")

# data.frame of colnames = c(storet, analyte)
# sdwisard::analytes

analytes <- d[, c("STORE_NUM", "CHEMICAL")] %>%
  distinct() %>%
  rename(storet = STORE_NUM, analyte = CHEMICAL)
write_rds(analytes, "~/Github/sdwisard/data-raw/analytes.rds")


# internal of colnames = c(psid, storet, analyte, start_date, end_date, n)
# sdwisard::psid_analyte

psid_analyte <-
  d[, c("PWSID", "STORE_NUM", "CHEMICAL", "SAMP_DATE")] %>%
  rename(psid = PWSID, storet = STORE_NUM, analyte = CHEMICAL) %>%
  lazy_dt() %>%
  group_by(psid, storet, analyte) %>%
  mutate(start_date = min(SAMP_DATE),
         end_date   = max(SAMP_DATE),
         n = n()) %>%
  ungroup() %>%
  select(-SAMP_DATE) %>%
  distinct() %>%
  as_tibble()

write_rds(psid_analyte, "~/Github/sdwisard/data-raw/psid_analyte.rds")
