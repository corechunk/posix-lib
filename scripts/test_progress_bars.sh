#!/usr/bin/env sh
# Test verification for progress_bars.sh using POSIX-compliant syntax

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

import "lib/core/colors.sh"

# ======================================================================
# SECTION 1: Syntax compatibility verifications (-n checks)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"

bar_file="$(dirname "$0")/../lib/ui/progress_bars.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$bar_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$bar_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$bar_file"

# ======================================================================
# SECTION 2: Functional verification of progress bars
# ======================================================================
print_header "Verifying Progress Bars Execution"

# Helper to feed percentages 0 to 100
feed_percentages() {
    _i=0
    while [ "$_i" -le 100 ]; do
        echo "$_i"
        _i=$((_i + 10))
        sleep 0.1
    done
}

feed_tagged() {
    echo "M:Initializing..."
    echo "P:0"
    sleep 0.2
    echo "L:Loading chunk 1..."
    echo "P:20"
    sleep 0.2
    echo "L:Loading chunk 2..."
    echo "P:40"
    sleep 0.2
    echo "L:Loading chunk 3..."
    echo "P:60"
    sleep 0.2
    echo "L:Loading chunk 4..."
    echo "P:80"
    sleep 0.2
    echo "L:Finishing..."
    echo "P:100"
    sleep 0.2
}

# 1. Test Linear Progress Bar
echo "Running bl_progress_bar (Linear)..."
feed_percentages | bl_progress_bar --width 40
echo "  --> bl_progress_bar (Linear): SUCCESS"

# 2. Test Tagged Progress Bar with Status and Logs
echo "Running bl_progress_bar (Tagged)..."
feed_tagged | bl_progress_bar --status --log --log-height 2 --width 40
echo "  --> bl_progress_bar (Tagged): SUCCESS"

# 3. Test Square Progress
echo "Running bl_square_progress..."
feed_percentages | bl_square_progress --width 5 --height 5
echo "  --> bl_square_progress: SUCCESS"

# 4. Test Spiral Progress
echo "Running bl_spiral_progress..."
feed_percentages | bl_spiral_progress --width 5 --height 5 --color-mode position
echo "  --> bl_spiral_progress: SUCCESS"

# 5. Test Terrain Loader
echo "Running bl_terrain_loader..."
feed_percentages | bl_terrain_loader --width 10 --height 5 --pattern random
echo "  --> bl_terrain_loader: SUCCESS"

printf "\n======================================================================\n"
echo "  Progress Bars test suite execution completed successfully."
printf "======================================================================\n"
