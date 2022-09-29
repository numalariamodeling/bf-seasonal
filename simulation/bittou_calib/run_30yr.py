import os
import time

import pandas as pd
from dtk.utils.core.DTKConfigBuilder import DTKConfigBuilder
from malaria.interventions.health_seeking import add_health_seeking
from simtools.ExperimentManager.ExperimentManagerFactory import ExperimentManagerFactory
from simtools.ModBuilder import ModBuilder, ModFn
from simtools.SetupParser import SetupParser
from load_paths import load_box_paths
from hbhi.set_up_interventions import InterventionSuite, add_all_interventions
from hbhi.set_up_general import initialize_cb, setup_ds
from hbhi.utils import add_nmf_trt, tryread_df, read_main_dfs, add_monthly_parasitemia_rep_by_year
from tqdm import tqdm


def input_override(cb):
    cb.update_params({
        "Air_Temperature_Filename": os.path.join('Bittou2', 'average', 'air_temperature_daily.bin'),
        "Land_Temperature_Filename": os.path.join('Bittou2', 'average', 'air_temperature_daily.bin'),
        "Rainfall_Filename": os.path.join('Bittou2', 'average', 'rainfall_daily.bin'),
        "Relative_Humidity_Filename": os.path.join('Bittou2', 'average', 'relative_humidity_daily.bin')
    })

    return {"Input_Override": 1}

SetupParser.default_block = 'NUCLUSTER'
datapath, projectpath = load_box_paths(parser_default=SetupParser.default_block)
larval_hab_csv = 'simulation_inputs/monthly_habitats_v4_fit.csv'

user = os.getlogin()
expname = f'{user}_bittou_seasonal_calib'

num_seeds = 10
years = 30
serialize = False

# BASIC SETUP
# Filtered report for the last year
cb = initialize_cb(years, serialize, filtered_report=1)
cb.update_params({
    'x_Temporary_Larval_Habitat': 1,  # Package default is 0.2
    'x_Base_Population': 0.4,
    'x_Birth': 0.4
})

# INTERVENTIONS
add_health_seeking(cb, start_day=21*365,
                   targets=[{'agemin': 0, 'agemax': 100,
                             'coverage': 0.4, 'rate': 0.3, 'seek': 1,
                             'trigger': 'NewClinicalCase'}],
                   drug=['Artemether', 'Lumefantrine'])

# REPORTS
add_monthly_parasitemia_rep_by_year(cb, 3, years, 1986) # Report for year 2013, 2014, 2015
# Simulation from 1986 to 2015 (30 years)

# Important DFs
df, rel_abund_df, lhdf = read_main_dfs(projectpath, country='burkina',
                                       larval_hab_csv=larval_hab_csv)
ds_list = ['Bittou']

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
    print(f'python simulation/bittou_calib/analyze_pfprcases.py -name bittou_seasonal_calib_30yr -id {expt_id}')
