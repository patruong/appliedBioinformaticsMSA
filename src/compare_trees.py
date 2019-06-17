import argparse
import sys
from dendropy import (
    tree,
    TaxonNameSpace
)
from dendropy.calculate import treecompare


def read_forest(filenames, true_tree_file):
    """
    Reads files with Netwick formated trees into dendropy tree objects
    :param filenames: array of paths to files to compare
    :param true_tree_file: path to file of "true" tree
    :return: array of dendropy trees and dendropy tree for "true" tree
    """
    def _read_tree_from_path(path, taxon_namespace):
        """
        Wrapper for netwick-file to dendropy tree
        """
        my_tree = tree.get_from_path(
            path,
            "netwick",
            taxon_namespace=taxon_namespace
        )
        return my_tree

    taxon_ns = TaxonNameSpace()  # needed
    true_tree = _read_tree_from_path(true_tree_file, taxon_ns)
    trees = [_read_tree_from_path(tree_path, taxon_ns) for tree_path in filenames]

    return trees, true_tree


def compute_distance(trees, true_tree):
    """
    Computes Robinson-Foulds distance between input trees and "true" tree
    :param trees: dendropy tree top be compared to the "true" tree
    :param true_tree: dentropy tree of the "true" tree
    :return: key:value dict where key is filename of tree
    """
    # TODO: look into output format and act accordingly
    return None


def format_and_print(distance_dict):
    """
    Prints tree distance in tab-seperated value format to stdout
    :param distance_dict: result dict generated from `compute_distance`
    :return: None
    """
    pass

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
        help="Paths to files containing trees in Netwick format"
    )
    args = parser.parse_args(sys.argv[1:])

    female_ents, wise_beard = read_forest(args.trees_to_compare, args.true_tree) # TODO implement
    distance = compute_distance(female_ents, wise_beard) # TODO implement
    format_and_print(distance) # TODO: implement

if __name__ == '__main__':
    main()