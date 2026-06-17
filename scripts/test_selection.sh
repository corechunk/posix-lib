#!/usr/bin/env sh
# Test verification for selection.sh using POSIX-compliant syntax

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

selection_file="$(dirname "$0")/../lib/string/selection.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$selection_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$selection_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$selection_file"

# ======================================================================
# SECTION 2: Functional verification of Selection helpers
# ======================================================================
print_header "Verifying Selection Parser, Expander and Validator"

verify_parser() {
    input="$1"
    expected="$2"
    result=$(bl_parse_selection "$input")
    if [ "$result" = "$expected" ]; then
        echo "  --> bl_parse_selection '$input' = '$result' (SUCCESS)"
    else
        echo "  --> bl_parse_selection '$input' = '$result' (Expected: '$expected') - FAILED" >&2
        exit 1
    fi
}

verify_parser "1,2,3" "1 2 3"
verify_parser "1-3,5" "1 2 3 5"
verify_parser "all" "all"
verify_parser "  1-3 ,  5 " "1 2 3 5"

# Verify syntax error
if bl_parse_selection "invalid_chars" >/dev/null 2>&1; then
    echo "  --> bl_parse_selection 'invalid_chars' (Expected: Error) - FAILED" >&2
    exit 1
else
    echo "  --> bl_parse_selection 'invalid_chars' = Error (SUCCESS)"
fi

# Expander check
expanded=$(bl_expand_selection 5 1 2 all 4)
if [ "$expanded" = "1 2 1 2 3 4 5 4" ]; then
    echo "  --> bl_expand_selection = '$expanded' (SUCCESS)"
else
    echo "  --> bl_expand_selection = '$expanded' (Expected: '1 2 1 2 3 4 5 4') - FAILED" >&2
    exit 1
fi

expanded_all=$(bl_expand_selection 5 all)
if [ "$expanded_all" = "1 2 3 4 5" ]; then
    echo "  --> bl_expand_selection 5 all = '$expanded_all' (SUCCESS)"
else
    echo "  --> bl_expand_selection 5 all = '$expanded_all' (Expected: '1 2 3 4 5') - FAILED" >&2
    exit 1
fi

# Validator check
if bl_validate_selection 5 1 2 3 4 5; then
    echo "  --> bl_validate_selection 5 [1 2 3 4 5] = Valid (SUCCESS)"
else
    echo "  --> bl_validate_selection 5 [1 2 3 4 5] = Invalid - FAILED" >&2
    exit 1
fi

if ! bl_validate_selection 5 1 6; then
    echo "  --> bl_validate_selection 5 [1 6] = Invalid (SUCCESS)"
else
    echo "  --> bl_validate_selection 5 [1 6] = Valid - FAILED" >&2
    exit 1
fi

printf "\n======================================================================\n"
echo "  Selection test suite execution completed successfully."
printf "======================================================================\n"
