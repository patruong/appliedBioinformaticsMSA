import argparse
import sys
import dendropy
from dendropy.calculate import treecompare






# tns = dendropy.TaxonNamespace()
# tree1 = tree.get_from_path(
#         "t1.nex",
#         "nexus",
#         taxon_namespace=tns)
# tree2 = tree.get_from_path(
#         "t2.nex",
#         "nexus",
#         taxon_namespace=tns)
# tree1.encode_bipartitions()
# tree2.encode_bipartitions()
# print(treecompare.symmetric_difference(tree1, tree2))

def read_forest(filenames, true_tree_file):
    return 1,2

def compute_distance(trees, true_tree):
    return None

def format_and_print(distance_dict):

def main():
    parser = argparse.ArgumentParser(
        description="Compares given \"true\" phylogenetic tree to other trees"
    )
    parser.add_argument(
        "-out",
        type=str,
        default="distance.tsv",
        help="Specify output csv. Defaults to run folder/distance.csv"
    )
    parser.add_argument(
        "true_tree",
        type=str,
        help="Path to file true tree in Netwick format"
    )
    parser.add_argument(
        "trees_to_compare",
        nargs="+",
        type=str,
        help="Paths to files containing trees in netwick format"
    )
    args = parser.parse_args(sys.argv[1:])

    female_ents, wise_beard = read_forest(args.trees_to_compare, args.true_tree) # TODO implement
    distance = compute_distance(female_ents, wise_beard) # TODO implement
    format_and_print(distance) # TODO: implement

if __name__ == '__main__':
    main()