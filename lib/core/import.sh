#!/usr/bin/env sh
# --- bash-lib Core Loader & Registries (POSIX Compliant) ---

# Verify that all listed dependencies exist in the environment.
# Handles both shell functions and system commands using type.
# Usage: bl_check_deps "caller_func" "dep1" "dep2" ...
bl_check_deps() {
    _bl_caller="$1"
    shift
    _bl_missing=0
    for _bl_dep in "$@"; do
        if ! type "$_bl_dep" >/dev/null 2>&1; then
            printf "\033[1;31m[ERROR]\033[0m %s: Missing dependency '\033[1;33m%s\033[0m'\n" "$_bl_caller" "$_bl_dep" >&2
            _bl_missing=1
        fi
    done
    return $_bl_missing
}

# Global registry of functions, categories, and dependencies.
bl_map_init "BL_REGISTRY" ""

# Helper to load static maps cleanly
_bl_reg_set() {
    bl_map_set "BL_REGISTRY" "$1" "$2" ""
}

# Core utilities
_bl_reg_set "core|bl_check_deps" ""
_bl_reg_set "core|bl_hex_to_rgb" ""
_bl_reg_set "core|bl_version_compare" ""
_bl_reg_set "string|bl_parse_selection" ""
_bl_reg_set "string|bl_expand_selection" ""
_bl_reg_set "string|bl_validate_selection" ""

# UI components
_bl_reg_set "ui|bl_progress_bar" "bl_hex_to_rgb|bl_check_deps"
_bl_reg_set "ui|bl_square_progress" "bl_hex_to_rgb|bl_check_deps"
_bl_reg_set "ui|bl_spiral_progress" "bl_hex_to_rgb|bl_check_deps"
_bl_reg_set "ui|bl_terrain_loader" "bl_hex_to_rgb|bl_check_deps"
_bl_reg_set "ui|bl_pie" "bl_check_deps"
_bl_reg_set "ui|bl_matrix_filler" "tput"
_bl_reg_set "ui|bl_load_ghost" ""
_bl_reg_set "ui|bl_load_bounce" ""
_bl_reg_set "ui|bl_load_marquee" ""
_bl_reg_set "ui|bl_load_wave" ""
_bl_reg_set "ui|bl_menu" ""
_bl_reg_set "ui|bl_toast" ""
_bl_reg_set "ui|bl_input_secure" ""
_bl_reg_set "ui|bl_chart_spark" ""

# I/O Pipes and Feeders
_bl_reg_set "io|bl_file_count_feeder_" ""
_bl_reg_set "io|_bl_count_percent_emitter_" ""
_bl_reg_set "io|bl_file_log_feeder_" ""

# Info & Diagnostics
_bl_reg_set "info|bl_info_check" "bl_registry_get_types|bl_registry_get_funcs|bl_registry_get_deps"
_bl_reg_set "info|bl_info_menu" "bl_registry_get_types|bl_registry_get_funcs|bl_registry_get_deps"
_bl_reg_set "info|bl_bash_tutor" ""

# Async operations
_bl_reg_set "async|bl_pid_store" ""
_bl_reg_set "async|bl_pid_wait" ""
_bl_reg_set "async|bl_pid_status" ""
_bl_reg_set "async|bl_pid_reap" ""

# Dev tools
_bl_reg_set "dev|bl_compile" ""

# Core Loader
_bl_reg_set "core|bl_import" "curl"
_bl_reg_set "core|bl_import_local" ""
_bl_reg_set "core|import" "bl_import_local"
_bl_reg_set "core|bl_update_registry" "curl|jq"

