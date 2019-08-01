# Entropy Filtering for Multiple-sequence alignments
## About
Project for the Applied Bioinformatics course taken by participants of [**Medbioinfo**](http://www.medbioinfo.se/)

This workflow is for trimming noisy regions from MSA using measurements of information entropy of said position. 

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

######################### PARAMETERS ####################
# Add additional desired thresholds
threshold:
  - 0.1
  - 0.2

######################### SOFTWARE ######################
filter_entropy:     "bin/shannon_entropy_msa.py"
trimAl:             "bin/trimAl/source/trimal"
distance_calculate: "bin/compare_trees.py"
FastTree:           "bin/FastTree"
```

Please set the path to `TrimAl` and `FastTree` executables under `SOFTWARE`.
Place the experimental data you with to run into a folder under `data/`, write the path to that folder. Please ensure that your MSA files are in `.msl` format.

## Running
After defining your input_folder(s) please add desired threshold parameters under `PARAMETERS` in your `config.yml`.
Now just run `snakemake` like in your project foöder:

```
snakemake -j 8 # dependent on number of cores.
```

## Output
The resulting distance files are save under `results/{experiment}` and a HTML repport can be found at `results/{experiment}/REPORT/Results_distance.html`.

### Intermediary files
All intermediary files are found under `run_folder`
All generated trees can be found in Newick format under `run_folder/{experiment}/Trees/{method_used}/` while all filtered MSA and entropy measurements can be found under `run_folder/{experiment}/MSA/{method_used}/`. The saved entropy per is saved as `my_filtered_alignment_id.csv` and filtered MSA as `my_filtered_alignment_id.msl`
