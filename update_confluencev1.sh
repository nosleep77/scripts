#!/bin/bash

# Set the URL of the Confluence page that you want to update
page_url='PAGE_URL'

# Set the name of the file that contains the output of your script
output_file='output.txt'

# Run the script that you want to get the output from
./your_script.sh > $output_file

# Get the current version of the Confluence page
page_json=$(curl -s -u USERNAME:PASSWORD -X GET -H 'Content-Type: application/json' $page_url)

# Extract the ID and version number of the page from the JSON response
page_id=$(echo $page_json | jq -r .id)
page_version=$(echo $page_json | jq -r .version.number)

# Update the Confluence page with the contents of the output file
curl -u USERNAME:PASSWORD -X PUT -H 'Content-Type: application/json' -d '{"id":"'$page_id'","type":"page","title":"My Page","version":{"number":'$page_version'},"body":{"storage":{"value":"'$(cat $output_file)'","representation":"storage"}}}' $page_url
