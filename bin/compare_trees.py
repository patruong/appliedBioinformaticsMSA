#!/usr/bin/python3.6m
import argparse
import sys
from os.path import basename
from dendropy import (
    Tree,
    TaxonNamespace
)
from dendropy.calculate import treecompare as tc


def read_forest(filenames, true_tree_file):
    """
    Reads files with Netwick formated trees into dendropy tree objects
    :param filenames: array of paths to files to compare
    :param true_tree_file: path to file of "true" tree
    :return: dict of dendropy trees with basename as key and dendropy tree for "true" tree
    """

    def _read_tree_from_path(path, taxon_namespace):
        """
        Wrapper for netwick-file to dendropy tree
        """
        tree = Tree()
        my_tree = tree.get_from_path(
            path,
            "newick",
            taxon_namespace=taxon_namespace
        )
        return my_tree

    taxon_ns = TaxonNamespace()  # needed
    true_tree = _read_tree_from_path(true_tree_file, taxon_ns)
    trees = {
        basename(tree_path).replace(".msl", ""):
            _read_tree_from_path(tree_path, taxon_ns)
        for tree_path in filenames
    }

    return trees, true_tree


def compute_distance(trees, true_tree):
    """
    Computes Robinson-Foulds distance between input trees and "true" tree
    :param trees: dict of dendropy tree top be compared to the "true" tree
    :param true_tree: dentropy tree of the "true" tree
    :return: key:value dict where key is filename of tree
    """
    distance_dict = {
        file: tc.unweighted_robinson_foulds_distance(tree, true_tree)
        for file, tree in trees.items()
    }
    return distance_dict


def format_and_print(distance_dict):
    """
    Prints tree distance in tab-seperated value format to stdout
    :param distance_dict: result dict generated from `compute_distance`
    :return: None
    """
    print("tree_label", "distance", sep="\t")
    for label, distance in distance_dict.items():
        print(label, distance, sep="\t")


def main():
    parser = argparse.ArgumentParser(
        description="Compares given \"true\" phylogenetic tree to other trees"
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

    tree_dict, true_tree = read_forest(args.trees_to_compare, args.true_tree)
    distance = compute_distance(tree_dict, true_tree)
    format_and_print(distance)


if __name__ == '__main__':
    main()
