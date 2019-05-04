
# Assumption is the the root of this program 
# is ~/xmlparsing, and this is where the XML File is located.
# The directory test/ contains the files to be processed
# When script is finished it will create directories under
# ~/xmlparsing/test with the names of FileType and copies
# the files into the appropriate directories

import os
import socket
import shutil
from xml.dom.minidom import parse

# SENT_TAG is the one that is read from XML File
# SENT_TAG holds the value of filename
# RECEIVED_TAG is obtained from the socket server

SENT_TAG = "test"
RECEIVED_TAG = "ins"

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(("example.com", 80))

# get directory listing of input in dir1[] list
dir1 = os.listdir("/home/joker/xmlparsing/test")

dom = parse("xmlfile1.xml")
a = len(dir1)
b = 0

while b < a:

	# assign the filename as value for the tags in XML File (e.g., <test> here)
	dom.getElementsByTagName(SENT_TAG)[0].firstChild.nodeValue = dir1[b]
	outputData = dom.toxml()
	# print(outputData)

	# send data to socket
	sock.sendall(outputData + '\x04')

	# receive data from socket and capture in "output" variable
	output = ""
	while 1:
			buffer = sock.recv(1024)
			if not buffer:
				break
			output += buffer
	sock.close()
	# print(output)
	b += 1


	# parse socket output and get the value of tags (e.g., <ins> here)
	s = output.find(("<%s>" % RECEIVED_TAG)) + 2 + len(RECEIVED_TAG)
	e = output.find(("</%s>" % RECEIVED_TAG))

	# create the directory	
	os.chdir("/home/joker/xmlparsing/test/")
	os.mkdir(output[s:e])

	# copy the file into the directory
	shutil.copyfile("/home/joker/xmlparsing/test/" + dir1[0], "/home/joker/xmlparsing/test/" + output[s:e] + "/" + dir1[0])


