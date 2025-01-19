#!/bin/bash

# Purpose: Analyze CMIP6 NetCDF files to categorize them by their time coverage duration
# The script:
# 1. Finds all NetCDF files in the CMIP6 directory
# 2. Extracts date ranges from filenames
# 3. Calculates duration in years
# 4. Groups files by duration and provides statistics
# 5. Validates date consistency and reports anomalies

# Dependency check for CDO (Climate Data Operators)
# if ! command -v cdo &>/dev/null; then
#     echo "CDO is not installed. Please install it before running this script."
#     echo "For example build a container and run 'sudo apt-get install cdo'"
#     exit 1
# fi

# Initialize associative array to store duration counts
declare -A count

# Use environment variables with defaults
CMIP6_PATH=${CMIP6_PATH:-"/capstor/store/cscs/swissai/a01/CMIP6/CMIP/CMCC/CMCC-CM2-HR4/historical/r1i1p1f1/"}
OUT_PATH=${OUT_PATH:-"${SCRATCH}/cmip6"}
LOG_DIR=${LOG_DIR:-"${SCRATCH}/logs"}

# Validate paths
if [ ! -d "$CMIP6_PATH" ]; then
    echo "Error: CMIP6_PATH directory does not exist: $CMIP6_PATH"
    exit 1
fi

if [ ! -d "$OUT_PATH" ]; then
    echo "Error: OUT_PATH directory does not exist: $OUT_PATH"
    exit 1
fi

# Extract all NetCDF files into a temporary file
find ${CMIP6_PATH} -name "*.nc" >files.txt

# extract_dates: Parse filename and calculate time duration
# Parameters:
#   $1: filename containing date information
# Returns:
#   space-separated string: start_date end_date years_rounded days_difference
# Format examples supported:
#   - YYYYMM-YYYYMM (e.g., 185001-201412)
#   - YYYYMMDD_HHMM-YYYYMMDD_HHMM
extract_dates() {
    local filename="$1"
    local datepart=$(echo "$filename" | grep -o '[0-9]\+\(-[0-9]\+\)*' | tail -1)

    if [[ $datepart =~ ^([0-9]{6})-([0-9]{6})$ ]]; then
        start="${BASH_REMATCH[1]}01"
        end="${BASH_REMATCH[2]}31"
    elif [[ $datepart =~ ^([0-9]{8})[0-9]{4}-([0-9]{8})[0-9]{4}$ ]]; then
        start="${BASH_REMATCH[1]}"
        end="${BASH_REMATCH[2]}"
    else
        echo "Unknown date format: $datepart" >&2
        return 1
    fi

    start_sec=$(date -d "${start}" +%s)
    end_sec=$(date -d "${end}" +%s)

    years=$(echo "scale=6; ($end_sec - $start_sec) / (365.25 * 24 * 3600)" | bc -l)
    years_rounded=$(printf "%.0f" $(echo "$years" | bc -l))

    days_diff=$(echo "scale=6; ($years_rounded - $years) * 365.25" | bc -l)
    days_diff_abs=$(echo "scale=6; if($days_diff < 0) -1*$days_diff else $days_diff" | bc -l)

    echo "$start $end $years_rounded $days_diff_abs"
}

# Counter for files with significant date rounding discrepancies
declare -i files_with_large_rounding=0

# Process each file and analyze its duration
while read -r line; do
    result=$(extract_dates "$line")
    if [ $? -ne 0 ]; then
        continue
    fi

    read start end years days_diff <<<"$result"

    # Print files with a specific amount of years
    # if [ "$years" -eq 250 ]; then
    #     echo "File with 250 years: $line"
    # fi

    count[$years]=$((${count[$years]:-0} + 1))

    # Check for significant rounding discrepancies (> 4 days)
    # This helps identify potential filename inconsistencies
    if (($( echo "$days_diff > 4" | bc -l))); then
        echo "WARNING: Large rounding for file: $line"
        echo "Period: $start to $end"
        echo "Rounding difference: $days_diff days"
        echo "---"
        ((files_with_large_rounding++))
    fi
done <files.txt

# Display results in a formatted table
echo "Duration (years) | Number of files"
echo "-----------------|-----------------"

# Sort and display duration statistics
for k in "${!count[@]}"; do
    printf "%14d | %d\n" "$k" "${count[$k]}"
done | sort -n

# Display summary statistics
echo "Total number of files:"
cat files.txt | wc -l

echo "Number of files with rounding > 4 days: $files_with_large_rounding"

