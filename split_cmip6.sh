#!/bin/bash

# Purpose: Analyze CMIP6 NetCDF files to categorize them by their time coverage duration
# The script:
# 1. Finds all NetCDF files in the CMIP6 directory
# 2. Extracts date ranges from filenames
# 3. Calculates duration in years
# 4. Groups files by duration and provides statistics
# 5. Validates date consistency and reports anomalies
# 6. Categorizes files into one-year, multi-year, and error files
# 7. Processes multi-year files with CDO to split them into yearly files
# 8. Outputs results and statistics with identical compression settings

# Dependency check for CDO (Climate Data Operators)
if ! command -v cdo &>/dev/null; then
    echo "CDO is not installed. Please install it before running this script."
    echo "For example build a container and run 'sudo apt-get install cdo'"
    exit 1
fi

# Initialize associative array to store duration counts
declare -A count

# Use environment variables with defaults
CMIP6_PATH=${CMIP6_PATH:-"/capstor/store/cscs/swissai/a01/CMIP6/CMIP/CMCC/CMCC-CM2-HR4/historical/r1i1p1f1/"}
OUT_PATH=${OUT_PATH:-"${SCRATCH}/cmip6"}

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

# Initialize files for categorization
one_year_files="files_1year.txt"
multi_year_files="files_multi.txt"
error_files="files_error.txt"

# Clear any existing category files
>"$one_year_files"
>"$multi_year_files"
>"$error_files"

# Process each file and analyze its duration
while read -r line; do
    result=$(extract_dates "$line")
    if [ $? -ne 0 ]; then
        echo "$line" >>"$error_files"
        continue
    fi

    read start end years days_diff <<<"$result"

    count[$years]=$((${count[$years]:-0} + 1))

    # Categorize files while processing
    if [ "$years" -eq 0 ]; then
        echo "$line" >>"$error_files"  # Treat 0-year files as errors
    elif [ "$years" -eq 1 ]; then
        echo "$line" >>"$one_year_files"
    else
        echo "$line" >>"$multi_year_files"
    fi

    # Check for significant rounding discrepancies (> 4 days)
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
echo -e "\nFile categorization summary:"
echo "Total files: $(wc -l <files.txt)"
echo "One-year files: $(wc -l <$one_year_files)"
echo "Multi-year files: $(wc -l <$multi_year_files)"
echo "Files with parsing errors: $(wc -l <$error_files)"
echo "Files with rounding > 4 days: $files_with_large_rounding"

# Process each file from multi_year_files with CDO splityear
echo -e "\nProcessing multi-year files with CDO..."
echo "----------------------------------------"

get_nc_settings() {
    local file="$1"
    local settings=""

    # Extract compression settings using ncdump
    local header=$(ncdump -h -s "${file}")

    # Get deflate level (look for first occurrence)
    local deflate_level=$(echo "$header" | grep -m1 "_DeflateLevel" | grep -o "[0-9]")
    if [ -z "$deflate_level" ]; then
        deflate_level=0  # No compression
    fi

    # Check if shuffling is enabled
    if echo "$header" | grep -q '_Shuffle = "true"'; then
        settings="-z zip_${deflate_level}"
    elif [ "$deflate_level" -gt 0 ]; then
        # If deflate is set but shuffle not explicitly true, still use compression
        settings="-z zip_${deflate_level}"
    fi

    # Always use NetCDF4 format and copy chunking from input
    settings+=" -f nc4"

    echo "$settings"
}

while IFS= read -r file; do
    # Get the relative path structure
    rel_path=${file#$CMIP6_PATH}
    out_dir="${OUT_PATH}/$(dirname ${rel_path})"

    # Create output directory structure
    mkdir -p "${out_dir}"

    # Get filename without extension
    base_name=$(basename "${file}" .nc)

    echo "Processing: ${file}"
    echo "Output to: ${out_dir}"

    # Get compression settings from input file
    nc_settings=$(get_nc_settings "${file}")

    echo "Compression settings: ${nc_settings}"

    # Use CDO to split the file by year
    # -f nc4 forces NetCDF4 output format
    # splityear splits into yearly files with automatic YYYY suffix
    if cdo ${nc_settings} -P ${OMP_NUM_THREADS} splityear "${file}" "${out_dir}/${base_name}_"; then
        echo "Successfully processed ${file}"
    else
        echo "Warning: Failed to process ${file} - output files may already exist"
    fi
    echo "----------------------------------------"
done <"$multi_year_files"

echo "CDO processing complete"

rm files.txt
rm $one_year_files
rm $multi_year_files
rm $error_files
