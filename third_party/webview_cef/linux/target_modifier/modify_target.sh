#!/bin/bash

# Will be something like /home/test/flutter_projects/example
program_path="${PWD%%/build/linux/*}"

# Will be the path of this script
scriptdir=$(cd $(dirname $0); pwd -P)

echo "Modifying target cc files..."

bash $scriptdir/tools/import_webview_cef_header_my_application.sh "$program_path/linux/my_application.cc"
bash $scriptdir/tools/add_key_release_event_to_my_application.sh "$program_path/linux/my_application.cc"
bash $scriptdir/tools/add_key_press_event_to_my_application.sh "$program_path/linux/my_application.cc"

bash $scriptdir/tools/import_webview_cef_header_main.sh "$program_path/linux/main.cc"
bash $scriptdir/tools/add_webview_init_to_main.sh "$program_path/linux/main.cc"
