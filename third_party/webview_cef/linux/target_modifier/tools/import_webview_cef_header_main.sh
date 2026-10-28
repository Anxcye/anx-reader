#!/bin/bash

# Adds '#include <webview_cef/webview_cef_plugin.h>' at the top of the file

# Check if the correct number of arguments is passed
if [ $# -ne 1 ]; then
  echo "Usage: $0 <file-path>"
  exit 1
fi

# Assign file path argument
file="$1"

# Check if the file exists
if [ ! -f "$file" ]; then
  echo "File not found: $file"
  exit 1
fi

# Check if the line already exists in the file
if grep -q '#include <webview_cef/webview_cef_plugin.h>' "$file"; then
  echo "The line '#include <webview_cef/webview_cef_plugin.h>' already exists in the file."
else
  # Add the line at the top of the file
  (echo "#include <webview_cef/webview_cef_plugin.h>"; cat "$file") > "$file.tmp" && mv "$file.tmp" "$file"
  echo "Added '#include <webview_cef/webview_cef_plugin.h>' at the top of the file."
fi
