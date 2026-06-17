#!/usr/bin/env sh
# Test verification for versions.sh using POSIX-compliant syntax

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

# ======================================================================
# SECTION 1: Syntax compatibility verifications (-n checks)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"

versions_file="$(dirname "$0")/../lib/core/versions.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$versions_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$versions_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$versions_file"

# ======================================================================
# SECTION 2: Functional verification of bl_version_compare
# ======================================================================
print_header "Verifying bl_version_compare Logic"

verify_comparison() {
    v1="$1"
    v2="$2"
    expected="$3"
    result=$(bl_version_compare "$v1" "$v2")
    if [ "$result" = "$expected" ]; then
        echo "  --> $v1 vs $v2 = '$result' (SUCCESS)"
    else
        echo "  --> $v1 vs $v2 = '$result' (Expected: '$expected') - FAILED" >&2
        exit 1
    fi
}

# 1. Equal versions
verify_comparison "1.2.3.4" "1.2.3.4" "equal"
verify_comparison "v1.2.0" "1.2" "equal"

# 2. Hotfix updates
verify_comparison "1.2.3.4" "1.2.3.5" "hotfix update"
verify_comparison "1.0.0.0" "1.0.0.1" "hotfix update"

# 3. Patch updates
verify_comparison "1.2.3" "1.2.4" "patch update"
verify_comparison "1.2.3.4" "1.2.4" "patch update"

# 4. Minor updates
verify_comparison "1.2" "1.3" "minor update"
verify_comparison "1.2.3.4" "1.3" "minor update"

# 5. Major updates
verify_comparison "1" "2" "major update"
verify_comparison "1.9.9.9" "2.0.0.0" "major update"

# 6. Downgrades
verify_comparison "2.0.0" "1.9.9" "downgrade"
verify_comparison "1.2.3.5" "1.2.3.4" "downgrade"

# 7. Invalid/Unknown
verify_comparison "" "1.0.0" "unknown"
verify_comparison "1.0.0" "" "unknown"

printf "\n======================================================================\n"
echo "  Versions test suite execution completed successfully."
printf "======================================================================\n"