# === BL_FILE_REGISTRY_START ===
bl_map_init "BL_FILE_REGISTRY" ""
_bl_file_set() {
    bl_map_set "BL_FILE_REGISTRY" "$1" "$2" ""
}
_bl_file_set "async|pid.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/async/pid.sh"
_bl_file_set "core|colors.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/colors.sh"
_bl_file_set "core|import.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/import.sh"
_bl_file_set "core|versions.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/versions.sh"
_bl_file_set "dev|compile.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/dev/compile.sh"
_bl_file_set "info|diagnostics.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/info/diagnostics.sh"
_bl_file_set "info|tutor.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/info/tutor.sh"
_bl_file_set "io|pipes.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/io/pipes.sh"
_bl_file_set "string|selection.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/string/selection.sh"
_bl_file_set "ui|matrix_filler.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/ui/matrix_filler.sh"
_bl_file_set "ui|progress_bars.sh" "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/ui/progress_bars.sh"
# === BL_FILE_REGISTRY_END ===

# Get all unique types registered
bl_registry_get_types() {
    _bl_types_seen=""
    for _bl_key in $(bl_map_keys "BL_REGISTRY" ""); do
        _bl_type="${_bl_key%%|*}"
        case " $_bl_types_seen " in
            *" $_bl_type "*) ;;
            *) _bl_types_seen="${_bl_types_seen} ${_bl_type}" ;;
        esac
    done
    printf "%s\n" "$_bl_types_seen"
}

# Get functions by type
bl_registry_get_funcs() {
    _bl_target_type="$1"
    _bl_funcs=""
    for _bl_key in $(bl_map_keys "BL_REGISTRY" ""); do
        _bl_type="${_bl_key%%|*}"
        _bl_func="${_bl_key#*|}"
        if [ "$_bl_type" = "$_bl_target_type" ]; then
            _bl_funcs="${_bl_funcs} ${_bl_func}"
        fi
    done
    printf "%s\n" "$_bl_funcs"
}

# Get dependencies for a specific function name
bl_registry_get_deps() {
    _bl_target_func="$1"
    for _bl_key in $(bl_map_keys "BL_REGISTRY" ""); do
        _bl_func="${_bl_key#*|}"
        if [ "$_bl_func" = "$_bl_target_func" ]; then
            bl_map_get "BL_REGISTRY" "$_bl_key" ""
            return 0
        fi
    done
    return 1
}

# Update the hardcoded BL_FILE_REGISTRY in lib/core/import.sh using GitHub API
bl_update_registry() {
    bl_check_deps "bl_update_registry" "curl" "jq" || return 1

    _bl_repo="${1:-bash-lib}"
    _bl_org="${2:-corechunk}"
    _bl_branch="${3:-main}"
    
    # POSIX replacement for BASH_SOURCE path resolution
    _bl_dir=$(dirname "$0")
    _bl_base_dir=$(cd "$_bl_dir/../.." && pwd)
    _bl_output_file="$_bl_base_dir/lib/core/import.sh"

    printf "\033[1;34m[INFO]\033[0m Fetching file tree for %s/%s (%s) from GitHub API...\n" "$_bl_org" "$_bl_repo" "$_bl_branch"
    _bl_tree_json=$(curl -s "https://api.github.com/repos/${_bl_org}/${_bl_repo}/git/trees/${_bl_branch}?recursive=1")
    if [ $? -ne 0 ] || [ -z "$_bl_tree_json" ] || [ "$(printf "%s" "$_bl_tree_json" | jq -r '.message // empty')" = "Not Found" ]; then
        printf "\033[1;31m[ERROR]\033[0m Failed to fetch repository tree. Check repo name and connection.\n" >&2
        return 1
    fi

    _bl_temp_file=$(mktemp)

    # Generate new registry mapping block
    _bl_new_registry=$(printf "%s" "$_bl_tree_json" | jq -r --arg org "$_bl_org" --arg repo "$_bl_repo" --arg branch "$_bl_branch" '
        .tree[]
        | select(.type == "blob" and (.path | endswith(".sh")))
        | .path as $p
        | ($p | split("/")) as $parts
        | (if ($p | startswith("lib/")) then $parts[1] elif ($parts | length) > 1 then $parts[0] else "main" end) as $cat
        | $parts[-1] as $file
        | "_bl_file_set \"\($cat)|\($file)\" \"https://raw.githubusercontent.com/\($org)/\($repo)/\($branch)/\($p)\""
    ' | sort)

    # Read import.sh and replace block between markers
    awk -v reg="$_bl_new_registry" '
        /# === BL_FILE_REGISTRY_START ===/ {
            print "# === BL_FILE_REGISTRY_START ==="
            print "bl_map_init \"BL_FILE_REGISTRY\" \"\""
            print "_bl_file_set() {"
            print "    bl_map_set \"BL_FILE_REGISTRY\" \"$1\" \"$2\" \"\""
            print "}"
            print reg
            skip = 1
            next
        }
        /# === BL_FILE_REGISTRY_END ===/ {
            print "# === BL_FILE_REGISTRY_END ==="
            skip = 0
            next
        }
        !skip { print }
    ' "$_bl_output_file" > "$_bl_temp_file"

    mv "$_bl_temp_file" "$_bl_output_file"
    printf "\033[1;32m[SUCCESS]\033[0m File registry updated successfully inside: %s\n" "$_bl_output_file"
    . "$_bl_output_file"
}

