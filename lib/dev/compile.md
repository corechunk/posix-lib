# Porting Notes: `lib/dev/compile.sh` to POSIX

This document outlines the translations made to convert `lib/dev/compile.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Config Variables & Local Arrays
*   **Bashism**:
    ```bash
    local source_dir=""
    local -a compile_remote_urls=()
    ```
*   **POSIX**: Leveraged `posix.sh` pseudo-arrays (`bl_arr_*`) and mapped configuration entries with scopes cleaned dynamically:
    ```sh
    _bl_salt=$(_bl_gen_salt)
    bl_map_init "COMPILE_CFG" "$_bl_salt"
    bl_arr_init "COMPILE_REMOTE_URLS" "$_bl_salt"
    ```

### Command Expansion & Non-Standard find Options (`-maxdepth`)
*   **Bashism**:
    ```bash
    local find_cmd=("find" "$source_dir")
    if [[ "$recursive" -eq 0 ]]; then
        find_cmd+=("-maxdepth" "1")
    fi
    ```
*   **POSIX**: Split non-recursive loops using standard POSIX `ls` and `for` expansions, and recursive file listing using standard `find` operations:
    ```sh
    if [ "$_bl_recursive" -eq 1 ]; then
        for _f in $(find "$_bl_source_dir" -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null | sort); do
            bl_arr_append "COMPILE_FILES" "$_f" "$_bl_salt"
        done
    else
        for _f in "$_bl_source_dir"/*.sh "$_bl_source_dir"/*.bash; do
            [ -f "$_f" ] || continue
            bl_arr_append "COMPILE_FILES" "$_f" "$_bl_salt"
        done
    fi
    ```

### Dynamic array values inside case arguments
*   **Bashism**:
    ```bash
    for url in "${compile_remote_urls[@]}"; do
    ```
*   **POSIX**: Read values sequentially from the pseudo-array:
    ```sh
    _bl_num_urls=$(tr '\0' '\n' < "$_bl_remote_path" | wc -l | tr -d ' ')
    _bl_ui=0
    while [ "$_bl_ui" -lt "$_bl_num_urls" ]; do
        _bl_url=$(bl_arr_get "COMPILE_REMOTE_URLS" "$_bl_ui" "$_bl_salt")
        ...
        _bl_ui=$((_bl_ui+1))
    done
    ```

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -c '. lib/core/posix.sh && . lib/core/import.sh && dash -n lib/dev/compile.sh'
posh -c '. lib/core/posix.sh && . lib/core/import.sh && posh -n lib/dev/compile.sh'
```
Both outputs return successfully.
