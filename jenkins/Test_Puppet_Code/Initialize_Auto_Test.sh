#!/usr/bin/env bash

### Variables
FOREMAN_USER="jenkins"
FOREMAN_IP="10.99.212.59"
JIRA_URL="10.99.212.42:8080"
JIRA_USER="build.cicd"
JIRA_PASS="Password123"

### Derived variables
FIRST_NAME=$(git log --pretty='%cn' -n1  HEAD | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
LAST_NAME=$(git log --pretty='%cn' -n1  HEAD | awk '{print $2}' | tr '[:upper:]' '[:lower:]')
BRANCH=$(echo "${GIT_BRANCH}" | cut -d/ -f2 )
JIRA_ID=$(echo  "${BRANCH}" | cut -d- -f1,2 )

echo -e "\n********************************************************************************************************"
echo "FIRST_NAME : ${FIRST_NAME} "
echo "LAST_NAME : ${LAST_NAME}"
echo "BRANCH : ${BRANCH}"
echo "JIRA_ID : ${JIRA_ID} "
echo -e "*********************************************************************************************************\n"

function jiraNewCommit() {
echo  -e "\n*********************************************************************************************************\n"
    echo   "JIRA TICKET UPDATE FOR ${JIRA_ID}"
    curl -D- -u "${JIRA_USER}":"${JIRA_PASS}" -X POST --data '{"body": "New commit found  on branch  '${BRANCH}' from user '${FIRST_NAME}' '${LAST_NAME}' "}' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
echo  -e "\n*********************************************************************************************************\n"
}


function copyforeman() {
	local FCHECK
    /usr/bin/rsync  -e "ssh -o StrictHostKeyChecking=no " -rvh --exclude '.git'  --exclude '*/.kitchen'  --delete  --exclude '.librarian/'  ./ ${FOREMAN_USER}@${FOREMAN_IP}:/etc/puppet/environments/${FIRST_NAME}_${LAST_NAME}/modules/
    /usr/bin/curl --request POST -k  -H 'Content-Type:application/json' 'https://'${FOREMAN_IP}'//api/smart_proxies/1/import_puppetclasses' --user fjtest:Password123

    FCHECK=$(echo $?)
    echo ${FCHECK}
    if [[ ${FCHECK} -eq 0 ]] ; then
            echo -e "\n\t RSYNC COMPLETED \n"
            /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Build Success, Copying to Foreman Personal Env. "} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
    else
        echo "NO RSYNC TRIGGERED"
            /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Build Failure while RSYNC, aborting "} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
            exit 1
    fi
}

function jiraUpdate() {
echo  -e "\n*********************************************************************************************************\n"
if  grep "^0" /tmp/kvalidation.txt && grep "^0" /tmp/pvalidation.txt
    then
                echo "Calling copyforeman"
                copyforeman
                echo -e "\n\n\t  $(cat /tmp/module_stat.txt)"
                echo -e "\n\n\t  $(cat /tmp/kitchen_stat.txt)"
                #curl -D- -u "${JIRA_USER}":"${JIRA_PASS}" -X POST --data '{"body": "Build Passed  : '${BRANCH}'  "}' -H "Content-Type: application/json"  http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
    else
                echo "No copyforeman called ."
                echo -e "\n*********************************************************************************************************"
                echo -e "\n\n\t $(cat /tmp/module_stat.txt)"
                echo -e "\n\n\t $(cat /tmp/kitchen_stat.txt)"
                echo -e "\n*********************************************************************************************************\n\n"
                curl -D- -u "${JIRA_USER}":"${JIRA_PASS}" -X POST --data '{"body": "Build failed  : '${BRANCH}'  "}' -H "Content-Type: application/json"  http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
fi
rm  -f /tmp/pvalidation /tmp/kvalidation /tmp/module_stat.txt /tmp/kitchen_stat.txt > /dev/null
echo  -e "\n*********************************************************************************************************\n"
}

function  kitchenTrigger() {
    local RBCHECK
    local KCHECK
    file test/integration/default/serverspec/*_spec.rb > /dev/null
    RBCHECK=$(echo $?)
    if  [[  ${RBCHECK} -eq 0  ]] ; then
            # Kitchen Execution
            echo -e "\n************************************** STARTING KITCHEN TESTING ****************************************\n"
            echo -e "\t Puppet Serverspec is present, executing  puppet modules  on Docker Containers for module : ${MODULE}  "
           # bundle install
            echo -e "\n*********************************************************************************************************\n\n"
            kitchen destroy > /dev/null 2>&1
            kitchen create && kitchen list
            echo -e "\n*********************************************************************************************************\n\n"
            kitchen test
            KCHECK=$(echo $?)
                if [[ ${KCHECK} -eq 0  ]]; then
                    echo -e "\n\t ${MODULE} Kitchen Test : PASSED" >> /tmp/kitchen_stat.txt
                    /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Serverspec tests passed."} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
                    echo    ${KCHECK} >  /tmp/kvalidation.txt
                else
                    echo -e "\n\t ${MODULE} Kitchen Test : FAILED" >> /tmp/kitchen_stat.txt
                    /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Serverspec tests failed."} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
                    echo ${KCHECK} > /tmp/kvalidation.txt
                fi
            echo -e "\n*********************************************************************************************************\n\n"
    else
            echo -e "\n*********************************************************************************************************\n\n"
            echo -e "\tServerspec is NOT present, therefore moving out from module ${MODULE} "
            echo -e "\n*********************************************************************************************************\n\n"
    fi
}

function puppetParser()  {
local CHECK
#SYNTAX Checking
echo -e "\n*********************************************************************************************************\n"
echo -e "\tPUPPET PARSER VALIDATION OUTPUT FOR MODULE :  ${MODULE} \n"
find . -type f -iname "*.pp" | xargs puppet parser validate
CHECK=$(echo $?)
if [[   ${CHECK} -eq 0  ]];  then
     echo -e "\n\tPuppet Parser Validation Test PASSED for ${MODULE}" | tee -a  /tmp/module_stat.txt
     echo -e "\n*********************************************************************************************************\n\n"
     /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Puppet parser validate passed."} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
     echo "${CHECK}"  > /tmp/pvalidation.txt
     kitchenTrigger
else
    echo  -e  "\n\n Puppet Parser Validation Test FAILED" | tee -a  /tmp/module_stat.txt
    /usr/bin/curl -D- -u ${JIRA_USER}:${JIRA_PASS} -X POST --data '{"body": "Puppet parser validate failed."} ' -H "Content-Type: application/json" http://${JIRA_URL}/rest/api/2/issue/${JIRA_ID}/comment > /dev/null 2>&1
    echo "${CHECK}"  >  /tmp/pvalidation.txt
fi
echo -e "\n*********************************************************************************************************\n\n"
}


function main() {
local  SHA
SHA=$(/usr/bin/git log | head  -1 | awk '{print $2}')
COUNT=0
#Checking for the updated modules in the cloned  branch
    for  MODULE in $(/usr/bin/git diff-tree --name-only --no-commit-id "${SHA}")
        do
            if [[   -d ${MODULE}  ]] ; then
                echo "${MODULE}"
                export MODULE
                    if [[   ${COUNT} -eq 0  ]] ; then
                            COUNT=1
                            jiraNewCommit                       # Updating JIRA
                    fi
                cd ${MODULE} && puppetParser                                    # Calling the Puppet Parser for module Checking
                cd ..
            else
                 echo -e "\n*********************************************************************************************************\n"
             	echo "\n \t No Changes found or The change didn't occured in  module strucuture."
                 echo -e "\n*********************************************************************************************************\n\n"
            fi
        done

if [[ ${COUNT} -eq 1 ]] ; then
jiraUpdate
fi

}

# Calling the main function
main
