# Loop across internal namespaces to check and confirm exactly which modules
# have loaded without configuration corruption.
bl_info_check() {
    # Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_info_check" "bl_registry_get_types" "bl_registry_get_funcs" "bl_registry_get_deps" || return 1

    # Ensure registry is loaded using the underlying map path variable
    if [ -z "$BL_MAP_BL_REGISTRY_" ]; then
        printf "\033[1;31m[ERROR]\033[0m BL_REGISTRY is not declared. Did you source lib/core/import.sh?\n" >&2
        return 1
    fi

    # Define color codes (fallback if not already exported)
    _bl_c_red="${BL_RED:-\033[31m}"
    _bl_c_green="${BL_GREEN:-\033[32m}"
    _bl_c_yellow="${BL_YELLOW:-\033[33m}"
    _bl_c_magenta="${BL_MAGENTA:-\033[35m}"
    _bl_c_reset="${BL_RESET:-\033[0m}"

    printf "\033[1m--- posix-lib Namespace Diagnostics ---\033[0m\n"
    _bl_all_ok=0

    # Get types and sort them
    _bl_types=$(bl_registry_get_types)
    _bl_sorted_types=$(echo "$_bl_types" | tr ' ' '\n' | sort)

    # Check if a dependency exists — shell function OR system command
    _bl_dep_exists() {
        posix_is_func "$1" || command -v "$1" >/dev/null 2>&1
    }

    for _bl_type in $_bl_sorted_types; do
        printf "\n%b[%s]%b\n" "$_bl_c_magenta" "$_bl_type" "$_bl_c_reset"
        _bl_funcs=$(bl_registry_get_funcs "$_bl_type")
        _bl_sorted_funcs=$(echo "$_bl_funcs" | tr ' ' '\n' | sort)

        for _bl_func in $_bl_sorted_funcs; do
            _bl_deps=$(bl_registry_get_deps "$_bl_func")
            _bl_dep_ok=true
            _bl_dep_statuses=""

            # Split dependencies by "|" and verify their load status
            _bl_old_ifs="$IFS"
            IFS='|'
            for _bl_dep in $_bl_deps; do
                if [ -n "$_bl_dep" ]; then
                    if _bl_dep_exists "$_bl_dep"; then
                        _bl_status="[%b$_bl_dep (ok)%b]"
                        _bl_dep_statuses="$_bl_dep_statuses $(printf "$_bl_status" "$_bl_c_green" "$_bl_c_reset")"
                    else
                        _bl_status="[%b$_bl_dep (MISSING)%b]"
                        _bl_dep_statuses="$_bl_dep_statuses $(printf "$_bl_status" "$_bl_c_red" "$_bl_c_reset")"
                        _bl_dep_ok=false
                    fi
                fi
            done
            IFS="$_bl_old_ifs"

            if posix_is_func "$_bl_func"; then
                if $_bl_dep_ok; then
                    printf "  %b✓%b %s %b(Loaded & OK)%b\n" "$_bl_c_green" "$_bl_c_reset" "$_bl_func" "$_bl_c_green" "$_bl_c_reset"
                else
                    printf "  %b⚠%b %s %b(Loaded, but dependency is missing!)%b\n" "$_bl_c_yellow" "$_bl_c_reset" "$_bl_func" "$_bl_c_red" "$_bl_c_reset"
                    _bl_all_ok=1
                fi
            else
                printf "  %b✗%b %s \033[38;5;244m(Not sourced/loaded)\033[0m\n" "$_bl_c_red" "$_bl_c_reset" "$_bl_func"
            fi

            # Print detailed dependency lists if they exist
            if [ -n "$_bl_dep_statuses" ]; then
                printf "      deps:%s\n" "$_bl_dep_statuses"
            fi
        done
    done

    return $_bl_all_ok
}

