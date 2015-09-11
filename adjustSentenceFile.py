import sys
from tempfile import mkstemp
from shutil import move
from os import remove, close

if len(sys.argv) < 2:
    print "USAGE: python %s FILENAME"%sys.argv[0]
    sys.exit()

filename = sys.argv[1]
#Create temp file
fh, tmp_path = mkstemp()
with open(tmp_path,'w') as new_file:
    with open(filename) as file:
        for line in file:
            line = line[0].upper() + line[1:]
            new_file.write(line)
close(fh)
#Remove original file
remove(filename)
#Move new file
move(tmp_path, filename)
        
