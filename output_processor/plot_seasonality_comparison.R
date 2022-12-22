library(dplyr)
library(lubridate)
library(purrr)
library(ggplot2)

projectdir <- "/projects/b1139/malaria-bf-hbhi/IO"
# projectdir <- "C:\\Users\\kbt4040\\NU-malaria-team Dropbox"
# simoutdir <- file.path(projectdir, "projects", "hbhi_burkina", 
#                        "simulation_output", "bittou_seasonal_calib")
simoutdir1 <- file.path(projectdir, "simulation_output", "bittou_seasonal_calib_10yr")
simoutdir2 <- file.path(projectdir, "simulation_output", "bittou_seasonal_calib_20yr")
simoutdir3 <- file.path(projectdir, "simulation_output", "bittou_seasonal_calib_30yr")
simoutdir4 <- file.path(projectdir, "simulation_output", "bittou_seasonal_calib_40yr")
simoutdir5 <- file.path(projectdir, "simulation_output", "bittou_seasonal_calib_50yr")

DS <- "Bittou"
# outputdir <- file.path(projectdir, "simulation_output", "selected_particles")

load_case_data <- function(projectdir) {
  case_fname <- file.path(projectdir, 'burkina_cases', 
                          'Cases_from_WHO', 
                          'Donnees_Paludisme_jgcleaned.csv')
  case_df <- data.table::fread(case_fname, encoding = "Latin-1")
  case_df <- case_df %>%
    select(DS_Name = `District/Admin2`, year = Année, month = Mois,
           repincd = Incidence) %>%
    na.omit()
  
  return(case_df)
}

simcases1 <- data.table::fread(file.path(simoutdir1, "U5_PfPR_ClinicalIncidence.csv"))
simcases2 <- data.table::fread(file.path(simoutdir2, "U5_PfPR_ClinicalIncidence.csv"))
simcases3 <- data.table::fread(file.path(simoutdir3, "U5_PfPR_ClinicalIncidence.csv"))
simcases4 <- data.table::fread(file.path(simoutdir4, "U5_PfPR_ClinicalIncidence.csv"))
simcases5 <- data.table::fread(file.path(simoutdir5, "U5_PfPR_ClinicalIncidence.csv"))

simcases1 <- simcases1 %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd1 = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

simcases2 <- simcases2 %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd2 = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

simcases3 <- simcases3 %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd3 = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

simcases4 <- simcases4 %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd4 = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

simcases5 <- simcases5 %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd5 = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

####


simcases1 <- simcases1 %>%
  group_by(DS_Name, year) %>%
  mutate(simincd1 = simincd1/sum(simincd1)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd1 = mean(simincd1))

simcases2 <- simcases2 %>%
  group_by(DS_Name, year) %>%
  mutate(simincd2 = simincd2/sum(simincd2)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd2 = mean(simincd2))

simcases3 <- simcases3 %>%
  group_by(DS_Name, year) %>%
  mutate(simincd3 = simincd3/sum(simincd3)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd3 = mean(simincd3))

simcases4 <- simcases4 %>%
  group_by(DS_Name, year) %>%
  mutate(simincd4 = simincd4/sum(simincd4)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd4 = mean(simincd4))

simcases5 <- simcases5 %>%
  group_by(DS_Name, year) %>%
  mutate(simincd5 = simincd5/sum(simincd5)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd5 = mean(simincd5))


ggplot() +
  geom_line(data=simcases1,aes(x=month, y=std_simincd1, col = '10 years')) +
  geom_line(data=simcases2,aes(x=month, y=std_simincd2, col = '20 years')) +
  geom_line(data=simcases3,aes(x=month, y=std_simincd3, col = '30 years')) +
  geom_line(data=simcases4,aes(x=month, y=std_simincd4, col = '40 years')) +
  geom_line(data=simcases5,aes(x=month, y=std_simincd5, col = '50 years')) +
  scale_x_continuous(breaks = 1:12, minor_breaks = NULL) +
  scale_color_manual(values=c("10 years" = "blue", "20 years" = "red", "30 years" = "green", "40 years" = "orange", "50 years" = "purple")) +
  labs(title="Seasonality Stabilization", colour="Legend")+
  xlab("Month") +
  ylab("Incidence")

# comb_df1 %>%
#   mutate(cs_repincd = cumsum(std_repincd),
#          cs_simincd = cumsum(std_simincd)) %>%
#   ggplot() +
#   geom_line(aes(x=month, y=cs_repincd)) +
#   geom_line(aes(x=month, y=cs_simincd), col = "red") +
#   scale_x_continuous(breaks = 1:12, minor_breaks = NULL)

# rcases %>%
#   filter(year <= 2014) %>%
#   group_by(DS_Name, year) %>%
#   mutate(repincd = repincd/sum(repincd)) %>%
#   group_by(DS_Name, month) %>%
#   summarise(std_repincd = mean(repincd)) %>%
#   ggplot() +
#   geom_line(aes(x=month, y=std_repincd)) +
#   scale_x_continuous(breaks = 1:12, minor_breaks = NULL)
