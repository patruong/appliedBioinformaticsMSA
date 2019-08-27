#!/usr/bin/python3.6m
import re
from collections import Counter
import math
import argparse
import sys
import os


class EntropyOfAlignment:
    def __init__(self, threshold, filter_output, output_filter=False):
        self.read_entropy = bool(output_filter)
        self.filter_threshold = threshold
        self.sequence_length = None
        self.reads = dict()
        self.filter_output_file = re.sub("__[0-9.]+__", "", filter_output)
        self.aa_abriviation = set(
            list("ARNDBCEQZGHILKMFPSTWYV-")
        )
        self.frequencies_per_position = list()
        self.entropy_per_position = []

        self._parse_msa_file()
        if not self.read_entropy:
            success = self._read_entropy_file()
            if not success:
                raise ImportError("Error importing entropy: " + filter_output)

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

        self.sequence_length = list(all_sequence_lengths)[0]
        self.reads = read_dict

    def _read_entropy_file(self):
        """ Check if entropy already have been calculated"""
        dirname = os.path.dirname(self.filter_output_file)
        os.makedirs(dirname, exist_ok=True)
        if os.path.isfile(self.filter_output_file):
            try:
                with open(self.filter_output_file, "r") as f:
                    entropy_per_position = [l.strip() for l in f.readlines()[1:]]  # Remove header
                    entropy_per_position = list(map(float, entropy_per_position))
                if len(entropy_per_position) != self.sequence_length:
                    raise ValueError("Wrong sequence length of entropy")
            except (ValueError, FileNotFoundError) as e:
                print(str(e), file=sys.stderr)
                return False

            self.entropy_per_position = entropy_per_position
            return True

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
            entropy = -sum([x_i * math.log2(x_i) for x_i in x])
            return entropy

        entropy_per_pos = [_entropy(pos_freq.values()) for pos_freq in self.frequencies_per_position]
        self.entropy_per_position = entropy_per_pos

    def _filter(self):
        keep_index = [idx for idx in range(self.sequence_length) if
                      self.entropy_per_position[idx] < self.filter_threshold]
        if not keep_index:
            print("No position passed filtering criteria. Inserting 'X'", file=sys.stderr)
            for head, seq in self.reads.items():
                self.reads[head] = "X"
        else:
            for head, seq in self.reads.items():
                filtered_seq = "".join(map(lambda idx: seq[idx], keep_index))
                self.reads[head] = filtered_seq

    def _write_filter_to_file(self):
        with open(self.filter_output_file, "w+") as f:
            f.write("Entropy\n")
            f.write("\n".join(map(str, self.entropy_per_position)))
            f.write("\n")

    def __str__(self):
        """ Write __str__ that output stdout as a one column csv"""
        msg = ""
        for header, seq in self.reads.items():
            msg += f"{header}\n{seq}\n"
        return msg

    def run(self):
        """ run """
        if self.read_entropy:
            self._calculate_frequencies_and_entropy_per_position()
            self._write_filter_to_file()
        else:
            self._filter()
            print(self)


def main():
    parser = argparse.ArgumentParser(
        description="Calculate entropy per column in MSA."
                    "\n\tINPUT: stdin"
                    "\n\tOUTPUT: stdout"
                    "\n\tUSAGE: ./shannon_entropy_msa t < {input} > {output}",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "threshold", type=float,
        help="Entropy threshold for filtering"
    )
    parser.add_argument(
        "filter_output", type=str,
        help="Please provide location of filter file"
    )
    parser.add_argument("--output-filter", help="Write filter", action="store_true")
    args = parser.parse_args(sys.argv[1:])
    entropy_align = EntropyOfAlignment(args.threshold, args.filter_output, args.output_filter)
    entropy_align.run()


if __name__ == '__main__':
    main()
