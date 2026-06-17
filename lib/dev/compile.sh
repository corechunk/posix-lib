#!/usr/bin/env bash

# 📦 bl_compile
# Compiles a directory of bash/sh scripts into a single monolithic script file.

bl_compile() {
    local source_dir=""
    local out_name=""
    local main_file=""
    local out_dir="./build"
    local verbose=0
    local strip_mode="none"
    local recursive=0
    local write_shebang=1
    local shebang_val="auto"
    local strict=0
    local -a compile_remote_urls=()

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -d|--dir) source_dir="$2"; shift 2 ;;
            -o|--out-name) out_name="$2"; shift 2 ;;
            -m|--main) main_file="$2"; shift 2 ;;
            --out-dir) out_dir="$2"; shift 2 ;;
            -v|--verbose) verbose=1; shift 1 ;;
            -r|--recursive) recursive=1; shift 1 ;;
            --no-shebang) write_shebang=0; shift 1 ;;
            --strict) strict=1; shift 1 ;;
            --lib-curl)
                shift
                if [[ "$1" == "start" ]]; then
                    shift
                    while [[ "$#" -gt 0 && "$1" != "stop" ]]; do
                        compile_remote_urls+=("$1")
                        shift
                    done
                    [[ "$1" == "stop" ]] && shift
                else
                    compile_remote_urls+=("$1")
                    shift
                fi
                ;;
            --shebang)
                if [[ "$2" == "false" || "$2" == "none" ]]; then
                    write_shebang=0
                    shift 2
                else
                    write_shebang=1
                    shebang_val="$2"
                    shift 2
                fi
                ;;
            -s|--strip)
                if [[ -n "$2" && "$2" != -* ]]; then
                    strip_mode="$2"
                    shift 2
                else
                    strip_mode="all"
                    shift 1
                fi
                ;;
            *) echo "Unknown parameter passed: $1"; return 1 ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$source_dir" || -z "$out_name" ]]; then
        echo -e "\033[1;31m❌ Error:\033[0m Missing required arguments."
        echo -e "\033[1;33mUsage:\033[0m bl_compile --dir <src> --out-name <name> [--main <main_file>] [--out-dir <dir>] [-v|--verbose] [-r|--recursive] [--no-shebang|--shebang <value>] [-s|--strip [empty|comments|all]]"
        return 1
    fi

    # Validate strip mode if set
    if [[ "$strip_mode" != "none" && "$strip_mode" != "empty" && "$strip_mode" != "comments" && "$strip_mode" != "all" ]]; then
        echo -e "\033[1;31m❌ Error:\033[0m Invalid strip mode '$strip_mode'. Valid options: empty, comments, all"
        return 1
    fi

    # Find all .sh and .bash files and sort them to ensure consistent builds
    local files=()
    # We drop -print0 and -d to maintain Zsh compatibility when sourced.
    local find_cmd=("find" "$source_dir")
    if [[ "$recursive" -eq 0 ]]; then
        find_cmd+=("-maxdepth" "1")
    fi
    find_cmd+=("-type" "f" "(" "-name" "*.sh" "-o" "-name" "*.bash" ")")

    while IFS= read -r file || [[ -n "$file" ]]; do
        files+=("$file")
    done < <("${find_cmd[@]}" | sort)

    # Check if main file exists (if provided)
    if [[ -n "$main_file" && ! -f "$main_file" ]]; then
        if [[ "$verbose" -eq 1 ]]; then
            echo -e "  \033[1;33m⚠️  [Skip]\033[0m Main entry file '$main_file' not found. Skipping compilation."
        fi
        return 0
    fi

    # Check if we have any files at all to compile
    if [[ "${#files[@]}" -eq 0 && -z "$main_file" ]]; then
        if [[ "$verbose" -eq 1 ]]; then
            echo -e "  \033[1;33m⚠️  [Skip]\033[0m No source files found in '$source_dir'. Skipping compilation."
        fi
        return 0
    fi

    # Create output directory safely
    out_dir="${out_dir%/}" # Strip trailing slash if present to avoid double slashes
    mkdir -p "$out_dir"
    local final_out="$out_dir/$out_name"
    
    # --- Shebang Intelligence ---
    local shebang=""
    if [[ "$write_shebang" -eq 1 ]]; then
        if [[ "$shebang_val" == "auto" ]]; then
            shebang="#/usr/bin/env bash" # Default shebang path fallback
            if [[ -n "$main_file" ]]; then
                local first_line
                read -r first_line < "$main_file"
                if [[ "$first_line" == "#!"* ]]; then
                    shebang="$first_line"
                fi
            fi
        else
            shebang="$shebang_val"
        fi

        # Zsh shebang correction: ensure we use #! shebang formatting.
        if [[ "$shebang" != "#!"* ]]; then
            shebang="#!${shebang#\#}"
        fi
    fi

    if [[ "$verbose" -eq 1 ]]; then
        printf "📦 \033[1;34mCompiling scripts\033[0m...\n"
        echo -e "  📁   \033[1;35m[Source Dir]\033[0m      \033[32m$source_dir\033[0m"
        echo -e "  📂   \033[1;35m[Output Dir]\033[0m      \033[32m$out_dir\033[0m"
        echo -e "  📄   \033[1;35m[Output Name]\033[0m     \033[32m$out_name\033[0m"
        if [[ -n "$main_file" ]]; then
            echo -e "  🎯   \033[1;35m[Main Entry]\033[0m      \033[32m$main_file\033[0m"
        else
            echo -e "  🎯   \033[1;35m[Main Entry]\033[0m      \033[90m(None)\033[0m"
        fi
        echo -e "  🔄   \033[1;35m[Recursive]\033[0m       \033[32m$([[ $recursive -eq 1 ]] && echo "true" || echo "false")\033[0m"
        if [[ "$write_shebang" -eq 1 ]]; then
            echo -e "  📝   \033[1;35m[Shebang]\033[0m         \033[32m$shebang\033[0m"
        else
            echo -e "  📝   \033[1;35m[Shebang]\033[0m         \033[90m(None)\033[0m"
        fi
        echo -e "  ⚙️   \033[1;35m[Strip Mode]\033[0m      \033[32m$strip_mode\033[0m"
        echo -e "  ⚖️   \033[1;35m[Strict Mode]\033[0m     \033[32m$strict\033[0m"
    fi

    # Initialize/clear the output file
    > "$final_out"

    # Write shebang if enabled
    if [[ "$write_shebang" -eq 1 ]]; then
        echo "$shebang" > "$final_out"
        echo "" >> "$final_out"
    fi

    # Build sed arguments dynamically based on strip mode
    local sed_args=("-e" "/^#!/d")
    if [[ "$strip_mode" == "empty" || "$strip_mode" == "all" ]]; then
        sed_args+=("-e" "/^[[:space:]]*$/d")
    fi
    if [[ "$strip_mode" == "comments" || "$strip_mode" == "all" ]]; then
        sed_args+=("-e" "/^[[:space:]]*#/d")
    fi