# Internal helper to curl and source a remote URL with pretty error handling.
_bl_curl_source() {
    _bl_key="$1"
    _bl_url="$2"
    _bl_verbose="$3"
    _bl_is_optional="${4:-0}"

    if [ "$_bl_verbose" -eq 1 ]; then
        _bl_tag="[Sourcing Remote]"
        _bl_cat="${_bl_key%%|*}"
        _bl_file="${_bl_key#*|}"
        if [ "$_bl_cat" = "$_bl_file" ]; then
            _bl_tag="[Sourcing Monolith]"
        fi
        printf "\033[1;34m%s\033[0m %s -> %s" "$_bl_tag" "$_bl_key" "$_bl_url"
    fi

    _bl_temp_err=$(mktemp)
    _bl_curl_out=$(curl -fsSL "$_bl_url" 2>"$_bl_temp_err")
    _bl_ec=$?
    _bl_curl_err=$(cat "$_bl_temp_err")
    rm -f "$_bl_temp_err"

    if [ "$_bl_ec" -eq 0 ]; then
        if [ "$_bl_verbose" -eq 1 ]; then
            printf " \033[1;32m✅\033[0m\n"
        fi
        # POSIX compliant source output stream
        printf "%s\n" "$_bl_curl_out" > "$_bl_temp_err"
        . "$_bl_temp_err"
        rm -f "$_bl_temp_err"
        return 0
    else
        _bl_err_label="\033[1;31m❌ [Network Error]\033[0m"
        if [ "$_bl_ec" -eq 22 ]; then
            _bl_err_label="\033[1;31m❌ [File Not Found]\033[0m"
        fi

        if [ "$_bl_verbose" -eq 1 ]; then
            printf "\n"
        fi

        if [ "$_bl_is_optional" -ne 1 ] || [ "$_bl_verbose" -eq 1 ]; then
            printf "  %s %s\n" "$_bl_err_label" "$_bl_curl_err" >&2
        fi
        return 1
    fi
}

