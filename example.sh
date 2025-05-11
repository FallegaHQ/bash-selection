#!/bin/bash

source ./menu.sh
declare result_single result_multi
# For single selection:
clear
echo "Single selection example"
echo "Press enter..."
read
selection_menu result_single "single" "Option 1" "Option 2" "Option 3"

# For multiple selection:
clear
echo "Multiple selection example"
echo "Press enter..."
read
selection_menu result_multi "multiple" "Option 1" "Option 2" "Option 3"

# The results
clear
echo "Multiple selection: ${result_multi[*]}"
echo "Single selection: $result_single"
echo "Press enter..."
read
clear