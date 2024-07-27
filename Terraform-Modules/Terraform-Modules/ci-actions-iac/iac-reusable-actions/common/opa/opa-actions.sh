#!/bin/bash

# Define colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

# Run the commands and store output
crit=$(opa eval -b $GITHUB_ACTION_PATH/policy/ -i $1 "data.tfanalysis.critical" --format=pretty)
warn=$(opa eval -b $GITHUB_ACTION_PATH/policy/ -i $1 "data.tfanalysis.warning" --format=pretty)

# Run the commands and store JSON output for Datadog processing
crit_json=$(opa eval -b $GITHUB_ACTION_PATH/policy/ -i $1 "data.tfanalysis.critical" --format=json)
warn_json=$(opa eval -b $GITHUB_ACTION_PATH/policy/ -i $1 "data.tfanalysis.warning" --format=json)
combined_output=$(jq -n --argjson crit_json "$crit_json" --argjson warn_json "$warn_json" '{critical: $crit_json, warning: $warn_json}')

# Print the new JSON object
echo "$combined_output" > opa_results.json

# Echo output with color. Multi-line output possible, so
# use a while loop to color each line
echo -e "${RED}Critical Errors:${NO_COLOR}"
while IFS= read -r line
do
   echo -e "${RED}${line}${NO_COLOR}"
done <<< "$crit"

if [ -n "$crit" ]; then
  echo "write to env for PR comment"
  echo "opa_errors<<EOF" >> $GITHUB_ENV
  echo -e "$crit" >> $GITHUB_ENV
  echo "EOF" >> $GITHUB_ENV
fi
 

echo -e "${YELLOW}Warning Errors:${NO_COLOR}"
while IFS= read -r line
do
   echo -e "${YELLOW}${line}${NO_COLOR}"
done <<< "$warn"

# Run the evaluation command with failure flag
if [ "$2" = "true" ]; then
  echo -e "Evaluation Result:"
  set +e
  opa eval -b $GITHUB_ACTION_PATH/policy/ -i $1 "data.tfanalysis.evaluate" --format=json --fail
  exit_code=$?
  set -e
  echo $exit_code
  echo "opa_exit_code=$exit_code" >> "$GITHUB_ENV"
else
  echo "Soft Failure selected"
  echo -e "Evaluation Result:"
  opa eval -b $GITHUB_ACTION_PATH/policy/ -i $1 "data.tfanalysis.evaluate" --format=json
fi

