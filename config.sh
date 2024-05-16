#!/bin/bash

temp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT

# Convert the multi-line environment variable to a YAML file format
echo "$CONFIG" > "$temp_dir"/config_replace.yaml

# Iterate over each entry in the YAML array
yq -e '.' "$temp_dir"/config_replace.yaml | jq -c '.[]' | while read -r item; do
  file=$(echo "$item" | jq -r '.file')
  replacements=$(echo "$item" | jq -r '.replacements')

  # Ensure the file exists
  if [ -f "$file" ]; then
    echo "Config injection: $file"
    # Iterate over each replacement for the file
    echo "$replacements" | yq -r '.[]' - | while read -r replacement; do
      # Extract the key part of the replacement to check for existence
      key=$(echo "$replacement" | cut -d'=' -f1 | xargs)

      # Check if the key exists in the JSON file (does not support explicit null value)
      if jq -e "has(\"$key\")" "$file" > /dev/null; then
        # Apply the jq replacement
        jq "$replacement" "$file" > "$temp_dir/tmp.json" && mv "$temp_dir/tmp.json" "$file"
        echo "Replacing: $replacement"
      else
        echo "Error: $key does not exist in $file"
        exit 1
      fi
    done
  else
    echo "Error: $file does not exist."
    exit 1
  fi
done
