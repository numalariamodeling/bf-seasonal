library(dplyr)
library(lubridate)
library(purrr)
library(ggplot2)

years <- 30

projectdir <- "/projects/b1139/malaria-bf-hbhi/IO"
# projectdir <- "C:\\Users\\kbt4040\\NU-malaria-team Dropbox"
# simoutdir <- file.path(projectdir, "projects", "hbhi_burkina", 
#                        "simulation_output", "bittou_seasonal_calib")
simoutdir <- file.path(projectdir, "simulation_output", "gourcy_mixspecies_300")
DS <- "Gourcy"
# outputdir <- file.path(projectdir, "simulation_output", "selected_particles")
mon_hab_csv <- file.path(projectdir, "simulation_inputs", "monthly_habitats_v4.csv")

# This section works to get the case csv out first. It makes a data table which renames the date and year and month and arranges it
load_case_data <- function(projectdir) {
  case_fname <- file.path(projectdir, 'burkina_cases/routine_seb_agg_confpres.csv')
  case_df <- data.table::fread(case_fname) %>% 
    rename(date = Date, repincd = case) %>%
    mutate(date = as.Date(date), year = year(date), 
           month = month(date)) %>%
    arrange(DS_Name, date)
  # only use year=2015 or something
  
  return(case_df)
}

# getting the u5pfpr from the simulation we ran
rcases <- load_case_data(projectdir) %>%
  filter(DS_Name == DS) %>%
  filter(age == 'ov5')
simcases <- data.table::fread(file.path(simoutdir, "U5_PfPR_ClinicalIncidence.csv"))
simcases <- simcases %>%
  group_by(DS_Name, year, month) %>%
  summarise(pop = mean(`Pop U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

# getting the events csv from the simulation we ran
simtreated <- data.table::fread(file.path(simoutdir, "events.csv"))
simtreated1 <- simtreated %>%
  filter(Time >= (years - 3) * 365 + 1) %>%
  filter(Age %/% 365 < 5) %>%
  mutate(year = (Time - 1) %/% 365,
         month = (Time - year * 365 - 1) %/% 30 + 1) %>%
  filter(month <= 12)

simtreated1 <- simtreated1 %>%
  group_by(DS_Name, year, month, Run_Number) %>%
  summarise(simincd = n()) %>%
  summarise(simincd = mean(simincd), .groups = "drop") %>%
  mutate(year = year + 1986) # change back to 1986 later

simtreated2 <- simtreated1 %>%
  left_join(simcases, by = c("DS_Name", "year", "month")) %>%
  mutate(simincd = simincd / pop)

rcases1 <- rcases %>%
  group_by(DS_Name, year) %>%
  mutate(repincd = repincd/sum(repincd)) %>%
  # group_by(DS_Name, month) %>%
  # summarise(std_repincd = mean(repincd)) %>%
  mutate(date=ymd(paste0("2010-", month, "-15")))

rcases2 <- rcases1 %>%
  group_by(DS_Name, month, date) %>%
  summarise(std_repincd = mean(repincd), .groups = "drop")

simcases1 <- simtreated2 %>%
  group_by(DS_Name, year) %>%
  mutate(simincd = simincd/sum(simincd)) %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd = mean(simincd)) %>%
  mutate(date=ymd(paste0("2010-", month, "-15")))

mon_hab <- data.table::fread(mon_hab_csv) %>%
  filter(archetype == DS) %>%
  select(archetype, starts_with("Month")) %>%
  tidyr::pivot_longer(-archetype, names_to = "month", names_prefix = "Month",
                      values_to = "multiplier") %>%
  mutate(month=as.numeric(month),
         date=ym(paste0("2010-", month)))
mon_hab1 <- bind_rows(mon_hab, mon_hab[1,])
mon_hab$auc <- (mon_hab$multiplier + lead(mon_hab1$multiplier)[-13]) / 2

# comb_df <- simcases1 %>%
#   left_join(rcases1, by = c("DS_Name", "month")) %>%
#   mutate(date=ymd(paste0("2010-", month, "-15")))

# ggplot(comb_df) +
#   geom_line(aes(x=date, y=repincd)) +
#   geom_line(aes(x=date, y=simincd), col = "red") +
#   scale_y_log10()

ggplot() +
  # geom_line(aes(x=date, y=repincd, group=year), data=rcases1, alpha = 0.5) +
  geom_line(aes(x=date, y=std_repincd, color="Routine_case_data"), data=rcases2) +
  geom_line(aes(x=date, y=std_simincd, color="Simulated_case_data"), data=simcases1) +
  labs(title="Gourcy mixed species 2015 300 shift") +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 0.25)) +
  scale_color_manual(values = c("Routine_case_data" = "blue", "Simulated_case_data" = "red")) +
  # geom_line(aes(x=date + ddays(15), y=auc), data=mon_hab, lty=2) +
  # geom_line(aes(x=date, y=multiplier), data=mon_hab, lty=2) +
  scale_x_date(date_breaks = "1 month", date_labels = "%m", minor_breaks = NULL)

# comb_df1 %>%
#   mutate(cs_repincd = cumsum(std_repincd),
#          cs_simincd = cumsum(std_simincd)) %>%
#   ggplot() +
#   geom_line(aes(x=month, y=cs_repincd)) +
#   geom_line(aes(x=month, y=cs_simincd), col = "red") +
#   scale_x_continuous(breaks = 1:12, minor_breaks = NULL)

