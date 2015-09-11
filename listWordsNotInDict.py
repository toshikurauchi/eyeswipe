import sys
from sets import Set

if len(sys.argv) < 3:
    print "USAGE: python %s DICT.txt SENTENCES.txt"%sys.argv[0] 
    sys.exit()

words_file_path = sys.argv[1]
sentences_file_path = sys.argv[2]

words = Set([])
with open(words_file_path) as words_file:
    for word in words_file:
        words.add(word.strip().lower())
        
words_not_in = Set([])
with open(sentences_file_path) as sentences_file:
    for line in sentences_file:
        sentence = line.split('\t')[-1]
        sentence_words = sentence.strip().split(' ')
        for word in sentence_words:
            word = word.replace('.', '')
            word = word.replace(',', '')
            word = word.lower()
            if word not in words:
                words_not_in.add(word)

for word in words_not_in:
    print word