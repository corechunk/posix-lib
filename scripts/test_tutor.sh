#!/usr/bin/env sh
# Test verification for tutor.sh using POSIX-compliant syntax

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

tutor_file="$(dirname "$0")/../lib/info/tutor.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$tutor_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$tutor_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$tutor_file"

# ======================================================================
# SECTION 2: Functional verification
# ======================================================================
print_header "Verifying bl_bash_tutor lesson retrieval"

# Retrieve lesson 1 output
lesson_out=$(bl_bash_tutor 01-posix-overview)

if echo "$lesson_out" | grep -q "Milestone 01: POSIX Shell Overview"; then
    echo "  --> Topic 01 Retrieval: SUCCESS"
else
    echo "  --> Topic 01 Retrieval: FAILED" >&2
    exit 1
fi

printf "\n======================================================================\n"
echo "  Tutor test suite checks completed successfully."
printf "======================================================================\n"

# Launch the interactive tutor if connected to a terminal (user observer)
if [ -t 0 ] && [ -t 1 ]; then
    printf "\n"
    printf "Launch interactive POSIX Compliance Tutor? [y/N]: "
    read -r launch_choice
    case "$launch_choice" in
        [yY]|[yY][eE][sS])
            bl_bash_tutor
            ;;
    esac
fi
