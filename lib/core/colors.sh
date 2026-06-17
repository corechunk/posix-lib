# --- ANSI Escape Color Codes (Raw and Fast) ---
BL_RED="\033[31m"
BL_GREEN="\033[32m"
BL_YELLOW="\033[33m"
BL_ORANGE="\033[38;5;166m"
BL_SKY_BLUE="\033[36m"
BL_MAGENTA="\033[35m"
BL_WHITE="\033[37m"
BL_RESET="\033[0m"

# --- Additional ANSI Colors ---
BL_BLUE="\033[34m"
BL_BLACK="\033[30m"
BL_GRAY="\033[90m"
BL_BRIGHT_RED="\033[91m"
BL_BRIGHT_GREEN="\033[92m"
BL_BRIGHT_YELLOW="\033[93m"
BL_BRIGHT_BLUE="\033[94m"
BL_BRIGHT_MAGENTA="\033[95m"
BL_BRIGHT_CYAN="\033[96m"
BL_BRIGHT_WHITE="\033[97m"

# Convert Hex color string (e.g., #00FF00 or 00FF00) to space-separated RGB decimals
# Usage: bl_hex_to_rgb <HEX_STRING>
bl_hex_to_rgb() {
    _bl_hex="${1#\#}"
    _bl_len=$(printf "%s" "$_bl_hex" | wc -c | tr -d ' ')
    if [ "$_bl_len" -eq 6 ]; then
        _bl_hex_r=$(posix_substr "$_bl_hex" 0 2)
        _bl_hex_g=$(posix_substr "$_bl_hex" 2 2)
        _bl_hex_b=$(posix_substr "$_bl_hex" 4 2)
        
        r=$(posix_hex_to_dec "$_bl_hex_r")
        g=$(posix_hex_to_dec "$_bl_hex_g")
        b=$(posix_hex_to_dec "$_bl_hex_b")
    else
        r=0; g=0; b=0
    fi
    echo "$r $g $b"
}
