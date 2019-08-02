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
config["output_report"] = []
for folder in config["input_folders"]:
    # Get expected tsv_example
    msa_file_folder = os.path.basename(folder.rstrip("/"))
    distance_output.append("results/{experiment}/{{method}}_distance.tsv".format(
        experiment=msa_file_folder
    ))
    config["output_report"].append(f"results/{msa_file_folder}/REPORT/Results_distance.html")
    # Get sample names in experiment folder
    config[msa_file_folder] = [
        os.path.basename(msa_file).replace(".msl", "")
        for msa_file in glob.glob(folder + "/*.msl")
    ]

config["output_distance"] = distance_output
config["methods"] = ["filter_entropy_{}".format(thres) for thres in config["threshold"]]
config["methods"].append("trimAl")

#######################################################################
#                           RULES                                     #
#######################################################################

rule all:
    """ Controlls expected output from workflow """
    input:
         expand(config["output_distance"], method=config["methods"]),
         config["output_report"]


rule generate_infographics:
    input:
        expand("results/{{experiment}}/{method}_distance.tsv", method=config["methods"])
    output:
        "results/{experiment}/REPORT/Results_distance.html"
    log:
        "logs/Infographics/{experiment}.log"
    shell:
        """
        mkdir -p results/{wildcards.experiment}/REPORT
        Rscript -e "rmarkdown::render('bin/infographics.Rmd', output_file = '../{output}')" --args {input} 2> {log}
        """

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
         python {params.compute_dist} {input.true_tree} {input.msa_files} > {output} 2> {log}
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
        filter_entropy = config["filter_entropy"]
    input:
        "data/msa_trimming/{experiment}/{id}.msl"
    output:
        trimmed_msl = "run_folder/{experiment}/MSA/filter_entropy_{threshold}/{id}_filter_entropy_{threshold}_trimmed.msl"
    log:
        "logs/filter_entropy/{experiment}_{threshold}_{id}.log"
    run:
         entropy_output = f"run_folder/{wildcards.experiment}/Entropy/{wildcards.id}_entropy.tsv"
         shell(f"{params.filter_entropy} {wildcards.threshold} {entropy_output} < {input} > {output.trimmed_msl} 2> {log}")

rule trimal:
    params:
        trimal = config["trimAl"]
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