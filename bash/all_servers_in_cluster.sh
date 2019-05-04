read -s -p "Enter sudo password: " PASS
for CLUSTER in 86 87 170 171 85; do
 for SERVER in {2..15}; do
        echo -e "\nChecking server: " s${SERVER}.t${CLUSTER} "\n"
        ssh -o stricthostkeychecking=no -q s${SERVER}.t${CLUSTER} "echo $PASS | sudo find /var/qmail/queue/mess -type f -exec grep -lir first_lastname {} \;"
 done
done
