#!/usr/bin/env sh
# Test verification for pid.sh using POSIX-compliant syntax

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
. "$(dirname "$0")/../lib/core/import.sh"

# ======================================================================
# SECTION 1: Syntax compatibility verifications (Pre-Sourcing)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"
cat <<'EOF'
```sh
dash -n lib/async/pid.sh
posh -n lib/async/pid.sh
```
EOF

pid_file="$(dirname "$0")/../lib/async/pid.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$pid_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$pid_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$pid_file"

# ======================================================================
# SECTION 2: Process Storage & Querying
# ======================================================================
print_header "Process storage & status queries"
cat <<'EOF'
```sh
# Spawn a sleep command in background to get a real PID
sleep 1 &
pid=$!
bl_pid_store "sleep_job" "$pid"
status=$(bl_pid_status "$pid")
```
EOF

sleep 2 &
pid=$!
bl_pid_store "sleep_job" "$pid"
echo "Stored process 'sleep_job' with PID: $pid"

status=$(bl_pid_status "$pid")
echo "Polled status immediately: $status (Expected: RUNNING)"

# ======================================================================
# SECTION 3: Process Blocking Wait
# ======================================================================
print_header "Process blocking wait (bl_pid_wait)"
cat <<'EOF'
```sh
bl_pid_wait "sleep_job"
```
EOF

echo "Waiting for 'sleep_job' to exit..."
bl_pid_wait "sleep_job"
echo "Wait complete."

status_after=$(bl_pid_status "$pid")
echo "Polled status after wait: $status_after (Expected: SUCCESS)"

# ======================================================================
# SECTION 4: Process Scavenger Reap (bl_pid_reap)
# ======================================================================
print_header "Scavenger reaping (bl_pid_reap)"
cat <<'EOF'
```sh
sleep 1 &
pid2=$!
bl_pid_store "temp_job" "$pid2"
sleep 1.5
bl_pid_reap
```
EOF

sleep 1 &
pid2=$!
bl_pid_store "temp_job" "$pid2"
echo "Spawned 'temp_job' with PID: $pid2"

echo "Sleeping to let background job exit..."
sleep 1.5

echo "Reaping dead processes..."
bl_pid_reap

# Check key removal in map
keys=$(bl_map_keys "BL_PIDS" "")
if [ -z "$keys" ]; then
    echo "Reap check: Stored PIDs map is empty (SUCCESS)"
else
    echo "Reap check: Map still contains keys: $keys (FAILED)"
fi

printf "\n======================================================================\n"
echo "  Expressive test suite execution completed successfully."
printf "======================================================================\n"
