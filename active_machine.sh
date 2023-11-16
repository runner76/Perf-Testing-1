#!/bin/bash

subnet="192.168.1"

# File to store the active hosts
output_file="inventory"

# Temporary file to hold unique active IPs
temp_file=$(mktemp)

# Loop through hosts and collect active IPs
for host in {86..90}; do
    ip="${subnet}.${host}"
    if ping -c 1 "$ip" > /dev/null 2>&1; then
        echo "$ip"
    fi
done | sort -u > "$temp_file"

# Check if [active_hosts] exists in the file
if grep -q "\[active_hosts\]" "$output_file"; then
    awk -v subnet="$subnet" '
        BEGIN {
            active = 0
        }
        /^\[active_hosts\]/ {
            print $0
            while ((getline < temp_file) > 0) {
                active_ips[$0] = 1
            }
            close(temp_file)
            active = 1
        }
        active && /^\[/ {
            for (line in active_ips) {
                print line
            }
	    print ""
            active = 0
        }
        !active
        END {
            if (!active) {
                if (length(active_ips) == 0) {
                    print "[active_hosts]"
                    while ((getline < temp_file) > 0) {
                        print $0
                    }
                    close(temp_file)
                }
            }
        }
    ' temp_file="$temp_file" "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
else
    echo "[active_hosts]" >> "$output_file"
    cat "$temp_file" >> "$output_file"
fi

# Remove temporary file
rm "$temp_file"

