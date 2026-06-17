# Porting Notes: `lib/ui/progress_bars.sh` to POSIX

This document outlines the translations made to convert `lib/ui/progress_bars.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Removal of Native Arrays (`local -a`, `local -A`)
*   **Bashism**: Standard array structures for log buffers, cell mappings, and grid configurations.
*   **POSIX**: Dynamically constructed in-memory variable spaces using `eval` keys (e.g. `_bl_log_buffer_X`, `_bl_cell_order_X_Y`, `_bl_grid_X`), providing fast O(1) performance without disk I/O bottlenecks.

### Process Substitution and Sorting (`sort < <(...)`)
*   **Bashism**: Sorting arrays using process substitutions.
*   **POSIX**: Redirected outputs from standard loop constructs to temporary files (`mktemp`) and processed them using redirected standard inputs (`< file`), keeping variable modifications inside the current execution context.

### Timed Non-blocking Reads (`read -t`)
*   **Bashism**: Using `read -t 0.01` to prevent blocking.
*   **POSIX**: Migrated stream reading to a standard `read -r` line loop, which processes updates sequentially as they flow from the feeder stream, eliminating CPU-spinning sleep loops.

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -n lib/ui/progress_bars.sh
posh -n lib/ui/progress_bars.sh
```
Both syntax checks pass successfully.
