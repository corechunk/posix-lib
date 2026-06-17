#!/usr/bin/env sh
# --- posix-lib Selection Parsers & Validators (POSIX Compliant) ---

# TIER 1: Stateless Parser (Expands ranges like "1-3" and splits by delimiter)
# Args: $1=input_string, $2=delimiter (default: ,)
# Returns: Space-separated string on stdout. Exit 1 on syntax error.
bl_parse_selection() {
    _bl_input="$1"
    _bl_delim="${2:-,}"
    _bl_expanded=""

    _bl_old_ifs="$IFS"
    IFS="$_bl_delim"
    set -- $_bl_input
    IFS="$_bl_old_ifs"

    for _bl_p in "$@"; do
        _bl_p=$(echo "$_bl_p" | tr -d '[:space:]') # trim spaces
        [ -z "$_bl_p" ] && continue
        
        if [ "$_bl_p" = "all" ] || [ "$_bl_p" = "ALL" ]; then
            _bl_expanded="$_bl_expanded all"
        elif posix_match_glob "$_bl_p" "*-*"; then
            _bl_s="${_bl_p%-*}"
            _bl_e="${_bl_p#*-}"
            
            # Verify both bounds are integers
            case "$_bl_s" in
                *[!0-9]*|"") return 1 ;;
            esac
            case "$_bl_e" in
                *[!0-9]*|"") return 1 ;;
            esac
            
            # Simple expansion
            _bl_i="$_bl_s"
            while [ "$_bl_i" -le "$_bl_e" ]; do
                _bl_expanded="$_bl_expanded $_bl_i"
                _bl_i=$((_bl_i+1))
            done
        else
            case "$_bl_p" in
                *[!0-9]*|"") return 1 ;;
            esac
            _bl_expanded="$_bl_expanded $_bl_p"
        fi
    done
    
    echo "${_bl_expanded# }"
}

# TIER 2: Keyword Expander (Replaces "all" with 1..max)
# Args: $1=max_index, $@=list_from_tier1
# Returns: Space-separated numbers
bl_expand_selection() {
    _bl_max=$1
    shift
    _bl_final=""
    
    for _bl_item in "$@"; do
        if [ "$_bl_item" = "all" ]; then
            _bl_i=1
            while [ "$_bl_i" -le "$_bl_max" ]; do
                _bl_final="$_bl_final $_bl_i"
                _bl_i=$((_bl_i+1))
            done
        else
            _bl_final="$_bl_final $_bl_item"
        fi
    done
    
    echo "${_bl_final# }"
}

# TIER 3: Range Validator (Strictly checks bounds)
# Args: $1=max, $@=numbers
# Returns: Exit 0 if all valid, Exit 1 if any out of bounds
bl_validate_selection() {
    _bl_max=$1
    shift
    [ "$#" -eq 0 ] && return 1
    
    for _bl_n in "$@"; do
        case "$_bl_n" in
            *[!0-9]*|"") return 1 ;;
        esac
        if [ "$_bl_n" -le 0 ] || [ "$_bl_n" -gt "$_bl_max" ]; then
            return 1
        fi
    done
    
    return 0
}
