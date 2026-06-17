# Porting Notes: `lib/async/pid.sh` to POSIX

This document outlines the translations made to convert `lib/async/pid.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Associative Array (`declare -A`)
*   **Bashism**: Associative array used to map names to process IDs.
    ```bash
    declare -g -A BL_PIDS
    BL_PIDS["$name"]="$pid"
    ```
*   **POSIX**: Sourced via `bl_map_init` and managed with `bl_map_set`, `bl_map_get`, `bl_map_keys`, and `bl_map_unset`.
    ```sh
    bl_map_init "BL_PIDS" ""
    bl_map_set "BL_PIDS" "$name" "$pid" ""
    ```

### Double Brackets (`[[ ... ]]`)
*   **Bashism**:
    ```bash
    [[ -n "$pid" ]]
    ```
*   **POSIX**: Replaced with standard single brackets.
    ```sh
    [ -n "$_bl_pid" ]
    ```

### Arithmetic Evaluation (`(( ... ))`)
*   **Bashism**:
    ```bash
    if (( ec == 0 || ec == 127 )); then
    ```
*   **POSIX**: Replaced with standard POSIX arithmetic tests.
    ```sh
    if [ "$_bl_ec" -eq 0 ] || [ "$_bl_ec" -eq 127 ]; then
    ```
