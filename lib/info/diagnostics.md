# Porting Notes: `lib/info/diagnostics.sh` to POSIX

This document outlines the translations made to convert `lib/info/diagnostics.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Function Inspection (`declare -f`)
*   **Bashism**:
    ```bash
    declare -f "$func" >/dev/null
    ```
*   **POSIX**: Checked using the globally exported `posix_is_func` wrapper function (defined in `lib/core/posix.sh`):
    ```sh
    posix_is_func "$_bl_func"
    ```

### Array Verification (`declare -p`)
*   **Bashism**:
    ```bash
    declare -p BL_REGISTRY
    ```
*   **POSIX**: Verified using the underlying variable name initialized by the map helper:
    ```sh
    [ -n "$BL_MAP_BL_REGISTRY_" ]
    ```

### Arrays and Process Substitution Menu Indexing
*   **Bashism**:
    ```bash
    local -a sorted_types
    read -r -a sorted_types < <(echo "$types" | tr ' ' '\n' | sort | tr '\n' ' ')
    ```
*   **POSIX**: Replaced arrays with space-separated strings and processed selections using standard loops:
    ```sh
    _bl_types=$(bl_registry_get_types)
    _bl_sorted_types=$(echo "$_bl_types" | tr ' ' '\n' | sort | tr '\n' ' ')
    
    # Rendering index items sequentially
    _bl_i=1
    for _bl_t in $_bl_sorted_types; do
        printf "  %b%d)%b %s\n" "$_bl_c_yellow" "$_bl_i" "$_bl_c_reset" "$_bl_t"
        _bl_i=$((_bl_i+1))
    done

    # Finding selection by index count
    _bl_idx=1
    _bl_sel_cat=""
    for _bl_t in $_bl_sorted_types; do
        if [ "$_bl_idx" -eq "$cat_opt" ]; then
            _bl_sel_cat="$_bl_t"
            break
        fi
        _bl_idx=$((_bl_idx+1))
    done
    ```

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -c '. lib/core/posix.sh && . lib/core/import.sh && dash -n lib/info/diagnostics.sh'
posh -c '. lib/core/posix.sh && . lib/core/import.sh && posh -n lib/info/diagnostics.sh'
```
Both outputs return successfully.
