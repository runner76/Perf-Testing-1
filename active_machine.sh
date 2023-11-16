#!/bin/bash

subnet="192.168.1"

# File to store the active hosts
output_file="inventory"

# Temporary file to hold unique IPs
temp_file=$(mktemp)

# Loop through hosts and collect active IPs
for host in {86..90}; do
    ip="${subnet}.${host}"
    if ping -c 1 "$ip" > /dev/null 2>&1; then
        echo "$ip"
    fi
done | sort -u > "$temp_file"

# Find the position of [active_hosts] in the file
line_number=$(awk '/\[active_hosts\]/{print NR; exit}' "$output_file")

# Insert the unique IPs between [active_hosts] and the next [
awk -v line="$line_number" 'NR==line+1 {print "[active_hosts]"; system("cat '"$temp_file"'")} {print} /^$/ && NR>line+1 && !printed {print ""; printed=1}' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"

# Add a new line at the end if it doesn't exist
last_char=$(tail -c 1 "$output_file" 2>/dev/null)
if [ -n "$last_char" ]; then
    echo "" >> "$output_file"
fi

# Remove duplicates, retaining empty lines
awk '!seen[$0]++ || $0 == ""' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"

# Remove temporary file
rm "$temp_file"

