library(tidyverse)
library(dtplyr)

# 10 mil rows x 55 cols from 2013-01-01 to 2019-09-27
d <- data.table::fread("~/Desktop/ca_water_datathon/chem.csv")
colnames(d)[c(1, 13, 25)] <- c("PWSID", "CHEMICAL", "CHEM_SORT")
d$PWSID <- d$PWSID %>% formatC(width = 7, flag = "0")
d$PWSID %>% nchar() %>% table()

# data.frame of colnames = c(psid, water_system_name, county, zipcode)
# sdwisard::water_systems

water_systems <- d[, c("PWSID", "Water System Name",
                       "Principal County Served")] %>%
  distinct() %>%
  rename(psid = PWSID,
         water_system_name = `Water System Name`,
         county = `Principal County Served`) %>%
  as_tibble()
write_rds(water_systems, "~/Documents/Github/sdwisard/data-raw/water_systems.rds")

# data.frame of colnames = c(storet, analyte)
# sdwisard::analytes

analytes <- d[, c("STORE_NUM", "CHEMICAL")] %>%
  distinct() %>%
  rename(storet = STORE_NUM, analyte = CHEMICAL) %>%
  as_tibble()
write_rds(analytes, "~/Documents/Github/sdwisard/data-raw/analytes.rds")


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

write_rds(psid_analyte, "~/Documents/Github/sdwisard/data-raw/psid_analyte.rds")


# count, filter NAs
water_systems <- read_rds("~/Documents/Github/sdwisard/data-raw/water_systems.rds")
analytes      <- read_rds("~/Documents/Github/sdwisard/data-raw/analytes.rds")
psid_analyte  <- read_rds("~/Documents/Github/sdwisard/data-raw/psid_analyte.rds")

sapply(water_systems, function(x) sum(is.na(x))) / nrow(water_systems)
sapply(analytes, function(x) sum(is.na(x))) / nrow(analytes)
sapply(psid_analyte, function(x) sum(is.na(x))) / nrow(psid_analyte)

# nearly 10% of psids have an NA county
# much less than 1% of storet numbers have an NA analyte
# much less than 1% of psids numbers have an NA storet or analyte

# do the psids with an NA county (~10%) tend to have few observatioins?
# Can we filter these out with little consequence?
p_na  <- filter(water_systems, is.na(water_system_name) | is.na(county)) %>%
  left_join(psid_analyte, by = "psid") %>%
  count(psid) %>%
  ggplot(aes(n)) +
  geom_line(stat="density")

p_all <- count(psid_analyte, psid) %>%
  ggplot(aes(n)) +
  geom_line(stat="density")

# compared to the distribution of observation counts at all psids
# the psids with missing county or water_system_name tend to have less
# observations -- they're smaller
cowplot::plot_grid(p_na, p_all)


# filter NAs and write new objects
filter(water_systems, ! is.na(water_system_name) & ! is.na(county)) %>%
  write_rds("~/Documents/Github/sdwisard/data-raw/water_systems.rds")

filter(analytes, ! is.na(analyte)) %>%
  write_rds("~/Documents/Github/sdwisard/data-raw/analytes.rds")

filter(psid_analyte, ! is.na(storet) & ! is.na(analyte)) %>%
  mutate(start_date = lubridate::ymd(lubridate::mdy_hms(start_date)),
         end_date   = lubridate::ymd(lubridate::mdy_hms(end_date))) %>%
  write_rds("~/Documents/Github/sdwisard/data-raw/psid_analyte.rds")




