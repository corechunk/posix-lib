# Porting Notes: `lib/info/tutor.sh` to POSIX

This document outlines the translations made to convert `lib/info/tutor.sh` from Bash-only syntax to POSIX-compliant shell script.

---

## 1. Replacements Implemented

### Subscriptions of Arrays (`topics=( ... )`)
*   **Bashism**: Standard array collections.
*   **POSIX**: Replaced with space-separated string collections, iterating using custom internal separators (`IFS=" "`) and positional parameters when required.

### Sed Escape Interpretations (`sed -e "s/.../\033.../g"`)
*   **Bashism**: Passing color sequences directly into replacement arguments.
*   **POSIX**: Extracted literal ESC bytes (`printf '\033'`) to assign color variables directly, preventing `sed` from interpreting `\0` as a match backreference.

---

## 2. Syntax Check
Validated successfully under `dash` and `posh`:
```sh
dash -n lib/info/tutor.sh
posh -n lib/info/tutor.sh
```
Both syntax checks pass successfully.
