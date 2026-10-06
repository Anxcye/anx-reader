#!/bin/bash

# Add
# g_signal_connect(view, \"key_press_event\", G_CALLBACK(processKeyEventForCEF), nullptr);
# after
# FlView* view = fl_view_new(project);
# if not already added

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

# Check if the line g_signal_connect exists in the file
if grep -q '^[[:space:]]*g_signal_connect(view, "key_press_event", G_CALLBACK(processKeyEventForCEF), nullptr);' "$file"; then
  echo "The line 'g_signal_connect(view, \"key_press_event\", G_CALLBACK(processKeyEventForCEF), nullptr);' already exists in the file."
else
  # Insert g_signal_connect after the first occurrence of FlView* view = fl_view_new(project);
  awk '
    /^[[:space:]]*FlView\* view = fl_view_new\(project\);/ {
      print $0;
      print "  g_signal_connect(view, \"key_press_event\", G_CALLBACK(processKeyEventForCEF), nullptr);";
      next;
    }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  echo "Added 'g_signal_connect(view, \"key_press_event\", G_CALLBACK(processKeyEventForCEF), nullptr);' after 'FlView* view = fl_view_new(project);'."
fi
