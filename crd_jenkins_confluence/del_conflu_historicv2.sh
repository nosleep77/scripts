#!/bin/bash

# Set the page ID of the Confluence page
PAGE_ID=1234

# Get the number of historical versions of the page
VERSION_COUNT=$(curl -s -u username:password -X GET "https://your-confluence-url/rest/api/content/$PAGE_ID/version" | jq '.results | length')

# Check if the number of historical versions is greater than 3
if [ $VERSION_COUNT -gt 3 ]; then
  # Subtract 3 from the number of versions to get the number of versions to delete
  VERSIONS_TO_DELETE=$((VERSION_COUNT - 3))

  # Get the IDs of the versions to delete
  VERSION_IDS=$(curl -s -u username:password -X GET "https://your-confluence-url/rest/api/content/$PAGE_ID/version" | jq -r '.results[:'"$VERSIONS_TO_DELETE"'].id')

  # Loop through the version IDs and delete each version
  for VERSION_ID in $VERSION_IDS; do
    curl -u username:password -X DELETE "https://your-confluence-url/rest/api/content/$PAGE_ID/version/$VERSION_ID"
  done
fi



curl -s -u username:password -X GET "https://your-confluence-url/rest/api/content/$PAGE_ID/version" | jq .

VERSION_IDS=$(curl -s -u username:password -X GET "https://your-confluence-url/rest/api/content/$PAGE_ID/version" | jq -r '.results[:'"$VERSIONS_TO_DELETE"'].PROPERTY_NAME_YOU_FOUND')
