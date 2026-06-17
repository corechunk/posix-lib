#!/usr/bin/env sh
# --- posix-lib Semantic Version Comparison (POSIX Compliant) ---

# Helper function to split dot-separated version strings into 4 segments.
_bl_split_version() {
    _bl_sver="$1"
    _bl_old_ifs="$IFS"
    IFS="."
    set -- $_bl_sver
    IFS="$_bl_old_ifs"
    
    _bl_p1="${1:-0}"
    _bl_p2="${2:-0}"
    _bl_p3="${3:-0}"
    _bl_p4="${4:-0}"
    echo "$_bl_p1 $_bl_p2 $_bl_p3 $_bl_p4"
}

# Left-to-right component-wise semantic version comparison utility.
# Usage: bl_version_compare <ver1> <ver2>
bl_version_compare() {
    # 1. Clean inputs: Strip 'v'/'V', all whitespace, tabs, and trailing newlines
    _bl_ver1=$(echo "$1" | tr -d 'vV[:space:]')
    _bl_ver2=$(echo "$2" | tr -d 'vV[:space:]')

    # If either version string ends up completely empty, return unknown
    if [ -z "$_bl_ver1" ] || [ -z "$_bl_ver2" ]; then
        echo "unknown"
        return
    fi

    # 2. Parse and pad components to exactly 4 integers
    _bl_parts1=$(_bl_split_version "$_bl_ver1")
    _bl_parts2=$(_bl_split_version "$_bl_ver2")

    _bl_old_ifs="$IFS"
    IFS=" "
    set -- $_bl_parts1
    _bl_v1_1="$1"; _bl_v1_2="$2"; _bl_v1_3="$3"; _bl_v1_4="$4"

    set -- $_bl_parts2
    _bl_v2_1="$1"; _bl_v2_2="$2"; _bl_v2_3="$3"; _bl_v2_4="$4"
    IFS="$_bl_old_ifs"

    # 3. Sequential Left-to-Right comparison
    # Major Update
    if [ "$_bl_v1_1" -lt "$_bl_v2_1" ]; then
        echo "major update"
        return
    elif [ "$_bl_v1_1" -gt "$_bl_v2_1" ]; then
        echo "downgrade"
        return
    fi

    # Minor Update
    if [ "$_bl_v1_2" -lt "$_bl_v2_2" ]; then
        echo "minor update"
        return
    elif [ "$_bl_v1_2" -gt "$_bl_v2_2" ]; then
        echo "downgrade"
        return
    fi

    # Patch Update
    if [ "$_bl_v1_3" -lt "$_bl_v2_3" ]; then
        echo "patch update"
        return
    elif [ "$_bl_v1_3" -gt "$_bl_v2_3" ]; then
        echo "downgrade"
        return
    fi

    # Hotfix Update
    if [ "$_bl_v1_4" -lt "$_bl_v2_4" ]; then
        echo "hotfix update"
        return
    elif [ "$_bl_v1_4" -gt "$_bl_v2_4" ]; then
        echo "downgrade"
        return
    fi

    # Exact Match
    echo "equal"
}
