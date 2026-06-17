#!/usr/bin/env sh
# --- posix-lib Feeder Pipes (POSIX Compliant) ---

# 1. Logic Layer: Monitors a directory for files matching a pattern and emits raw finished count
# Args: $1=Total, $2=Hz, $3=Directory, $4=Pattern
bl_file_count_feeder_() {
    _bl_total=$1
    _bl_hz=${2:-10}
    _bl_dir="${3:-/tmp}"
    _bl_pattern="${4:-*.done}"
    _bl_finished=0
    
    # Convert Hz to decimal interval (POSIX arithmetic)
    _bl_ms=$(( 1000 / _bl_hz ))
    _bl_interval=$(printf "%d.%03d" $(( _bl_ms / 1000 )) $(( _bl_ms % 1000 )))

    while [ "$_bl_finished" -lt "$_bl_total" ]; do
        _bl_count=0
        for _bl_f in "$_bl_dir"/$_bl_pattern; do
            [ -e "$_bl_f" ] && _bl_count=$((_bl_count+1))
        done
        _bl_finished="$_bl_count"
        
        echo "$_bl_finished"
        sleep "$_bl_interval"
    done
}

# 2. Math Layer: Converts raw count to 0-100 stream
# Args: $1=Total, $2=Format (optional: "v2" for P: tag)
# _bl_count_percent_emitter_ now accepts a flag "tagged" (or "--tagged") to emit P: prefixed percentages
_bl_count_percent_emitter_() {
    _bl_total=$1
    _bl_flag="$2"
    while read -r _bl_count; do
        _bl_percent=$(( (_bl_count * 100) / _bl_total ))
        if [ "$_bl_flag" = "tagged" ] || [ "$_bl_flag" = "--tagged" ]; then
            echo "P:$_bl_percent"
        else
            echo "$_bl_percent"
        fi
        [ "$_bl_percent" -ge 100 ] && break
    done
}

# bl_file_log_feeder_ now accepts an optional third argument specifying the prefix (default M:)
bl_file_log_feeder_() {
    _bl_logfile="$1"
    _bl_hz=${2:-5}
    _bl_prefix="${3:-M:}"
    _bl_ms=$(( 1000 / _bl_hz ))
    _bl_interval=$(printf "%d.%03d" $(( _bl_ms / 1000 )) $(( _bl_ms % 1000 )))
    
    while [ -f "$_bl_logfile" ]; do
        _bl_line=$(tail -n 1 "$_bl_logfile" | cut -c 1-80)
        echo "${_bl_prefix}${_bl_line}"
        sleep "$_bl_interval"
    done
}
