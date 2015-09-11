import os
from sets import Set

DIR_PATH = os.path.dirname(os.path.realpath(__file__))
sentences_file = os.path.join(DIR_PATH, 'resources/sentencesEN.txt')
output_file = os.path.join(DIR_PATH, 'resources/recordered_sentencesEN.txt')

bigrams = Set()
with open(sentences_file, 'rb') as f:
    for line in f:
        sentence = line.strip().replace('.', '').lower().split(' ')
        for w1, w2 in zip(sentence[:-1], sentence[1:]):
            bigrams.add((w1, w2))
with open(output_file, 'wb') as f:
    for bigram in bigrams:
        f.write('%s %s\n' % bigram)
