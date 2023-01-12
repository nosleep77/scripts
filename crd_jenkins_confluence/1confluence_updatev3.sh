#!/bin/bash
set -euo pipefail

Username=$1
Password=$2
Confluence_URL=$3
Page_ID=$4
HTML_report_file=$5

HTML=$(<$HTML_report_file)
HTML=$(echo $HTML | tr -d '\r\n')
HTML=$(echo "$HTML" | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e "s/'/\\\'/g" -e 's/"/\\"/g' -e 's/ /\\t/g' -e 's//\\n/g')


#oldcontent=$(curl  -u  -u "$Username:$Password" -X GET "https://$Confluence_URL/wiki/rest/api/content/$Page_ID?expand=body.storage" | jq | grep value | sed 's/\"/\\"/g')
current_version=$(curl  -s -u "$Username:$Password" -X GET "https://$Confluence_URL/wiki/rest/api/content/$Page_ID" | jq .version.number)
echo $current_version
current_version=$((current_version+1))
generate_put_data()
{
  cat <<EOF
{
  "id": "$Page_ID",
  "type": "page",
  "title": "Brainstorming",
  "space": {
    "key": "TEST"
  },
  "body": {
    "storage": {
      "value": "10/01/2023 22:57PM $HTML" ,
      "representation": "storage"
    }
  },
  "version": {
    "number": $current_version
  }
}
EOF
}
curl -i -u "$Username:$Password" -X PUT -H "Content-Type: application/json"  -H "Accept: application/json"  --data "$(generate_put_data)" "https://$Confluence_URL/wiki/rest/api/content/$Page_ID"
