# Loop across internal namespaces to check and confirm exactly which modules
# have loaded without configuration corruption.
bl_info_check() {
# Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_info_check" "bl_registry_get_types" "bl_registry_get_funcs" "bl_registry_get_deps" || return 1

    # Ensure registry is loaded
    if ! declare -p BL_REGISTRY >/dev/null 2>&1; then
        echo -e "\033[1;31m[ERROR]\033[0m BL_REGISTRY is not declared. Did you source lib/core/import.sh?" >&2
        return 1
    fi

    echo -e "\033[1m--- bash-lib Namespace Diagnostics ---\033[0m"
    local all_ok=0

    # Get types and sort them
    local types
    types=$(bl_registry_get_types)
    local sorted_types
    sorted_types=$(echo "$types" | tr ' ' '\n' | sort)

    # Check if a dependency exists — shell function OR system command
    _bl_dep_exists() { declare -f "$1" >/dev/null 2>&1 || command -v "$1" >/dev/null 2>&1; }

    for type in $sorted_types; do
        echo -e "\n\033[1;35m[$type]\033[0m"
        local funcs
        funcs=$(bl_registry_get_funcs "$type")
        local sorted_funcs
        sorted_funcs=$(echo "$funcs" | tr ' ' '\n' | sort)

        for func in $sorted_funcs; do
            local deps
            deps=$(bl_registry_get_deps "$func")
            local dep_ok=true
            local -a dep_statuses=()

            # Split dependencies by "|" and verify their load status
            local OLD_IFS="$IFS"
            IFS='|'
            for dep in $deps; do
                if [ -n "$dep" ]; then
                    if _bl_dep_exists "$dep"; then
                        dep_statuses+=("[\033[1;32m$dep (ok)\033[0m]")
                    else
                        dep_statuses+=("[\033[1;31m$dep (MISSING)\033[0m]")
                        dep_ok=false
                    fi
                fi
            done
            IFS="$OLD_IFS"

            if declare -f "$func" >/dev/null; then
                if $dep_ok; then
                    echo -e "  \033[1;32m✓\033[0m $func \033[1;32m(Loaded & OK)\033[0m"
                else
                    echo -e "  \033[1;33m⚠\033[0m $func \033[1;31m(Loaded, but dependency is missing!)\033[0m"
                    all_ok=1
                fi
            else
                echo -e "  \033[1;31m✗\033[0m $func \033[38;5;244m(Not sourced/loaded)\033[0m"
            fi

            # Print detailed dependency lists if they exist (runs for loaded & unloaded alike)
            if [ ${#dep_statuses[@]} -gt 0 ]; then
                echo -e "      deps: ${dep_statuses[*]}"
            fi
        done
    done

    return $all_ok
}

bl_info_menu() {
# Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_info_menu" "bl_registry_get_types" "bl_registry_get_funcs" "bl_registry_get_deps" || return 1

    # Ensure registry is loaded
    if ! declare -p BL_REGISTRY >/dev/null 2>&1; then
        echo -e "\033[1;31m[ERROR]\033[0m BL_REGISTRY is not declared. Did you source lib/core/import.sh?" >&2
        return 1
    fi

    # Inner usage/details retriever
    bl_info_get_details() {
        local func="$1"
        case "${func}" in
            import)
                echo -e "\033[1;34mDescription:\033[0m Sources local .sh/.bash files or extensionless bash-shebang files matching a glob pattern."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mimport [-v] [--strict] <pattern> [pattern...]\033[0m"
                echo -e "\033[1;36mExamples:\033[0m"
                echo -e "  \033[1;33mimport lib/*\033[0m          Source all eligible files under lib/ (recursively)"
                echo -e "  \033[1;33mimport lib/ui lib/core\033[0m Multiple dirs at once"
                echo -e "  \033[1;33mimport --strict lib/*\033[0m Fails (exit 1) immediately if any file fails to source"
                echo -e "  \033[1;33mimport /abs/path/*.sh\033[0m  Absolute paths supported"
                echo -e "\033[1;35mNote:\033[0m        Relative patterns resolve from \$PWD. Deduplicates automatically."
                echo -e "\033[1;36mBacked by:\033[0m   bl_import_local"
                ;;
            bl_import)
                echo -e "\033[1;34mDescription:\033[0m Sources remote library files from GitHub via BL_FILE_REGISTRY."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_import [-v] [--strict] <pattern>\033[0m"
                echo -e "\033[1;36mExamples:\033[0m"
                echo -e "  \033[1;33mbl_import \"*\"\033[0m         Import all registered remote files"
                echo -e "  \033[1;33mbl_import --strict \"*\"\033[0m  Import all, but exit on the first file that fails to download"
                echo -e "  \033[1;33mbl_import \"ui/*\"\033[0m      Import all ui/ remote files"
                echo -e "  \033[1;33mbl_import \"core/colors.sh\"\033[0m  Import a specific remote file"
                echo -e "\033[1;35mRequires:\033[0m    curl, BL_FILE_REGISTRY populated"
                ;;
            bl_import_local)
                echo -e "\033[1;34mDescription:\033[0m Core implementation behind import(). Sources local .sh/.bash and bash-shebang files."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_import_local [-v] [--strict] <pattern> [pattern...]\033[0m"
                echo -e "\033[1;35mEligible files:\033[0m .sh, .bash extensions, or extensionless files with #!/*bash shebang."
                echo -e "\033[1;35mNote:\033[0m        Deduplicates — same file is never sourced twice per call."
                ;;
            bl_compile)
                echo -e "\033[1;34mDescription:\033[0m Bundles a directory of scripts into a single compiled script file."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_compile --dir <src> --out-name <name> [--main <main_file>] [--out-dir <dir>] [-v|--verbose] [-r|--recursive] [--no-shebang|--shebang <value>] [-s|--strip [empty|comments|all]] [--strict] [--lib-curl [start <urls...> stop]]\033[0m"
                echo -e "\033[1;36mExamples:\033[0m"
                echo -e "  \033[1;33mbl_compile --dir lib/ --out-name bash-lib.sh\033[0m  Compiles the library into one file"
                echo -e "  \033[1;33mbl_compile --dir lib/ --out-name cplay --lib-curl start \"url1\" \"url2\" stop\033[0m  Inlines remote scripts"
                echo -e "  \033[1;33mbl_compile --dir lib/ --out-name cplay --strict\033[0m  Fails build if any fetch fails"
                ;;
            bl_matrix_filler)
                echo -e "\033[1;34mDescription:\033[0m Terminal digital rain animation effect (Matrix style) with persistent fading trails."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_matrix_filler [--mode classic|rain|fade] [--start-color N] [--end-color N] [--start-hex HEX] [--end-hex HEX] [--lang j,c,k] [--density N] [--duration SEC]\033[0m"
                echo -e "\033[1;36mArguments:\033[0m"
                echo -e "  \033[1;33m--mode\033[0m        'classic' (default), 'rain', or 'fade' for smooth RGB blending."
                echo -e "  \033[1;33m--start-color\033[0m Default tput start color index (default: 2/green)."
                echo -e "  \033[1;33m--end-color\033[0m   Default tput end color index (default: 7/white)."
                echo -e "  \033[1;33m--start-hex\033[0m   Trail color gradient hex (e.g., '#00FF00')."
                echo -e "  \033[1;33m--end-hex\033[0m     Head/Splash color gradient hex."
                echo -e "  \033[1;33m--lang\033[0m        Characters: 'j' (Japanese), 'c' (Chinese), 'k' (Korean)."
                echo -e "  \033[1;33m--density\033[0m     Spawn chance ratio (lower is denser, default 50)."
                echo -e "  \033[1;33m--duration\033[0m    Auto-exit timeout in seconds."
                echo -e "\033[1;35mBehaviors:\033[0m    Fills the terminal with falling characters. Exits on any key press."
                echo -e "\033[1;36mDependencies:\033[0m tput"
                ;;
            bl_square_progress)
                echo -e "\033[1;34mDescription:\033[0m Renders a square/rectangular progress indicator that fills up block by block."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_square_progress [-l label] [-t] [-w N] [-H N] [-fw] [--brackets] [--color-mode mode] [--start HEX] [--end HEX]\033[0m"
                echo -e "\033[1;36mArguments:\033[0m"
                echo -e "  \033[1;33m-l | --label\033[0m      Set the header label text (defaults to 'Progress')."
                echo -e "  \033[1;33m-t | --tagged\033[0m     Enable tagged Mode B. Parses stdin streams dynamically:"
                echo -e "                      - \033[1;32mP:[0-100]\033[0m updates percentage."
                echo -e "                      - \033[1;32mM:[message]\033[0m updates the status text."
                echo -e "  \033[1;33m-w | --width\033[0m      Set grid width in columns (default: 10)."
                echo -e "  \033[1;33m-H | --height\033[0m     Set grid height in rows (default: 10)."
                echo -e "  \033[1;33m-fw | --full-width\033[0m Auto-expand grid to fill the full terminal width."
                echo -e "  \033[1;33m--brackets\033[0m        Render bracket decorations around each row."
                echo -e "  \033[1;33m--color-mode\033[0m      'global' (default, whole grid shifts color) or 'position' (static left-to-right gradient)."
                echo -e "  \033[1;33m--start / --end\033[0m   Start/end transition color hex codes."
                echo -e "\033[1;36mDependencies:\033[0m  bl_hex_to_rgb, bl_check_deps"
                ;;
            bl_spiral_progress)
                echo -e "\033[1;34mDescription:\033[0m Renders a rectangular progress indicator that fills up in a spiral (inward or outward)."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_spiral_progress [-l label] [-t] [-w N] [-H N] [-fw] [--brackets] [--direction in|out] [--color-mode mode] [--start HEX] [--end HEX]\033[0m"
                echo -e "\033[1;36mArguments:\033[0m"
                echo -e "  \033[1;33m--direction\033[0m       'in' (default, outer edges to center) or 'out' (center to outer edges)."
                echo -e "  \033[1;33m-l | --label\033[0m      Set the header label text (defaults to 'Progress')."
                echo -e "  \033[1;33m-t | --tagged\033[0m     Enable tagged Mode B. Parses stdin streams dynamically."
                echo -e "  \033[1;33m-w | --width\033[0m      Set grid width in columns (default: 10)."
                echo -e "  \033[1;33m-H | --height\033[0m     Set grid height in rows (default: 10)."
                echo -e "  \033[1;33m-fw | --full-width\033[0m Auto-expand grid to fill the full terminal width."
                echo -e "  \033[1;33m--brackets\033[0m        Render bracket decorations around each row."
                echo -e "  \033[1;33m--color-mode\033[0m      'global' (default) or 'position' (static gradient along spiral order)."
                echo -e "  \033[1;33m--start / --end\033[0m   Start/end transition color hex codes."
                echo -e "\033[1;36mDependencies:\033[0m  bl_hex_to_rgb, bl_check_deps"
                ;;
            bl_progress_bar)
                echo -e "\033[1;34mDescription:\033[0m Renders responsive percentage progress bars with selective rendering components."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_progress_bar [-l label] [-w N] [-fw] [--status] [--log] [--log-height n] [--color-mode mode] [--start HEX] [--end HEX]\033[0m"
                echo -e "\033[1;36mArguments:\033[0m"
                echo -e "  \033[1;33m-l | --label\033[0m      Set the header label text (defaults to 'Progress')."
                echo -e "  \033[1;33m-w | --width\033[0m      Set the rendering width of the bar."
                echo -e "  \033[1;33m-fw | --full-width\033[0m Expand the bar to fill the full terminal width."
                echo -e "  \033[1;33m--status\033[0m          Enable rendering of the 'M:[status]' message line."
                echo -e "  \033[1;33m--log\033[0m             Enable rendering of scrolling logs from 'L:[log]' tags."
                echo -e "  \033[1;33m--log-height\033[0m      Explicitly set the number of log lines (implies --log, defaults to 3)."
                echo -e "  \033[1;33m--color-mode\033[0m      'global' (whole bar shifts color, default) or 'position' (static left-to-right gradient)."
                echo -e "  \033[1;33m--start / --end\033[0m   Start/end transition color hex codes."
                echo -e "\033[1;35mBehaviors:\033[0m    Automatically switches to Tagged parsing mode if --status or --log are passed."
                echo -e "\033[1;36mDependencies:\033[0m  bl_hex_to_rgb, bl_check_deps"
                ;;
            bl_terrain_loader)
                echo -e "\033[1;34mDescription:\033[0m Renders an animated 2D terrain/chunk loading grid. Blocks fill one at a time using configurable patterns and color modes."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_terrain_loader [-l label] [-w N] [-h N] [-fw] [-fh] [--pattern mode] [--minecraft] [--color-mode mode] [--start HEX] [--end HEX]\033[0m"
                echo -e "\033[1;36mArguments:\033[0m"
                echo -e "  \033[1;33m-l | --label\033[0m        Display label shown above the grid (default: 'Generating Terrain...')."
                echo -e "  \033[1;33m-w | --width\033[0m         Grid width in characters (default: 40)."
                echo -e "  \033[1;33m-h | --height\033[0m        Grid height in rows (default: 15)."
                echo -e "  \033[1;33m-fw | --full-width\033[0m   Auto-set width to full terminal column count."
                echo -e "  \033[1;33m-fh | --full-height\033[0m  Auto-set height to terminal line count minus 2."
                echo -e "  \033[1;33m--pattern\033[0m             Fill pattern: 'random' (default), 'center-out', or 'minecraft'."
                echo -e "  \033[1;33m--minecraft\033[0m           Shortcut for --pattern minecraft. Enables fuzzy center-out expansion with"
                echo -e "                        random lag-spike blocks (15% chance), just like real Minecraft chunk loading."
                echo -e "  \033[1;33m--color-mode\033[0m          'time' (blocks colored by fill order, default), 'position' (left-to-right gradient), or 'global' (solid shifting color)."
                echo -e "  \033[1;33m--start / --end\033[0m       Start/end gradient hex colors (default: yellow → cyan)."
                echo -e "  \033[1;33m--fg\033[0m                  Foreground ANSI color index for minecraft/fallback mode."
                echo -e "\033[1;35mInput:\033[0m        Reads plain numbers 0-100 or tagged 'P:[0-100]' from stdin."
                echo -e "\033[1;36mDependencies:\033[0m bl_hex_to_rgb, bl_check_deps"
                ;;
            bl_check_deps)
                echo -e "\033[1;34mDescription:\033[0m Verification utility that runs before a function executes to guard against missing dependencies."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_check_deps <caller_name> <dep1> [dep2 ...]\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mcaller_name\033[0m     The name of the function requiring dependencies (for diagnostic logging)."
                echo -e "  \033[1;33mdep1 / dep2\033[0m     Names of functions to verify in environment memory."
                echo -e "\033[1;35mReturn Code:\033[0m  0 if all dependencies exist, 1 if any dependency is missing."
                ;;
            bl_hex_to_rgb)
                echo -e "\033[1;34mDescription:\033[0m Color parser converting hex code colors to terminal-usable RGB decimal channels."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_hex_to_rgb <HEX_STRING>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mHEX_STRING\033[0m      Hex color string with or without '#'. E.g., '#00FF00' or '00FF00'."
                echo -e "\033[1;35mOutputs:\033[0m      Space-separated red, green, and blue decimal integers on stdout. E.g., '0 255 0'."
                ;;
            bl_version_compare)
                echo -e "\033[1;34mDescription:\033[0m Left-to-right component-wise semantic version comparison utility."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_version_compare <ver1> <ver2>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mver1\033[0m            First version (e.g. '1.2.0.1')."
                echo -e "  \033[1;33mver2\033[0m            Second version to compare against (e.g. '1.3.0')."
                echo -e "\033[1;35mOutputs:\033[0m      Outputs comparison status: 'equal', 'major update', 'minor update', 'patch update', 'hotfix update', or 'downgrade'."
                ;;
            bl_parse_selection)
                echo -e "\033[1;34mDescription:\033[0m Splits menu selection inputs and expands range expressions (e.g. '1-4' into '1 2 3 4')."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_parse_selection <input_string> [delimiter]\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33minput_string\033[0m    Input selection string. E.g., '1,3-5'."
                echo -e "  \033[1;33mdelimiter\033[0m       Custom delimiter separating selections (defaults to ',')."
                echo -e "\033[1;35mOutputs:\033[0m      Space-separated expanded token numbers. Returns exit code 1 on parsing syntax errors."
                ;;
            bl_expand_selection)
                echo -e "\033[1;34mDescription:\033[0m Keyword-aware expansion utility. Translates 'all' keywords into numerical sequences."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_expand_selection <max_index> <parsed_inputs...>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mmax_index\033[0m       The maximum item index available in the current list."
                echo -e "  \033[1;33mparsed_inputs\033[0m   List of raw parsed tokens."
                echo -e "\033[1;35mOutputs:\033[0m      Space-separated numbers containing expanded sequences."
                ;;
            bl_validate_selection)
                echo -e "\033[1;34mDescription:\033[0m Boundary checks menu options to ensure all selected items are valid."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_validate_selection <max_index> <indices...>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mmax_index\033[0m       The maximum item index allowed."
                echo -e "  \033[1;33mindices\033[0m         One or more expanded numbers to validate."
                echo -e "\033[1;35mReturn Code:\033[0m  0 if all numbers are between 1 and max_index (inclusive); 1 otherwise."
                ;;
            bl_file_count_feeder_)
                echo -e "\033[1;34mDescription:\033[0m Directory polling engine. Watches matching marker file creation to feed sync ratios."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_file_count_feeder_ <total> [hz] [dir] [pattern]\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mtotal\033[0m           Total expected file count matching the pattern."
                echo -e "  \033[1;33mhz\033[0m              Polling frequency in Hertz (default: 10)."
                echo -e "  \033[1;33mdir\033[0m             Directory path to scan (defaults to registry path)."
                echo -e "  \033[1;33mpattern\033[0m         File match pattern. E.g., '*.done'."
                echo -e "\033[1;35mOutputs:\033[0m      Standard stream of current file counts."
                ;;
            _bl_count_percent_emitter_)
                echo -e "\033[1;34mDescription:\033[0m Math streaming emitter translating raw completed integers into percentage tokens."
                echo -e "\033[1;32mUsage:\033[0m       \033[33m_bl_count_percent_emitter_ <total> [flag]\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mtotal\033[0m           Denominator representing 100% completion."
                echo -e "  \033[1;33mflag\033[0m            Set 'tagged' or '--tagged' to output tagged progress format (e.g. 'P:50') instead of raw strings."
                echo -e "\033[1;35mOutputs:\033[0m      Percentage flow stream."
                ;;
            bl_file_log_feeder_)
                echo -e "\033[1;34mDescription:\033[0m Tails a log file and reformats the last line as a progress bar message feed."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_file_log_feeder_ <logfile> [hz] [prefix]\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mlogfile\033[0m         Path to log file being monitored."
                echo -e "  \033[1;33mhz\033[0m              Tail polling frequency in Hertz (default: 5)."
                echo -e "  \033[1;33mprefix\033[0m          Custom log output prefix (default: 'M:')."
                echo -e "\033[1;35mOutputs:\033[0m      Stream of status messages prefixed with the given prefix."
                ;;
            bl_info_check)
                echo -e "\033[1;34mDescription:\033[0m Core environment diagnostic utility. Sweeps loaded memory to verify framework functions and dependencies."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_info_check\033[0m"
                echo -e "\033[1;35mBehaviors:\033[0m    Outputs namespace categories and color-coded status checks grouped dynamically."
                ;;
            bl_info_menu)
                echo -e "\033[1;34mDescription:\033[0m Launches an interactive terminal UI menu containing full documentation."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_info_menu\033[0m"
                echo -e "\033[1;36mDependencies:\033[0m bl_registry_get_types, bl_registry_get_funcs, bl_registry_get_deps"
                ;;
            bl_registry_get_types)
                echo -e "\033[1;34mDescription:\033[0m Parses the BL_REGISTRY and returns a space-separated list of all available namespaces/types (e.g., 'core info ui')."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_registry_get_types\033[0m"
                echo -e "\033[1;35mOutputs:\033[0m      Unique types directly to stdout."
                ;;
            bl_registry_get_funcs)
                echo -e "\033[1;34mDescription:\033[0m Parses the BL_REGISTRY for a specific namespace and returns its associated functions."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_registry_get_funcs <namespace>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mnamespace\033[0m       The group to lookup (e.g., 'ui', 'core')."
                echo -e "\033[1;35mOutputs:\033[0m      Space-separated function names."
                ;;
            bl_registry_get_deps)
                echo -e "\033[1;34mDescription:\033[0m Returns the dependency string for a specific function."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_registry_get_deps <function_name>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mfunction_name\033[0m   The name of the function to check."
                echo -e "\033[1;35mOutputs:\033[0m      Pipe-separated dependencies (e.g., 'curl|jq'), or empty string if none."
                ;;
            bl_bash_tutor)
                echo -e "\033[1;34mDescription:\033[0m Interactive bash interpreter options and scripting lessons manual."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_bash_tutor\033[0m"
                echo -e "\033[1;35mBehaviors:\033[0m    Launches tutor menu covering set modes, string expansions, quoting, and scope declarations."
                ;;
            bl_pid_status)
                echo -e "\033[1;34mDescription:\033[0m [Planned] Queries process directory state via /proc/\$PID or signal kill -0."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_pid_status <pid>\033[0m"
                echo -e "\033[1;35mOutputs:\033[0m      Status string representing process states: 'RUNNING', 'SUCCESS', or 'FAILED'."
                ;;
            bl_pid_reap)
                echo -e "\033[1;34mDescription:\033[0m [Planned] Non-blocking tracking PID scavenger sweep."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_pid_reap\033[0m"
                echo -e "\033[1;35mBehaviors:\033[0m    Iterates over background job registries, reaping dead process vectors and harvesting exit codes."
                ;;
            bl_pid_store)
                echo -e "\033[1;34mDescription:\033[0m Stores a background PID in the global registry."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_pid_store <name> <pid>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mname\033[0m            Identifier name for the background process."
                echo -e "  \033[1;33mpid\033[0m             Process ID."
                ;;
            bl_pid_wait)
                echo -e "\033[1;34mDescription:\033[0m Waits for a specific registered background process to finish and unsets it."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_pid_wait <name>\033[0m"
                echo -e "\033[1;36mParameters:\033[0m"
                echo -e "  \033[1;33mname\033[0m            Identifier name of the process."
                ;;
            bl_terrain_loader_opt)
                echo -e "\033[1;34mDescription:\033[0m Experimental optimized terrain loader (delegates to bl_terrain_loader for now)."
                echo -e "\033[1;32mUsage:\033[0m       \033[33mbl_terrain_loader_opt [args...]\033[0m"
                ;;
            *)
                echo -e "\033[1;34mDescription:\033[0m [Planned] Details and usage will be added upon implementation."
                local deps
                deps=$(bl_registry_get_deps "$func")
                if [[ -n "$deps" ]]; then
                    echo -e "\033[1;36mDependencies:\033[0m $deps"
                fi
                ;;
        esac
    }

    local types
    types=$(bl_registry_get_types)
    local -a sorted_types
    read -r -a sorted_types < <(echo "$types" | tr ' ' '\n' | sort | tr '\n' ' ')

    while true; do
        clear
        echo -e "\033[1;35m=========================================\033[0m"
        echo -e "\033[1;36m       BASH-LIB EXPLORER MANUAL          \033[0m"
        echo -e "\033[1;35m=========================================\033[0m"
        echo -e "Select a category to explore:\n"
        
        for i in "${!sorted_types[@]}"; do
            printf "  \033[1;33m%d)\033[0m %s\n" "$((i+1))" "${sorted_types[i]}"
        done
        echo -e "\n  \033[1;31mx)\033[0m Exit Browser"
        echo -e "\033[1;35m-----------------------------------------\033[0m"
        read -rp "Select an option: " cat_opt

        if [[ "$cat_opt" == "x" || "$cat_opt" == "X" ]]; then
            break
        fi

        if [[ "$cat_opt" =~ ^[0-9]+$ ]] && (( cat_opt > 0 && cat_opt <= ${#sorted_types[@]} )); then
            local sel_cat="${sorted_types[$((cat_opt-1))]}"
            
            while true; do
                clear
                echo -e "\033[1;35m=========================================\033[0m"
                echo -e "Category: \033[1;32m[$sel_cat]\033[0m"
                echo -e "\033[1;35m=========================================\033[0m"
                
                local funcs
                funcs=$(bl_registry_get_funcs "$sel_cat")
                local -a sorted_funcs
                read -r -a sorted_funcs < <(echo "$funcs" | tr ' ' '\n' | sort | tr '\n' ' ')

                for i in "${!sorted_funcs[@]}"; do
                    local f="${sorted_funcs[i]}"
                    local load_status="\033[1;31m✗\033[0m"
                    if declare -f "$f" >/dev/null; then
                        load_status="\033[1;32m✓\033[0m"
                    fi
                    printf "  \033[1;33m%d)\033[0m %b %s\n" "$((i+1))" "$load_status" "$f"
                done
                echo -e "\n  \033[1;31mb)\033[0m Back to Categories"
                echo -e "\033[1;35m-----------------------------------------\033[0m"
                read -rp "Select a function to view details: " func_opt

                if [[ "$func_opt" == "b" || "$func_opt" == "B" ]]; then
                    break
                fi

                if [[ "$func_opt" =~ ^[0-9]+$ ]] && (( func_opt > 0 && func_opt <= ${#sorted_funcs[@]} )); then
                    local sel_func="${sorted_funcs[$((func_opt-1))]}"
                    clear
                    echo -e "\033[1;35m=========================================\033[0m"
                    echo -e "Function: \033[1;32m$sel_func\033[0m"
                    echo -e "\033[1;35m=========================================\033[0m"
                    bl_info_get_details "$sel_func"
                    echo -e "\033[1;35m=========================================\033[0m"
                    read -rp "Press Enter to return to function list..."
                fi
            done
        fi
    done
}
