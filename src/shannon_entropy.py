import re
from collections import Counter

class EntropyOfAlignment:
    def __init__(self):
        self.reads = dict()
        self.aa_abriviation = {
            ""
        }
        self.frequencies_per_position = list()

    def parse_MSA_file(self, filename):
        with open(filename, "r") as f:
            for i, line in enumerate(f):
                if re.search(line[0], "^>"):
                    current_header = line
                    self.reads[current_header] = list()
                else:
                    if set(line) == self.aa_abriviation:
                        self.reads[current_header] += line.strip()
                    else:
                        raise ImportError("Malformed file {}, line {}".format(filename, i))
                    # TODO: make sure sequence length are the same for all reads throw error
                    # TODO: write this in lab journal

    def calculate_frequies_per_position(self):
        _, all_sequences = zip(*self.reads)
        aa_per_position = list(zip(*all_sequences))
        sequence_length = len(aa_per_position)
        for aas_at_current in aa_per_position:

