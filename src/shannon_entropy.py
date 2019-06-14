import re
from collections    import Counter
from math           import log2


class EntropyOfAlignment:
    def __init__(self):
        self.reads = dict()
        self.aa_abriviation = {
            ""
        }
        self.frequencies_per_position = list()
        self.entropy_per_read = {}

    def parse_msa_file(self, filename):
        read_dict = {}
        with open(filename, "r") as f:
            for i, line in enumerate(f):
                if re.search(line[0], "^>"):
                    current_header = line
                    read_dict[current_header] = list()
                else:
                    if set(line) == self.aa_abriviation:
                        read_dict[current_header] += line.strip()
                    else:
                        raise ImportError("Malformed file {}, line {}".format(filename, i))

        _, all_sequences = zip(*read_dict)
        all_sequence_lengths = set([len(seq) for seq in all_sequences])
        if len(all_sequence_lengths) != 1:
            raise ImportError("Malformated file {}, multiple alignment lengths!".format(filename))

        self.reads = read_dict

    def calculate_frequies_per_position(self):
        def _calculate_freq(aa_list, seq_len):
            count_dict = dict(Counter(aa_list))
            freq_dict = {key: value/sequence_length for key, value in count_dict.items()}
            return freq_dict

        _, all_sequences = zip(*self.reads)
        aa_per_position = list(zip(*all_sequences))
        sequence_length = len(aa_per_position)
        all_freqs = [_calculate_freq(current_pos, sequence_length) for current_pos in aa_per_position]

        self.frequencies_per_position = all_freqs

    def calculate_entropy_of_reads(self):
        def _calculate_frequency_of_read(read, freq_map):
            p_k = freq_map[read[0]]
            entropy_single = -p_k*log2(p_k)
            return entropy_single + _calculate_frequency_of_read(read[1:], freq_map)

        entropy_per_read = {}
        for header, sequence in self.reads:
            entropy_per_read[header] = _calculate_frequency_of_read(sequence, self.frequencies_per_position)

        self.entropy_per_read = entropy_per_read