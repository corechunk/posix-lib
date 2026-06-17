# Porting Notes: `lib/io/pipes.sh` to POSIX

This document outlines the translations made to convert `lib/io/pipes.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Arithmetic loops & conditions (`while (( finished < total )); do`)
*   **Bashism**:
    ```bash
    while (( finished < total )); do
    ```
*   **POSIX**: Sourced directly as standard `while` logic utilizing `[`:
    ```sh
    while [ "$_bl_finished" -lt "$_bl_total" ]; do
    ```

### Array expansions (`local files=( "$dir"/$pattern )`)
*   **Bashism**:
    ```bash
    local files=( "$dir"/$pattern )
    finished=${#files[@]}
    [[ -e "${files[0]}" ]] || finished=0
    ```
*   **POSIX**: Iterated matching patterns via standard glob expansion, counting elements that exist:
    ```sh
    _bl_count=0
    for _bl_f in "$_bl_dir"/$_bl_pattern; do
        [ -e "$_bl_f" ] && _bl_count=$((_bl_count+1))
    done
    _bl_finished="$_bl_count"
    ```

### Double Brackets (`[[ $percent -ge 100 ]]`)
*   **Bashism**:
    ```bash
    [[ $percent -ge 100 ]] && break
    ```
*   **POSIX**: Translated to standard POSIX `[`:
    ```sh
    [ "$_bl_percent" -ge 100 ] && break
    ```

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -c '. lib/core/posix.sh && dash -n lib/io/pipes.sh'
posh -c '. lib/core/posix.sh && posh -n lib/io/pipes.sh'
```
Both outputs return successfully.