# Import remote libraries by pattern (e.g., "*", "ui/*", "core/colors.sh")
bl_import() {
    bl_check_deps "bl_import" "curl" || return 1

    _bl_verbose=0
    _bl_strict=0
    _bl_has_error=0
    _bl_pattern=""
    
    _bl_salt=$(_bl_gen_salt)
    bl_arr_init "remote_urls" "$_bl_salt"

    # Parse flags
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -v|--verbose) _bl_verbose=1; shift ;;
            --strict) _bl_strict=1; shift ;;
            --lib-curl)
                shift
                if [ "$1" = "start" ]; then
                    shift
                    while [ "$#" -gt 0 ] && [ "$1" != "stop" ]; do
                        bl_arr_append "remote_urls" "$1" "$_bl_salt"
                        shift
                    done
                    [ "$1" = "stop" ] && shift
                else
                    bl_arr_append "remote_urls" "$1" "$_bl_salt"
                    shift
                fi
                ;;
            -*) printf "\033[1;31m[ERROR]\033[0m Unknown flag: %s\n" "$1" >&2; return 1 ;;
            *) _bl_pattern="$1"; shift ;;
        esac
    done
    
    # Iterate and source direct URLs if provided
    _bl_idx=0
    while true; do
        _bl_url=$(bl_arr_get "remote_urls" "$_bl_idx" "$_bl_salt")
        [ -z "$_bl_url" ] && break
        if ! _bl_curl_source "remote|$_bl_url" "$_bl_url" "$_bl_verbose" 0; then
            if [ "$_bl_strict" -eq 1 ]; then
                bl_cleanup_scope "$_bl_salt"
                return 1
            fi
        fi
        _bl_idx=$(( _bl_idx + 1 ))
    done
    
    if [ "$_bl_idx" -gt 0 ]; then
        bl_cleanup_scope "$_bl_salt"
        return 0
    fi
    bl_cleanup_scope "$_bl_salt"
    
    _bl_pattern="${_bl_pattern:-*}"
    _bl_search_cat=""
    _bl_search_file=""
    _bl_is_glob=0

    case "$_bl_pattern" in
        "*")
            _bl_search_cat="*"
            _bl_search_file="*"
            _bl_is_glob=1
            ;;
        */*)
            _bl_search_cat="${_bl_pattern%%/*}"
            _bl_search_file="${_bl_pattern#*/}"
            [ -z "$_bl_search_file" ] && _bl_search_file="*"
            [ "$_bl_search_file" = "*" ] && _bl_is_glob=1
            ;;
        *)
            _bl_search_cat="$_bl_pattern"
            _bl_search_file="*"
            _bl_is_glob=1
            ;;
    esac

    # --- Specific file import path ---
    if [ "$_bl_is_glob" -eq 0 ]; then
        _bl_key="$_bl_search_cat|$_bl_search_file"
        _bl_url=$(bl_map_get "BL_FILE_REGISTRY" "$_bl_key" "" 2>/dev/null || true)
        if [ -z "$_bl_url" ]; then
            printf "\033[1;31m[ERROR]\033[0m Registry entry not found: %s\n" "$_bl_key" >&2
            return $_bl_strict
        fi
        if ! posix_match_glob "$_bl_search_file" "*.sh" && ! posix_match_glob "$_bl_search_file" "*.bash"; then
            printf "\033[1;31m[ERROR]\033[0m '%s' is not a .sh or .bash file.\n" "$_bl_search_file" >&2
            return $_bl_strict
        fi
        if ! _bl_curl_source "$_bl_key" "$_bl_url" "$_bl_verbose" 0; then
            printf "\033[1;31m[ERROR]\033[0m Failed to source remote library: %s (%s)\n" "$_bl_key" "$_bl_url" >&2
            return $_bl_strict
        fi
        return 0
    fi

    # --- Category glob import path ---
    _bl_salt_cats=$(_bl_gen_salt)
    bl_map_init "sourced_cats" "$_bl_salt_cats"
    _bl_cats_count=0

    for _bl_key in $(bl_map_keys "BL_FILE_REGISTRY" ""); do
        _bl_cat="${_bl_key%%|*}"
        _bl_file="${_bl_key#*|}"

        if [ "$_bl_search_cat" != "*" ] && [ "$_bl_cat" != "$_bl_search_cat" ]; then
            continue
        fi

        if ! posix_match_glob "$_bl_file" "*.sh" && ! posix_match_glob "$_bl_file" "*.bash" && [ "$_bl_file" != "$_bl_cat" ]; then
            continue
        fi

        bl_map_set "sourced_cats" "$_bl_cat" "1" "$_bl_salt_cats"
        _bl_cats_count=$(( _bl_cats_count + 1 ))
    done

    if [ "$_bl_cats_count" -eq 0 ]; then
        printf "\033[1;33m[bl_import]\033[0m No sourceable entries matched: %s\n" "$_bl_pattern" >&2
        bl_cleanup_scope "$_bl_salt_cats"
        return $_bl_strict
    fi

    # Process each matched category
    for _bl_cat in $(bl_map_keys "sourced_cats" "$_bl_salt_cats"); do
        _bl_monolith_key="$_bl_cat|$_bl_cat"
        _bl_monolith_url=$(bl_map_get "BL_FILE_REGISTRY" "$_bl_monolith_key" "" 2>/dev/null || true)
        _bl_monolith_sourced=0

        if [ -n "$_bl_monolith_url" ]; then
            if _bl_curl_source "$_bl_monolith_key" "$_bl_monolith_url" "$_bl_verbose" 1; then
                _bl_monolith_sourced=1
            else
                [ "$_bl_verbose" -eq 1 ] && printf "\033[1;33m[WARN]\033[0m Monolith failed for '%s', falling back to individual files.\n" "$_bl_cat" >&2
            fi
        fi

        if [ "$_bl_monolith_sourced" -eq 0 ]; then
            _bl_fallback_found=0
            for _bl_key in $(bl_map_keys "BL_FILE_REGISTRY" ""); do
                _bl_fcat="${_bl_key%%|*}"
                _bl_file="${_bl_key#*|}"

                [ "$_bl_fcat" != "$_bl_cat" ] && continue
                if ! posix_match_glob "$_bl_file" "*.sh" && ! posix_match_glob "$_bl_file" "*.bash"; then
                    continue
                fi

                _bl_url=$(bl_map_get "BL_FILE_REGISTRY" "$_bl_key" "" 2>/dev/null || true)
                [ -z "$_bl_url" ] && continue

                if ! _bl_curl_source "$_bl_key" "$_bl_url" "$_bl_verbose" 0; then
                    printf "\033[1;31m[ERROR]\033[0m Failed to source remote library: %s (%s)\n" "$_bl_key" "$_bl_url" >&2
                    if [ "$_bl_strict" -eq 1 ]; then
                        bl_cleanup_scope "$_bl_salt_cats"
                        return 1
                    fi
                    _bl_has_error=1
                fi
                _bl_fallback_found=$(( _bl_fallback_found + 1 ))
            done
            if [ "$_bl_fallback_found" -eq 0 ]; then
                printf "\033[1;33m[bl_import]\033[0m No sourceable files matched for category: %s\n" "$_bl_cat" >&2
                if [ "$_bl_strict" -eq 1 ]; then
                    bl_cleanup_scope "$_bl_salt_cats"
                    return 1
                fi
                _bl_has_error=1
            fi
        fi
    done

    bl_cleanup_scope "$_bl_salt_cats"
    if [ "$_bl_strict" -eq 1 ] && [ "$_bl_has_error" -eq 1 ]; then
        return 1
    fi
    return 0
}

