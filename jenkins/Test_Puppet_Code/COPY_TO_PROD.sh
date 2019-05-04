#!/usr/bin/env bash

#USER DEFINED INPUTS
PROD_LOCATION="/etc/puppet/environments/production/modules/"
FOREMAN_USER="jenkins"
FOREMAN_IP="10.99.212.59"
JIRA_URL="10.99.212.42:8080"
JIRA_USER="build.cicd"
JIRA_PASS="Password123"

#FIXED VARIABLES
BRANCH=$(echo ${GIT_BRANCH} | cut -d/ -f2 )
JIRA_ID=$(echo  ${BRANCH} | cut -d- -f1,2 )

#Funcation to copy  data from feature branch selected to Foreman UAT environment.
function copy_to_production() {
    local RCHECK
    echo -e "\n********************************************************************************************************"
    echo -e "\n\t Commit Recieved on '${BRANCH}' branch,  Pushing Code to Production Envrionment"
    echo -e "\n********************************************************************************************************\n\n"

    # RSYNC FROM FOREMAN PERSONAL ENV TO UAT ENV.
    /usr/bin/rsync -e "ssh -o StrictHostKeyChecking=no" -rvh  --exclude '.git' ./  ${FOREMAN_USER}@${FOREMAN_IP}:${PROD_LOCATION}
    /usr/bin/curl --request POST -k  -H 'Content-Type:application/json' 'https://'${FOREMAN_IP}'//api/smart_proxies/1/import_puppetclasses' --user fjtest:Password123
    RCHECK=$(echo $?)
    if [[ ${RCHECK} -eq 0 ]];then
    echo -e "\n\tRSYNC COMPLETED \n"
    else
    	exit 1
    fi
    set -x
    # Adding JIRA Comment for the same.
    /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Merging Feature Branch : '${BRANCH}' with UAT environment. "} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment #> /dev/null 2>&1
    echo -e "\n**********************************************  UPDATING JIRA  *********************************************************\n\n"
	set +x
}

# Calling Main Function
copy_to_production
