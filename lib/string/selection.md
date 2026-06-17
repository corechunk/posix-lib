# Porting Notes: `lib/string/selection.sh` to POSIX

This document outlines the translations made to convert `lib/string/selection.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Array Parsing & Herestrings (`IFS="$delim" read -ra parts <<< "$input"`)
*   **Bashism**:
    ```bash
    IFS="$delim" read -ra parts <<< "$input"
    for p in "${parts[@]}"; do
    ```
*   **POSIX**: Dynamically split the string using IFS and positional parameter mapping (`set --`), iterating standard fields:
    ```sh
    _bl_old_ifs="$IFS"
    IFS="$_bl_delim"
    set -- $_bl_input
    IFS="$_bl_old_ifs"

    for _bl_p in "$@"; do
    ```

### Regex Bounds Checking (`[[ "$p" =~ ^[0-9]+$ ]]`)
*   **Bashism**:
    ```bash
    if [[ "$s" =~ ^[0-9]+$ && "$e" =~ ^[0-9]+$ ]]; then
    ```
*   **POSIX**: Leveraged standard shell `case` patterns to test numerical formats safely:
    ```sh
    case "$_bl_s" in
        *[!0-9]*|"") return 1 ;;
    esac
    ```

### Arithmetic Loops & Array additions (`for ((i=s; i<=e; i++)); do expanded+=("$i"); done`)
*   **Bashism**:
    ```bash
    for ((i=s; i<=e; i++)); do expanded+=("$i"); done
    ```
*   **POSIX**: Used a standard `while` loop, accumulating values into space-separated strings:
    ```sh
    _bl_i="$_bl_s"
    while [ "$_bl_i" -le "$_bl_e" ]; do
        _bl_expanded="$_bl_expanded $_bl_i"
        _bl_i=$((_bl_i+1))
    done
    ```

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -c '. lib/core/posix.sh && dash -n lib/string/selection.sh'
posh -c '. lib/core/posix.sh && posh -n lib/string/selection.sh'
```
Both outputs return successfully.
