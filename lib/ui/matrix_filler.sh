# Enhanced matrix filler animation with multiple modes, color gradients, and language character sets.
# Supports start/end colors as either tput index or hexadecimal (e.g., "#00FF00").
# Dependencies: tput, bl_check_deps (project utility)

# Helper: Convert hex color to RGB components
hex_to_rgb() {
  _bl_hex=$1
  _bl_hex=${_bl_hex#"#"}
  _bl_r=$(posix_hex_to_dec "$(posix_substr "$_bl_hex" 0 2)")
  _bl_g=$(posix_hex_to_dec "$(posix_substr "$_bl_hex" 2 2)")
  _bl_b=$(posix_hex_to_dec "$(posix_substr "$_bl_hex" 4 2)")
  printf "%d %d %d" "$_bl_r" "$_bl_g" "$_bl_b"
}

# Helper: Build ANSI escape sequence for truecolor foreground
rgb_seq() {
  printf "\033[38;2;%s;%s;%sm" "$1" "$2" "$3"
}

bl_matrix_filler() {
    # Parse options
    _bl_mode="classic"        # classic | rain | fade
    _bl_start_color=2          # default tput color index (green)
    _bl_end_color=7            # default tput color index (white)
    _bl_start_hex=""          # optional hex overrides
    _bl_end_hex=""
    _bl_langs=""              # combination of j,c,k for Japanese, Chinese, Korean
    _bl_density=50            # default spawn probability (lower = denser)
    _bl_duration=5            # default to 5 seconds
    
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --mode) _bl_mode="$2"; shift 2;;
            --start-color) _bl_start_color="$2"; shift 2;;
            --end-color) _bl_end_color="$2"; shift 2;;
            --start-hex) _bl_start_hex="$2"; shift 2;;
            --end-hex) _bl_end_hex="$2"; shift 2;;
            --lang) _bl_langs="${_bl_langs}${2},"; shift 2;;
            --density) _bl_density="$2"; shift 2;;
            --duration) _bl_duration="$2"; shift 2;;
            *) break;;
        esac
    done

    # Build character set based on language flags
    _bl_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%^&*()_+{}[]"
    case "$_bl_langs" in
        *j*) _bl_chars="${_bl_chars}あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめも야유요라리루레로와온" ;;
    esac
    case "$_bl_langs" in
        *c*) _bl_chars="${_bl_chars}一二三四五六七八九十百千万" ;;
    esac
    case "$_bl_langs" in
        *k*) _bl_chars="${_bl_chars}가각간갇갈갉감갑갓갔강갖갗같" ;;
    esac
    
    _bl_char_len=$(printf "%s" "$_bl_chars" | wc -c | tr -d ' ')

    # Ensure dependencies are present
    bl_check_deps "bl_matrix_filler" "tput" || return 1

    _bl_cols=$(tput cols 2>/dev/null || echo 80)
    _bl_lines=$(tput lines 2>/dev/null || echo 24)
    _bl_start_time=$(date +%s)

    # Fast In-Memory LCG Random State Initialization
    _bl_rand_state=$(date +%s)
    _bl_mem_rand() {
        # X_{n+1} = (1103515245 * X_n + 12345) % 2147483648
        _bl_rand_state=$(( (1103515245 * _bl_rand_state + 12345) % 2147483648 ))
        _bl_rand_val=$(( _bl_rand_state ))
        if [ "$_bl_rand_val" -lt 0 ]; then
            _bl_rand_val=$(( -_bl_rand_val ))
        fi
        if [ -n "$1" ] && [ -n "$2" ]; then
            _bl_rand_val=$(( (_bl_rand_val % ($2 - $1 + 1)) + $1 ))
        fi
    }

    # Resize handling
    trap '_bl_cols=$(tput cols 2>/dev/null || echo 80); _bl_lines=$(tput lines 2>/dev/null || echo 24)' WINCH
    # Cleanup on exit
    trap 'tput sgr0 2>/dev/null || true; tput cnorm 2>/dev/null || true; clear 2>/dev/null || true; [ -n "$_bl_old_stty" ] && stty "$_bl_old_stty" 2>/dev/null; trap - WINCH INT TERM; exit 1' INT TERM

    tput civis 2>/dev/null || true
    clear 2>/dev/null || true

    # Set raw stty mode for non-blocking read
    _bl_old_stty=$(stty -g 2>/dev/null || true)
    if [ -n "$_bl_old_stty" ]; then
        stty raw -echo min 0 time 1 2>/dev/null || true
    fi

    # Initialize drops & speeds in-memory
    _bl_i=0
    while [ "$_bl_i" -lt "$_bl_cols" ]; do
        eval "_bl_drop_${_bl_i}=0"
        
        _bl_mem_rand 1 3
        eval "_bl_speed_${_bl_i}=\$_bl_rand_val"
        
        _bl_mem_rand 10 19
        eval "_bl_length_${_bl_i}=\$_bl_rand_val"
        
        _bl_i=$((_bl_i+1))
    done

    # Prepare color sequences
    if [ -n "$_bl_start_hex" ]; then
        _bl_rgb_parts=$(hex_to_rgb "$_bl_start_hex")
        set -- $_bl_rgb_parts
        _bl_sr=$1; _bl_sg=$2; _bl_sb=$3
        _bl_start_seq=$(rgb_seq "$_bl_sr" "$_bl_sg" "$_bl_sb")
        _bl_dark_seq=$(rgb_seq $((_bl_sr/3)) $((_bl_sg/3)) $((_bl_sb/3)))
        _bl_darker_seq=$(rgb_seq $((_bl_sr/8)) $((_bl_sg/8)) $((_bl_sb/8)))
    else
        _bl_start_seq=$(tput setaf "$_bl_start_color" 2>/dev/null || true)
        _bl_dark_seq="\033[2m${_bl_start_seq}"
        _bl_darker_seq="\033[2m\033[38;5;22m"
    fi
    
    if [ -n "$_bl_end_hex" ]; then
        _bl_rgb_parts=$(hex_to_rgb "$_bl_end_hex")
        set -- $_bl_rgb_parts
        _bl_er=$1; _bl_eg=$2; _bl_eb=$3
        _bl_end_seq=$(rgb_seq "$_bl_er" "$_bl_eg" "$_bl_eb")
        _bl_end_dark_seq=$(rgb_seq $((_bl_er/3)) $((_bl_eg/3)) $((_bl_eb/3)))
        _bl_end_darker_seq=$(rgb_seq $((_bl_er/8)) $((_bl_eg/8)) $((_bl_eb/8)))
    else
        _bl_end_seq=$(tput setaf "$_bl_end_color" 2>/dev/null || true)
        _bl_end_dark_seq="\033[2m${_bl_end_seq}"
        _bl_end_darker_seq="\033[2m\033[38;5;53m"
    fi

    while true; do
        if [ "$_bl_duration" -gt 0 ] && [ "$(( $(date +%s) - _bl_start_time ))" -ge "$_bl_duration" ]; then
            break
        fi

        _bl_frame_buffer=""
        _bl_i=0
        while [ "$_bl_i" -lt "$_bl_cols" ]; do
            eval "_bl_drop_val=\$_bl_drop_${_bl_i}"
            eval "_bl_speed_val=\$_bl_speed_${_bl_i}"

            # Possibly start a new drop
            if [ "$_bl_drop_val" -eq 0 ]; then
                _bl_mem_rand 1 "$_bl_density"
                if [ "$_bl_rand_val" -eq 1 ]; then
                    _bl_drop_val=1
                    eval "_bl_drop_${_bl_i}=1"
                    _bl_mem_rand 1 3
                    eval "_bl_speed_${_bl_i}=\$_bl_rand_val"
                    _bl_speed_val=$_bl_rand_val
                fi
            fi

            if [ "$_bl_drop_val" -gt 0 ]; then
                # Move down based on speed
                _bl_mem_rand 1 "$_bl_speed_val"
                if [ "$_bl_rand_val" -eq 1 ]; then
                    _bl_mem_rand 0 $((_bl_char_len - 1))
                    _bl_rand_char=$(posix_substr "$_bl_chars" "$_bl_rand_val" 1)

                    # Determine colors
                    _bl_head_color=""
                    _bl_middle_color=""
                    _bl_dark_color=""
                    _bl_darker_color=""
                    
                    case "$_bl_mode" in
                        rain)
                            if [ "$_bl_drop_val" -gt "$(( _bl_lines * 8 / 10 ))" ]; then
                                _bl_head_color=$_bl_end_seq
                            else
                               _bl_head_color=$_bl_start_seq
                            fi
                            _bl_middle_color=$_bl_start_seq
                            _bl_dark_color=$_bl_dark_seq
                            _bl_darker_color=$_bl_darker_seq
                            ;;
                        fade)
                            if [ -n "$_bl_start_hex" ] && [ -n "$_bl_end_hex" ]; then
                                _bl_fraction=$(( _bl_drop_val * 100 / _bl_lines ))
                                [ "$_bl_fraction" -gt 100 ] && _bl_fraction=100
                                _bl_br=$(( _bl_sr + (_bl_er - _bl_sr) * _bl_fraction / 100 ))
                                _bl_bg=$(( _bl_sg + (_bl_eg - _bl_sg) * _bl_fraction / 100 ))
                                _bl_bb=$(( _bl_sb + (_bl_eb - _bl_sb) * _bl_fraction / 100 ))
                                
                                _bl_head_color=$(rgb_seq "$_bl_br" "$_bl_bg" "$_bl_bb")
                                _bl_middle_color=$_bl_head_color
                                _bl_dark_color=$(rgb_seq $((_bl_br/3)) $((_bl_bg/3)) $((_bl_bb/3)))
                                _bl_darker_color=$(rgb_seq $((_bl_br/8)) $((_bl_bg/8)) $((_bl_bb/8)))
                            else
                                _bl_fraction=$(( _bl_drop_val * 100 / _bl_lines ))
                                if [ "$_bl_fraction" -gt 50 ]; then
                                    _bl_head_color=$_bl_end_seq
                                    _bl_middle_color=$_bl_end_seq
                                    _bl_dark_color=$_bl_end_dark_seq
                                    _bl_darker_color=$_bl_end_darker_seq
                                else
                                    _bl_head_color=$_bl_start_seq
                                    _bl_middle_color=$_bl_start_seq
                                    _bl_dark_color=$_bl_dark_seq
                                    _bl_darker_color=$_bl_darker_seq
                                fi
                            fi
                            ;;
                        *)
                            _bl_head_color=$_bl_end_seq
                            _bl_middle_color=$_bl_start_seq
                            _bl_dark_color=$_bl_dark_seq
                            _bl_darker_color=$_bl_darker_seq
                            ;;
                    esac

                    # 1. Print head character
                    if [ "$_bl_drop_val" -le "$_bl_lines" ]; then
                        _bl_frame_buffer="${_bl_frame_buffer}\033[$((_bl_drop_val+1));$((_bl_i+1))H${_bl_head_color}\033[1m${_bl_rand_char}"
                    fi

                    # 2. Print middle character
                    _bl_mid=$((_bl_drop_val - 1))
                    if [ "$_bl_mid" -gt 0 ] && [ "$_bl_mid" -le "$_bl_lines" ]; then
                        _bl_frame_buffer="${_bl_frame_buffer}\033[$((_bl_mid+1));$((_bl_i+1))H\033[0m${_bl_middle_color}${_bl_rand_char}"
                    fi

                    # 3. Fade to Dark
                    _bl_dark_pos=$((_bl_drop_val - 6))
                    if [ "$_bl_dark_pos" -gt 0 ] && [ "$_bl_dark_pos" -le "$_bl_lines" ]; then
                        _bl_mem_rand 0 $((_bl_char_len - 1))
                        _bl_rand_char_dark=$(posix_substr "$_bl_chars" "$_bl_rand_val" 1)
                        _bl_frame_buffer="${_bl_frame_buffer}\033[$((_bl_dark_pos+1));$((_bl_i+1))H\033[0m${_bl_dark_color}${_bl_rand_char_dark}"
                    fi

                    # 4. Fade to Very Dark
                    _bl_darker_pos=$((_bl_drop_val - 14))
                    if [ "$_bl_darker_pos" -gt 0 ] && [ "$_bl_darker_pos" -le "$_bl_lines" ]; then
                        _bl_mem_rand 0 $((_bl_char_len - 1))
                        _bl_rand_char_darker=$(posix_substr "$_bl_chars" "$_bl_rand_val" 1)
                        _bl_frame_buffer="${_bl_frame_buffer}\033[$((_bl_darker_pos+1));$((_bl_i+1))H\033[0m${_bl_darker_color}${_bl_rand_char_darker}"
                    fi

                    # Increment drop
                    _bl_drop_val=$(( _bl_drop_val + 1 ))
                    eval "_bl_drop_${_bl_i}=\$_bl_drop_val"
                    if [ "$_bl_drop_val" -gt "$(( _bl_lines + 20 ))" ]; then
                        eval "_bl_drop_${_bl_i}=0"
                    fi
                fi
            fi
            _bl_i=$((_bl_i+1))
        done
        printf "%b" "$_bl_frame_buffer"
        
        # Read a key safely with non-blocking stty settings
        _bl_key=""
        read -r _bl_key <&0 2>/dev/null || true
        if [ -n "$_bl_key" ]; then
            break
        fi
    done

    tput sgr0 2>/dev/null || true
    tput cnorm 2>/dev/null || true
    clear 2>/dev/null || true
    [ -n "$_bl_old_stty" ] && stty "$_bl_old_stty" 2>/dev/null || true
    trap - WINCH INT TERM
}
