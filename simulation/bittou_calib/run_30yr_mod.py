import os
import time

import pandas as pd
from dtk.utils.core.DTKConfigBuilder import DTKConfigBuilder
from dtk.vector.species import set_species, set_larval_habitat, update_species_param
from malaria.interventions.health_seeking import add_health_seeking
from malaria.reports.MalariaReport import add_event_counter_report
from simtools.ExperimentManager.ExperimentManagerFactory import ExperimentManagerFactory
from simtools.ModBuilder import ModBuilder, ModFn
from simtools.SetupParser import SetupParser
from load_paths import load_box_paths
from hbhi.set_up_interventions import InterventionSuite, add_all_interventions
from hbhi.set_up_general import initialize_cb, setup_ds
from hbhi.utils import add_nmf_trt, tryread_df, read_main_dfs, add_monthly_parasitemia_rep_by_year
from tqdm import tqdm

#Change this to Dori_season with specific shift_day
def input_override(cb): ## CHANGE THE REST TOO
    cb.update_params({
        "Air_Temperature_Filename": os.path.join('Dori_season', 'Dori_5yr', 'shift_0', 'air_temperature_daily.bin'),
        "Land_Temperature_Filename": os.path.join('Dori_season', 'Dori_5yr', 'shift_0', 'air_temperature_daily.bin'),
        "Rainfall_Filename": os.path.join('Dori_season', 'Dori_5yr', 'shift_0', 'rainfall_daily.bin'),
        "Relative_Humidity_Filename": os.path.join('Dori_season', 'Dori_5yr', 'shift_0', 'relative_humidity_daily.bin')
    })

    return {"Input_Override": 1}
  

# def input_override(cb): ## CHANGE THE REST TOO
#     cb.update_params({
#         "Air_Temperature_Filename": os.path.join('Dori_season', 'dori_shifted', '2015', 'shift_330', 'air_temperature_daily.bin'),
#         "Land_Temperature_Filename": os.path.join('Dori_season', 'dori_shifted', '2015', 'shift_330', 'land_temperature_daily.bin'),
#         "Rainfall_Filename": os.path.join('Dori_season', 'dori_shifted', '2015', 'shift_330', 'rainfall_daily.bin'),
#         "Relative_Humidity_Filename": os.path.join('Dori_season', 'dori_shifted', '2015', 'shift_330', 'relative_humidity_daily.bin')
#     })
# 
#     return {"Input_Override": 1}
  
#Add this to ModFn below!
def species_override(cb):
    set_species(cb, ["arabiensis", "funestus", "gambiae"])
    set_larval_habitat(cb, {"arabiensis": {'TEMPORARY_RAINFALL': 2.57e9, 'CONSTANT': 1.63e5},
                            "funestus": {'WATER_VEGETATION': 5.15e8, 'CONSTANT':3.25e4},
                            "gambiae": {'TEMPORARY_RAINFALL': 7.5e7, 'CONSTANT': 4.74e3}
                            })
    update_species_param(cb, 'arabiensis', 'Anthropophily', 0.88, overwrite=True)
    update_species_param(cb, 'arabiensis', 'Indoor_Feeding_Fraction', 0.5, overwrite=True)
    update_species_param(cb, 'funestus', 'Anthropophily', 0.5, overwrite=True)
    update_species_param(cb, 'funestus', 'Indoor_Feeding_Fraction', 0.86, overwrite=True)
    update_species_param(cb, 'gambiae', 'Anthropophily', 0.74, overwrite=True)
    update_species_param(cb, 'gambiae', 'Indoor_Feeding_Fraction', 0.9, overwrite=True)

    return {"Species_Override": 1}


SetupParser.default_block = 'NUCLUSTER'
datapath, projectpath = load_box_paths(parser_default=SetupParser.default_block)
larval_hab_csv = 'simulation_inputs/monthly_habitats_v4.csv'

user = os.getlogin()
expname = f'{user}_new_dori_5yr_mixspecies_0' # Change this

num_seeds = 100
years = 30
serialize = False

# BASIC SETUP
# Filtered report for the last year
cb = initialize_cb(years, serialize, filtered_report=1)
cb.update_params({
    'x_Temporary_Larval_Habitat': 1,  # Package default is 0.2
    'x_Base_Population': 0.5,
    'x_Birth': 0.5
})
 
# INTERVENTIONS
add_health_seeking(cb, start_day=0, # 5*365
                   targets=[{'agemin': 0, 'agemax': 100,
                             'coverage': 0.5, 'rate': 0.3, 'seek': 1,
                             'trigger': 'NewClinicalCase'}],
                   drug=['Artemether', 'Lumefantrine'])

# REPORTS
add_monthly_parasitemia_rep_by_year(cb, 4, years, 1986) # Report for year 2013, 2014, 2015
#add_event_counter_report(cb, event_trigger_list=['Received_Treatment'], start=(years-3)*365)
cb.update_params({'Report_Event_Recorder_Events': ['Received_Treatment'],
                  'Report_Event_Recorder' : 1,
                  'Report_Event_Recorder_Start_Day' : (years-4)*365,
                  'Report_Event_Recorder_End_Day' : years*365,
                  'Report_Event_Recorder_Min_Age_Years' : 0,
                  'Report_Event_Recorder_Max_Age_Years' : 10,
                  'Report_Event_Recorder_Individual_Properties' : [],
                  'Report_Event_Recorder_Ignore_Events_In_List' : 0
                 })

# Simulation from 1986 to 2015 (30 years)

# Important DFs
df, rel_abund_df, lhdf = read_main_dfs(projectpath, country='burkina',
                                       larval_hab_csv=larval_hab_csv)
ds_list = ['Dori']

# BUILDER
list_of_sims = []
for my_ds in ds_list:
    L = []

    L = L + [[ModFn(setup_ds,
                    my_ds=my_ds,
                    archetype_ds=df.at[my_ds, 'seasonality_archetype_2'],
                    pull_from_serialization=False,
                    burnin_id='',
                    rel_abund_df=rel_abund_df,
                    lhdf=lhdf,
                    demographic_suffix='_IPs_risk',
                    use_arch_input=False,
                    hab_multiplier=1,
                    parser_default=SetupParser.default_block),
              ModFn(input_override),
              ModFn(species_override),
              ModFn(DTKConfigBuilder.set_param, 'DS_Name', my_ds),
              ModFn(DTKConfigBuilder.set_param, 'Run_Number', 4326 + x)]
             for x in range(num_seeds)]
list_of_sims = list_of_sims + L

builder = ModBuilder.from_list(list_of_sims)

run_sim_args = {
    'exp_name': expname,
    'config_builder': cb,
    'exp_builder': builder
}

if __name__ == "__main__":
    SetupParser.init()
    exp_manager = ExperimentManagerFactory.init()
    exp_manager.run_simulations(**run_sim_args)

    time.sleep(20)
    exp_manager.wait_for_finished(verbose=True)
    assert (exp_manager.succeeded())
    expt_id = exp_manager.experiment.exp_id
    print(f'python simulation/bittou_calib/analyze_pfprcases.py -name new_dori_5yr_mixspecies_0 -id {expt_id}')
