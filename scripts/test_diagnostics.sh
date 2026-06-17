#!/usr/bin/env sh
# Test verification for diagnostics.sh using POSIX-compliant syntax

set -e

print_header() {
    printf "\n######################################################################\n"
    printf "  SECTION: %s\n" "$1"
    printf "######################################################################\n"
}

# ======================================================================
# Source requirements first
# ======================================================================
. "$(dirname "$0")/../lib/core/posix.sh"
. "$(dirname "$0")/../lib/core/import.sh"

# ======================================================================
# SECTION 1: Syntax compatibility verifications (-n checks)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"

diag_file="$(dirname "$0")/../lib/info/diagnostics.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$diag_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$diag_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$diag_file"

# ======================================================================
# SECTION 2: Functional verification of bl_info_check
# ======================================================================
print_header "Verifying bl_info_check Output"

# Run check
bl_info_check

printf "\n======================================================================\n"
echo "  Diagnostics test suite execution completed successfully."
printf "======================================================================\n"
