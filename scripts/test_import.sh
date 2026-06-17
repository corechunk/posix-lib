#!/usr/bin/env sh
# Test verification for import.sh using POSIX-compliant syntax
# Note: Because both posix.sh and import.sh are written in strict POSIX, this test script
# can be run directly with a standard POSIX shell (e.g. `sh scripts/test_import.sh` or `dash scripts/test_import.sh`).
set -e


# Source requirements first so environment mappings are populated
. "$(dirname "$0")/../lib/core/posix.sh"

print_header() {
    printf "\n######################################################################\n"
    printf "  SECTION: %s\n" "$1"
    printf "######################################################################\n"
}

# ======================================================================
# SECTION 1: Syntax compatibility verifications (Pre-Sourcing)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"
cat <<'EOF'
```sh
dash -n lib/core/import.sh
posh -n lib/core/import.sh
```
EOF

import_file="$(dirname "$0")/../lib/core/import.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$import_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$import_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source import.sh
# ======================================================================
. "$import_file"

# ======================================================================
# SECTION 2: Dependency Verification Checks (bl_check_deps)
# ======================================================================
print_header "Dependency verifications"
cat <<'EOF'
```sh
bl_check_deps "caller_func" "curl" "sh"
bl_check_deps "caller_func" "nonexistent_command_xyz"
```
EOF

if bl_check_deps "TestCaller" "curl" "sh"; then
    echo "Dependencies verify check: SUCCESS (curl and sh exist)"
else
    echo "Dependencies verify check: FAILED"
fi

if ! bl_check_deps "TestCaller" "nonexistent_command_xyz" 2>/dev/null; then
    echo "Dependencies verify check: SUCCESS (nonexistent_command_xyz correctly reported missing)"
else
    echo "Dependencies verify check: FAILED"
fi

# ======================================================================
# SECTION 3: Registry Key/Type Retrieval
# ======================================================================
print_header "Registry mapping lookups"
cat <<'EOF'
```sh
types=$(bl_registry_get_types)
core_funcs=$(bl_registry_get_funcs "core")
deps=$(bl_registry_get_deps "bl_update_registry")
```
EOF

types=$(bl_registry_get_types)
echo "Registered types: $types"

core_funcs=$(bl_registry_get_funcs "core")
echo "Core functions registered: $core_funcs"

deps=$(bl_registry_get_deps "bl_update_registry")
echo "Deps of bl_update_registry: '$deps' (Expected: 'curl|jq')"

# ======================================================================
# SECTION 4: Remote Sourcing Pattern Check (bl_import)
# ======================================================================
print_header "Remote Import (bl_import) mapping rules"
cat <<'EOF'
```sh
bl_import "core/colors.sh"
```
EOF

if bl_import "core/colors.sh"; then
    echo "bl_import remote glob matching: SUCCESS"
else
    echo "bl_import remote glob matching: FAILED"
fi

# ======================================================================
# SECTION 5: Local Import Pattern Check (import / bl_import_local)
# ======================================================================
print_header "Local Import (import) resolution"
cat <<'EOF'
```sh
import "lib/core/colors.sh"
```
EOF

if import "lib/core/colors.sh"; then
    echo "import local resolver check: SUCCESS"
else
    echo "import local resolver check: FAILED"
fi

printf "\n======================================================================\n"
echo "  Expressive test suite execution completed successfully."
printf "======================================================================\n"
