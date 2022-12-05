#   ./script.sh <Env> <Version> <GrafanaURL> <Token>
#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'    
      
if [ $# -lt 4 ]
  then
    echo "Missing argument"
    exit 1
fi

Env=$1
Version=$2
Grafana_URL=$3
Token=$4     
exit_code=0


#GET /api/search?dashboard_uid=<uid>
#GET /api/dashboards/uid/<ui>
#curl -s --location --request GET 'http://localhost:3000/api/search' --header "Authorization: Bearer $4" | jq -r ' .[] | select(.type == "dash-db") | .uid'

printf "\n"

#Grabing all yaml files and store their relative path in array
mapfile -d $'\0' array < <(find ./deployment/$Env/ -type f -iname "*.yml" -or -iname "*.yaml" -print0)

#Filtering Yaml files. Keeping only Grafandashboard CRs
new_array=()

#create array of uids from deployment folder - deployment_files_uids
declare -A deployment_files_uids
for i in "${array[@]}"
do
   : 
    x=$(myenv="GrafanaDashboard" yq e ' select(.kind == env(myenv)) | .kind' $i)
    if [ "$x" = "GrafanaDashboard" ]; then
        # "$i" = filename 
        uid=$(yq -o=json eval $i | jq '.spec' | jq -r '.json' |  jq -r '.uid')
        uid=$(echo $uid)
        deployment_files_uids["$uid"]+="$i"
        new_array+=($i)
    fi
done



len1=${#new_array[*]};
echo "Found ${len1} Yaml files of kind GrafanaDashboard in the deployment folder ./deployment/$Env/ :"

#Printing the name of the Grafanadashboard CRs 
for i in "${new_array[@]}"
do
   : 
    printf "   ${GREEN} $i ${NC}\n"
done
printf "\n"

#Save the name of dashboards and version in an array
k8s_crs_names=$(kubectl get grafanadashboards -n monitoring -o jsonpath="{.items[*].metadata.name}")
k8s_crs_names_array=($(echo "$k8s_crs_names" | tr ' ' '\n'))

k8s_uids_array=()
k8s_ver_array=()
#Store uid and version from k8s in seperate arrays
for i in "${k8s_crs_names_array[@]}"
do
    :
    k8s_uids_array+=($(kubectl get grafanadashboard  $i -n monitoring  -o json | jq -r '.spec.json' | jq -r '.uid'))
    k8s_ver_array+=($(kubectl get grafanadashboard  $i -n monitoring  -o json | jq -r '.metadata.labels.version'))
done

#for KEY in "${!deployment_files_uids[@]}"; do
#  # Print the KEY value
#  echo "Key: $KEY"
#  # Print the VALUE attached to that KEY
#  echo "Value: ${deployment_files_uids[$KEY]}"
#done

grafana_uids=$(curl -s --location --request GET "http://$Grafana_URL/api/search" --header "Authorization: Bearer $Token" | jq -r ' .[] | select(.type == "dash-db") | .uid')
grafana_uid_array=($(echo "$grafana_uids" | tr ' ' '\n'))

#check kubernetes
printf "${PURPLE}\t\t******** kubernetes & Grafana CR check ********\n${NC}"
for cr_uid in "${!deployment_files_uids[@]}"; do
    match_bool_k8s=0
    for j in "${!k8s_uids_array[@]}"; do
        if [ "${k8s_uids_array[$j]}" == "$cr_uid" ] ; then  
        # If the above condition is evaluated to true when an UID match is found
        # The followong condition will check if there is a version match as well
            if [ "${k8s_ver_array[$j]}" == "$Version" ] ; then 
                printf "${BLUE}\ndashboard with UID: $cr_uid and version: $Version in kubernetes - filename:${deployment_files_uids[$cr_uid]} - found  \n${NC}"
                match_bool_k8s=1   
            fi
        fi
    done

    if [ $match_bool_k8s -eq "0" ] ; then 
            printf "${RED}\ndashboard with UID: $cr_uid and version: $Version in kubernetes - ${deployment_files_uids[$cr_uid]} - Not found  \n${NC}"
            exit_code=1
    fi

    #check_grafana
    match_bool_grafana=0
    for grafana_uid in "${grafana_uid_array[@]}" 
    do
        :
        if [ "$grafana_uid" == "$cr_uid" ] ; then
                printf "${BLUE}\n Dashboard with UID: $cr_uid and version: $Version in Grafana - filename: ${deployment_files_uids[$cr_uid]}- found\n${NC}"
                match_bool_grafana=1
        fi
    done
    if [ $match_bool_grafana -eq "0" ] ; then 
            printf "${RED}\n Dashboard with UID: $cr_uid and version: $Version in Grafana - filename:${deployment_files_uids[$cr_uid]} -not found ${NC}\n"
            exit_code=1
   fi
done

exit $exit_code
printf "\n"
