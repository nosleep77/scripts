

for each pattern, find it in zone file where file starts with the word "cluster", append ';' to the beginning of the line and the line before it.


while read LINE ; do
 a=$(grep -i sender84)
 b=$(echo -e "$a \n")
 echo $b
done < zone.example.com




if  [[ $a == cluster* ]] ;
then
    echo $LINE
fi


while read LINE ; do
 a=$(grep -i sender84)
 b=$(grep -n sender84)

 	if  [[ $a == cluster* ]] ;
	 then
	    echo $LINE
	fi

cut -d ':' -f1

done < zone.example.com

====================

while read LINE
 do
        if  [[ $LINE == *second* && $LINE == that* ]] ;
        then
     	 echo $LINE | sed 's/^/#/'
        fi
done < file1


========================

IFS="\n"
for i in 'grep second file1' ; do
 sed -i '/that/s/^/;/' file1
done


# Notes
# http://www.linuxforums.org/forum/programming-scripting/182390-little-tricky-adding-comment-but-specific-case.html#post859506
# http://www.linuxquestions.org/questions/showthread.php?p=4462438#post4462438
