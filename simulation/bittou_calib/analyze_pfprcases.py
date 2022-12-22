import argparse
import os
from simtools.Analysis.SSMTAnalysis import SSMTAnalysis
from simtools.Analysis.AnalyzeManager import AnalyzeManager
from simtools.SetupParser import SetupParser
from analyzer_collection import MonthlyPfPRAnalyzerU5, EventReporterAnalyzer
from load_paths import load_box_paths

SetupParser.default_block = 'NUCLUSTER'
datapath, projectpath = load_box_paths(parser_default=SetupParser.default_block)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-name', dest='exp_name', type=str, required=False)
    parser.add_argument('-id', dest='exp_id', type=str, required=True)

    return parser.parse_args()

# put the expt ID of step 04 here, with a good expt name

working_dir = "."

if __name__ == "__main__":
    SetupParser.init()
    args = parse_args()
    exp_name = args.exp_name if args.exp_name else 'dori_seasonal'

    experiments = {
        exp_name: args.exp_id,
    }

    analyzers = [MonthlyPfPRAnalyzerU5]

    sweep_variables = ["DS_Name",
                       'archetype',
                       'Run_Number']

    output_dir = os.path.join(projectpath, 'simulation_output')

    for expt_name, expt_id in experiments.items():
        analyzers = []
        analyzers.append(MonthlyPfPRAnalyzerU5(expt_name=expt_name,
                                               sweep_variables=sweep_variables,
                                               start_year=2013,
                                               end_year=2016,
                                               working_dir=os.path.join(output_dir, expt_name)))
        analyzers.append(EventReporterAnalyzer(exp_name=expt_name,
                                               sweep_variables=sweep_variables,
                                               working_dir=os.path.join(output_dir)))
        am = AnalyzeManager(expt_id, analyzers=analyzers)
        am.analyze()
