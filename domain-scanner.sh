#!/bin/bash

# Base directory for scanning
BASE_DIR="."

# Resulting JSON file
OUTPUT_FILE="./domains.json"

# Temporary file for writing data
TEMP_FILE=$(mktemp)

# Array to store domains
domains=()

# Folder counters
total_dirs=0
processed_dirs=0

# Function to count the total number of directories for progress tracking
countDirs() {
    find "$1" -maxdepth 4 -type d | wc -l
}

# Function to display a progress bar
progressBar() {
    local screen_column=110
    local progress=$(( ($1 * 100 / $2 * 100) / 100 ))
    local done=$(( ($progress * 4) / 10 ))
    local left=$(( 40 - $done ))

    # Build progressbar string lengths
    local fill=$(printf "%${done}s")
    local empty=$(printf "%${left}s")
    local clear=$(printf "%${screen_column}s")

    printf "\r${clear// / }"
    local substring="\r[${fill// /#}${empty// /-}] ${progress}%% ${3}"
    substring="${substring:0:${screen_column}} "
    printf "\r${substring}"
}

# Function to process .noautodomain file
processNoautodomainFile() {
    local domain=$1
    local noautodomain_file=$2
    local current_dir=$3
    local full_domain=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        IFS='=' read -r subdomain folder <<< "$line"
        subdomain=$(echo "$subdomain" | tr -cd 'a-zA-Z0-9-_') # Removing unwanted characters
        folder=$(echo "$folder" | tr -cd 'a-zA-Z0-9-_/.')     # Removing unwanted characters

        if [[ -n "$subdomain" && -n "$folder" ]]; then
            if [[ "$subdomain" == "www" ]]; then
                full_domain="$domain"
            else
                full_domain="$subdomain.$domain"
            fi

            # Save the domain and path to JSON
            local real_dir=$(realpath "$current_dir/$folder")
            domains+=("\"$full_domain\": \"$real_dir\"")
        fi
    done < "$noautodomain_file"
}

# Recursive function to scan domains
scanDomain() {
    local current_dir=$1
    local domain=$2

    for dir in "$current_dir"/*/; do
        dir=${dir%/} # Removing trailing slash
        local folder_name=$(basename "$dir")
        local full_domain=""

        if [[ "$folder_name" == "www" ]]; then
            # If there are no subdomains, it is the main domain.
            full_domain="$domain"
        else
            # If there are subdomains, we form a full subdomain
            full_domain="$folder_name.$domain"
        fi

        if [[ ! -f "$dir/.noautodomain" ]]; then
            # Save the domain and path for JSON
            local real_dir=$(realpath "$dir")
            domains+=("\"$full_domain\": \"$real_dir\"")
        fi

        # If this is the "www" folder, it scans other domains
        if [[ "$folder_name" != "www" ]]; then
            findDomain "$dir" "$full_domain"
        fi
    done
}

# Function to find domains
findDomain() {
    local current_dir=$1
    local domain=$2

    if [[ -z "$domain" ]]; then
        domain=$(basename "$current_dir")
    fi

    # Increasing the number of processed folders
    processed_dirs=$((processed_dirs + 1))
    progressBar "$processed_dirs" "$total_dirs" "Processing dir: $current_dir"

    # Checking the presence of the file ".noautodomain"
    if [[ -f "$current_dir/.noautodomain" ]]; then
        processNoautodomainFile "$domain" "$current_dir/.noautodomain" "$current_dir"
        return
    fi

    for dir in "$current_dir"/*/; do
        dir=${dir%/}
        local folder_name=$(basename "$dir")

        # We display progress
        processed_dirs=$((processed_dirs + 1))
        progressBar "$processed_dirs" "$total_dirs" "Processing dir: $dir"

        # If you find the "www" folder, then write down all the nested domains
        if [[ "$folder_name" == "www" ]]; then
            scanDomain "$current_dir" "$domain"
        fi
    done
}

# Count the total number of directories
total_dirs=$(countDirs "$BASE_DIR")
# remove leading whitespace characters
total_dirs="${total_dirs#${total_dirs%%[![:space:]]*}}"

echo "Start scan directory: $BASE_DIR ($total_dirs)"

# Start scanning from the base directory
for dir in "$BASE_DIR"/*/; do
    dir=${dir%/}
    findDomain "$dir"
done

# Write JSON file
echo "{" > "$TEMP_FILE"
first_entry=true
for line in "${domains[@]}"; do
    if [[ "$first_entry" = true ]]; then
        first_entry=false
    else
        echo "," >> "$TEMP_FILE"
    fi
    printf %s "  $line" >> "$TEMP_FILE"
done
echo "" >> "$TEMP_FILE"
echo "}" >> "$TEMP_FILE"

progressBar 100 100 " finish\n"

# Move the temporary file to the final JSON file
mv "$TEMP_FILE" "$OUTPUT_FILE"

OUTPUT_FILE=$(realpath "$OUTPUT_FILE")
echo "The result is saved in $OUTPUT_FILE"