# Process Remote URLs (First)
local fetch_failed=0
for url in "${compile_remote_urls[@]}"; do
    [[ "$verbose" -eq 1 ]] && echo -e "  \033[1;33m↳\033[0m \033[1;34m[Remote Include]\033[0m \033[36m$url\033[0m"

    local tmp_fetch
    tmp_fetch=$(mktemp)
    curl -fsSL "$url" > "$tmp_fetch"
    local ec=$?

    if [[ $ec -ne 0 ]]; then
        echo -e "\033[1;31m❌ Error:\033[0m Failed to fetch $url" >&2
        fetch_failed=1
        rm -f "$tmp_fetch"
        break
    fi

    echo "# --- Inlined Remote: $url ---" >> "$final_out"
    sed "${sed_args[@]}" "$tmp_fetch" >> "$final_out"
    echo "" >> "$final_out"
    rm -f "$tmp_fetch"
done

for file in "${files[@]}"; do
    # If fetch failed and in strict mode, abort local processing.
    if [[ "$fetch_failed" -eq 1 && "$strict" -eq 1 ]]; then
        break
    fi

    # Skip the main file (-ef checks if they point to the same physical file safely)
        if [[ -z "$main_file" || ! "$file" -ef "$main_file" ]]; then
            [[ "$verbose" -eq 1 ]] && echo -e "  \033[1;33m↳\033[0m \033[1;34m[Include]\033[0m \033[36m$file\033[0m"
            echo "# --- Included: $file ---" >> "$final_out"
            # Dump content but strip out shebangs and comments/empty lines according to strip mode
            sed "${sed_args[@]}" "$file" >> "$final_out"
            echo "" >> "$final_out"
        fi
    done

    # --- Append Main Entry ---
    if [[ -n "$main_file" ]]; then
        [[ "$verbose" -eq 1 ]] && printf "  \033[1;35m➜\033[0m  %-15b \033[36m%s\033[0m\n" "\033[1;33m[Main Entry]\033[0m" "$main_file"
        echo "# --- Main Entry: $main_file ---" >> "$final_out"
        sed "${sed_args[@]}" "$main_file" >> "$final_out"
    fi
    
    # Finalize
    chmod +x "$final_out"
    if [[ "$fetch_failed" -eq 1 ]]; then
        echo -e "⚠️  \033[1;33mFinished with warnings:\033[0m Compiled to \033[1;36m$final_out\033[0m (Some remote files failed to fetch)."
        return 1
    else
        echo -e "✅  \033[1;32mSuccess:\033[0m Compiled to \033[1;36m$final_out\033[0m"
        return 0
    fi
}

