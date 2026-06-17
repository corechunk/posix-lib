# Porting Notes: `lib/core/posix.sh` Helper Engine

This document details the core POSIX sh emulation wrappers and implementation specifics of the `posix.sh` library helper engine.

---

## 1. Engine Emulation Features

To replace native Bash features, the helper engine implements the following POSIX-compliant APIs:

*   **Variable Namespacing (`bl_var_*`)**: Stores values using dynamically exported `BL_VAR_<NAME>_<SALT>` strings.
*   **Array Emulation (`bl_arr_*`)**: Mimics 0-indexed arrays using temporary files with `\0` (NUL) byte separators.
*   **Associative Maps (`bl_map_*`)**: Mimics associative key-value dictionaries using real temporary subdirectories. Key files are safe-sanitized via `tr ':/.-' '____'`.
*   **Cleanup Sweepers (`bl_cleanup_*`)**: Garbage-collects scope-specific variables, arrays, and maps when functions exit.
*   **String/Math Helpers (`posix_*`)**: Emulates string slicing (`posix_substr`), hex conversions (`posix_hex_to_dec`), and pseudo-random generators (`posix_random`).
*   **Function Inspection (`posix_is_func`)**: Verifies if a utility name is loaded in current shell execution memory by checking standard POSIX `command -V` or `type` outputs.

---

## 2. Notable Porting Corrections

### Resource Registry Scope delimiter
*   **Issue**: Originally, resource tracking used colons `:` to separate resource properties (e.g. `type:name:salt`). However, since `bl_map_set` sanitizes key names by replacing colons with underscores `_`, the filenames stored on disk lost their delimiters, which broke parser extractions `%%:*` and `#*:`.
*   **Fix**: Modified the tracking register to use pipes (`|`) as the delimiter. Because `|` is not translated by the key sanitization rules, it preserves structure:
    ```sh
    # Keys created on disk:
    VAR|USER_SHELL|eBgidK
    ```
    This enables clean, safe substring extraction during `bl_cleanup_scope` and `bl_cleanup_global` sweeps.
