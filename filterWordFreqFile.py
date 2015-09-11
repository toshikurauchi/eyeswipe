
import csv
import sys


def filter_file(words_filename, freqs_filename, out_filename):
    with open(words_filename, 'r') as words_file:
        words = [row.lower().strip() for row in words_file]

    words_in_both = []

    with open(out_filename, 'w') as outfile:
        writer = csv.writer(outfile, delimiter='\t')
        with open(freqs_filename, 'r') as csvfile:
            reader = csv.reader(csvfile, delimiter='\t')
            for row in reader:
                if len(row) < 2:
                    continue
                word, freq = row[:2]
                word = word.lower().strip()
                if word in words:
                    writer.writerow([freq, word])
                    words_in_both.append(word)
        for word in words:
            if word not in words_in_both:
                writer.writerow([1, word])


if __name__ == '__main__':
    import os

    if len(sys.argv) not in [1, 4]:
        print('USAGE python %s [WORD_FILE FREQ_FILE OUT_FILE]' % sys.argv[0])
        sys.exit()

    if len(sys.argv) == 4:
        words_filename, freqs_filename, out_filename = sys.argv[1:]
        filter_file(words_filename, freqs_filename, out_filename)
    else:
        cur_dir = os.path.dirname(os.path.realpath(__file__))
        words_filename = os.path.join(cur_dir, 'resources/words_mck.txt')
        for c in 'abcdefghijklmnopqrstuvwxyz':
            freqs_filename = os.path.join(cur_dir, 'ngram/w2/{c}.txt'.format(c=c))
            out_filename = os.path.join(cur_dir, 'resources/words_mck_{c}_2grams.txt'.format(c=c))
            filter_file(words_filename, freqs_filename, out_filename)
