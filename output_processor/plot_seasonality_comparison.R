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
  case_fname <- file.path(projectdir, 'burkina_cases/routine_seb_agg_confpres.csv')
  case_df <- data.table::fread(case_fname) %>% 
    rename(date = Date, repincd = case) %>%
    mutate(date = as.Date(date), year = year(date), 
           month = month(date)) %>%
    arrange(DS_Name, date)
  
  return(case_df)
}

rcases <- load_case_data(projectdir) %>%
  filter(DS_Name == DS) %>%
  filter(age == 'ov5')
simcases <- data.table::fread(file.path(simoutdir, "U5_PfPR_ClinicalIncidence.csv"))
simcases <- simcases %>%
  group_by(DS_Name, year, month) %>%
  summarise(simincd = mean(`Cases U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

rcases1 <- rcases %>%
  group_by(DS_Name, year) %>%
  mutate(repincd = repincd/sum(repincd)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_repincd = mean(repincd))

simcases1 <- simcases %>%
  group_by(DS_Name, year) %>%
  mutate(simincd = simincd/sum(simincd)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd = mean(simincd))

comb_df <- simcases1 %>%
  left_join(rcases1, by = c("DS_Name", "month")) %>%
  ungroup()

# ggplot(comb_df) +
#   geom_line(aes(x=date, y=repincd)) +
#   geom_line(aes(x=date, y=simincd), col = "red") +
#   scale_y_log10()

ggplot(comb_df) +
  geom_line(aes(x=month, y=std_repincd)) +
  geom_line(aes(x=month, y=std_simincd), col = "red") +
  scale_x_continuous(breaks = 1:12, minor_breaks = NULL)

