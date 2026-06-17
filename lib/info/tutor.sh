# --- posix-lib Interactive POSIX Shell Tutor ---

bl_bash_tutor() {
    _bl_topics="01-posix-overview 02-shell-compliance 03-variables-expansion 04-conditionals-testing 05-loops-iteration 06-functions-scopes 07-subshells-command-sub 08-arrays-maps-emulation 09-io-redirections-pipes 10-strict-mode-set-e"

    bl_tutor_format_lesson() {
        _bl_esc=$(printf '\033')
        _bl_green="${_bl_esc}[32m"
        _bl_cyan="${_bl_esc}[1;36m"
        _bl_mag="${_bl_esc}[1;35m"
        _bl_reset="${_bl_esc}[0m"
        
        while IFS= read -r _bl_line; do
            case "$_bl_line" in
                "# "*)
                    printf "%b%s%b\n" "$_bl_mag" "$_bl_line" "$_bl_reset"
                    ;;
                "### "*)
                    printf "%b%s%b\n" "$_bl_cyan" "$_bl_line" "$_bl_reset"
                    ;;
                *"\`"*)
                    # Standard POSIX replacement for inline code highlight
                    printf "%s\n" "$_bl_line" | sed -e "s/\`\([^\`]*\)\`/${_bl_green}\1${_bl_reset}/g"
                    ;;
                *)
                    printf "%s\n" "$_bl_line"
                    ;;
            esac
        done
    }

    bl_tutor_get_lesson() {
        case "$1" in
            01-posix-overview)
cat <<'EOF'
# 🔴 Milestone 01: POSIX Shell Overview

### 1. What is POSIX?
The Portable Operating System Interface (POSIX) standard defines the system interface, including the shell grammar and utilities. Scripting in strict POSIX ensures your code runs natively on any Unix-like system (Linux, macOS, BSD, embedded platforms) without requiring Bash.

### 2. POSIX Shell vs. Bash
- **Interpreter**: POSIX scripts target `/bin/sh` (which can be Dash, Posh, Ash, or Bash in POSIX mode).
- **Features**: Avoids non-standard extensions like arrays (`local -a`), process substitutions (`<(...)`), and double-bracket testing (`[[ ... ]]`).
- **Compatibility**: Runs faster and starts up much quicker on resource-constrained environments.
EOF
                ;;
            02-shell-compliance)
cat <<'EOF'
# 🔴 Milestone 02: Shell Compliance & Portability

### 1. Shebang Selection
Always use `/bin/sh` instead of `/bin/bash` to enforce portability.
```sh
#!/bin/sh
# Portable POSIX script
```

### 2. Syntax Check
Test compatibility against strict shells like Dash or Posh using syntax check flags:
```sh
dash -n script.sh
posh -n script.sh
```
EOF
                ;;
            03-variables-expansion)
cat <<'EOF'
# 🔴 Milestone 03: Variables & Parameter Expansion

### 1. Assignment Rules
POSIX variable names must start with a letter or underscore and contain only alphanumeric characters or underscores. Assignment must not contain spaces around `=`:
```sh
# Correct
my_var="value"

# Incorrect / Syntax error in POSIX
# my_var = "value"
```

### 2. Standard Parameter Expansion
Use standard POSIX-compliant expansions instead of Bash string slicing (`${var:offset:length}`):
```sh
# Default Value
val="${1:-default_value}"

# Alternative Value
val="${var:+replacement_value}"

# Strip Suffix (Shortest match)
name="archive.tar.gz"
echo "${name%.gz}"   # Output: archive.tar

# Strip Prefix (Shortest match)
echo "${name#*.}"    # Output: tar.gz
```
EOF
                ;;
            04-conditionals-testing)
cat <<'EOF'
# 🔴 Milestone 04: Conditionals & Testing

### 1. Single Brackets vs Double Brackets
Never use `[[ ... ]]` in POSIX scripts. Always use standard `[ ... ]` or the `test` command.
```sh
# Correct (POSIX)
if [ "$name" = "admin" ]; then
    echo "Access granted"
fi

# Incorrect (Bash-only syntax)
# if [[ $name == "admin" ]]; then ...
```

### 2. String & Number Operators
- **String comparison**: Use `=` and `!=`.
- **Numeric comparison**: Use `-eq`, `-ne`, `-lt`, `-le`, `-gt`, `-ge`.
```sh
# String test
[ "$str1" = "$str2" ]

# Numeric test
[ "$num1" -lt "$num2" ]
```
EOF
                ;;
            05-loops-iteration)
cat <<'EOF'
# 🔴 Milestone 05: Loops & Iteration

### 1. While and For Loops
POSIX supports standard `for var in list` and `while cond` loops. C-style `for ((i=0; i<10; i++))` loops are Bashisms.
```sh
# Correct (POSIX For Loop)
for item in apple banana cherry; do
    echo "Fruit: $item"
done

# Correct (POSIX Loop Index Simulation)
i=0
while [ "$i" -lt 10 ]; do
    echo "Index: $i"
    i=$((i + 1))
done
```
EOF
                ;;
            06-functions-scopes)
cat <<'EOF'
# 🔴 Milestone 06: Functions & Local Scopes

### 1. Definition Syntax
POSIX function definitions must not use the `function` keyword.
```sh
# Correct (POSIX)
my_func() {
    echo "Hello"
}

# Incorrect (Bashism)
# function my_func() { ... }
```