# Returns 0 if the file should be sourced, 1 otherwise
_bl_is_sourceable() {
    _bl_f="$1"
    _bl_base="${_bl_f##*/}"
    if posix_match_glob "$_bl_f" "*.sh" || posix_match_glob "$_bl_f" "*.bash"; then
        return 0
    fi
    # Non-extension checks
    case "$_bl_base" in
        *.*) ;;
        *)
            if [ -f "$_bl_f" ]; then
                _bl_shebang=$(head -n 1 "$_bl_f" 2>/dev/null)
                # Matches sh/bash wrappers or general sh interpreters
                case "$_bl_shebang" in
                    *bash*|*sh*) return 0 ;;
                esac
            fi
            ;;
    esac
    return 1
}

bl_import_local() {
    bl_check_deps "bl_import_local" || return 1

    _bl_verbose=0
    _bl_strict=0
    
    _bl_salt_local=$(_bl_gen_salt)
    bl_arr_init "local_patterns" "$_bl_salt_local"
    _bl_pats_count=0

    # Parse flags before patterns
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -v|--verbose) _bl_verbose=1; shift ;;
            --strict) _bl_strict=1; shift ;;
            *)
                bl_arr_append "local_patterns" "$1" "$_bl_salt_local"
                _bl_pats_count=$(( _bl_pats_count + 1 ))
                shift
                ;;
        esac
    done

    if [ "$_bl_pats_count" -eq 0 ]; then
        printf "\033[1;31m[import]\033[0m pattern required (e.g. \"lib/*\")\n" >&2
        bl_cleanup_scope "$_bl_salt_local"
        return 1
    fi

    # Tracking seen files cleanly in POSIX map
    bl_map_init "seen_files" "$_bl_salt_local"
    _bl_found=0

    _bl_pidx=0
    while true; do
        _bl_pattern=$(bl_arr_get "local_patterns" "$_bl_pidx" "$_bl_salt_local")
        [ -z "$_bl_pattern" ] && break
        
        # Resolve path
        case "$_bl_pattern" in
            /*) ;;
            *) _bl_pattern="${PWD}/${_bl_pattern}" ;;
        esac

        # POSIX emulates recursive globbing via find matching directories and files
        _bl_dir_target="${_bl_pattern%/*}"
        _bl_file_pattern="${_bl_pattern##*/}"

        if [ -d "$_bl_pattern" ]; then
            _bl_dir_target="$_bl_pattern"
            _bl_file_pattern="*"
        fi

        if [ -d "$_bl_dir_target" ]; then
            # Use POSIX find to grab files matching patterns
            for _bl_file in $(find "$_bl_dir_target" -type f 2>/dev/null); do
                _bl_fbase="${_bl_file##*/}"
                if [ "$_bl_file_pattern" != "*" ] && ! posix_match_glob "$_bl_fbase" "$_bl_file_pattern"; then
                    continue
                fi
                _bl_seen_val=$(bl_map_get "seen_files" "$_bl_file" "$_bl_salt_local" 2>/dev/null || true)
                [ -n "$_bl_seen_val" ] && continue
                _bl_is_sourceable "$_bl_file" || continue
                
                bl_map_set "seen_files" "$_bl_file" "1" "$_bl_salt_local"
                [ "$_bl_verbose" -eq 1 ] && printf "\033[1;34m[import]\033[0m %s\n" "$_bl_file"
                . "$_bl_file"
                _bl_found=$(( _bl_found + 1 ))
            done
        elif [ -f "$_bl_pattern" ]; then
            _bl_seen_val=$(bl_map_get "seen_files" "$_bl_pattern" "$_bl_salt_local" 2>/dev/null || true)
            if [ -z "$_bl_seen_val" ] && _bl_is_sourceable "$_bl_pattern"; then
                bl_map_set "seen_files" "$_bl_pattern" "1" "$_bl_salt_local"
                [ "$_bl_verbose" -eq 1 ] && printf "\033[1;34m[import]\033[0m %s\n" "$_bl_pattern"
                . "$_bl_pattern"
                _bl_found=$(( _bl_found + 1 ))
            fi
        fi
        
        _bl_pidx=$(( _bl_pidx + 1 ))
    done

    bl_cleanup_scope "$_bl_salt_local"
    if [ "$_bl_found" -eq 0 ]; then
        return $_bl_strict
    fi
    return 0
}

# Simple import keyword backed by bl_import_local
import() {
    bl_check_deps "import" "bl_import_local" || return 1
    bl_import_local "$@"
}
