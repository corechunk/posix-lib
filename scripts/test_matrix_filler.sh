#!/usr/bin/env sh
# Test verification for matrix_filler.sh using POSIX-compliant syntax

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

matrix_file="$(dirname "$0")/../lib/ui/matrix_filler.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$matrix_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$matrix_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$matrix_file"

# ======================================================================
# SECTION 2: Functional verification of bl_matrix_filler
# ======================================================================
print_header "Verifying bl_matrix_filler Execution (Short 5s duration per mode)"

# 1. Test Classic Mode
echo "Running Matrix Filler: Classic Mode (5s, low density 150)..."
bl_matrix_filler --duration 5 --mode classic --density 150
echo "  --> Classic Mode: SUCCESS"

# 2. Test Rain Mode
echo "Running Matrix Filler: Rain Mode (5s, low density 150)..."
bl_matrix_filler --duration 5 --mode rain --density 150
echo "  --> Rain Mode: SUCCESS"

# 3. Test Fade Mode
echo "Running Matrix Filler: Fade Mode (5s, low density 150)..."
bl_matrix_filler --duration 5 --mode fade --density 150
echo "  --> Fade Mode: SUCCESS"

printf "\n======================================================================\n"
echo "  Matrix Filler test suite execution completed successfully."
printf "======================================================================\n"
