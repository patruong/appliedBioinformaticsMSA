configfile: "config.yml"

import os
import glob


#######################################################################
#                           FUNCTIONS                                 #
#######################################################################
# Thank you @kichik stackoverflow
def frange(x, y, jump):
  while x < y:
    yield x
    x += jump


def sample_trimmed_path(sample_list, experiment, method):
    """
    Get all trees id from experiemnt given method method wildcard
    :param sample_list: list of all ids, given input folder
    :param experiment: name of input folder
    :param method: method used to calculate tree
    :return: List of paths to requested trees
    """
    trimmed_file_path = f"run_folder/{experiment}/Trees/{method}/{{id}}_{method}.tree"
    trimmed_file_paths = [
        trimmed_file_path.format(id=sample)
        for sample in sample_list

    ]
    return trimmed_file_paths


def infographics_input(wildcards):
    """
    Get entropy interval and ask for those files (OBS: checkpoint)
    :param wildcards: wildcard.experiment
    :return: list of paths to requested method dependent method
    """
    with open(checkpoints.get_entropy_interval.get(experiment=wildcards.experiment).output[0], "r") as f:
        entropy_min, entropy_max = map(float, f.readlines()[1].strip().split("\t"))
        min_max = frange(entropy_min, entropy_max, (entropy_max-entropy_min)/10)

    methods = ["filter_entropy_{}".format(i) for i in min_max]
    methods += ["trimAl", "unfiltered"]

    input_pattern = f"results/{wildcards.experiment}/{{method}}_distance.tsv"
    info_input = [input_pattern.format(method=method) for method in methods]

    return info_input

def entropy_input(wildcards):
    """
    Get all entropy filters from all reads in experiment folder
    :param wildcards: wildcards.experiment to access reads under config[{config}}
    :return: List of paths to each reads entropy file
    """
    input_pattern = "run_folder/{experiment}/Entropy/{{id}}_entropy.tsv".format(experiment=wildcards.experiment)
    entropy_files = [input_pattern.format(id=id) for id in config[wildcards.experiment]]
    return entropy_files


def msl_input(wildcards):
    """
    Connect unfiltered id to FastTree rule
    :param wildcards:
    :return:
    """
    if wildcards.method == "unfiltered":
        return  f"data/msa_trimming/{wildcards.experiment}/{wildcards.id}.msl"
    else:
        return f"run_folder/{wildcards.experiment}/MSA/{wildcards.method}/{wildcards.id}_{wildcards.method}.msl"

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

    config["output_report"].append(f"results/{msa_file_folder}/REPORT/Results_distance.html")
    # Get sample names in experiment folder
    config[msa_file_folder] = [
        os.path.basename(msa_file).replace(".msl", "")
        for msa_file in glob.glob(folder + "/*.msl")
    ]

#######################################################################
#                           RULES                                     #
#######################################################################

rule all:
    """ Controls expected output from workflow """
    input:
         config["output_report"]


rule generate_infographics:
    input:
        infographics_input
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
        msl_input
    output:
        "run_folder/{experiment}/Trees/{method}/{id}_{method}.tree"
    log:
        "logs/FastTree/{experiment}_{method}_{id}.log"
    shell:
         """
         {params.fasttree} {input} > {output} 2> {log}
         """

rule filter_entropy:
    params:
        filter_entropy = config["filter_entropy"]
    input:
        msa = "data/msa_trimming/{experiment}/{id}.msl",
        entropy = "run_folder/{experiment}/Entropy/{id}_entropy.tsv"

    output:
        trimmed_msl = "run_folder/{experiment}/MSA/filter_entropy_{threshold}/{id}_filter_entropy_{threshold}.msl"
    log:
        "logs/filter_entropy/{experiment}_{threshold}_{id}.log"
    shell:
         """
         {params.filter_entropy} {wildcards.threshold} {input.entropy} < {input.msa} > {output.trimmed_msl} 2> {log}
         """

checkpoint get_entropy_interval:
    input:
        entropy_input
    output:
        entropy_interval = "run_folder/{experiment}/Entropy/entropy_min_max.tsv"
    run:
        c_min = 0
        c_max = 0
        for f_name in input:
            with open(f_name, "r") as f:
                lines = list(map(float,[l.strip() for l in f.readlines()][1:]))
                tmp_max = max(lines)
                tmp_min = min(lines)
                if tmp_max > c_max: c_max = tmp_max
                if tmp_min < c_min: c_min = tmp_min

        with open(output.entropy_interval, "w+") as f:
            f.write("Min\tMax\n")
            f.write("{}\t{}\n".format(c_min, c_max))


rule calculate_entropy:
    params:
        filter_entropy = config["filter_entropy"]
    input:
        msl = "data/msa_trimming/{experiment}/{id}.msl",
    output:
        entropy = "run_folder/{experiment}/Entropy/{id}_entropy.tsv"
    log:
        "logs/calculate_entropy/{experiment}_{id}.log"
    shell:
         """
         {params.filter_entropy} 1 {output.entropy} --output-filter < {input} 2> {log}
         """



rule trimal:
    params:
        trimal = config["trimAl"]
    input:
         "data/msa_trimming/{experiment}/{id}.msl"
    output:
        "run_folder/{experiment}/MSA/trimAl/{id}_trimAl.msl"
    log:
        "logs/trimAl/{experiment}_{id}.log"
    shell:
         """
         {params.trimal} -in {input} -out {output} -automated1
         """
