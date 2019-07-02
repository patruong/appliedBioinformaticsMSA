configfile: "config.yml"

import os
import glob


#######################################################################
#                           FUNCTIONS                                 #
#######################################################################

def sample_trimmed_path(sample_list, experiment, method):
    trimmed_file_path = f"run_folder/{experiment}/Trees/{method}/{{id}}_{method}_trimmed.tree"
    trimmed_file_paths = [
        trimmed_file_path.format(id=sample)
        for sample in sample_list
    ]
    return trimmed_file_paths


#######################################################################
#                           CONFIG                                    #
#######################################################################

# Get all expected distance csv and their corresponding inputs
# Add to config dict for later use
distance_output = []
for folder in config["input_folders"]:
    # Get expected tsv_example
    msa_file_folder = os.path.basename(folder.rstrip("/"))
    distance_output.append("results/{experiment}/{{method}}_distance.tsv".format(
        experiment=msa_file_folder
    ))
    # Get sample names in experiment folder
    config[msa_file_folder] = [
        os.path.basename(msa_file).replace(".msl", "")
        for msa_file in glob.glob(folder + "/*.msl")
    ]

config["output"] = distance_output


#######################################################################
#                           RULES                                     #
#######################################################################

rule all:
    """ Controlls expected output from workflow """
    input:
         expand(config["output"], method=config["methods"])


rule compute_distance:
    """
    Computes distance per sample coppared to corresponding true tree
    Input:
        - True tree file
        - All output trees from FastTree in newick format
    Output: Distance TSV for experiment dependent on method for read-columns trimming method
    """
    params:
        compute_dist = config["distance_calculate"]
    input:
        true_tree = "data/msa_trimming/{experiment}/{experiment}.tree",
        msa_files = lambda wildcards: sample_trimmed_path(
            config[wildcards.experiment],
            wildcards.experiment,
            wildcards.method
        )
    output:
        "results/{experiment}/{method}_distance.tsv"
    log:
        "logs/distance/{experiment}_{method}.log"
    shell:
         """
         python {params.compute_dist} {input.true_tree} {input.msa_files} > {output}
         """


rule fast_tree:
    params:
        fasttree = config["FastTree"]
    input:
        "run_folder/{experiment}/MSA/{method}/{id}_{method}_trimmed.msl"
    output:
        "run_folder/{experiment}/Trees/{method}/{id}_{method}_trimmed.tree"
    log:
        "logs/FastTree/{experiment}_{id}.log"
    shell:
         """
         {params.fasttree} {input} > {output} 2> {log}
         """

rule filter_entropy:
    params:
        filter_entropy = config["methods"]["filter_entropy"],
        threshold = 0.05
    input:
        "data/msa_trimming/{experiment}/{id}.msl"
    output:
        trimmed_msl = "run_folder/{experiment}/MSA/filter_entropy/{id}_filter_entropy_trimmed.msl",
        filter_stats = "run_folder/{experiment}/MSA/filter_entropy/{id}_filter_entropy_trimmed.csv"

    log:
        "logs/filter_entropy/{experiment}_{id}.log"
    shell:
         """
         {params.filter_entropy} {params.threshold} < {input} > {output}
         """

rule trimal:
    params:
        trimal = config["methods"]["trimAl"]
    input:
         "data/msa_trimming/{experiment}/{id}.msl"
    output:
        "run_folder/{experiment}/MSA/trimAl/{id}_trimAl_trimmed.msl"
    log:
        "logs/trimAl/{experiment}_{id}.log"
    shell:
         """
         {params.trimal} -in {input} > {output}
         """