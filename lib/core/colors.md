# Porting Notes: `lib/core/colors.sh` to POSIX

This document outlines the translations made to convert `lib/core/colors.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Global variables & ANSI-C escaping (`declare -g` and `$'...'`)
*   **Bashism**:
    ```bash
    declare -g BL_RED=$'\e[31m'
    ```
*   **POSIX**: Sourced directly as standard variables with octal backslash formatting.
    ```sh
    BL_RED="\033[31m"
    ```

### Hex Slicing & Base Math (`${hex:0:2}` and `16#`)
*   **Bashism**:
    ```bash
    r=$((16#${hex:0:2}))
    ```
*   **POSIX**: Slices are handled using the `posix_substr` helper and decoded using `posix_hex_to_dec`.
    ```sh
    _bl_hex_r=$(posix_substr "$_bl_hex" 0 2)
    r=$(posix_hex_to_dec "$_bl_hex_r")
    ```

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -c '. lib/core/posix.sh && dash -n lib/core/colors.sh'
posh -c '. lib/core/posix.sh && posh -n lib/core/colors.sh'
```
Both outputs return successfully.
