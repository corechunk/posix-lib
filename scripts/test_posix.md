# Verification Notes: `scripts/test_posix.sh`

This document details the express verification suite executed to test `lib/core/posix.sh` and syntax check `lib/core/import.sh`.

---

## 1. POSIX Verification Test Suite
The script `scripts/test_posix.sh` tests all core helper functions in a pure POSIX environment:
*   **Variable Registry**: `bl_var_init`, `bl_var_set`, `bl_var_get`, and `bl_cleanup_scope`.
*   **Array Emulation**: `bl_arr_init`, `bl_arr_append`, and `bl_arr_get`.
*   **Associative Map Emulation**: `bl_map_init`, `bl_map_set`, `bl_map_get`, and `bl_map_keys`.
*   **Logical Operations**: `posix_all_true` and `posix_any_true`.
*   **Pattern Matching**: `posix_match_glob` and `posix_match_regex`.
*   **Arithmetic Evaluation**: `posix_arith_test`.
*   **C-Style Loop Emulation**: `posix_for` (tested with 1 to 10 loop iterations).
*   **Substrings & Hex conversions**: `posix_substr` and `posix_hex_to_dec`.
*   **Pseudo-Random Range validation**: `posix_random` (tested with 8 range profiles).

### Execution Command:
```sh
sh scripts/test_posix.sh
```

---

## 2. Shell Compatibility Checks (-n syntax tests)
Syntax checking the rewritten library files requires sourcing the `posix.sh` module first to register map environments.

### Command for `posix.sh` Syntax Check:
```sh
dash -n lib/core/posix.sh
posh -n lib/core/posix.sh
```

### Command for `import.sh` Syntax Check:
```sh
dash -c '. lib/core/posix.sh && dash -n lib/core/import.sh'
posh -c '. lib/core/posix.sh && posh -n lib/core/import.sh'
```
Both tests confirm `SYNTAX OK` under both standard engines.
