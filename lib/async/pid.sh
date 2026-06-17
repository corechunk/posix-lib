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
			wait "$_bl_pid"
		fi
	fi
	bl_map_unset "BL_PIDS" "$_bl_name"
}

# Queries process state via /proc or kill -0
bl_pid_status() {
	_bl_pid="$1"
	if [ -z "$_bl_pid" ]; then
		echo "FAILED"
		return 1
	fi
	if kill -0 "$_bl_pid" 2>/dev/null; then
		echo "RUNNING"
		return 0
	fi
	
	# Try to wait on it to harvest the code, discard output
	wait "$_bl_pid" 2>/dev/null
	_bl_ec=$?
	# 127 typically means the child already exited and was reaped
	if [ "$_bl_ec" -eq 0 ] || [ "$_bl_ec" -eq 127 ]; then
		echo "SUCCESS"
	else
		echo "FAILED"
	fi
	return $_bl_ec
}

# Non-blocking background scavenger sweep
bl_pid_reap() {
	for _bl_name in $(bl_map_keys "BL_PIDS" ""); do
		_bl_pid=$(bl_map_get "BL_PIDS" "$_bl_name" "" 2>/dev/null || true)
		if [ -n "$_bl_pid" ] && ! kill -0 "$_bl_pid" 2>/dev/null; then
			# Process is dead, wait to reap and capture exit code
			wait "$_bl_pid" 2>/dev/null
			bl_map_unset "BL_PIDS" "$_bl_name"
		fi
	done
}
