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

















#!/bin/bash

# Set the login credentials and page ID
USERNAME='username'
PASSWORD='password'
PAGE_ID='page-id'

# Set the URL of the Confluence site
CONFLUENCE_URL='https://your-confluence-site.com/'

# Read the HTML file into a variable
HTML=$(<file.html)

# Set the JSON payload for the update request
JSON='{"id":"'$PAGE_ID'","type":"page","title":"Page Title","space":{"key":"SPACEKEY"},"body":{"storage":{"value":"'$HTML'","representation":"storage"}}}'

# Send the update request to the Confluence REST API
RESPONSE=$(curl -u "$USERNAME:$PASSWORD" -X PUT -H "Content-Type: application/json" -d "$JSON" "$CONFLUENCE_URL/rest/api/content/$PAGE_ID")

# Check the response for errors
ERROR=$(echo "$RESPONSE" | jq -r .status.message)
if [ "$ERROR" != "null" ]; then
  echo "Error: $ERROR"
  exit 1
fi

# Parse the response to get the new content ID
CONTENT_ID=$(echo "$RESPONSE" | jq -r .id)

# Get the updated content from Confluence
UPDATED_CONTENT=$(curl -u "$USERNAME:$PASSWORD" "$CONFLUENCE_URL/rest/api/content/$CONTENT_ID?expand=body.storage")

# Decode the HTML content
DECODED_HTML=$(echo "$UPDATED_CONTENT" | jq -r .body.storage.value | sed 's/%/\\x/g')

# Set the JSON payload for the update request
JSON='{"id":"'$CONTENT_ID'","type":"page","title":"Page Title","space":{"key":"SPACEKEY"},"body":{"storage":{"value":"'$DECODED_HTML'","representation":"storage"}}}'

# Send the update request to the Confluence REST API
curl -u "$USERNAME:$PASSWORD" -X PUT -H "Content-Type: application/json" -d "$JSON" "$CONFLUENCE_URL/rest/api/content/$CONTENT_ID"




















#!/bin/bash

# Set the base URL for the Confluence REST API
CONFLUENCE_API_BASE_URL='https://your-confluence-instance.com/rest/api'

# Set your Confluence credentials
USERNAME='your-username'
PASSWORD='your-password'

# Set the ID of the page you want to update
PAGE_ID='12345'

# Set the path to the text file
TEXT_FILE_PATH='/path/to/your/text/file.txt'

# Read the contents of the text file into a variable
PAGE_CONTENTS=$(<"$TEXT_FILE_PATH")

# Escape special characters in the text file contents
PAGE_CONTENTS=$(echo "$PAGE_CONTENTS" | sed 's/\n/\\n/g' | sed 's/\t/\\t/g' | sed 's/"/\\"/g')

# Use curl to send a PUT request to the Confluence REST API to update the page
curl -u "$USERNAME:$PASSWORD" -X PUT -H 'Content-Type: application/json' -d "{\"id\":\"$PAGE_ID\",\"type\":\"page\",\"title\":\"My Page\",\"body\":{\"storage\":{\"value\":\"$PAGE_CONTENTS\",\"representation\":\"storage\"}}}" "$CONFLUENCE_API_BASE_URL/content/$PAGE_ID"
