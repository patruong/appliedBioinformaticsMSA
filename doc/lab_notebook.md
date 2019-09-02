# Graduate School in Medical Bioinformatics
## Lab book for the final project in Applied Bioinformatics

### Members
| Person        |  E-mail         | Reference  |
| ------------- |:-------------:| -----:|
| [Juan Inda](https://www.chalmers.se/en/staff/Pages/inda.aspx)      | inda@chalmers.se | JI |
|  Joel Ås     |  joel.as@medsci.uu.se     |  JÅ  |
| Patrick Truong |  ptruong@kth.se     |  PT   |


### Logs

<!---
DATES goes under ####
Put your reference JI, JÅ, PT and an explanation of what you do
-->

#### 13.06.2019

- JI, JÅ, PT
  - Definition of the problem
  - Task assignment
    - Juan: Lab book
    - Patrick: gh-Pages
    - Joel: entropy
        - Started script for calculating entropy `src/shannon_entropy_msa.py`

#### 14.06.2019

- JI
  - Updated the lab-book
```bash
results/lab_book.md
```
- JÅ
    - Finished `src/shannon_entropy_msa.py`
        - Outputs filtered msa in fasta format to `stdout`
        - saves filter scores in csv format
    - Started script to tree comparison `src/compare_tree.py`


#### 17.06.2019
- JÅ
    - added `FastTree` to bin
    - Wrote code for reading `dendropy` trees from Newick files in `src/compare_trees.py`


#### 18.06.2019
- JÅ
    - Finished and tested `compare_trees.py`
    - Moved tested scripts to `bin`
    - Wrote a config and a pair of Snakemake rules
        - added `config.yml` for IO of workflow


#### 2.07.2019
- JÅ 
   - Added entropy cut-off as a wildcard for for experiment setup. This means that each threshold should be defined in `config.yml` and each experiment folder defined will run with those cut-offs  

#### 29.07.2019
- JÅ
    - Wrote automatic plotting of results per experiment folder

#### 2.08.2019
- JÅ
    - Rewrote the entropy workflow as to remove unnecessary calculations

#### 27.08.2019
- JÅ
    - Selected entropy threshold are now selected automatically

#### 30.08.2019
- JÅ
    - Workflow for baseline unfiltered read distance from true phylo. Need to update graphs in `infographics.Rmd`

#### 2.09.2019
- JÅ
    - Updated plots in `ìnfographics.Rmd`