### 2. Scoping Variables Portable
The `local` keyword is not formally defined in standard POSIX, although supported by many modern interpreters (Dash, Ash). For absolute portability, prefix variables or manage them carefully.
```sh
# Recommended local scoping pattern in posix-lib:
bl_my_func() {
    _bl_local_var="unique_value"
    echo "$_bl_local_var"
}
```
EOF
                ;;
            07-subshells-command-sub)
cat <<'EOF'
# 🔴 Milestone 07: Subshells & Command Substitution

### 1. Command Substitution Syntax
Use `$(command)` instead of backticks `` `command` ``. It allows nesting and is easier to read.
```sh
# Correct (POSIX)
current_dir=$(pwd)

# Nesting Command Substitutions
files_count=$(ls -l "$(pwd)" | wc -l)
```

### 2. Subshell Context
Executing code enclosed in parentheses `( ... )` creates a subshell. Variables set inside a subshell do not leak to the parent environment.
```sh
(
    temp_var="inside"
    echo "Subshell: $temp_var"
)
# $temp_var is empty/unset here in parent scope
```
EOF
                ;;
            08-arrays-maps-emulation)
cat <<'EOF'
# 🔴 Milestone 08: Array & Map Emulation

### 1. In-Memory Arrays
POSIX shells do not have native arrays. You can emulate arrays using space-separated strings or dynamic eval variable structures:
```sh
# Emulating arrays via space-separated list:
fruits="apple banana orange"
for f in $fruits; do
    echo "$f"
done

# Dynamic Variable Emulation:
i=0
while [ "$i" -lt 3 ]; do
    eval "arr_${i}=\"val_${i}\""
    i=$((i + 1))
done
```

### 2. Associative Maps
Map emulation can be done natively using `/tmp` backing storage (like `posix.sh` does) or dynamic in-memory variables utilizing `eval`:
```sh
# Dynamic eval map mapping:
key="user_name"
val="Alice"
eval "map_${key}=\"\${val}\""

# Lookup:
eval "echo \${map_${key}}"
```
EOF
                ;;
            09-io-redirections-pipes)
cat <<'EOF'
# 🔴 Milestone 09: I/O Redirections & Pipes

### 1. Redirecting Streams
Standard input (0), output (1), and error (2) streams can be redirected portably:
```sh
# Redirect stderr to stdout, and stdout to file
command > file 2>&1

# Silence stderr
command 2>/dev/null
```

### 2. Non-blocking Stdin Reading
Since `read -t` is a Bashism, use raw terminal settings with `stty` or block-buffered piping to pace data flow when reading streams.
```sh
# Reading stdin line-by-line portably
while read -r line; do
    echo "Line: $line"
done < file.txt
```
EOF
                ;;
            10-strict-mode-set-e)
cat <<'EOF'
# 🔴 Milestone 10: Strict Mode & Exit Codes

### 1. Enforcing Strictness
Use standard strict mode flags to capture command failures, but shield testing statements:
```sh
set -e # Exit immediately if a command exits with a non-zero status

# Shielding tests:
# If you run `[ "$val" = "1" ]` and it is false, the script will exit.
# Shield it using if/then blocks:
if [ "$val" = "1" ]; then
    echo "Matches"
fi
```

### 2. Cleaning Up
Traps can capture signals to clean up resources before exiting:
```sh
trap 'echo "Cleaning up..."; rm -f /tmp/tempfile' EXIT INT TERM
```
EOF
                ;;
            *)
                echo "Topic not found."
                ;;
        esac
    }

    if [ -n "$1" ]; then
        bl_tutor_get_lesson "$1" | bl_tutor_format_lesson
        return 0
    fi

    while true; do
        clear
        printf "\033[1;35m=========================================\033[0m\n"
        printf "\033[1;36m          POSIX COMPLIANCE TUTOR         \033[0m\n"
        printf "\033[1;35m=========================================\033[0m\n"
        printf "Select a lesson topic to learn:\n\n"
        
        _bl_i=1
        _bl_old_ifs="$IFS"
        IFS=" "
        for _bl_topic in $_bl_topics; do
            printf "  \033[1;33m%2d)\033[0m %s\n" "$_bl_i" "$_bl_topic"
            _bl_i=$((_bl_i + 1))
        done
        IFS="$_bl_old_ifs"
        
        printf "\n  \033[1;31mx)\033[0m Exit Tutor\n"
        printf "\033[1;35m-----------------------------------------\033[0m\n"
        printf "Select an option: "
        read -r choice

        if [ "$choice" = "x" ] || [ "$choice" = "X" ]; then
            break
        fi

        _bl_selected=""
        _bl_i=1
        _bl_old_ifs="$IFS"
        IFS=" "
        for _bl_topic in $_bl_topics; do
            if [ "$_bl_i" -eq "$choice" ] 2>/dev/null; then
                _bl_selected="$_bl_topic"
                break
            fi
            _bl_i=$((_bl_i + 1))
        done
        IFS="$_bl_old_ifs"

        if [ -n "$_bl_selected" ]; then
            clear
            bl_tutor_get_lesson "$_bl_selected" | bl_tutor_format_lesson
            printf "\n\033[1;35m=========================================\033[0m\n"
            printf "Press Enter to return to lesson menu..."
            read -r _bl_dummy
        else
            printf "Invalid option.\n"
            sleep 1
        fi
    done
}
