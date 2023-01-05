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
