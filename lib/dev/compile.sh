#!/usr/bin/env sh
# --- posix-lib Compiler Builder (POSIX Compliant) ---

bl_compile() {
    _bl_salt=$(_bl_gen_salt)
    bl_map_init "COMPILE_CFG" "$_bl_salt"
    
    # Set default config values
    bl_map_set "COMPILE_CFG" "source_dir" "" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "out_name" "" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "main_file" "" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "out_dir" "./build" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "verbose" "0" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "strip_mode" "none" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "recursive" "0" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "write_shebang" "1" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "shebang_val" "auto" "$_bl_salt"
    bl_map_set "COMPILE_CFG" "strict" "0" "$_bl_salt"
    
    bl_arr_init "COMPILE_REMOTE_URLS" "$_bl_salt"

    # Argument Parsing
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--dir)
                bl_map_set "COMPILE_CFG" "source_dir" "$2" "$_bl_salt"
                shift 2 ;;
            -o|--out-name)
                bl_map_set "COMPILE_CFG" "out_name" "$2" "$_bl_salt"
                shift 2 ;;
            -m|--main)
                bl_map_set "COMPILE_CFG" "main_file" "$2" "$_bl_salt"
                shift 2 ;;
            --out-dir)
                bl_map_set "COMPILE_CFG" "out_dir" "$2" "$_bl_salt"
                shift 2 ;;
            -v|--verbose)
                bl_map_set "COMPILE_CFG" "verbose" "1" "$_bl_salt"
                shift 1 ;;
            -r|--recursive)
                bl_map_set "COMPILE_CFG" "recursive" "1" "$_bl_salt"
                shift 1 ;;
            --no-shebang)
                bl_map_set "COMPILE_CFG" "write_shebang" "0" "$_bl_salt"
                shift 1 ;;
            --strict)
                bl_map_set "COMPILE_CFG" "strict" "1" "$_bl_salt"
                shift 1 ;;
            --lib-curl)
                shift
                if [ "$1" = "start" ]; then
                    shift
                    while [ "$#" -gt 0 ] && [ "$1" != "stop" ]; do
                        bl_arr_append "COMPILE_REMOTE_URLS" "$1" "$_bl_salt"
                        shift
                    done
                    [ "$1" = "stop" ] && shift
                else
                    bl_arr_append "COMPILE_REMOTE_URLS" "$1" "$_bl_salt"
                    shift
                fi
                ;;
            --shebang)
                if [ "$2" = "false" ] || [ "$2" = "none" ]; then
                    bl_map_set "COMPILE_CFG" "write_shebang" "0" "$_bl_salt"
                else
                    bl_map_set "COMPILE_CFG" "write_shebang" "1" "$_bl_salt"
                    bl_map_set "COMPILE_CFG" "shebang_val" "$2" "$_bl_salt"
                fi
                shift 2
                ;;
            -s|--strip)
                if [ -n "$2" ] && [ "$(posix_substr "$2" 0 1)" != "-" ]; then
                    bl_map_set "COMPILE_CFG" "strip_mode" "$2" "$_bl_salt"
                    shift 2
                else
                    bl_map_set "COMPILE_CFG" "strip_mode" "all" "$_bl_salt"
                    shift 1
                fi
                ;;
            *)
                echo "Unknown parameter passed: $1" >&2
                bl_cleanup_scope "$_bl_salt"
                return 1 ;;
        esac
    done

    # Fetch variable configuration
    _bl_source_dir=$(bl_map_get "COMPILE_CFG" "source_dir" "$_bl_salt")
    _bl_out_name=$(bl_map_get "COMPILE_CFG" "out_name" "$_bl_salt")
    _bl_main_file=$(bl_map_get "COMPILE_CFG" "main_file" "$_bl_salt")
    _bl_out_dir=$(bl_map_get "COMPILE_CFG" "out_dir" "$_bl_salt")
    _bl_verbose=$(bl_map_get "COMPILE_CFG" "verbose" "$_bl_salt")
    _bl_strip_mode=$(bl_map_get "COMPILE_CFG" "strip_mode" "$_bl_salt")
    _bl_recursive=$(bl_map_get "COMPILE_CFG" "recursive" "$_bl_salt")
    _bl_write_shebang=$(bl_map_get "COMPILE_CFG" "write_shebang" "$_bl_salt")
    _bl_shebang_val=$(bl_map_get "COMPILE_CFG" "shebang_val" "$_bl_salt")
    _bl_strict=$(bl_map_get "COMPILE_CFG" "strict" "$_bl_salt")

    # Validate required arguments
    if [ -z "$_bl_source_dir" ] || [ -z "$_bl_out_name" ]; then
        printf "\033[1;31m❌ Error:\033[0m Missing required arguments.\n" >&2
        printf "\033[1;33mUsage:\033[0m bl_compile --dir <src> --out-name <name> [--main <main_file>] [--out-dir <dir>] [-v|--verbose] [-r|--recursive] [--no-shebang|--shebang <value>] [-s|--strip [empty|comments|all]]\n" >&2
        bl_cleanup_scope "$_bl_salt"
        return 1
    fi

    # Validate strip mode
    if [ "$_bl_strip_mode" != "none" ] && [ "$_bl_strip_mode" != "empty" ] && [ "$_bl_strip_mode" != "comments" ] && [ "$_bl_strip_mode" != "all" ]; then
        printf "\033[1;31m❌ Error:\033[0m Invalid strip mode '%s'. Valid options: empty, comments, all\n" "$_bl_strip_mode" >&2
        bl_cleanup_scope "$_bl_salt"
        return 1
    fi

    # Check if main file exists (if provided)
    if [ -n "$_bl_main_file" ] && [ ! -f "$_bl_main_file" ]; then
        if [ "$_bl_verbose" -eq 1 ]; then
            printf "  \033[1;33m⚠️  [Skip]\033[0m Main entry file '%s' not found. Skipping compilation.\n" "$_bl_main_file"
        fi
        bl_cleanup_scope "$_bl_salt"
        return 0
    fi

    # Find and store local files using files array
    bl_arr_init "COMPILE_FILES" "$_bl_salt"
    
    _bl_files_found=0
    if [ "$_bl_recursive" -eq 1 ]; then
        for _f in $(find "$_bl_source_dir" -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null | sort); do
            bl_arr_append "COMPILE_FILES" "$_f" "$_bl_salt"
            _bl_files_found=$((_bl_files_found+1))
        done
    else
        for _f in "$_bl_source_dir"/*.sh "$_bl_source_dir"/*.bash; do
            [ -f "$_f" ] || continue
            bl_arr_append "COMPILE_FILES" "$_f" "$_bl_salt"
            _bl_files_found=$((_bl_files_found+1))
        done
    fi

    # Check if we have files to compile
    if [ "$_bl_files_found" -eq 0 ] && [ -z "$_bl_main_file" ]; then
        if [ "$_bl_verbose" -eq 1 ]; then
            printf "  \033[1;33m⚠️  [Skip]\033[0m No source files found in '%s'. Skipping compilation.\n" "$_bl_source_dir"
        fi
        bl_cleanup_scope "$_bl_salt"
        return 0
    fi

    # Create output directory
    _bl_out_dir="${_bl_out_dir%/}"
    mkdir -p "$_bl_out_dir"
    _bl_final_out="$_bl_out_dir/$_bl_out_name"

    # Shebang Resolution
    _bl_shebang=""
    if [ "$_bl_write_shebang" -eq 1 ]; then
        if [ "$_bl_shebang_val" = "auto" ]; then
            _bl_shebang="#!/usr/bin/env sh"
            if [ -n "$_bl_main_file" ]; then
                read -r _bl_first_line < "$_bl_main_file"
                if [ "$(posix_substr "$_bl_first_line" 0 2)" = "#!" ]; then
                    _bl_shebang="$_bl_first_line"
                fi
            fi
        else
            _bl_shebang="$_bl_shebang_val"
        fi

        # Prefix shebang symbol if missing
        if [ "$(posix_substr "$_bl_shebang" 0 2)" != "#!" ]; then
            _bl_shebang="#!${_bl_shebang#\#}"
        fi
    fi

    if [ "$_bl_verbose" -eq 1 ]; then
        printf "📦 \033[1;34mCompiling scripts\033[0m...\n"
        printf "  📁   \033[1;35m[Source Dir]\033[0m      \033[32m%s\033[0m\n" "$_bl_source_dir"
        printf "  📂   \033[1;35m[Output Dir]\033[0m      \033[32m%s\033[0m\n" "$_bl_out_dir"
        printf "  📄   \033[1;35m[Output Name]\033[0m     \033[32m%s\033[0m\n" "$_bl_out_name"
        if [ -n "$_bl_main_file" ]; then
            printf "  🎯   \033[1;35m[Main Entry]\033[0m      \033[32m%s\033[0m\n" "$_bl_main_file"
        else
            printf "  🎯   \033[1;35m[Main Entry]\033[0m      \033[90m(None)\033[0m\n"
        fi
        _bl_rec_str="false"
        [ "$_bl_recursive" -eq 1 ] && _bl_rec_str="true"
        printf "  🔄   \033[1;35m[Recursive]\033[0m       \033[32m%s\033[0m\n" "$_bl_rec_str"
        if [ "$_bl_write_shebang" -eq 1 ]; then
            printf "  📝   \033[1;35m[Shebang]\033[0m         \033[32m%s\033[0m\n" "$_bl_shebang"
        else
            printf "  📝   \033[1;35m[Shebang]\033[0m         \033[90m(None)\033[0m\n"
        fi
        printf "  ⚙️   \033[1;35m[Strip Mode]\033[0m      \033[32m%s\033[0m\n" "$_bl_strip_mode"
        printf "  ⚖️   \033[1;35m[Strict Mode]\033[0m     \033[32m%s\033[0m\n" "$_bl_strict"
    fi

    # Clear output file
    > "$_bl_final_out"

    # Write Shebang
    if [ "$_bl_write_shebang" -eq 1 ]; then
        printf "%s\n\n" "$_bl_shebang" > "$_bl_final_out"
    fi

    # Build sed arguments
    _bl_sed_script="/^#!/d"
    if [ "$_bl_strip_mode" = "empty" ] || [ "$_bl_strip_mode" = "all" ]; then
        _bl_sed_script="${_bl_sed_script};/^[[:space:]]*$/d"
    fi
    if [ "$_bl_strip_mode" = "comments" ] || [ "$_bl_strip_mode" = "all" ]; then
        _bl_sed_script="${_bl_sed_script};/^[[:space:]]*#/d"
    fi

    # Process Remote URLs
    _bl_fetch_failed=0
    eval "_bl_remote_path=\"\$BL_ARR_COMPILE_REMOTE_URLS_${_bl_salt}\""
    if [ -f "$_bl_remote_path" ]; then
        _bl_num_urls=$(tr '\0' '\n' < "$_bl_remote_path" | wc -l | tr -d ' ')
        _bl_ui=0
        while [ "$_bl_ui" -lt "$_bl_num_urls" ]; do
            _bl_url=$(bl_arr_get "COMPILE_REMOTE_URLS" "$_bl_ui" "$_bl_salt")
            [ "$_bl_verbose" -eq 1 ] && printf "  \033[1;33m↳\033[0m \033[1;34m[Remote Include]\033[0m \033[36m%s\033[0m\n" "$_bl_url"
            
            _bl_tmp_fetch=$(mktemp)
            if curl -fsSL "$_bl_url" > "$_bl_tmp_fetch"; then
                printf "# --- Inlined Remote: %s ---\n" "$_bl_url" >> "$_bl_final_out"
                sed -e "$_bl_sed_script" "$_bl_tmp_fetch" >> "$_bl_final_out"
                printf "\n" >> "$_bl_final_out"
            else
                printf "\033[1;31m❌ Error:\033[0m Failed to fetch %s\n" "$_bl_url" >&2
                _bl_fetch_failed=1
                rm -f "$_bl_tmp_fetch"
                break
            fi
            rm -f "$_bl_tmp_fetch"
            _bl_ui=$((_bl_ui+1))
        done
    fi

    # Process Local Files
    _bl_fi=0
    while [ "$_bl_fi" -lt "$_bl_files_found" ]; do
        if [ "$_bl_fetch_failed" -eq 1 ] && [ "$_bl_strict" -eq 1 ]; then
            break
        fi

        _bl_file=$(bl_arr_get "COMPILE_FILES" "$_bl_fi" "$_bl_salt")
        
        # Skip main file if same physical file
        _bl_is_main=0
        if [ -n "$_bl_main_file" ]; then
            if [ "$_bl_file" -ef "$_bl_main_file" ]; then
                _bl_is_main=1
            fi
        fi

        if [ "$_bl_is_main" -eq 0 ]; then
            [ "$_bl_verbose" -eq 1 ] && printf "  \033[1;33m↳\033[0m \033[1;34m[Include]\033[0m \033[36m%s\033[0m\n" "$_bl_file"
            printf "# --- Included: %s ---\n" "$_bl_file" >> "$_bl_final_out"
            sed -e "$_bl_sed_script" "$_bl_file" >> "$_bl_final_out"
            printf "\n" >> "$_bl_final_out"
        fi

        _bl_fi=$((_bl_fi+1))
    done

    # Append Main Entry
    if [ -n "$_bl_main_file" ] && { [ "$_bl_fetch_failed" -eq 0 ] || [ "$_bl_strict" -eq 0 ]; }; then
        [ "$_bl_verbose" -eq 1 ] && printf "  \033[1;35m➜\033[0m  %-15b \033[36m%s\033[0m\n" "\033[1;33m[Main Entry]\033[0m" "$_bl_main_file"
        printf "# --- Main Entry: %s ---\n" "$_bl_main_file" >> "$_bl_final_out"
        sed -e "$_bl_sed_script" "$_bl_main_file" >> "$_bl_final_out"
    fi

    # Finalize
    chmod +x "$_bl_final_out"
    if [ "$_bl_fetch_failed" -eq 1 ]; then
        printf "⚠️  \033[1;33mFinished with warnings:\033[0m Compiled to \033[1;36m%s\033[0m (Some remote files failed to fetch).\n" "$_bl_final_out"
        bl_cleanup_scope "$_bl_salt"
        return 1
    else
        printf "✅  \033[1;32mSuccess:\033[0m Compiled to \033[1;36m%s\033[0m\n" "$_bl_final_out"
        bl_cleanup_scope "$_bl_salt"
        return 0
    fi
}

bl_compile_folder() {
    _bl_salt=$(_bl_gen_salt)
    bl_map_init "COMP_FLDR_CFG" "$_bl_salt"

    bl_map_set "COMP_FLDR_CFG" "source_dir" "" "$_bl_salt"
    bl_map_set "COMP_FLDR_CFG" "recursive" "0" "$_bl_salt"
    bl_map_set "COMP_FLDR_CFG" "verbose" "0" "$_bl_salt"
    bl_map_set "COMP_FLDR_CFG" "strip_mode" "none" "$_bl_salt"
    bl_map_set "COMP_FLDR_CFG" "pass_args" "" "$_bl_salt"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--dir)
                bl_map_set "COMP_FLDR_CFG" "source_dir" "$2" "$_bl_salt"
                shift 2 ;;
            -r|--recursive)
                bl_map_set "COMP_FLDR_CFG" "recursive" "1" "$_bl_salt"
                shift 1 ;;
            -v|--verbose)
                bl_map_set "COMP_FLDR_CFG" "verbose" "1" "$_bl_salt"
                _bl_pass=$(bl_map_get "COMP_FLDR_CFG" "pass_args" "$_bl_salt")
                bl_map_set "COMP_FLDR_CFG" "pass_args" "$_bl_pass -v" "$_bl_salt"
                shift 1 ;;
            -s|--strip)
                if [ -n "$2" ] && [ "$(posix_substr "$2" 0 1)" != "-" ]; then
                    bl_map_set "COMP_FLDR_CFG" "strip_mode" "$2" "$_bl_salt"
                    _bl_pass=$(bl_map_get "COMP_FLDR_CFG" "pass_args" "$_bl_salt")
                    bl_map_set "COMP_FLDR_CFG" "pass_args" "$_bl_pass -s $2" "$_bl_salt"
                    shift 2
                else
                    bl_map_set "COMP_FLDR_CFG" "strip_mode" "all" "$_bl_salt"
                    _bl_pass=$(bl_map_get "COMP_FLDR_CFG" "pass_args" "$_bl_salt")
                    bl_map_set "COMP_FLDR_CFG" "pass_args" "$_bl_pass -s all" "$_bl_salt"
                    shift 1
                fi
                ;;
            *)
                echo "Unknown parameter passed: $1" >&2
                bl_cleanup_scope "$_bl_salt"
                return 1 ;;
        esac
    done

    _bl_source_dir=$(bl_map_get "COMP_FLDR_CFG" "source_dir" "$_bl_salt")
    _bl_recursive=$(bl_map_get "COMP_FLDR_CFG" "recursive" "$_bl_salt")
    _bl_verbose=$(bl_map_get "COMP_FLDR_CFG" "verbose" "$_bl_salt")
    _bl_pass_args=$(bl_map_get "COMP_FLDR_CFG" "pass_args" "$_bl_salt")

    if [ -z "$_bl_source_dir" ]; then
        printf "\033[1;31m❌ Error:\033[0m Missing required source directory.\n" >&2
        printf "\033[1;33mUsage:\033[0m bl_compile_folder --dir <src> [-r|--recursive] [-v|--verbose] [-s|--strip [empty|comments|all]]\n" >&2
        bl_cleanup_scope "$_bl_salt"
        return 1
    fi

    if [ ! -d "$_bl_source_dir" ]; then
        printf "\033[1;31m❌ Error:\033[0m Directory '%s' not found.\n" "$_bl_source_dir" >&2
        bl_cleanup_scope "$_bl_salt"
        return 1
    fi

    _bl_source_dir="${_bl_source_dir%/}"

    bl_arr_init "TARGET_DIRS" "$_bl_salt"
    _bl_dirs_found=0

    if [ "$_bl_recursive" -eq 1 ]; then
        for _d in $(find "$_bl_source_dir" -type d 2>/dev/null | sort); do
            bl_arr_append "TARGET_DIRS" "$_d" "$_bl_salt"
            _bl_dirs_found=$((_bl_dirs_found+1))
        done
    else
        bl_arr_append "TARGET_DIRS" "$_bl_source_dir" "$_bl_salt"
        _bl_dirs_found=1
    fi

    _bl_di=0
    while [ "$_bl_di" -lt "$_bl_dirs_found" ]; do
        _bl_target_dir=$(bl_arr_get "TARGET_DIRS" "$_bl_di" "$_bl_salt")
        
        # Resolve path
        _bl_abs_path=$(realpath "$_bl_target_dir" 2>/dev/null || readlink -f "$_bl_target_dir" 2>/dev/null || echo "$_bl_target_dir")
        _bl_folder_name="${_bl_abs_path##*/}"
        [ -z "$_bl_folder_name" ] && _bl_folder_name="root"

        if [ "$_bl_verbose" -eq 1 ]; then
            printf "\n📂 \033[1;35m[Folder Build]\033[0m Processing directory: \033[1;36m%s\033[0m\n" "$_bl_target_dir"
        fi

        # Execute flat compile for each folder
        bl_compile --dir "$_bl_target_dir" \
                   --out-dir "$_bl_target_dir" \
                   --out-name "$_bl_folder_name" \
                   --no-shebang \
                   $_bl_pass_args
                   
        _bl_di=$((_bl_di+1))
    done

    bl_cleanup_scope "$_bl_salt"
}
