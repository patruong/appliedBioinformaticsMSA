configfile: "config.yml"

import os
import glob


#######################################################################
#                           FUNCTIONS                                 #
#######################################################################

def sample_trimmed_path(sample_list):
    trimmed_file_path = [
        "run_folder/trimmed/{{experiment}}/{{method}}/{id}_trimmed.tree".format(id=sample)
        for sample in sample_list
    ]
    return trimmed_file_path


#######################################################################
#                           CONFIG                                    #
#######################################################################

# Get all expected distance csv and their corresponding inputs
# Add to config dict for later use
distance_output = []
for folder in config["input_folders"]:
    # Get expected tsv_example
    msa_file_folder = os.path.dirname(folder + "/")
    distance_output = "results/{experiment}/{method}_distance.tsv".format(
        experiment=msa_file_folder,
        method=config["methods"]
    )

    # Get sample names in experiment folder
    config[msa_file_folder] = [
        os.path.basename(msa_file).replace(".msl", "")
        for msa_file in glob.glob(folder + "*.msl")]

config["output"] = distance_output


#


#######################################################################
#                           RULES                                     #
#######################################################################

rule all:
    """ Controlls expected output from workflow """
    input:
         config["output"]


rule compute_distance:
    """
    Computes distance per sample coppared to corresponding true tree
    Input:
        - True tree file
        - All output trees from FastTree in newick format
    Output: Distance TSV for experiment dependent on method for read-columns trimming method
    """
    params:
        compute_dist = config["Calculate"]
    input:
        true_tree = "data/msa_trimmings/{experiment}/{experiment}.tree",
        msa_files = lambda wildcard: sample_trimmed_path([wildcard.experiment])
    output:
          "results/{experiment}/{method}_distance.tsv"
    shell:
         """
         python {params.compute_dist} {input.true_tree} {input.msa_files} > {output}
         """
