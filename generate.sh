#!/bin/sh

# Enable error handling to stop the script on any error
set -e

# Function to display help
display_help() {
    echo "Usage: $0 filename (without .md extension)" >&2
    exit 1
}

# Check if a parameter is provided
if [ -z "$1" ]; then
    filename=`find . -name 'draft-*.md' | sed 's/.md$//' | tr -d './'`
    echo "warning: using default filename: $filename" >&2
else
    filename="$1"
fi

# Check if the .adoc file exists
if [ ! -f "$filename.md" ]; then
    echo "Error: File $filename.md not found." >&2
    display_help
fi

cd ./docs

# https://github.com/cabo/kramdown-rfc
kramdown-rfc ../$filename.md > $filename.xml

# Generate text, html, and pdf versions
xml2rfc --text --html --pdf "$filename.xml"

# Generate a clean text version
xml2rfc --text --no-pagination -o "$filename.clean.txt" "$filename.xml"


# Replace instances in index.html
#docname=`echo $filename | sed 's/-[0-9][0-9]$//'`
#sed -i "s/$docname-[0-9]\{2\}/$filename/g" index.html
