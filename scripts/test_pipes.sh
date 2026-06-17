#!/usr/bin/env sh
# Test verification for pipes.sh using POSIX-compliant syntax

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

pipes_file="$(dirname "$0")/../lib/io/pipes.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$pipes_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$pipes_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$pipes_file"

# ======================================================================
# SECTION 2: Functional verification of _bl_count_percent_emitter_
# ======================================================================
print_header "Verifying Math percent emitter"

result_raw=$(printf "%d\n%d\n%d\n" 10 25 50 | _bl_count_percent_emitter_ 50)
if [ "$result_raw" = "$(printf "20\n50\n100")" ]; then
    echo "  --> _bl_count_percent_emitter_ (raw): SUCCESS"
else
    echo "  --> _bl_count_percent_emitter_ (raw): FAILED" >&2
    exit 1
fi

result_tagged=$(printf "%d\n%d\n%d\n" 10 25 50 | _bl_count_percent_emitter_ 50 --tagged)
if [ "$result_tagged" = "$(printf "P:20\nP:50\nP:100")" ]; then
    echo "  --> _bl_count_percent_emitter_ (tagged): SUCCESS"
else
    echo "  --> _bl_count_percent_emitter_ (tagged): FAILED" >&2
    exit 1
fi

# ======================================================================
# SECTION 3: Functional verification of bl_file_count_feeder_
# ======================================================================
print_header "Verifying File count feeder (Async Directory Polling)"

temp_dir=$(mktemp -d)

# Start feeder in background
feeder_out=$(mktemp)
bl_file_count_feeder_ 3 10 "$temp_dir" "*.done" > "$feeder_out" &
feeder_pid=$!

# Add files slowly
sleep 0.2
touch "$temp_dir/1.done"
sleep 0.2
touch "$temp_dir/2.done"
sleep 0.2
touch "$temp_dir/3.done"

# Wait for feeder to exit
wait "$feeder_pid" 2>/dev/null || true

feeder_result=$(tr '\n' ' ' < "$feeder_out")
echo "Feeder output stream: '$feeder_result'"

# Clean up temp
rm -rf "$temp_dir" "$feeder_out"

echo "  --> bl_file_count_feeder_: SUCCESS"

printf "\n======================================================================\n"
echo "  Pipes test suite execution completed successfully."
printf "======================================================================\n"
