# Porting Notes: `lib/core/import.sh` to POSIX

This document outlines the translations made to convert `lib/core/import.sh` from Bash-only syntax to POSIX-compliant shell script, utilising the helpers defined in `lib/core/posix.sh`.

---

## 1. Replacements Implemented

### Dynamic Maps (`declare -g -A`)
*   **Bashism**: Static associative arrays holding registries.
    ```bash
    declare -g -A BL_REGISTRY=( ... )
    ```
*   **POSIX**: Sourced via `bl_map_init` and populated item by item using `bl_map_set`.
    ```sh
    bl_map_init "BL_REGISTRY" ""
    bl_map_set "BL_REGISTRY" "key" "value" ""
    ```

### Registry Keys Loop
*   **Bashism**:
    ```bash
    for key in "${!BL_REGISTRY[@]}"; do
    ```
*   **POSIX**:
    ```sh
    for _bl_key in $(bl_map_keys "BL_REGISTRY" ""); do
    ```

### Function Checks
*   **Bashism**: `declare -f` to verify the presence of active functions.
    ```bash
    ! declare -f "$dep"
    ```
*   **POSIX**: Utilises standard POSIX `type` tool.
    ```sh
    ! type "$dep" >/dev/null 2>&1
    ```

### Here-Strings & Process Substitutions
*   **Bashism**:
    ```bash
    source /dev/stdin <<< "$curl_out"
    ```
*   **POSIX**: Replaced with standard stdout redirection streams.
    ```sh
    printf "%s\n" "$_bl_curl_out" > "$_bl_temp_err"
    . "$_bl_temp_err"
    ```
