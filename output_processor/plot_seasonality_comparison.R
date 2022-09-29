library(dplyr)
library(lubridate)
library(purrr)
library(ggplot2)

projectdir <- "/projects/b1139/malaria-bf-hbhi/IO"
# projectdir <- "C:\\Users\\kbt4040\\NU-malaria-team Dropbox"
# simoutdir <- file.path(projectdir, "projects", "hbhi_burkina", 
#                        "simulation_output", "bittou_seasonal_calib")
simoutdir <- file.path(projectdir, "simulation_output", "bittou_seasonal_calib_30yr")
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

simcases <- data.table::fread(file.path(simoutdir, "U5_PfPR_ClinicalIncidence.csv"))
simcases <- simcases %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

simcases <- simcases %>%
  group_by(DS_Name, year) %>%
  mutate(simincd = simincd/sum(simincd)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd = mean(simincd))

ggplot(simcases) +
  geom_line(aes(x=month, y=std_simincd), col = "red") +
  scale_x_continuous(breaks = 1:12, minor_breaks = NULL)

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
