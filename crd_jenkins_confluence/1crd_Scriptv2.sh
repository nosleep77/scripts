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
Namespace=$5 
exit_code=0

echo "<html><head>
<title>GrafanaDashboard check</title></head><body>"  > report.html
echo "<h1 style=\"text-align:center;color:blue;font-size:160%;\">GrafanaDashboard CR check </h1><p></p>" >> report.html
echo "<table>
      <tr>
    <th>Dashboard uid</th>
                <th>Crd file</th>
                <th>version</th>
                <th>Found in K8s</th>
                <th>Version Found in k8s</th>
                <th>Found in Grafana</th>
    </tr>" >> report.html

#   ./script.sh <Env> <Version> <GrafanaURL> <Token>

#GET /api/search?dashboard_uid=<uid>
#GET /api/dashboards/uid/<ui>
#curl -s --location --request GET 'http://localhost:3000/api/search' --header "Authorization: Bearer $4" | jq -r ' .[] | select(.type == "dash-db") | .uid'

printf "\n"

# if [ "$Env" == "prod" ]; then 
#     Grafana_URL="prod.grafana.url"
# elif [ "$Env" == "dev" ]; then
#         Grafana_URL="dev.grafana.url"
# else
#         echo "env not found"
#         exit 1 
#     fi
echo $Grafana_URL
#Grabing all yaml files and store their relative path in array
array=()

all_yaml_files=$(find ./deployment/$Env/dashboards/  -type f -iname "*.yml" -or -iname "*.yaml" -print0 | tr  '\0' ' ')
array=(`echo ${all_yaml_files}`)


#mapfile -d $'\0' array < <(find ./deployment/$Env/dashboards/  -type f -iname "*.yml" -or -iname "*.yaml" -print0)

#Filtering Yaml files. Keeping only Grafandashboard CRs
deployment_files_path=()

declare -A deployment_files_uids
declare -A deployment_files_vers

for i in "${array[@]}"
do
   : 
    x=$(myenv="GrafanaDashboard" yq e ' select(.kind == env(myenv)) | .kind' $i)
    if [ "$x" = "GrafanaDashboard" ]; then
        # "$i" = filename 
        uid=$(yq -o=json eval $i | jq '.spec' | jq -r '.json' |  jq -r '.uid')
        ver=$(yq -o=json eval $i | jq '.metadata.labels.version')
        deployment_files_vers["$uid"]+="$ver"
        deployment_files_uids["$uid"]+="$i"
        deployment_files_path+=($i)
    fi
done
for i in "${!deployment_files_vers[@]}"
do
echo "${i}=${deployment_files_vers[$i]}"
done

