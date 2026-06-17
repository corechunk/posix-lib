# Porting Notes: `lib/ui/matrix_filler.sh` to POSIX

This document outlines the translations made to convert `lib/ui/matrix_filler.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Fast In-Memory LCG Random State Initialization (`$RANDOM`)
*   **Bashism**: Using `$RANDOM` to generate integers.
*   **POSIX**: Integrated a pure-arithmetic, in-memory Linear Congruential Generator (LCG) function (`_bl_mem_rand`) that does not require spawning subprocesses (`od`, `shuf`, etc.), ensuring real-time performance.
    ```sh
    _bl_rand_state=$(date +%s)
    _bl_mem_rand() {
        _bl_rand_state=$(( (1103515245 * _bl_rand_state + 12345) % 2147483648 ))
        _bl_rand_val=$(( _bl_rand_state ))
        ...
    }
    ```

### Terminal Commands under `set -e`
*   **Bashism**: Standard unshielded calls to `tput` or `clear`.
*   **POSIX**: Shielded all terminal control escapes (`tput civis`, `tput sgr0`, `clear`, etc.) using `|| true` to prevent shell aborts when executing under strict `set -e` environments.

### Cleanup Traps Compatibility
*   **Bashism**: Trapping on `RETURN` or other non-POSIX shell exit signals.
*   **POSIX**: Declared compatible traps limited strictly to `INT TERM` signals to ensure uniform execution under Dash/Posh.

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -n lib/ui/matrix_filler.sh
posh -n lib/ui/matrix_filler.sh
```
Both syntax checks pass successfully.
