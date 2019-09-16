# Entropy Filtering for Multiple-sequence alignments
## About
Project for the Applied Bioinformatics course taken by participants of [**Medbioinfo**](http://www.medbioinfo.se/)

This workflow is for trimming noisy regions from MSA using measurements of information entropy of said position. The threshold for entropy filtering will be set, with equal distance, from minimum observed entropy in experimental reads to maximum observed.

## Prerequisites
+ `Python 3.6`
  + `DendroPy 4.4.0`
  + `Snakemake 3.13.3+`

+ `R 3.5.1 +`
  + `rehaspe2`
  + `Plotly`
  + `ggplot2`
  + `plyr`
  + `knitr`

+ `Trimal`
+ `FastTree`

## Setup
First clone this repo into desired location.
```
git clone https://github.com/patruong/appliedBioinformaticsMSA                   
```

We recommend using [**Conda**](https://conda.io/en/latest/) for python packages.
All R-packages are on [**CRAN**](https://cran.r-project.org/)

There is a pre-compiled version of [`FastTree`](http://www.microbesonline.org/fasttree/) under `bin/` but we recommend to follow their installation instructions.

Same goes for [`TrimAl`](http://trimal.cgenomics.org/downloads), please follow their installation instruction.  

Once `TrimAl` and `FastTree` is installed please open or create `config.yml` with this layout:

```
---
######################### INPUT   #######################
input_folders:
  - "data/my_MSA_folder"
  - "data/my_other_msa_folder"
######################### PARAMETERS ####################
nr_entropy_slices: 5

######################### SOFTWARE ######################

filter_entropy:     "bin/shannon_entropy_msa.py"
trimAl:             "bin/trimAl/source/trimal"
distance_calculate: "bin/compare_trees.py"
FastTree:           "bin/FastTree"

```

Please set the path to `TrimAl` and `FastTree` executables under `SOFTWARE`.
Place the experimental data you with to run into a folder under `data/`, write the path to that folder. Please ensure that your MSA files are in `.msl` format.

## Running
After defining your input_folder(s) please add desired number of threshold parameters under `PARAMETERS` in your `config.yml`.
Observe that increasing the number of slices will add to the runtime.
Now just run `snakemake` like in your project folder:

```
snakemake -j 8 # dependent on number of cores.
```

## Output
The resulting distance files are save under `results/{experiment}` and a HTML repport can be found at `results/{experiment}/REPORT/Results_distance.html`.

### Intermediary files
All intermediary files are found under `run_folder`

- Generated trees in Newick format `run_folder/{experiment}/Trees/{trimming_method}/{read_id}.tree`
- Trimmed MSA found under `run_folder/{experiment}/MSA/{trimming_method}/{read_id}.msl`
- Entropy calculations under `run_folder/{experiment}/Entropy/{read_id}_entropy.tsv`