len1=${#deployment_files_path[*]};
echo "Found ${len1} Yaml files of kind GrafanaDashboard in the deployment folder ./deployment/$Env/dashboards :"
#Printing the name of the Grafanadashboard CRs 
for i in "${deployment_files_path[@]}"
do
   : 
    printf "   ${GREEN} $i ${NC}\n"
done
printf "\n"

#k8s_crs_names=$(kubectl get grafanadashboards -o jsonpath="{.items[*].metadata.name}")
#k8s_crs_names_array=($(echo "$k8s_crs_names" | tr ' ' '\n'))

k8s_uids_array=()
k8s_ver_array=()

#Store uid and version
#from k8s in seperate arrays

#for i in "${k8s_crs_names_array[@]}"
#do
    :
    #k8s_uids_array+=($(kubectl get grafanadashboard  $i -o json | jq -r '.spec.json' | jq -r '.uid'))
    #k8s_ver_array+=($(kubectl get grafanadashboard  $i  -o json | jq -r '.metadata.labels.version'))
#done
###
kubectl_json_output=$(kubectl get grafanadashboards -o json -n ${Namespace})
#readarray -t k8s_ver_array < <( echo $kubectl_json_output | jq -r '.items[].metadata.labels.version')
#readarray -t k8s_uids_array < <( echo $kubectl_json_output  | jq -r '.items[].spec.json' | jq -r '.uid')
###

k8s_vers_string=$(echo $kubectl_json_output   | jq -r '.items[].metadata.labels.version')
k8s_uids_string=$(echo $kubectl_json_output   | jq -r '.items[].spec.json' |  jq -r '.uid' )

#k8s_uids_string=$(kubectl get grafanadashboards -n monitoring -o jsonpath="{.items[*].spec.json}" -n monitoring | jq '.uid')
k8s_uids_array=(`echo ${k8s_uids_string}`)
k8s_ver_array=(`echo ${k8s_vers_string}`)

echo 'k8s_ver_array'

echo $k8s_uids_string

echo "${k8s_uids_array[*]}"

#k8s_uids

#readarray -t k8s_ver_array < <( kubectl get grafanadashboards -o json | jq -r '.items[].metadata.labels.version')
#readarray -t k8s_uids_array < <( kubectl get grafanadashboards -o json  | jq -r '.items[].spec.json' | jq -r '.uid')

#Checking k8s
grafana_uids=$(curl -s --location --request GET "http://$Grafana_URL/api/search" --header "Authorization: Bearer $Token" | jq -r ' .[] | select(.type == "dash-db") | .uid')
grafana_uid_array=($(echo "$grafana_uids" | tr ' ' '\n'))

GrafanaColumn=" "

 
printf "${PURPLE}\t\t******** Grafana CR check ********\n${NC}"
for cr_uid in "${!deployment_files_uids[@]}"; do

    #check_grafana
    match_bool_grafana=0
    for grafana_uid in "${grafana_uid_array[@]}" 
    do
        :
        if [ "$grafana_uid" == "$cr_uid" ] ; then
                printf "${BLUE}\n Dashboard with UID: $cr_uid and version: $Version in Grafana - filename: ${deployment_files_uids[$cr_uid]}- found\n${NC}"
                GrafanaColumn+=$(echo " True ")
                match_bool_grafana=1
        fi
    done
    if [ $match_bool_grafana -eq "0" ] ; then 
            printf "${RED}\n Dashboard with UID: $cr_uid and version: $Version in Grafana - filename:${deployment_files_uids[$cr_uid]} -not found ${NC}\n"
            GrafanaColumn+=$(echo " False ")
            #echo "<tr> <td>False</td> </tr>" >> report.html
            exit_code=1
   fi
done
echo $GrafanaColumn
GrafanaColumnArray=(`echo ${GrafanaColumn}`)

 
iter=0
printf "${PURPLE}\t\t******** kubernetes CR check ********\n${NC}"
for cr_uid in "${!deployment_files_uids[@]}"; do
    match_bool_uid=0
    match_bool_version=0
    for j in "${!k8s_uids_array[@]}"; do
        if [ "${k8s_uids_array[$j]}" == "$cr_uid" ] ; then  
        match_bool_uid=1
        # If the above condition is evaluated to true when an UID match is found
        # The followong condition will check if there is a version match as well
            if [ "${k8s_ver_array[$j]}" == "$Version" ] ; then 
                printf "${BLUE}\ndashboard with UID: $cr_uid and version: $Version in kubernetes - filename:${deployment_files_uids[$cr_uid]} - found  \n${NC}"
                echo "<tr>
                <td>$cr_uid</td>
                <td>${deployment_files_uids[$cr_uid]}</td>
                <td>${deployment_files_vers[$cr_uid]} </td>
                <td style=\"color:blue;\"> True </td>
                <td style=\"color:blue;\"> True</td>" >> report.html
                if [ "${GrafanaColumnArray[$iter]}" == "False" ] ; then 
                    echo " <td style=\"color:red;\">${GrafanaColumnArray[$iter]}</td> " >> report.html
                else
                    echo " <td style=\"color:blue;\">${GrafanaColumnArray[$iter]}</td> " >> report.html
                fi
                echo "</tr> " >> report.html
                match_bool_version=1
                break;
            fi
        
        fi
    done

    if [ $match_bool_uid -eq "1"  ] && [ $match_bool_version -eq "0" ]; then 
            printf "${RED}\ndashboard with UID: $cr_uid and version: $Version in kubernetes - ${deployment_files_uids[$cr_uid]} - Not found  \n${NC}"
            echo "mismatch"
            echo "<tr>
                <td> $cr_uid</td>
                <td> ${deployment_files_uids[$cr_uid]} </td>
                <td> ${deployment_files_vers[$cr_uid]} </td>
                <td style=\"color:blue;\"> True </td>
                <td style=\"color:red;\"> False </td>" >> report.html
                if [ "${GrafanaColumnArray[$iter]}" == "False" ] ; then 
                    echo " <td style=\"color:red;\">${GrafanaColumnArray[$iter]}</td> " >> report.html
                else
                    echo " <td style=\"color:blue;\">${GrafanaColumnArray[$iter]}</td> " >> report.html
                fi
                echo "</tr> " >> report.html

            exit_code=1
    fi

    if [ $match_bool_uid -eq "0" ] && [ $match_bool_version -eq "0" ]; then 
            printf "${RED}\ndashboard with UID: $cr_uid and version: $Version in kubernetes - ${deployment_files_uids[$cr_uid]} - Not found  \n${NC}"
            echo "<tr>
                <td>$cr_uid</td>
                <td>${deployment_files_uids[$cr_uid]}</td>
                <td>${deployment_files_vers[$cr_uid]} </td>
                <td style=\"color:red;\"> False </td>
                <td style=\"color:red;\"> False </td>" >> report.html
                if [ "${GrafanaColumnArray[$iter]}" == "False" ] ; then 
                    echo " <td style=\"color:red;\">${GrafanaColumnArray[$iter]}</td> " >> report.html
                fi
                if [ "${GrafanaColumnArray[$iter]}" == "True" ] ; then 
                    echo " <td style=\"color:blue;\">${GrafanaColumnArray[$iter]}</td> " >> report.html
                fi
                echo "</tr> " >> report.html

            exit_code=1
    fi
    iter=$((iter+1))

done
echo "</table> </body></html>" >> report.html
exit $exit_code
