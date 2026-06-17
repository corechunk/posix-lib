#!/usr/bin/env sh
# --- Scope Helpers ---

# Generate a salt for a function scope
_bl_gen_salt() {
    _bl_salt_val=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 6)
    printf "%s" "$_bl_salt_val"
}

# --- Registry for Tracking ---
# bl_map_init "_BL_RESOURCE_REGISTRY" ""  # moved below after definition

_bl_register_resource() {
    # If the name is _BL_RESOURCE_REGISTRY, do NOT register it
    [ "$2" = "_BL_RESOURCE_REGISTRY" ] && return 0
    # Key: type:name:salt, Value: 1 (to store presence)
    bl_map_set "_BL_RESOURCE_REGISTRY" "$1:$2:$3" "1" ""
}

# --- Variable Helpers ---
# Usage: bl_var_init "varname" [salt]
bl_var_init() {
    _bl_register_resource "VAR" "$1" "$2"
}

# Usage: bl_var_set "varname" "value" [salt]
bl_var_set() {
    export "BL_VAR_${1}_${3}=${2}"
}

# Usage: val=$(bl_var_get "varname" [salt])
bl_var_get() {
    eval "echo \"\${BL_VAR_${1}_${2}}\""
}

# Usage: bl_var_unset "varname" [salt]
bl_var_unset() {
    unset "BL_VAR_${1}_${2}"
}

# --- Array Helpers (0-based) ---
# Usage: bl_arr_init "arr" [salt]
bl_arr_init() {
    _bl_arr_path=$(mktemp)
    export "BL_ARR_${1}_${2}=${_bl_arr_path}"
    _bl_register_resource "ARR" "$1" "$2"
}

# Usage: bl_arr_append "arr" "value" [salt]
bl_arr_append() {
    eval "_bl_arr_path=\"\$BL_ARR_${1}_${3}\""
    printf "%s\0" "$2" >>"$_bl_arr_path"
}

# Usage: val=$(bl_arr_get "arr" index [salt])
bl_arr_get() {
    eval "_bl_arr_path=\"\$BL_ARR_${1}_${3}\""
    _bl_idx=$(( $2 + 1 ))
    tr '\0' '\n' < "$_bl_arr_path" | sed -n "${_bl_idx}p"
}

# Usage: bl_arr_unset "arr" [salt]
bl_arr_unset() {
    eval "_bl_arr_path=\"\$BL_ARR_${1}_${2}\""
    [ -f "$_bl_arr_path" ] && rm -f "$_bl_arr_path"
    unset "BL_ARR_${1}_${2}"
}

# Usage: bl_map_init "map" [salt]
bl_map_init() {
    _bl_map_dir=$(mktemp -d)
    # Translate invalid environment variable characters in map name and salt to underscores
    _bl_map_var_name=$(printf "%s" "BL_MAP_${1}_${2}" | tr ':/.-' '____')
    export "${_bl_map_var_name}=${_bl_map_dir}"
    _bl_register_resource "MAP" "$1" "$2"
}

# Usage: bl_map_set "map" "key" "value" [salt]
bl_map_set() {
    _bl_map_var_name=$(printf "%s" "BL_MAP_${1}_${4}" | tr ':/.-' '____')
    eval "_bl_map_dir=\"\$${_bl_map_var_name}\""
    _bl_key_file=$(printf "%s" "$2" | tr ':/.-' '____')
    printf "%s" "$3" > "$_bl_map_dir/$_bl_key_file"
}

# Usage: val=$(bl_map_get "map" "key" [salt])
bl_map_get() {
    _bl_map_var_name=$(printf "%s" "BL_MAP_${1}_${3}" | tr ':/.-' '____')
    eval "_bl_map_dir=\"\$${_bl_map_var_name}\""
    _bl_key_file=$(printf "%s" "$2" | tr ':/.-' '____')
    cat "$_bl_map_dir/$_bl_key_file"
}

# Usage: bl_map_unset "map" [salt]
bl_map_unset() {
    _bl_map_var_name=$(printf "%s" "BL_MAP_${1}_${2}" | tr ':/.-' '____')
    eval "_bl_map_dir=\"\$${_bl_map_var_name}\""
    [ -d "$_bl_map_dir" ] && rm -rf "$_bl_map_dir"
    unset "${_bl_map_var_name}"
}

# Usage: bl_map_unset_key "map" "key" [salt]
bl_map_unset_key() {
    _bl_map_var_name=$(printf "%s" "BL_MAP_${1}_${3}" | tr ':/.-' '____')
    eval "_bl_map_dir=\"\$${_bl_map_var_name}\""
    _bl_key_file=$(printf "%s" "$2" | tr ':/.-' '____')
    [ -f "$_bl_map_dir/$_bl_key_file" ] && rm -f "$_bl_map_dir/$_bl_key_file"
}

# Usage: bl_map_keys "map" [salt]
bl_map_keys() {
    _bl_map_var_name=$(printf "%s" "BL_MAP_${1}_${2}" | tr ':/.-' '____')
    eval "_bl_map_dir=\"\$${_bl_map_var_name}\""
    if [ -d "$_bl_map_dir" ]; then
        # List files in the directory; return 0 even if empty
        ls -1 "$_bl_map_dir" 2>/dev/null || true
    fi
}




# --- Cleanup Helpers ---

