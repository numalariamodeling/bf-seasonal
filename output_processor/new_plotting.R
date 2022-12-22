library(dplyr)
library(lubridate)
library(purrr)
library(ggplot2)

years <- 30
DS <- "Dori"
ds <- tolower(DS)

projectdir <- "/projects/b1139/malaria-bf-hbhi/IO"
simoutdir <- file.path(projectdir, "simulation_output", "new_dori_5yr_mixspecies_0")

master_csv <- file.path(projectdir, "burkina_DS_pop.csv")
mon_hab_csv <- file.path(projectdir, "simulation_inputs", "monthly_habitats_v4.csv")

load_case_data <- function(projectdir) {
  case_fname <- file.path(projectdir, 'burkina_cases/routine_seb_agg_confpres.csv')
  case_df <- data.table::fread(case_fname) %>% 
    rename(date = Date, repincd = case) %>%
    mutate(date = as.Date(date), year = year(date), 
           month = month(date)) %>%
    arrange(DS_Name, date)
  master_df <- data.table::fread(master_csv) %>%
    select(DS_Name, seasonality_archetype_2)
  case_df <- case_df %>%
    left_join(master_df, by="DS_Name") %>%
    rename(archetype = seasonality_archetype_2)
  
  return(case_df)
}

rcases <- load_case_data(projectdir) %>%
  filter(year >= 2015) %>%
  # filter(DS_Name == DS) %>%
  filter(archetype == DS) %>%
  filter(age == 'ov5')
simcases <- data.table::fread(file.path(simoutdir, "U5_PfPR_ClinicalIncidence.csv"))
simcases <- simcases %>%
  group_by(DS_Name, year, month) %>%
  summarise(pop = mean(`Pop U5`)) %>%
  mutate(date = paste(year, month) %>% ym)

simtreated <- data.table::fread(file.path(simoutdir, "events.csv"))
simtreated1 <- simtreated %>%
  filter(Time >= (years - 4) * 365 + 1) %>% # change to -3
  filter(Age %/% 365 < 5) %>%
  mutate(year = (Time - 1) %/% 365,
         month = (Time - year * 365 - 1) %/% 30 + 1) %>%
  filter(month <= 12)

simtreated1 <- simtreated1 %>%
  group_by(DS_Name, year, month, Run_Number) %>%
  summarise(simincd = n()) %>%
  summarise(simincd = mean(simincd), .groups = "drop") %>%
  mutate(year = year + 1986)

simtreated2 <- simtreated1 %>%
  left_join(simcases, by = c("DS_Name", "year", "month")) %>%
  mutate(simincd = simincd / pop)

rcases1 <- rcases %>%
  group_by(DS_Name, year) %>%
  mutate(repincd = repincd/sum(repincd)) %>%
  group_by(archetype, year, month, date) %>%
  summarise(std_repincd = mean(repincd)) %>%
  mutate(date1=ymd(paste(year, month, "15", sep="-")))

rcases2 <- rcases1 %>%
  group_by(archetype, month) %>%
  summarise(date=min(date1),
            std_repincd = mean(std_repincd), .groups = "drop")

simcases1 <- simtreated2 %>%
  group_by(DS_Name, year) %>%
  mutate(std_simincd = simincd/sum(simincd),
         year = year + 3) %>% # change to 2
  mutate(date=ymd(paste0(year, month, "-15")))

simcases2 <- simcases1 %>%
  group_by(DS_Name, month) %>%
  summarise(std_simincd = mean(std_simincd),
            date = min(date))

mon_hab <- data.table::fread(mon_hab_csv) %>%
  filter(archetype == DS) %>%
  select(archetype, starts_with("Month")) %>%
  tidyr::pivot_longer(-archetype, names_to = "month", names_prefix = "Month",
                      values_to = "multiplier") %>%
  mutate(month=as.numeric(month),
         date=ym(paste0("2015-", month)))
mon_hab1 <- bind_rows(mon_hab, mon_hab[1,])
mon_hab$auc <- (mon_hab$multiplier + lead(mon_hab1$multiplier)[-13]) / 2

# All 4 years
ggplot() +
  geom_line(aes(x=date1, y=std_repincd, colour= 'Routine_case_data'), data=rcases1) +
  geom_line(aes(x=date, y=std_simincd, colour='Simulated_case_data_30'), data=simcases1) +
  labs(title="Dori 4 years Shift 0") +
  xlab("Date")+
  scale_y_continuous(expand = c(0, 0), limits = c(0, 0.25)) +
  scale_color_manual(values = c("Routine_case_data" = "blue", "Simulated_case_data_30" = "red")) +
  scale_x_date(date_breaks = "6 month", date_labels = "%b %y", minor_breaks = NULL)

# Average of years
ggplot() +
  geom_line(aes(x=date, y=std_repincd, colour= 'Routine_case_data'), data=rcases2) +
  geom_line(aes(x=date, y=std_simincd, colour='Simulated_case_data_30'), data=simcases2) +
  geom_line(aes(x=date, y=multiplier), data=mon_hab, lty=2) +
  labs(title="Dori Shift 0") +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 0.25)) +
  scale_color_manual(values = c("Routine_case_data" = "blue", "Simulated_case_data_30" = "red")) +
  scale_x_date(date_breaks = "1 month", date_labels = "%m", minor_breaks = NULL)
