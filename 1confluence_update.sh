#!/bin/bash
set -euo pipefail

Username=$1
Password=$2
Confluence_URL=$3
Page_ID=$4
HTML_report_file=$5

HTML=$(<$HTML_report_file)
HTML=$(cat $HTML_report_file | tr -d '\r\n')

HTML=${HTML//\\/\\\\} # \ 
HTML=${HTML//\//\\\/} # / 
HTML=${HTML//\'/\\\'} # ' (not strictly needed ?)
HTML=${HTML//\"/\\\"} # " 
HTML=${HTML//   /\\t} # \t (tab)
HTML=${HTML//
/\\\n} # \n (newline)
HTML=${HTML//^M/\\\r} # \r (carriage return)
HTML=${HTML//^L/\\\f} # \f (form feed)
HTML=${HTML//^H/\\\b} # \b (backspace)
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
      "value": "$HTML" ,
      "representation": "storage"
    }
  },
  "version": {
    "number": $current_version
  }
}
EOF
}
