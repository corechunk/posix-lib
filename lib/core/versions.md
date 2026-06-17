# Porting Notes: `lib/core/versions.sh` to POSIX

This document outlines the translations made to convert `lib/core/versions.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Local variables & bashisms (`local` and `[[ ... ]]`)
*   **Bashism**:
    ```bash
    local ver1=$(echo "$1" | tr -d 'vV[:space:]')
    if [[ -z "$ver1" || -z "$ver2" ]]; then
    ```
*   **POSIX**: Sourced directly as standard variables with safe namespaces.
    ```sh
    _bl_ver1=$(echo "$1" | tr -d 'vV[:space:]')
    if [ -z "$_bl_ver1" ] || [ -z "$_bl_ver2" ]; then
    ```

### Array Parsing & Herestrings (`IFS='.' read -r -a v1_parts <<< "$ver1"`)
*   **Bashism**:
    ```bash
    IFS='.' read -r -a v1_parts <<< "$ver1"
    ```
*   **POSIX**: Extracted and normalized component parts by using a custom function `_bl_split_version` that splits via `IFS` and sets parameters using `set --`:
    ```sh
    _bl_split_version() {
        _bl_sver="$1"
        _bl_old_ifs="$IFS"
        IFS="."
        set -- $_bl_sver
        IFS="$_bl_old_ifs"
        
        _bl_p1="${1:-0}"
        _bl_p2="${2:-0}"
        _bl_p3="${3:-0}"
        _bl_p4="${4:-0}"
        echo "$_bl_p1 $_bl_p2 $_bl_p3 $_bl_p4"
    }
    ```

### Arithmetic Loops & Arrays (`for i in {0..3}; do (( v1_parts[i] < v2_parts[i] ))`)
*   **Bashism**:
    ```bash
    for i in {0..3}; do
        if (( v1_parts[i] < v2_parts[i] )); then
    ```
*   **POSIX**: Unrolled into sequential, component-specific standard test calls:
    ```sh
    if [ "$_bl_v1_1" -lt "$_bl_v2_1" ]; then
        echo "major update"
        return
    elif [ "$_bl_v1_1" -gt "$_bl_v2_1" ]; then
        ...
    ```

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -c '. lib/core/posix.sh && dash -n lib/core/versions.sh'
posh -c '. lib/core/posix.sh && posh -n lib/core/versions.sh'
```
Both outputs return successfully.
