#!/usr/bin/env sh
# Test verification for colors.sh using POSIX-compliant syntax

set -e

print_header() {
    printf "\n######################################################################\n"
    printf "  SECTION: %s\n" "$1"
    printf "######################################################################\n"
}

# ======================================================================
# Source requirements first so environment variables/helpers are defined
# ======================================================================
. "$(dirname "$0")/../lib/core/posix.sh"

# ======================================================================
# SECTION 1: Syntax compatibility verifications (-n checks)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"
cat <<'EOF'
```sh
dash -n lib/core/colors.sh
posh -n lib/core/colors.sh
```
EOF

colors_file="$(dirname "$0")/../lib/core/colors.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$colors_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$colors_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$colors_file"

# ======================================================================
# SECTION 2: Verify Color Escape Codes
# ======================================================================
print_header "Verifying Color Escape Codes"

if [ -n "$BL_RED" ] && [ -n "$BL_GREEN" ] && [ -n "$BL_RESET" ]; then
    printf "  --> %bRED COLOR%b\n" "$BL_RED" "$BL_RESET"
    printf "  --> %bGREEN COLOR%b\n" "$BL_GREEN" "$BL_RESET"
    printf "  --> %bYELLOW COLOR%b\n" "$BL_YELLOW" "$BL_RESET"
    printf "  --> %bSKY BLUE COLOR%b\n" "$BL_SKY_BLUE" "$BL_RESET"
    echo "Color variables verified successfully."
else
    echo "ERROR: Color variables not loaded properly." >&2
    exit 1
fi

# ======================================================================
# SECTION 3: Verify Hex to RGB Conversion
# ======================================================================
print_header "Verifying bl_hex_to_rgb Conversion"

verify_hex_rgb() {
    hex="$1"
    expected="$2"
    result=$(bl_hex_to_rgb "$hex")
    if [ "$result" = "$expected" ]; then
        echo "  --> bl_hex_to_rgb '$hex' = '$result' (SUCCESS)"
    else
        echo "  --> bl_hex_to_rgb '$hex' = '$result' (Expected: '$expected') - FAILED" >&2
        exit 1
    fi
}

verify_hex_rgb "#FF00FF" "255 0 255"
verify_hex_rgb "00FF00" "0 255 0"
verify_hex_rgb "#123456" "18 52 86"
verify_hex_rgb "invalid" "0 0 0"

printf "\n======================================================================\n"
echo "  Colors test suite execution completed successfully."
printf "======================================================================\n"
