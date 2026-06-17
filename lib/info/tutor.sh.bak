#!/usr/bin/env bash
# --- bash-lib Bash Tutor & Reference Guide ---
# An interactive lesson system browser for Shell Options, Expansions, and Scopes.

bl_bash_tutor() {
    # Educational data retriever
    bl_tutor_get_lesson() {
        local topic="$1"
        case "$topic" in
            modes)
                echo -e "\033[1;36m=== LESSON 1: SHELL MODES & OPTIONS ===\033[0m"
                echo -e "Bash options alter global shell interpreter behavior via \033[33mset\033[0m and \033[33mshopt\033[0m.\n"
                
                echo -e "\033[1;34m1. Strict Mode (nounset)\033[0m"
                echo -e "  - Code:  \033[32mset -u\033[0m or \033[32mset -o nounset\033[0m"
                echo -e "  - Rule:  Treats referencing unset/unbound variables as a fatal error."
                echo -e "  - Crash: Attempting to print \033[31m\$UNSET_VAR\033[0m immediately terminates execution."
                echo -e "  - Fix:   Use default fallback expansion syntax: \033[32m\${UNSET_VAR:-}\033[0m\n"
                
                echo -e "\033[1;34m2. Exit on Error (errexit)\033[0m"
                echo -e "  - Code:  \033[32mset -e\033[0m or \033[32mset -o errexit\033[0m"
                echo -e "  - Rule:  Exit immediately if a command yields a non-zero exit status."
                echo -e "  - Note:  Commonly coupled with \033[32mset -o pipefail\033[0m to capture pipe errors.\n"
                
                echo -e "\033[1;34m3. POSIX Compliance Mode\033[0m"
                echo -e "  - Code:  \033[32mset -o posix\033[0m"
                echo -e "  - Rule:  Alters Bash behaviors to adhere strictly to the POSIX standard,"
                echo -e "           disabling non-POSIX Bash-isms (like process substitution \033[31m<(...)\033[0m)."
                ;;
            parameters)
                echo -e "\033[1;36m=== LESSON 2: PARAMETER EXPANSION (\${} MAGIC) ===\033[0m"
                echo -e "Using \033[33m\${var}\033[0m enables raw string manipulations directly in shell memory without subshells.\n"
                
                echo -e "\033[1;34m1. Default Fallbacks\033[0m"
                echo -e "  - \033[32m\${var:-fallback}\033[0m : Evaluates to 'fallback' if var is unset or empty."
                echo -e "  - \033[32m\${var:=fallback}\033[0m : Assigns 'fallback' to var if unset/empty.\n"
                
                echo -e "\033[1;34m2. Pattern Stripping (Slicing strings)\033[0m"
                echo -e "  - \033[32m\${var#pattern}\033[0m  : Strips shortest match of pattern from the FRONT."
                echo -e "  - \033[32m\${var##pattern}\033[0m : Strips longest match of pattern from the FRONT."
                echo -e "  - \033[32m\${var%pattern}\033[0m  : Strips shortest match of pattern from the BACK."
                echo -e "  - \033[32m\${var%%pattern}\033[0m : Strips longest match of pattern from the BACK."
                echo -e "  - \033[35mExample:\033[0m If \033[33mfile=\"path/to/script.sh\"\033[0m:"
                echo -e "           \033[32m\${file##*/}\033[0m evaluates to \033[32m\"script.sh\"\033[0m."
                echo -e "           \033[32m\${file%.*}\033[0m  evaluates to \033[32m\"path/to/script\"\033[0m.\n"
                
                echo -e "\033[1;34m3. Substrings & Search/Replace\033[0m"
                echo -e "  - \033[32m\${var:offset:length}\033[0m : Slices string. E.g. \033[32m\${foo:0:5}\033[0m."
                echo -e "  - \033[32m\${var/search/replace}\033[0m : Replaces first occurrence of search."
                echo -e "  - \033[32m\${var//search/replace}\033[0m: Replaces all occurrences."
                ;;
            quoting)
                echo -e "\033[1;36m=== LESSON 3: QUOTING & EXPANSION RULES ===\033[0m"
                echo -e "Quotes control word splitting, globbing, and code evaluation.\n"
                
                echo -e "\033[1;34m1. Double Quotes (\"\") - Weak Quoting\033[0m"
                echo -e "  - Behavior: Allows variables to expand (\033[32m\$var\033[0m) and subshells to evaluate (\033[32m\$(cmd)\033[0m)."
                echo -e "  - CRITICAL: Prevents word splitting (treating spaces as file arguments)."
                echo -e "  - Rule:     Always wrap path references in double quotes: \033[32mcd \"\$path\"\033[0m.\n"
                
                echo -e "\033[1;34m2. Single Quotes ('') - Strong Quoting\033[0m"
                echo -e "  - Behavior: Suppresses all expansions. Everything is treated as a literal character."
                echo -e "  - Example:  \033[32m'\$var'\033[0m outputs the literal characters \033[31m\$var\033[0m.\n"
                
                echo -e "\033[1;34m3. Subshell Expansion vs Backticks\033[0m"
                echo -e "  - \033[32m\$(command)\033[0m : Modern standard for command execution substitution."
                echo -e "  - \033[31m\`command\`\033[0m   : Legacy backticks (discouraged; nested quoting escapes are messy)."
                ;;
            scoping)
                echo -e "\033[1;36m=== LESSON 4: SCORING, VARIABLE SCOPING & DECLARE ===\033[0m"
                echo -e "Variables in Bash are global by default unless scoped explicitly.\n"
                
                echo -e "\033[1;34m1. Scope Modifiers: local vs declare\033[0m"
                echo -e "  - \033[32mlocal var\033[0m   : Scopes var dynamically to current function and children."
                echo -e "                  Only valid inside a function definition!"
                echo -e "  - \033[32mdeclare var\033[0m : Creates local functional scopes. Use \033[32mdeclare -g\033[0m"
                echo -e "                  to explicitly override scoping and declare a global variable.\n"
                
                echo -e "\033[1;34m2. Declare Attribute Flags\033[0m"
                echo -e "  - \033[32mdeclare -i var\033[0m : Integer flag. Forces mathematical context on assignment."
                echo -e "  - \033[32mdeclare -a var\033[0m : Creates an indexed array."
                echo -e "  - \033[32mdeclare -A var\033[0m : Creates an associative array (hashmap).\n"
                
                echo -e "\033[1;34m3. Subshell Boundary Scopes ( ... )\033[0m"
                echo -e "  - Parent processes share copies of variables down into subshells."
                echo -e "  - Subshells \033[31mCANNOT\033[0m modify or push variable updates back up to parent shells."
                ;;
        esac
    }

    while true; do
        clear
        echo -e "\033[1;35m=========================================\033[0m"
        echo -e "\033[1;36m          BASH INTERPRETER TUTOR         \033[0m"
        echo -e "\033[1;35m=========================================\033[0m"
        echo -e "Select a lesson topic to learn:\n"
        echo -e "  \033[1;33m1)\033[0m Shell Options & Strict Modes (set -e/u/posix)"
        echo -e "  \033[1;33m2)\033[0m Parameter Expansion (\${} Slicing & Fallbacks)"
        echo -e "  \033[1;33m3)\033[0m Quoting and Expansion Rules (\"\" vs '' vs \$())"
        echo -e "  \033[1;33m4)\033[0m Variable Scoping & declare Attributes"
        echo -e "\n  \033[1;31mx)\033[0m Exit Tutor"
        echo -e "\033[1;35m-----------------------------------------\033[0m"
        read -rp "Select an option: " choice

        case "$choice" in
            1)
                clear
                bl_tutor_get_lesson "modes"
                echo -e "\n\033[1;35m=========================================\033[0m"
                read -rp "Press Enter to return to lesson menu..."
                ;;
            2)
                clear
                bl_tutor_get_lesson "parameters"
                echo -e "\n\033[1;35m=========================================\033[0m"
                read -rp "Press Enter to return to lesson menu..."
                ;;
            3)
                clear
                bl_tutor_get_lesson "quoting"
                echo -e "\n\033[1;35m=========================================\033[0m"
                read -rp "Press Enter to return to lesson menu..."
                ;;
            4)
                clear
                bl_tutor_get_lesson "scoping"
                echo -e "\n\033[1;35m=========================================\033[0m"
                read -rp "Press Enter to return to lesson menu..."
                ;;
            x|X)
                break
                ;;
        esac
    done
}
