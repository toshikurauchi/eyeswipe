import sys
import csv
from unidecode import unidecode
from tempfile import mkstemp
from shutil import move
from os import remove, close

if len(sys.argv) < 2:
    print "Usage: python %s FILENAME"%sys.argv[0]
    sys.exit()

filename = sys.argv[1]
exceptions = [',','.','!',';',':','?']
#Create temp file
fh, tmp_path = mkstemp()
with open(tmp_path,'w') as new_file:
    with open(filename, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter='\t')
        writer = csv.writer(new_file, delimiter='\t')
        for line in reader:
            word = unidecode(line[0]).lower()
            found = False
            for e in exceptions:
                if e in word:
                    found = True
                    break
            if not found:
                writer.writerow([word, line[1]])

close(fh)
#Remove original file
remove(filename)
#Move new file
move(tmp_path, filename)
