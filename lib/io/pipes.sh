#!/usr/bin/env bash

# 1. Logic Layer: Monitors a directory for files matching a pattern and emits raw finished count
# Args: $1=Total, $2=Hz, $3=Directory, $4=Pattern
bl_file_count_feeder_() {
	local total=$1
	local hz=${2:-10}
	local dir="${3:-/tmp}"
	local pattern="${4:-*.done}"
	local finished=0
	
	# Convert Hz to decimal interval (Bash Integer Scaling)
	local ms=$(( 1000 / hz ))
	local interval=$(printf "%d.%03d" $(( ms / 1000 )) $(( ms % 1000 )))

	while (( finished < total )); do
		local files=( "$dir"/$pattern )
		finished=${#files[@]}
		[[ -e "${files[0]}" ]] || finished=0
		
		echo "$finished"
		sleep "$interval"
	done
}

# 2. Math Layer: Converts raw count to 0-100 stream
# Args: $1=Total, $2=Format (optional: "v2" for P: tag)
# _bl_count_percent_emitter_ now accepts a flag "tagged" (or "--tagged") to emit P: prefixed percentages
_bl_count_percent_emitter_() {
    local total=$1
    local flag="$2"
    while read -r count; do
        local percent=$(( (count * 100) / total ))
        if [[ "$flag" == "tagged" || "$flag" == "--tagged" ]]; then
            echo "P:$percent"
        else
            echo "$percent"
        fi
        [[ $percent -ge 100 ]] && break
    done
}

# bl_file_log_feeder_ now accepts an optional third argument specifying the prefix (default M:)
bl_file_log_feeder_() {
    local logfile="$1"
    local hz=${2:-5}
    local prefix="${3:-M:}"
    local ms=$(( 1000 / hz ))
    local interval=$(printf "%d.%03d" $(( ms / 1000 )) $(( ms % 1000 )))
    while [[ -f "$logfile" ]]; do
        local line=$(tail -n 1 "$logfile" | cut -c 1-80)
        echo "${prefix}${line}"
        sleep "$interval"
    done
}
