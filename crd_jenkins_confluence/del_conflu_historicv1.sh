

#!/bin/bash

# Set the Confluence URL and page ID
CONFLUENCE_URL="https://confluence.example.com"
PAGE_ID="12345"

# Get the list of historical versions of the page
VERSIONS=$(curl -s -u username:password -X GET "$CONFLUENCE_URL/rest/api/content/$PAGE_ID/version" | jq -r '.results[].number')

# Get the most recent version of the page
LATEST_VERSION=$(curl -s -u username:password -X GET "$CONFLUENCE_URL/rest/api/content/$PAGE_ID" | jq -r '.version.number')

# Iterate through the list of historical versions and delete them
for version in $VERSIONS; do
    if [ $version -ne $LATEST_VERSION ]; then
        curl -u username:password -X DELETE "$CONFLUENCE_URL/rest/api/content/$PAGE_ID/version/$version"
    fi
done
