#!/bin/bash

#USER DEFINED INPUTS
UAT_LOCATION="/etc/puppet/environments/uat/modules/"
FOREMAN_USER="jenkins"
FOREMAN_IP="10.99.212.59"
JIRA_URL="10.99.212.42:8080"
JIRA_USER="build.cicd"
JIRA_PASS="Password123"

#FIXED VARIABLES
BRANCH=$(echo ${SELECT_BRANCH} | cut -d/ -f2 )
JIRA_ID=$(echo  ${BRANCH} | cut -d- -f1,2 )



#Funcation to copy  data from feature branch selected to Foreman UAT environment.
function copy_to_uat() {
	local RCHECK
    echo -e "\n********************************************************************************************************"
    echo -e "\n\t Merging feature branch : ${BRANCH} with UAT environment"
    echo -e "\n********************************************************************************************************\n\n"

    # RSYNC FROM FOREMAN PERSONAL ENV TO UAT ENV.
    /usr/bin/rsync -e "ssh -o StrictHostKeyChecking=no" -rvh --delete --exclude '.git' ./  ${FOREMAN_USER}@${FOREMAN_IP}:${UAT_LOCATION}
    /usr/bin/curl --request POST -k  -H 'Content-Type:application/json' 'https://'${FOREMAN_IP}'//api/smart_proxies/1/import_puppetclasses' --user fjtest:Password123

    RCHECK=$(echo $?)
    if [[ ${RCHECK} -eq 0 ]];then
    echo -e "\n\tRSYNC COMPLETED \n"
    /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Merging Feature Branch : '${BRANCH}' with UAT environment.  "} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
    else
    /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Merge Failed : '${BRANCH}' with UAT environment. "} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
    	exit 1
    fi

    echo -e "\n**********************************************  UPDATING JIRA  *********************************************************\n\n"
}

function invalidInput {
    echo -e "\n********************************************************************************************************"
    #This is executing because user has selected invalid inputs.
    echo -e "\n \t INVALID INPUTS "
    echo -e "\n********************************************************************************************************\n\n"
	exit 1
}

main() {
    if [[    ${SELECT_BRANCH}  == ${GIT_BRANCH}  && ${CONFIRMATION}  == "YES"    ]] ; then
        copy_to_uat
    else
        invalidInput
    fi
}

# Calling Main Function
main
