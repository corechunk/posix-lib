# Master Porting & Architecture Notes: `bash-lib` to `posix-lib`

This document details the architecture, design choices, dependency structure, and testing model for the ported `posix-lib`.

---

## 1. Legacy vs. POSIX Architecture

### The Legacy `bash-lib` Behavior
*   In the original `bash-lib` codebase, scripts only contained function and variable declarations.
*   To use these modules, developers had to source `import.sh` first to register variables, environment states, and lookup trees.
*   Other library modules were dynamically resolved and loaded using the `import` or `bl_import` functions. Sourcing `import.sh` beforehand was mandatory for these helpers and map declarations to exist in execution memory.

### The Ported `posix-lib` Behavior
*   To support local scopes, dynamic variable registries, pseudo-arrays, and associative maps under strict POSIX shells, we introduced the helper wrapper library: `lib/core/posix.sh`.
*   Consequently, `lib/core/posix.sh` is now a direct dependency of `lib/core/import.sh`.
*   In fact, `posix.sh` is the underlying dependency foundation for **all** files in the repository.

---

## 2. Testing & Verification Pattern

Because of the new POSIX dependency chain, functional test verification must follow specific setup rules:

1.  **Testing `posix.sh`**:
    *   Since it has no other library dependencies, the test suite (`scripts/test_posix.sh`) syntax checks (`-n`) and sources `posix.sh` directly, then tests its functions.
2.  **Testing `import.sh`**:
    *   It relies on POSIX helpers. The test suite (`scripts/test_import.sh`) first sources `lib/core/posix.sh`, runs the syntax check (`-n`) on `lib/core/import.sh`, sources `import.sh`, and then tests the registry getters and loaders.
3.  **Testing All Other Modules**:
    *   Every other module in the library relies on the registry, maps, arrays, and imports.
    *   To syntax check (`-n`) or test any other module, the test script must:
        1.  Dot‑source `lib/core/posix.sh`
        2.  Dot‑source `lib/core/import.sh`
        3.  Run the syntax compatibility checks (`-n`) on the target script
        4.  Dot‑source the target script
        5.  Execute and verify all of its functions in various configurations.
