#!/bin/bash

subnet="192.168.1"

# File to store the active hosts
output_file="inventory"

# Temporary files to hold unique active IPs and the content of the next header
temp_file1=$(mktemp)
temp_file2=$(mktemp)

# Check if [active_hosts] exists in the file
if grep -q "\[active_hosts\]" "$output_file"; then
    # Find the line number of [active_hosts] and the next header
    active_line_number=$(awk '/\[active_hosts\]/{print NR; exit}' "$output_file")
    next_header=$(awk -v line="$active_line_number" 'NR > line && /^\[/ {print NR; exit}' "$output_file")

    # If a next header exists, move its content to a second temp file
    if [ -n "$next_header" ]; then
        awk -v start="$next_header" 'NR >= start {print $0}' "$output_file" > "$temp_file2"
    fi

    # Check for active IPs and store them in the first temp file
    declare -A active_ips
    for host in {86..90}; do
        ip="${subnet}.${host}"
        if ping -c 1 "$ip" > /dev/null 2>&1; then
            echo "$ip"
            active_ips["$ip"]=1
        fi
    done | sort -u > "$temp_file1"

    # Remove inactive IPs from [active_hosts] section
    awk -v start="$active_line_number" -v end="$next_header" '
        NR >= start && NR < end {
            if ($0 ~ /^[0-9]/ && !($0 in active_ips)) {
                next
            }
            print $0
        }
        NR < start || NR >= end
    ' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"

    # Add a blank line after the last entry or [active_hosts] if no active hosts exist
    if [ -s "$temp_file1" ]; then
        echo "" >> "$output_file"
    fi

else
    # If [active_hosts] doesn't exist, add it and populate with active IPs
    declare -A active_ips
    for host in {86..90}; do
        ip="${subnet}.${host}"
        if ping -c 1 "$ip" > /dev/null 2>&1; then
            echo "$ip"
            active_ips["$ip"]=1
        fi
    done | sort -u > "$output_file"
fi

# Remove temporary files
rm "$temp_file1" "$temp_file2"

