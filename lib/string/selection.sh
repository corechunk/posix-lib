#!/usr/bin/env bash

# TIER 1: Stateless Parser (Expands ranges like "1-3" and splits by delimiter)
# Args: $1=input_string, $2=delimiter (default: ,)
# Returns: Space-separated string on stdout. Exit 1 on syntax error.
bl_parse_selection() {
	local input="$1"
	local delim="${2:-,}"
	local -a expanded=()

	local -a parts
	IFS="$delim" read -ra parts <<< "$input"
	for p in "${parts[@]}"; do
		p="${p// /}" # trim spaces
		[[ -z "$p" ]] && continue
		
		if [[ "$p" == "all" || "$p" == "ALL" ]]; then
			expanded+=("all")
		elif [[ "$p" == *-* ]]; then
			local s="${p%-*}"
			local e="${p#*-}"
			if [[ "$s" =~ ^[0-9]+$ && "$e" =~ ^[0-9]+$ ]]; then
				# Simple expansion, no bounds checking yet
				for ((i=s; i<=e; i++)); do expanded+=("$i"); done
			else
				return 1 # Syntax error
			fi
		elif [[ "$p" =~ ^[0-9]+$ ]]; then
			expanded+=("$p")
		else
			return 1 # Invalid characters
		fi
	done
	echo "${expanded[*]}"
}

# TIER 2: Keyword Expander (Replaces "all" with 1..max)
# Args: $1=max_index, $@=list_from_tier1
# Returns: Space-separated numbers
bl_expand_selection() {
	local max=$1
	shift
	local -a final=()
	for item in "$@"; do
		if [[ "$item" == "all" ]]; then
			for ((i=1; i<=max; i++)); do final+=("$i"); done
		else
			final+=("$item")
		fi
	done
	echo "${final[*]}"
}

# TIER 3: Range Validator (Strictly checks bounds)
# Args: $1=max, $@=numbers
# Returns: Exit 0 if all valid, Exit 1 if any out of bounds
bl_validate_selection() {
	local max=$1
	shift
	[[ $# -eq 0 ]] && return 1
	for n in "$@"; do
		(( n > 0 && n <= max )) || return 1
	done
	return 0
}
