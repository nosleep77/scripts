#!/bin/bash

# Set the base URL for the Confluence instance
base_url="https://confluence.example.com"

# Set the URL for the Confluence page
page_url="$base_url/display/SPACE/Page+Title"

# Retrieve the page HTML and search for the page ID and version
page_html=$(curl -s "$page_url")
page_id=$(echo "$page_html" | grep -oP '(?<=data-id=")[^"]*')
page_version=$(echo "$page_html" | grep -oP '(?<=data-version=")[^"]*')

# Print the page ID and version
echo "Page ID: $page_id"
echo "Page version: $page_version"



curl -u username:password -X POST -H "Content-Type: text/html" --data-binary @file.html "https://your-confluence-site.com/rest/api/content/"












#!/bin/bash

# Set the login credentials and page ID
USERNAME='username'
PASSWORD='password'
PAGE_ID='page-id'

# Set the URL of the Confluence site
CONFLUENCE_URL='https://your-confluence-site.com/'

# Read the HTML file into a variable
HTML=$(<file.html)

# Encode the HTML content as a URL parameter
HTML_ENCODED=$(printf "%s" "$HTML" | jq -R -s -r @uri)

# Set the JSON payload for the update request
JSON='{"id":"'$PAGE_ID'","type":"page","title":"Page Title","space":{"key":"SPACEKEY"},"body":{"storage":{"value":"'$HTML_ENCODED'","representation":"storage"}}}'

# Send the update request to the Confluence REST API
curl -u "$USERNAME:$PASSWORD" -X PUT -H "Content-Type: application/json" -d "$JSON" "$CONFLUENCE_URL/rest/api/content/$PAGE_ID"


