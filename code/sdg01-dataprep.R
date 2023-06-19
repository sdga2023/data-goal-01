library(dplyr)

beeswarmdata.update <- read.csv("../Input data/Beeswarm_data_2022-09-26.csv")
regionbeeswarm <- filter(beeswarmdata.update,
                         regiontype != "World",
                         # type columns was removed from the data
                         #type != "precovid",
                         dottype == "millions",
                         dotsize == 20,
                         regiontype == "4 regions",
                         year %in% c(1990, 2019, 2020)
) %>%
  select(year, welfare, region) %>%
  mutate(region, region = case_when(
    region == "East Asia & Pacific" ~ "EAS",
    region == "South Asia" ~ "SAS",
    region == "Sub-Saharan Africa" ~ "SSF",
    region == "Rest of the world" ~ "RESTOFWORLD",
  ))
write.csv(regionbeeswarm, "../Output data/regionbeeswarm.csv", row.names=FALSE)

povlines <- read.csv("../Input data/NationalPovertyLines.csv")
povlines <- select(povlines, countrycode, incomegroup, povertyline, gdp) %>%
  #Missing gdp data for some countries
  filter(!(countrycode %in% c("SYR", "YEM", "SSD", "VEN"))) %>%
  mutate(incomegroup = recode(incomegroup, `Low income` = "LIC", `Lower middle income` = "LMC", `Upper middle income` = "UMC", `High income` = "HIC"))
write.csv(povlines, "../Output data/povlines.csv", row.names=FALSE)

climpov.raw <- read.csv("../Input data/ClimatePoverty_scatter.csv")
climpov <- select(climpov.raw, iso3c = code, year, povertyrate, gdppc, ghgpc) %>%
  filter(!is.na(povertyrate)) %>%
  filter(!is.na(gdppc)) %>%
  filter(!is.na(ghgpc))
#Move Mali and China to the bottom, so they are rendered above all others
chnmli <- filter(climpov, iso3c %in% c("CHN", "MLI")) %>% filter(year < 2020)
rest <- filter(climpov, !(iso3c %in% c("CHN", "MLI"))) %>%
  filter(year %in% c(2019, 2022))
climpov.all <- rbind(rest, chnmli)
write.csv(climpov.all, "../Output data/povertyclimate.csv", row.names=FALSE)

targetmet <- filter(climpov.raw, year == 2022) %>%
  select(code, povertytargetmet) %>%
  filter(!is.na(povertytargetmet)) %>%
  rename(iso3c = code)
write.csv(targetmet, "../Output data/povertytargetmet.csv", row.names=FALSE)

mali.projection <- filter(climpov.raw, code == "MLI") %>%
  select(iso3c = code, gdppc_need_baseline, ghgpc_need_baseline, ghgpc_need_energy) %>%
  filter(!is.na(gdppc_need_baseline))
write.csv(mali.projection, "../Output data/maliprojections.csv", row.names=FALSE)



