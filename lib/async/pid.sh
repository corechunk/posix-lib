#!/usr/bin/env sh

# Global registry for active background PIDs
bl_map_init "BL_PIDS" ""

# Takes Name ($1) and PID ($2)
bl_pid_store() {
	_bl_name=$1
	_bl_pid=$2
	bl_map_set "BL_PIDS" "$_bl_name" "$_bl_pid" ""
}

# Takes Name ($1), waits if active, then unsets
bl_pid_wait() {
	_bl_name=$1
	_bl_pid=$(bl_map_get "BL_PIDS" "$_bl_name" "" 2>/dev/null || true)
	if [ -n "$_bl_pid" ]; then
		if kill -0 "$_bl_pid" 2>/dev/null; then
			wait "$_bl_pid" 2>/dev/null || true
		fi
	fi
	bl_map_unset_key "BL_PIDS" "$_bl_name" ""
}

# Queries process state via /proc or kill -0
bl_pid_status() {
	_bl_spid="$1"
	if [ -z "$_bl_spid" ]; then
		echo "FAILED"
		return 1
	fi
	if kill -0 "$_bl_spid" 2>/dev/null; then
		echo "RUNNING"
		return 0
	fi
	
	# Try to wait on it to harvest the code, discard output.
	# Note: in POSIX, wait on an already-exited/harvested child returns 127.
	wait "$_bl_spid" 2>/dev/null || true
	_bl_sec=$?
	if [ "$_bl_sec" -eq 0 ] || [ "$_bl_sec" -eq 127 ]; then
		echo "SUCCESS"
		return 0
	else
		echo "FAILED"
		return "$_bl_sec"
	fi
}

# Non-blocking background scavenger sweep
bl_pid_reap() {
	for _bl_name in $(bl_map_keys "BL_PIDS" ""); do
		_bl_pid=$(bl_map_get "BL_PIDS" "$_bl_name" "" 2>/dev/null || true)
		if [ -n "$_bl_pid" ]; then
			if ! kill -0 "$_bl_pid" 2>/dev/null; then
				# Process is dead, wait to reap and capture exit code safely
				wait "$_bl_pid" 2>/dev/null || true
				bl_map_unset_key "BL_PIDS" "$_bl_name" ""
			fi
		else
			# Key exists but value is empty, cleanup registry key
			bl_map_unset_key "BL_PIDS" "$_bl_name" ""
		fi
	done
}


