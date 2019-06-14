#!/usr/bin/python3.6m
import re
from   collections  import Counter
import math
import argparse
import sys


class EntropyOfAlignment:
    def __init__(self):
        self.reads = dict()
        self.aa_abriviation = set(
            list("ARNDBCEQZGHILKMFPSTWYV-")
        )
        self.frequencies_per_position = list()
        self.entropy_per_position = []

    def _parse_msa_file(self):
        """ Read file and geat each alignment for each read """
        read_dict = {}
        current_header = None
        for i, line in enumerate(sys.stdin):
            line = line.strip()
            if re.search(line[0], "^>"):
                current_header = line
                read_dict[current_header] = ""
            else:
                if current_header is None:
                    raise ImportError("Malformed Header! line {}".format(line))
                elif set(line) <= self.aa_abriviation:
                    read_dict[current_header] += line
                else:
                    raise ImportError("Malformed Line! line {}".format(line))

        _, all_sequences = zip(*read_dict.items())
        all_sequence_lengths = set([len(seq) for seq in all_sequences])
        if len(all_sequence_lengths) != 1:
            raise ImportError("Malformated file, multiple alignment lengths!")

        self.reads = read_dict

    def _calculate_frequencies_and_entropy_per_position(self):
        """ Calculates Shannon entropy per column and stores it in object """
        def _calculate_freq(aa_list, seq_len):
            """ Calculates each frequency per variable in column"""
            count_dict = dict(Counter(aa_list))
            freq_dict = {key: value/seq_len for key, value in count_dict.items()}
            return freq_dict

        _, all_sequences = zip(*self.reads.items())
        aa_per_position = list(zip(*all_sequences))
        sequence_length = len(aa_per_position)
        all_freqs = [_calculate_freq(current_pos, sequence_length) for current_pos in aa_per_position]

        self.frequencies_per_position = all_freqs

        def _entropy(x):
            """ Calculates Shannons entropy """
            entropy = sum([-x_i * math.log2(x_i) for x_i in x])
            return entropy

        entropy_per_pos = [_entropy(pos_freq.values()) for pos_freq in self.frequencies_per_position]
        self.entropy_per_position = entropy_per_pos

    def __str__(self):
        """ Write __str__ that output stdout as a one column csv"""
        msg = "\n".join(map(str, self.entropy_per_position))
        return msg

    def run(self):
        """ run """
        self._parse_msa_file()
        self._calculate_frequencies_and_entropy_per_position()
        print(self)


def main():
    parser = argparse.ArgumentParser(
        description="Calculate entropy per column in MSA."
                    "\n\tINPUT: stdin"
                    "\n\tOUTPUT: stdout"
                    "\n\tUSAGE: ./shannon_entropy_msa < {input} > {output}",
        formatter_class=argparse.RawTextHelpFormatter
    )
    _ = parser.parse_args()
    entropy_aling = EntropyOfAlignment()
    entropy_aling.run()


if __name__ == '__main__':
    main()
