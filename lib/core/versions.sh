#!/usr/bin/env bash

# Left-to-right component-wise semantic version comparison utility.
bl_version_compare() {
    # 1. Clean inputs: Strip 'v'/'V', all whitespace, tabs, and trailing newlines
    local ver1=$(echo "$1" | tr -d 'vV[:space:]')
    local ver2=$(echo "$2" | tr -d 'vV[:space:]')

    # If either version string ends up completely empty, return unknown
    if [[ -z "$ver1" || -z "$ver2" ]]; then
        echo "unknown"
        return
    fi

    # 2. Parse into arrays using '.' as the delimiter
    IFS='.' read -r -a v1_parts <<< "$ver1"
    IFS='.' read -r -a v2_parts <<< "$ver2"

    # 3. HEAVY-DUTY PADDING: Force both arrays to have exactly 4 elements (0 to 3)
    for i in {0..3}; do
        if [[ -z "${v1_parts[i]}" ]]; then
            v1_parts[i]=0
        fi
        if [[ -z "${v2_parts[i]}" ]]; then
            v2_parts[i]=0
        fi
    done

    # 4. Strict Directional Left-to-Right Traversal
    for i in {0..3}; do
        if (( v1_parts[i] < v2_parts[i] )); then
            # The destination version (v2) is larger -> An update is available!
            case $i in
                0) echo "major update"; return ;;
                1) echo "minor update"; return ;;
                2) echo "patch update"; return ;;
                3) echo "hotfix update"; return ;;
            esac
        elif (( v1_parts[i] > v2_parts[i] )); then
            # The current version (v1) is larger -> Higher version already here!
            echo "downgrade"
            return
        fi
    done

    # If the loop finishes without returning, all parts matched perfectly
    echo "equal"
}
