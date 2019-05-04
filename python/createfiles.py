# Created Dec 2 2013
# This scripts creates specific number of files within min and max limit across many folders

import os
import random
import math
import sys

size1 = int(input('Enter minimum size of file: '))
size2 = int(input('Enter maximum size of file: '))
totalFiles = int(input('Total files: '))
maxFilesPerFolder = int(input('Maximum files per folder: '))

totalFolders = math.ceil(totalFiles / maxFilesPerFolder)
foldersCreated = 0
filesCreated = 0

randSize = random.randint(size1, size2)

while 1:
  while foldersCreated < totalFolders:
    z = "folder" + str(foldersCreated)
    os.mkdir(z)
    filesCreatedinFolder = 0
    while filesCreatedinFolder < maxFilesPerFolder:
      c = 0
      f = open(z + "/file" + str(filesCreated), "wb")
      while c < randSize:
        f.write(bytes("e", 'UTF-8'))
        c += 1
      f.close()
      randSize = random.randint(size1, size2)
      filesCreatedinFolder += 1
      filesCreated += 1
      if filesCreated >= totalFiles:
        sys.exit()
    foldersCreated += 1