# Usage: bl_cleanup_scope "salt"
bl_cleanup_scope() {
    _bl_target_salt=$1
    for entry in $(bl_map_keys "_BL_RESOURCE_REGISTRY" ""); do
        _bl_type="${entry%%:*}"
        _bl_rest="${entry#*:}"
        _bl_name="${_bl_rest%%:*}"
        _bl_salt="${_bl_rest#*:}"
        
        if [ "$_bl_salt" = "$_bl_target_salt" ]; then
            case "$_bl_type" in
                VAR) bl_var_unset "$_bl_name" "$_bl_salt" ;;
                ARR) bl_arr_unset "$_bl_name" "$_bl_salt" ;;
                MAP) bl_map_unset "$_bl_name" "$_bl_salt" ;;
            esac
        fi
    done
}

# Usage: bl_cleanup_global
bl_cleanup_global() {
    for entry in $(bl_map_keys "_BL_RESOURCE_REGISTRY" ""); do
        _bl_type="${entry%%:*}"
        _bl_rest="${entry#*:}"
        _bl_name="${_bl_rest%%:*}"
        _bl_salt="${_bl_rest#*:}"
        
        case "$_bl_type" in
            VAR) bl_var_unset "$_bl_name" "$_bl_salt" ;;
            ARR) bl_arr_unset "$_bl_name" "$_bl_salt" ;;
            MAP) bl_map_unset "$_bl_name" "$_bl_salt" ;;
        esac
    done
    bl_map_unset "_BL_RESOURCE_REGISTRY" ""
}
# ---------------------------------------------------------------------------
# POSIX helper utilities – pattern & regex matching, combined logical tests
# ---------------------------------------------------------------------------

# posix_match_glob STRING PATTERN
#   Returns 0 (true) if STRING matches the glob PATTERN (e.g. "*.sh").
#   Implemented with a POSIX case statement.
posix_match_glob() {
    _p_str=$1
    _p_pat=$2
    case "$_p_str" in
        $_p_pat) return 0 ;;
        *) return 1 ;;
    esac
}

# posix_match_regex STRING REGEX
#   Returns 0 (true) if STRING matches the extended regular expression REGEX.
#   Uses grep -E for portability (POSIX grep supports -E in many implementations).
posix_match_regex() {
    _p_str=$1
    _p_regex=$2
    printf '%s' "$_p_str" | grep -E -q "$_p_regex"
}

# posix_all_true CONDITION1 [CONDITION2 ...]
#   Evaluate a series of POSIX test expressions passed as arguments.
#   Each argument should be a full test expression that can be evaluated
#   with "eval [ expression ]". Returns 0 only if every condition succeeds.
posix_all_true() {
    for _cond in "$@"; do
        if ! eval "[ $_cond ]"; then
            return 1
        fi
    done
    return 0
}

# posix_any_true CONDITION1 [CONDITION2 ...]
#   Returns 0 if any of the supplied POSIX test expressions succeeds.
posix_any_true() {
    for _cond in "$@"; do
        if eval "[ $_cond ]"; then
            return 0
        fi
    done
    return 1
}
# posix_arith_test EXPRESSION
#   Evaluates an arithmetic expression and returns success (0) if the result is non‑zero.
#   Mimics Bash's (( expression )) command.
posix_arith_test() {
    eval "_val=$(( $1 ))"
    [ "$_val" -ne 0 ]
}

# posix_for INIT TEST INCR BODY
#   Emulates Bash's C‑style for loop using only POSIX constructs.
#   Example:
#     posix_for "i=0" "i<10" "i=$(( i+1 ))" 'printf "%s\n" "$i"'
posix_for() {
    eval "$1"          # initialization
    while eval "[ $2 ]"; do
        eval "$4"      # body
        eval "$3"      # increment
    done
}

# posix_random [max] [min]
#   Generates a pseudo-random integer within a range [min, max] (defaults: min=0, max=32767).
#   Uses od and /dev/urandom for seeding.
posix_random() {
    _p_max=${1:-32767}
    _p_min=${2:-0}
    _p_range=$(( _p_max - _p_min + 1 ))
    # Read a 2-byte unsigned integer from /dev/urandom
    _p_rand=$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')
    # Fallback to seconds since epoch if od/urandom fails
    if [ -z "$_p_rand" ] || ! [ "$_p_rand" -eq "$_p_rand" ] 2>/dev/null; then
        _p_rand=$(date +%s)
    fi
    printf "%d\n" $(( (_p_rand % _p_range) + _p_min ))
}

# posix_substr STRING OFFSET [LENGTH]
#   Extracts a substring from STRING starting at OFFSET (0-indexed).
#   If LENGTH is omitted, extracts to the end of the string.
posix_substr() {
    _p_str=$1
    _p_offset=$2
    _p_len=$3
    if [ -n "$_p_len" ]; then
        # cut uses 1-based index, so add 1 to offset
        printf "%s" "$_p_str" | cut -c $(( _p_offset + 1 ))-$(( _p_offset + _p_len ))
    else
        printf "%s" "$_p_str" | cut -c $(( _p_offset + 1 ))-
    fi
}

# posix_hex_to_dec HEX_VAL
#   Converts a hexadecimal string to a decimal integer (handles hash prefixes if any).
posix_hex_to_dec() {
    _p_hex=${1#\#} # Strip '#' if present
    _p_hex=${_p_hex#0x} # Strip '0x' if present
    printf "%d\n" "0x$_p_hex"
}

# --- Initialization ---
bl_map_init "_BL_RESOURCE_REGISTRY" ""