bl_info_menu() {
    # Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_info_menu" "bl_registry_get_types" "bl_registry_get_funcs" "bl_registry_get_deps" || return 1

    # Ensure registry is loaded using the underlying map path variable
    if [ -z "$BL_MAP_BL_REGISTRY_" ]; then
        printf "\033[1;31m[ERROR]\033[0m BL_REGISTRY is not declared. Did you source lib/core/import.sh?\n" >&2
        return 1
    fi

    # Define color codes (fallback if not already exported)
    _bl_c_red="${BL_RED:-\033[31m}"
    _bl_c_green="${BL_GREEN:-\033[32m}"
    _bl_c_yellow="${BL_YELLOW:-\033[33m}"
    _bl_c_magenta="${BL_MAGENTA:-\033[35m}"
    _bl_c_cyan="${BL_CYAN:-\033[36m}"
    _bl_c_blue="${BL_BLUE:-\033[34m}"
    _bl_c_reset="${BL_RESET:-\033[0m}"

    bl_info_get_details() {
        _bl_dfunc="$1"
        case "${_bl_dfunc}" in
            import)
                printf "%bDescription:%b Sources local .sh/.bash files or extensionless POSIX/bash shebang files matching a glob pattern.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mimport [-v] [--strict] <pattern> [pattern...]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bExamples:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mimport lib/*\033[0m          Source all eligible files under lib/ (recursively)\n"
                printf "  \033[1;33mimport lib/ui lib/core\033[0m Multiple dirs at once\n"
                printf "  \033[1;33mimport --strict lib/*\033[0m Fails (exit 1) immediately if any file fails to source\n"
                printf "  \033[1;33mimport /abs/path/*.sh\033[0m  Absolute paths supported\n"
                printf "%bNote:%b        Relative patterns resolve from \$PWD. Deduplicates automatically.\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "%bBacked by:%b   bl_import_local\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_import)
                printf "%bDescription:%b Sources remote library files from GitHub via BL_FILE_REGISTRY.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_import [-v] [--strict] <pattern>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bExamples:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mbl_import \"*\"\033[0m         Import all registered remote files\n"
                printf "  \033[1;33mbl_import --strict \"*\"\033[0m  Import all, but exit on the first file that fails to download\n"
                printf "  \033[1;33mbl_import \"ui/*\"\033[0m      Import all ui/ remote files\n"
                printf "  \033[1;33mbl_import \"core/colors.sh\"\033[0m  Import a specific remote file\n"
                printf "%bRequires:%b    curl, BL_FILE_REGISTRY populated\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_import_local)
                printf "%bDescription:%b Core implementation behind import(). Sources local .sh/.bash and shebang files.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_import_local [-v] [--strict] <pattern> [pattern...]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bEligible files:%b .sh, .bash extensions, or extensionless files with #!/*sh shebang.\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "%bNote:%b        Deduplicates — same file is never sourced twice per call.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_compile)
                printf "%bDescription:%b Bundles a directory of scripts into a single compiled script file.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_compile --dir <src> --out-name <name> [--main <main_file>] [--out-dir <dir>] [-v|--verbose] [-r|--recursive] [--no-shebang|--shebang <value>] [-s|--strip [empty|comments|all]] [--strict] [--lib-curl [start <urls...> stop]]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bExamples:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mbl_compile --dir lib/ --out-name posix-lib.sh\033[0m  Compiles the library into one file\n"
                printf "  \033[1;33mbl_compile --dir lib/ --out-name cplay --lib-curl start \"url1\" \"url2\" stop\033[0m  Inlines remote scripts\n"
                printf "  \033[1;33mbl_compile --dir lib/ --out-name cplay --strict\033[0m  Fails build if any fetch fails\n"
                ;;
            bl_matrix_filler)
                printf "%bDescription:%b Terminal digital rain animation effect (Matrix style) with persistent fading trails.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_matrix_filler [--mode classic|rain|fade] [--start-color N] [--end-color N] [--start-hex HEX] [--end-hex HEX] [--lang j,c,k] [--density N] [--duration SEC]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bArguments:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33m--mode\033[0m        'classic' (default), 'rain', or 'fade' for smooth RGB blending.\n"
                printf "  \033[1;33m--start-color\033[0m Default tput start color index (default: 2/green).\n"
                printf "  \033[1;33m--end-color\033[0m   Default tput end color index (default: 7/white).\n"
                printf "  \033[1;33m--start-hex\033[0m   Trail color gradient hex (e.g., '#00FF00').\n"
                printf "  \033[1;33m--end-hex\033[0m     Head/Splash color gradient hex.\n"
                printf "  \033[1;33m--lang\033[0m        Characters: 'j' (Japanese), 'c' (Chinese), 'k' (Korean).\n"
                printf "  \033[1;33m--density\033[0m     Spawn chance ratio (lower is denser, default 50).\n"
                printf "  \033[1;33m--duration\033[0m    Auto-exit timeout in seconds.\n"
                printf "%bBehaviors:%b    Fills the terminal with falling characters. Exits on any key press.\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "%bDependencies:%b tput\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_square_progress)
                printf "%bDescription:%b Renders a square/rectangular progress indicator that fills up block by block.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_square_progress [-l label] [-t] [-w N] [-H N] [-fw] [--brackets] [--color-mode mode] [--start HEX] [--end HEX]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bArguments:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33m-l | --label\033[0m      Set the header label text (defaults to 'Progress').\n"
                printf "  \033[1;33m-t | --tagged\033[0m     Enable tagged Mode B. Parses stdin streams dynamically:\n"
                printf "                      - \033[1;32mP:[0-100]\033[0m updates percentage.\n"
                printf "                      - \033[1;32mM:[message]\033[0m updates the status text.\n"
                printf "  \033[1;33m-w | --width\033[0m      Set grid width in columns (default: 10).\n"
                printf "  \033[1;33m-H | --height\033[0m     Set grid height in rows (default: 10).\n"
                printf "  \033[1;33m-fw | --full-width\033[0m Auto-expand grid to fill the full terminal width.\n"
                printf "  \033[1;33m--brackets\033[0m        Render bracket decorations around each row.\n"
                printf "  \033[1;33m--color-mode\033[0m      'global' (default, whole grid shifts color) or 'position' (static left-to-right gradient).\n"
                printf "  \033[1;33m--start / --end\033[0m   Start/end transition color hex codes.\n"
                printf "%bDependencies:%b  bl_hex_to_rgb, bl_check_deps\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_spiral_progress)
                printf "%bDescription:%b Renders a rectangular progress indicator that fills up in a spiral (inward or outward).\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_spiral_progress [-l label] [-t] [-w N] [-H N] [-fw] [--brackets] [--direction in|out] [--color-mode mode] [--start HEX] [--end HEX]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bArguments:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33m--direction\033[0m       'in' (default, outer edges to center) or 'out' (center to outer edges).\n"
                printf "  \033[1;33m-l | --label\033[0m      Set the header label text (defaults to 'Progress').\n"
                printf "  \033[1;33m-t | --tagged\033[0m     Enable tagged Mode B. Parses stdin streams dynamically.\n"
                printf "  \033[1;33m-w | --width\033[0m      Set grid width in columns (default: 10).\n"
                printf "  \033[1;33m-H | --height\033[0m     Set grid height in rows (default: 10).\n"
                printf "  \033[1;33m-fw | --full-width\033[0m Auto-expand grid to fill the full terminal width.\n"
                printf "  \033[1;33m--brackets\033[0m        Render bracket decorations around each row.\n"
                printf "  \033[1;33m--color-mode\033[0m      'global' (default) or 'position' (static gradient along spiral order).\n"
                printf "  \033[1;33m--start / --end\033[0m   Start/end transition color hex codes.\n"
                printf "%bDependencies:%b  bl_hex_to_rgb, bl_check_deps\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_progress_bar)
                printf "%bDescription:%b Renders responsive percentage progress bars with selective rendering components.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_progress_bar [-l label] [-w N] [-fw] [--status] [--log] [--log-height n] [--color-mode mode] [--start HEX] [--end HEX]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bArguments:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33m-l | --label\033[0m      Set the header label text (defaults to 'Progress').\n"
                printf "  \033[1;33m-w | --width\033[0m      Set the rendering width of the bar.\n"
                printf "  \033[1;33m-fw | --full-width\033[0m Expand the bar to fill the full terminal width.\n"
                printf "  \033[1;33m--status\033[0m          Enable rendering of the 'M:[status]' message line.\n"
                printf "  \033[1;33m--log\033[0m             Enable rendering of scrolling logs from 'L:[log]' tags.\n"
                printf "  \033[1;33m--log-height\033[0m      Explicitly set the number of log lines (implies --log, defaults to 3).\n"
                printf "  \033[1;33m--color-mode\033[0m      'global' (whole bar shifts color, default) or 'position' (static left-to-right gradient).\n"
                printf "  \033[1;33m--start / --end\033[0m   Start/end transition color hex codes.\n"
                printf "%bBehaviors:%b    Automatically switches to Tagged parsing mode if --status or --log are passed.\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "%bDependencies:%b  bl_hex_to_rgb, bl_check_deps\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_terrain_loader)
                printf "%bDescription:%b Renders an animated 2D terrain/chunk loading grid. Blocks fill one at a time using configurable patterns and color modes.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_terrain_loader [-l label] [-w N] [-h N] [-fw] [-fh] [--pattern mode] [--minecraft] [--color-mode mode] [--start HEX] [--end HEX]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bArguments:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33m-l | --label\033[0m        Display label shown above the grid (default: 'Generating Terrain...').\n"
                printf "  \033[1;33m-w | --width\033[0m         Grid width in characters (default: 40).\n"
                printf "  \033[1;33m-h | --height\033[0m        Grid height in rows (default: 15).\n"
                printf "  \033[1;33m-fw | --full-width\033[0m   Auto-set width to full terminal column count.\n"
                printf "  \033[1;33m-fh | --full-height\033[0m  Auto-set height to terminal line count minus 2.\n"
                printf "  \033[1;33m--pattern\033[0m             Fill pattern: 'random' (default), 'center-out', or 'minecraft'.\n"
                printf "  \033[1;33m--minecraft\033[0m           Shortcut for --pattern minecraft. Enables fuzzy center-out expansion with\n"
                printf "                        random lag-spike blocks (15% chance), just like real Minecraft chunk loading.\n"
                printf "  \033[1;33m--color-mode\033[0m          'time' (blocks colored by fill order, default), 'position' (left-to-right gradient), or 'global' (solid shifting color).\n"
                printf "  \033[1;33m--start / --end\033[0m       Start/end gradient hex colors (default: yellow → cyan).\n"
                printf "  \033[1;33m--fg\033[0m                  Foreground ANSI color index for minecraft/fallback mode.\n"
                printf "%bInput:%b        Reads plain numbers 0-100 or tagged 'P:[0-100]' from stdin.\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "%bDependencies:%b bl_hex_to_rgb, bl_check_deps\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_check_deps)
                printf "%bDescription:%b Verification utility that runs before a function executes to guard against missing dependencies.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_check_deps <caller_name> <dep1> [dep2 ...]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mcaller_name\033[0m     The name of the function requiring dependencies (for diagnostic logging).\n"
                printf "  \033[1;33mdep1 / dep2\033[0m     Names of functions to verify in environment memory.\n"
                printf "%bReturn Code:%b  0 if all dependencies exist, 1 if any dependency is missing.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_hex_to_rgb)
                printf "%bDescription:%b Color parser converting hex code colors to terminal-usable RGB decimal channels.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_hex_to_rgb <HEX_STRING>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mHEX_STRING\033[0m      Hex color string with or without '#'. E.g., '#00FF00' or '00FF00'.\n"
                printf "%bOutputs:%b      Space-separated red, green, and blue decimal integers on stdout. E.g., '0 255 0'.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_version_compare)
                printf "%bDescription:%b Left-to-right component-wise semantic version comparison utility.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_version_compare <ver1> <ver2>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mver1\033[0m            First version (e.g. '1.2.0.1').\n"
                printf "  \033[1;33mver2\033[0m            Second version to compare against (e.g. '1.3.0').\n"
                printf "%bOutputs:%b      Outputs comparison status: 'equal', 'major update', 'minor update', 'patch update', 'hotfix update', or 'downgrade'.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_parse_selection)
                printf "%bDescription:%b Splits menu selection inputs and expands range expressions (e.g. '1-4' into '1 2 3 4').\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_parse_selection <input_string> [delimiter]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33minput_string\033[0m    Input selection string. E.g., '1,3-5'.\n"
                printf "  \033[1;33delimiter\033[0m       Custom delimiter separating selections (defaults to ',').\n"
                printf "%bOutputs:%b      Space-separated expanded token numbers. Returns exit code 1 on parsing syntax errors.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_expand_selection)
                printf "%bDescription:%b Keyword-aware expansion utility. Translates 'all' keywords into numerical sequences.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_expand_selection <max_index> <parsed_inputs...>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mmax_index\033[0m       The maximum item index available in the current list.\n"
                printf "  \033[1;33mparsed_inputs\033[0m   List of raw parsed tokens.\n"
                printf "%bOutputs:%b      Space-separated numbers containing expanded sequences.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_validate_selection)
                printf "%bDescription:%b Boundary checks menu options to ensure all selected items are valid.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_validate_selection <max_index> <indices...>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mmax_index\033[0m       The maximum item index allowed.\n"
                printf "  \033[1;33mindices\033[0m         One or more expanded numbers to validate.\n"
                printf "%bReturn Code:%b  0 if all numbers are between 1 and max_index (inclusive); 1 otherwise.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_file_count_feeder_)
                printf "%bDescription:%b Directory polling engine. Watches matching marker file creation to feed sync ratios.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_file_count_feeder_ <total> [hz] [dir] [pattern]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mtotal\033[0m           Total expected file count matching the pattern.\n"
                printf "  \033[1;33mhz\033[0m              Polling frequency in Hertz (default: 10).\n"
                printf "  \033[1;33mdir\033[0m             Directory path to scan (defaults to registry path).\n"
                printf "  \033[1;33mpattern\033[0m         File match pattern. E.g., '*.done'.\n"
                printf "%bOutputs:%b      Standard stream of current file counts.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            _bl_count_percent_emitter_)
                printf "%bDescription:%b Math streaming emitter translating raw completed integers into percentage tokens.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33m_bl_count_percent_emitter_ <total> [flag]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mtotal\033[0m           Denominator representing 100% completion.\n"
                printf "  \033[1;33mflag\033[0m            Set 'tagged' or '--tagged' to output tagged progress format (e.g. 'P:50') instead of raw strings.\n"
                printf "%bOutputs:%b      Percentage flow stream.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_file_log_feeder_)
                printf "%bDescription:%b Tails a log file and reformats the last line as a progress bar message feed.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_file_log_feeder_ <logfile> [hz] [prefix]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mlogfile\033[0m         Path to log file being monitored.\n"
                printf "  \033[1;33mhz\033[0m              Tail polling frequency in Hertz (default: 5).\n"
                printf "  \033[1;33mprefix\033[0m          Custom log output prefix (default: 'M:').\n"
                printf "%bOutputs:%b      Stream of status messages prefixed with the given prefix.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_info_check)
                printf "%bDescription:%b Core environment diagnostic utility. Sweeps loaded memory to verify framework functions and dependencies.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_info_check\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bBehaviors:%b    Outputs namespace categories and color-coded status checks grouped dynamically.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_info_menu)
                printf "%bDescription:%b Launches an interactive terminal UI menu containing full documentation.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_info_menu\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bDependencies:%b bl_registry_get_types, bl_registry_get_funcs, bl_registry_get_deps\n" "$_bl_c_cyan" "$_bl_c_reset"
                ;;
            bl_registry_get_types)
                printf "%bDescription:%b Parses the BL_REGISTRY and returns a space-separated list of all available namespaces/types (e.g., 'core info ui').\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_registry_get_types\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bOutputs:%b      Unique types directly to stdout.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_registry_get_funcs)
                printf "%bDescription:%b Parses the BL_REGISTRY for a specific namespace and returns its associated functions.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_registry_get_funcs <namespace>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mnamespace\033[0m       The group to lookup (e.g., 'ui', 'core').\n"
                printf "%bOutputs:%b      Space-separated function names.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_registry_get_deps)
                printf "%bDescription:%b Returns the dependency string for a specific function.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_registry_get_deps <function_name>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mfunction_name\033[0m   The name of the function to check.\n"
                printf "%bOutputs:%b      Pipe-separated dependencies (e.g., 'curl|jq'), or empty string if none.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_bash_tutor)
                printf "%bDescription:%b Interactive tutor interpreter options and scripting lessons manual.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_bash_tutor\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bBehaviors:%b    Launches tutor menu covering set modes, string expansions, quoting, and scope declarations.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_pid_status)
                printf "%bDescription:%b Queries process directory state via /proc/\$PID or signal kill -0.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_pid_status <pid>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bOutputs:%b      Status string representing process states: 'RUNNING', 'SUCCESS', or 'FAILED'.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_pid_reap)
                printf "%bDescription:%b Non-blocking tracking PID scavenger sweep.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_pid_reap\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bBehaviors:%b    Iterates over background job registries, reaping dead process vectors and harvesting exit codes.\n" "$_bl_c_magenta" "$_bl_c_reset"
                ;;
            bl_pid_store)
                printf "%bDescription:%b Stores a background PID in the global registry.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_pid_store <name> <pid>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mname\033[0m            Identifier name for the background process.\n"
                printf "  \033[1;33mpid\033[0m             Process ID.\n"
                ;;
            bl_pid_wait)
                printf "%bDescription:%b Waits for a specific registered background process to finish and unsets it.\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_pid_wait <name>\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                printf "%bParameters:%b\n" "$_bl_c_cyan" "$_bl_c_reset"
                printf "  \033[1;33mname\033[0m            Identifier name of the process.\n"
                ;;
            bl_terrain_loader_opt)
                printf "%bDescription:%b Experimental optimized terrain loader (delegates to bl_terrain_loader for now).\n" "$_bl_c_blue" "$_bl_c_reset"
                printf "%bUsage:%b       \033[33mbl_terrain_loader_opt [args...]\033[0m\n" "$_bl_c_green" "$_bl_c_reset"
                ;;
            *)
                printf "%bDescription:%b Details and usage will be added upon implementation.\n" "$_bl_c_blue" "$_bl_c_reset"
                _bl_ddeps=$(bl_registry_get_deps "$_bl_dfunc")
                if [ -n "$_bl_ddeps" ]; then
                    printf "%bDependencies:%b %s\n" "$_bl_c_cyan" "$_bl_c_reset" "$_bl_ddeps"
                fi
                ;;
        esac
    }

    _bl_types=$(bl_registry_get_types)
    _bl_sorted_types=$(echo "$_bl_types" | tr ' ' '\n' | sort | tr '\n' ' ')

    while true; do
        clear
        printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
        printf "%b       POSIX-LIB EXPLORER MANUAL         %b\n" "$_bl_c_cyan" "$_bl_c_reset"
        printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
        printf "Select a category to explore:\n\n"
        
        _bl_num_types=0
        _bl_i=1
        for _bl_t in $_bl_sorted_types; do
            printf "  %b%d)%b %s\n" "$_bl_c_yellow" "$_bl_i" "$_bl_c_reset" "$_bl_t"
            _bl_i=$((_bl_i+1))
            _bl_num_types=$((_bl_num_types+1))
        done
        printf "\n  %b%s)%b Exit Browser\n" "$_bl_c_red" "x" "$_bl_c_reset"
        printf "%b-----------------------------------------%b\n" "$_bl_c_magenta" "$_bl_c_reset"
        printf "Select an option: "
        read -r cat_opt

        if [ "$cat_opt" = "x" ] || [ "$cat_opt" = "X" ]; then
            break
        fi

        case "$cat_opt" in
            *[!0-9]*) _bl_is_num=0 ;;
            "") _bl_is_num=0 ;;
            *) _bl_is_num=1 ;;
        esac

        if [ "$_bl_is_num" -eq 1 ] && [ "$cat_opt" -gt 0 ] && [ "$cat_opt" -le "$_bl_num_types" ]; then
            # Find selected category
            _bl_idx=1
            _bl_sel_cat=""
            for _bl_t in $_bl_sorted_types; do
                if [ "$_bl_idx" -eq "$cat_opt" ]; then
                    _bl_sel_cat="$_bl_t"
                    break
                fi
                _bl_idx=$((_bl_idx+1))
            done
            
            while true; do
                clear
                printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "Category: %b[%s]%b\n" "$_bl_c_green" "$_bl_sel_cat" "$_bl_c_reset"
                printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
                
                _bl_funcs=$(bl_registry_get_funcs "$_bl_sel_cat")
                _bl_sorted_funcs=$(echo "$_bl_funcs" | tr ' ' '\n' | sort | tr '\n' ' ')
                
                _bl_num_funcs=0
                _bl_i=1
                for _bl_f in $_bl_sorted_funcs; do
                    _bl_load_status="%b✗%b"
                    if posix_is_func "$_bl_f"; then
                        _bl_load_status="%b✓%b"
                    fi
                    printf "  %b%d)%b " "$_bl_c_yellow" "$_bl_i" "$_bl_c_reset"
                    printf "$_bl_load_status" "$_bl_c_green" "$_bl_c_reset"
                    printf " %s\n" "$_bl_f"
                    
                    _bl_i=$((_bl_i+1))
                    _bl_num_funcs=$((_bl_num_funcs+1))
                done
                printf "\n  %b%s)%b Back to Categories\n" "$_bl_c_red" "b" "$_bl_c_reset"
                printf "%b-----------------------------------------%b\n" "$_bl_c_magenta" "$_bl_c_reset"
                printf "Select a function to view details: "
                read -r func_opt

                if [ "$func_opt" = "b" ] || [ "$func_opt" = "B" ]; then
                    break
                fi

                case "$func_opt" in
                    *[!0-9]*) _bl_is_num=0 ;;
                    "") _bl_is_num=0 ;;
                    *) _bl_is_num=1 ;;
                esac

                if [ "$_bl_is_num" -eq 1 ] && [ "$func_opt" -gt 0 ] && [ "$func_opt" -le "$_bl_num_funcs" ]; then
                    _bl_idx=1
                    _bl_sel_func=""
                    for _bl_f in $_bl_sorted_funcs; do
                        if [ "$_bl_idx" -eq "$func_opt" ]; then
                            _bl_sel_func="$_bl_f"
                            break
                        fi
                        _bl_idx=$((_bl_idx+1))
                    done
                    
                    clear
                    printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
                    printf "Function: %b%s%b\n" "$_bl_c_green" "$_bl_sel_func" "$_bl_c_reset"
                    printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
                    bl_info_get_details "$_bl_sel_func"
                    printf "%b=========================================%b\n" "$_bl_c_magenta" "$_bl_c_reset"
                    printf "Press Enter to return to function list..."
                    read -r _junk
                fi
            done
        fi
    done
}