bl_compile_folder() {
    local source_dir=""
    local recursive=0
    local verbose=0
    local strip_mode="none"

    # Parse arguments for this function, gathering arguments to pass downstream
    local pass_args=()

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -d|--dir) source_dir="$2"; shift 2 ;;
            -r|--recursive) recursive=1; shift 1 ;;
            -v|--verbose) verbose=1; pass_args+=("-v"); shift 1 ;;
            -s|--strip)
                if [[ -n "$2" && "$2" != -* ]]; then
                    strip_mode="$2"
                    pass_args+=("-s" "$2")
                    shift 2
                else
                    strip_mode="all"
                    pass_args+=("-s" "all")
                    shift 1
                fi
                ;;
            *) echo "Unknown parameter passed: $1"; return 1 ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$source_dir" ]]; then
        echo -e "\033[1;31m❌ Error:\033[0m Missing required source directory."
        echo -e "\033[1;33mUsage:\033[0m bl_compile_folder --dir <src> [-r|--recursive] [-v|--verbose] [-s|--strip [empty|comments|all]]"
        return 1
    fi

    # Check if source directory exists
    if [[ ! -d "$source_dir" ]]; then
        echo -e "\033[1;31m❌ Error:\033[0m Directory '$source_dir' not found."
        return 1
    fi

    # Normalize source dir (strip trailing slash)
    source_dir="${source_dir%/}"

    # Build target directories list
    local target_dirs=()
    if [[ "$recursive" -eq 1 ]]; then
        # Recursively find all directories under the source directory
        while IFS= read -r dir || [[ -n "$dir" ]]; do
            target_dirs+=("$dir")
        done < <(find "$source_dir" -type d | sort)
    else
        target_dirs+=("$source_dir")
    fi

    # Compile each directory
    for target_dir in "${target_dirs[@]}"; do
        # Safely resolve absolute path to extract leaf folder name (handles "." and absolute paths)
        local abs_path
        abs_path=$(realpath "$target_dir" 2>/dev/null || readlink -f "$target_dir" 2>/dev/null || echo "$target_dir")
        local folder_name="${abs_path##*/}"
        if [[ -z "$folder_name" ]]; then
            folder_name="root"
        fi

        if [[ "$verbose" -eq 1 ]]; then
            echo -e "\n📂 \033[1;35m[Folder Build]\033[0m Processing directory: \033[1;36m$target_dir\033[0m"
        fi

        # Execute bl_compile without -r (flat compile for each folder), and with --no-shebang
        bl_compile --dir "$target_dir" \
                   --out-dir "$target_dir" \
                   --out-name "$folder_name" \
                   --no-shebang \
                   "${pass_args[@]}"
    done
}
