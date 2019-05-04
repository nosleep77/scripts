
echo -e "\n Enter password: " && read PASS
for SERVER in {4..16}; do
 echo -e "\nfixing sigs on server " $SERVER
 ssh -o stricthostkeychecking=no -q s${SERVER}.t45 "echo $PASS | sudo service postfix restart"
 echo -e "\nserver " $SERVER " fixed!\n"
done
