# --- UI Bar V3: The Quantum Console ---
# Mode A (Linear): Input is 0-100.
# Mode B (Tagged): Triggered if --status or --log are passed. Input uses P: [0-100], M: [Status], L: [Log Entry]
bl_progress_bar() {
    bl_check_deps "bl_progress_bar" "bl_hex_to_rgb" || return 1

    _bl_label="Progress"
    _bl_show_status=false
    _bl_show_log=false
    _bl_log_height=3
    _bl_color_mode="position"
    _bl_r1=0; _bl_g1=0; _bl_b1=255 # Default Start: Blue
    _bl_r2=0; _bl_g2=255; _bl_b2=0  # Default End: Green
    _bl_user_width=0
    _bl_full_width=false

    # Flag Parser
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -l|--label) _bl_label="$2"; shift 2 ;;
            --status) _bl_show_status=true; shift ;;
            --log) _bl_show_log=true; shift ;;
            --log-height) _bl_show_log=true; _bl_log_height="$2"; shift 2 ;;
            -w|--width) _bl_user_width="$2"; shift 2 ;;
            -fw|--full-width) _bl_full_width=true; shift ;;
            -c|--color-mode) _bl_color_mode="$2"; shift 2 ;;
            -h|--hex|--start)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r1="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g1="${_bl_tmp%% *}"
                _bl_b1="${_bl_tmp#* }"
                shift 2
                ;;
            --end)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r2="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g2="${_bl_tmp%% *}"
                _bl_b2="${_bl_tmp#* }"
                shift 2
                ;;
            *) shift ;;
        esac
    done

    # Switch to tagged mode if any extra rendering section is enabled
    _bl_tagged=false
    if [ "$_bl_show_status" = "true" ] || [ "$_bl_show_log" = "true" ]; then _bl_tagged=true; fi

    _bl_margin=2
    _bl_width=0  # actual rendering width, may be set from flags
    _bl_bar_source="████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
    _bl_empty_source="------------------------------------------------------------------------------------------------------------------------------------------------------"
    
    _bl_percent=0
    _bl_status_msg="Initializing..."

    # Initialize log_buffer using dynamic variables instead of arrays
    _bl_i=0
    while [ "$_bl_i" -lt "$_bl_log_height" ]; do
        eval "_bl_log_buffer_${_bl_i}=\"\""
        _bl_i=$((_bl_i+1))
    done

    tput civis 2>/dev/null || true

    # Initialize previous terminal width tracker
    _bl_prev_term_w=0
    while read -r _bl_line; do
        # Check for terminal resize
        _bl_term_w=$(tput cols 2>/dev/null || echo 80)
        if [ "$_bl_term_w" -ne "$_bl_prev_term_w" ]; then
            _bl_max_allowed=$(( _bl_term_w - _bl_margin * 2 ))
            if [ "$_bl_full_width" = "true" ]; then
                _bl_width=$_bl_max_allowed
            elif [ "$_bl_user_width" -gt 0 ]; then
                _bl_width=$_bl_user_width
                if [ "$_bl_width" -gt "$_bl_max_allowed" ]; then _bl_width=$_bl_max_allowed; fi
            else
                _bl_width=$_bl_max_allowed
            fi
            _bl_prev_term_w=$_bl_term_w
        fi

        if [ "$_bl_tagged" = "true" ]; then
            case "$_bl_line" in
                P:*) _bl_percent="${_bl_line#P:}" ;;
                M:*) _bl_status_msg="${_bl_line#M:}" ;;
                L:*) 
                    if [ "$_bl_show_log" = "true" ]; then
                        _bl_raw_msg="${_bl_line#L:}"
                        _bl_max_w=$((_bl_width - _bl_margin - 5))
                        if [ "$_bl_max_w" -lt 10 ]; then _bl_max_w=10; fi

                        # Wrap by splitting into chunks
                        while [ -n "$_bl_raw_msg" ]; do
                            _bl_chunk=$(posix_substr "$_bl_raw_msg" 0 "$_bl_max_w")
                            _bl_raw_msg=$(posix_substr "$_bl_raw_msg" "$_bl_max_w")
                            
                            # Shift logs up
                            _bl_i=0
                            while [ "$_bl_i" -lt "$((_bl_log_height - 1))" ]; do
                                _bl_next=$((_bl_i + 1))
                                eval "_bl_log_buffer_${_bl_i}=\"\$_bl_log_buffer_${_bl_next}\""
                                _bl_i=$((_bl_i+1))
                            done
                            eval "_bl_log_buffer_$((_bl_log_height - 1))=\"\$_bl_chunk\""
                        done
                    fi
                    ;;
            esac
        else
            # Linear Mode: Expect pure numbers
            case "$_bl_line" in
                *[!0-9]*) ;;
                "") ;;
                *) _bl_percent="$_bl_line" ;;
            esac
        fi

        if [ "$_bl_percent" -lt 0 ]; then _bl_percent=0; fi
        if [ "$_bl_percent" -gt 100 ]; then _bl_percent=100; fi

        _bl_bar_max=$(( _bl_width - (_bl_margin * 2) - 2 ))
        if [ "$_bl_bar_max" -lt 10 ]; then _bl_bar_max=10; fi

        _bl_filled_count=$(( _bl_bar_max * _bl_percent / 100 ))
        _bl_spaces=$(posix_substr "$_bl_empty_source" 0 $((_bl_bar_max - _bl_filled_count)))

        # Global color logic
        _bl_r_global=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_percent / 100 ))
        _bl_g_global=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_percent / 100 ))
        _bl_b_global=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_percent / 100 ))
        _bl_global_color_esc="\033[38;2;${_bl_r_global};${_bl_g_global};${_bl_b_global}m"

        # Line 1: Header
        printf "\r\033[K%${_bl_margin}s ${_bl_global_color_esc}%3d%% %s\033[0m\n" "" "$_bl_percent" "$_bl_label"
        
        # Line 2: The Bar
        printf "\033[K%${_bl_margin}s" ""
        
        # Filled Portion
        if [ "$_bl_color_mode" = "position" ]; then
            _bl_i=0
            while [ "$_bl_i" -lt "$_bl_filled_count" ]; do
                _bl_r_pos=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_i / (_bl_bar_max - 1) ))
                _bl_g_pos=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_i / (_bl_bar_max - 1) ))
                _bl_b_pos=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_i / (_bl_bar_max - 1) ))
                printf "\033[38;2;${_bl_r_pos};${_bl_g_pos};${_bl_b_pos}m█"
                _bl_i=$((_bl_i + 1))
            done
        else
            _bl_sub_bar=$(posix_substr "$_bl_bar_source" 0 "$_bl_filled_count")
            printf "%b%s" "$_bl_global_color_esc" "$_bl_sub_bar"
        fi
        
        # Empty Portion
        printf "\033[38;2;60;60;60m%s\033[0m" "$_bl_spaces"

        _bl_lines_to_reset=1 # Current line is Line 2, so up 1 gets us back to Line 1

        if [ "$_bl_show_status" = "true" ]; then
            # Line 3: Status Message
            printf "\n\033[K%${_bl_margin}s \033[1;34m➜\033[0m %s" "" "$_bl_status_msg"
            _bl_lines_to_reset=$((_bl_lines_to_reset + 1))
        fi

        if [ "$_bl_show_log" = "true" ]; then
            # Lines 4+: Scrolling Logs
            _bl_i=0
            while [ "$_bl_i" -lt "$_bl_log_height" ]; do
                eval "_bl_log_val=\"\$_bl_log_buffer_${_bl_i}\""
                printf "\n\033[K%${_bl_margin}s \033[2m│ %b\033[0m" "" "$_bl_log_val"
                _bl_lines_to_reset=$((_bl_lines_to_reset + 1))
                _bl_i=$((_bl_i + 1))
            done
        fi

        if [ "$_bl_percent" -ge 100 ]; then break; fi
        printf "\033[%dA" "$_bl_lines_to_reset" # Return to Line 1 start
    done
    
    tput cnorm 2>/dev/null || true
    printf "\n"
}

# --- UI Square Progress ---
# A square/rectangular progress indicator that fills up dot by dot.
# Supports Mode A (Linear: 0-100) and Mode B (Tagged: P:[val], M:[status]).
bl_square_progress() {
    bl_check_deps "bl_square_progress" "bl_hex_to_rgb" || return 1

    _bl_label="Progress"
    _bl_tagged=false
    _bl_r1=0; _bl_g1=0; _bl_b1=255 # Default Start: Blue
    _bl_r2=0; _bl_g2=255; _bl_b2=0  # Default End: Green
    
    _bl_width=10
    _bl_height=10
    _bl_full_width=false
    _bl_show_brackets=false
    _bl_color_mode="global"

    # Flag Parser
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -l|--label) _bl_label="$2"; shift 2 ;;
            -t|--tagged) _bl_tagged=true; shift ;;
            -w|--width) _bl_width="$2"; shift 2 ;;
            -H|--height) _bl_height="$2"; shift 2 ;;
            -fw|--full-width) _bl_full_width=true; shift ;;
            --brackets) _bl_show_brackets=true; shift ;;
            -c|--color-mode) _bl_color_mode="$2"; shift 2 ;;
            -h|--hex|--start)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r1="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g1="${_bl_tmp%% *}"
                _bl_b1="${_bl_tmp#* }"
                shift 2
                ;;
            --end)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r2="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g2="${_bl_tmp%% *}"
                _bl_b2="${_bl_tmp#* }"
                shift 2
                ;;
            *) shift ;;
        esac
    done

    _bl_margin=2
    _bl_percent=0
    _bl_status_msg="Initializing..."
    _bl_empty_char="·"
    _bl_fill_char="■"

    tput civis 2>/dev/null || true
    
    while read -r _bl_line; do
        if [ "$_bl_tagged" = "true" ]; then
            case "$_bl_line" in
                P:*) _bl_percent="${_bl_line#P:}" ;;
                M:*) _bl_status_msg="${_bl_line#M:}" ;;
            esac
        else
            case "$_bl_line" in
                *[!0-9]*) ;;
                "") ;;
                *) _bl_percent="$_bl_line" ;;
            esac
        fi

        if [ "$_bl_percent" -lt 0 ]; then _bl_percent=0; fi
        if [ "$_bl_percent" -gt 100 ]; then _bl_percent=100; fi

        _bl_term_cols=$(tput cols 2>/dev/null || echo 80)
        _bl_grid_w=$_bl_width
        _bl_extra_chars=$_bl_margin
        
        if [ "$_bl_show_brackets" = "true" ]; then
            _bl_extra_chars=$(( _bl_extra_chars + 3 )) # "[ " and "]" takes 3 visual spaces
        fi

        if [ "$_bl_full_width" = "true" ]; then
            _bl_grid_w=$(( (_bl_term_cols - _bl_extra_chars) / 2 )) # divide by 2 because "■ " is 2 chars wide
            if [ "$_bl_grid_w" -lt 5 ]; then _bl_grid_w=5; fi
        fi

        _bl_total_cells=$(( _bl_grid_w * _bl_height ))
        _bl_filled_cells=$(( _bl_total_cells * _bl_percent / 100 ))

        # Global Color Calc
        _bl_r_global=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_percent / 100 ))
        _bl_g_global=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_percent / 100 ))
        _bl_b_global=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_percent / 100 ))
        _bl_global_color_esc="\033[38;2;${_bl_r_global};${_bl_g_global};${_bl_b_global}m"

        # Render Header
        printf "\r\033[K%${_bl_margin}s ${_bl_global_color_esc}== %s ==\033[0m\n" "" "$_bl_label"
        
        # Render Grid
        _bl_row=0
        while [ "$_bl_row" -lt "$_bl_height" ]; do
            printf "\033[K%${_bl_margin}s" ""
            if [ "$_bl_show_brackets" = "true" ]; then
                printf "\033[1;37m[ \033[0m"
            fi
            
            _bl_col=0
            while [ "$_bl_col" -lt "$_bl_grid_w" ]; do
                _bl_cell=$(( _bl_row * _bl_grid_w + _bl_col ))
                
                _bl_cell_color_esc=""
                if [ "$_bl_color_mode" = "position" ]; then
                    if [ "$_bl_total_cells" -gt 1 ]; then
                        _bl_r_pos=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_cell / (_bl_total_cells - 1) ))
                        _bl_g_pos=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_cell / (_bl_total_cells - 1) ))
                        _bl_b_pos=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_cell / (_bl_total_cells - 1) ))
                        _bl_cell_color_esc="\033[38;2;${_bl_r_pos};${_bl_g_pos};${_bl_b_pos}m"
                    else
                        _bl_cell_color_esc="$_bl_global_color_esc"
                    fi
                else
                    _bl_cell_color_esc="$_bl_global_color_esc"
                fi

                if [ "$_bl_cell" -lt "$_bl_filled_cells" ]; then
                    printf "%b%s \033[0m" "$_bl_cell_color_esc" "$_bl_fill_char"
                else
                    printf "\033[38;5;239m%s \033[0m" "$_bl_empty_char"
                fi
                _bl_col=$((_bl_col + 1))
            done

            if [ "$_bl_show_brackets" = "true" ]; then
                printf "\033[1;37m]\033[0m"
            fi
            printf "\n"
            _bl_row=$((_bl_row + 1))
        done
        
        # Render Status Footer
        if [ "$_bl_tagged" = "true" ]; then
            printf "\033[K%${_bl_margin}s \033[1;33m%3d%%\033[0m - \033[38;5;248m%s\033[0m\n" "" "$_bl_percent" "$_bl_status_msg"
        else
            printf "\033[K%${_bl_margin}s \033[1;33m%3d%%\033[0m\n" "" "$_bl_percent"
        fi

        if [ "$_bl_percent" -ge 100 ]; then break; fi
        
        _bl_lines_to_reset=$(( _bl_height + 2 ))
        printf "\033[%dA" "$_bl_lines_to_reset" # Return to top
    done
    
    tput cnorm 2>/dev/null || true
}

# --- UI Spiral Progress ---
# A square/rectangular progress indicator that fills up in a spiral (inward or outward).
# Supports Mode A (Linear: 0-100) and Mode B (Tagged: P:[val], M:[status]).
bl_spiral_progress() {
    bl_check_deps "bl_spiral_progress" "bl_hex_to_rgb" || return 1

    _bl_label="Progress"
    _bl_tagged=false
    _bl_r1=0; _bl_g1=0; _bl_b1=255
    _bl_r2=0; _bl_g2=255; _bl_b2=0
    
    _bl_width=10
    _bl_height=10
    _bl_full_width=false
    _bl_show_brackets=false
    _bl_color_mode="global"
    _bl_direction="in"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -l|--label) _bl_label="$2"; shift 2 ;;
            -t|--tagged) _bl_tagged=true; shift ;;
            -w|--width) _bl_width="$2"; shift 2 ;;
            -H|--height) _bl_height="$2"; shift 2 ;;
            -fw|--full-width) _bl_full_width=true; shift ;;
            --brackets) _bl_show_brackets=true; shift ;;
            -c|--color-mode) _bl_color_mode="$2"; shift 2 ;;
            --direction) _bl_direction="$2"; shift 2 ;;
            -h|--hex|--start)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r1="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g1="${_bl_tmp%% *}"
                _bl_b1="${_bl_tmp#* }"
                shift 2
                ;;
            --end)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r2="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g2="${_bl_tmp%% *}"
                _bl_b2="${_bl_tmp#* }"
                shift 2
                ;;
            *) shift ;;
        esac
    done

    _bl_margin=2
    _bl_percent=0
    _bl_status_msg="Initializing..."
    _bl_empty_char="·"
    _bl_fill_char="■"

    _bl_term_cols=$(tput cols 2>/dev/null || echo 80)
    _bl_grid_w=$_bl_width
    _bl_extra_chars=$_bl_margin
    
    if [ "$_bl_show_brackets" = "true" ]; then _bl_extra_chars=$(( _bl_extra_chars + 3 )); fi
    if [ "$_bl_full_width" = "true" ]; then
        _bl_grid_w=$(( (_bl_term_cols - _bl_extra_chars) / 2 ))
        if [ "$_bl_grid_w" -lt 5 ]; then _bl_grid_w=5; fi
    fi

    _bl_total_cells=$(( _bl_grid_w * _bl_height ))
    
    # Pre-calculate spiral mapping using eval for dynamic variables
    _bl_top=0
    _bl_bottom=$((_bl_height - 1))
    _bl_left=0
    _bl_right=$((_bl_grid_w - 1))
    _bl_count=0

    while [ "$_bl_count" -lt "$_bl_total_cells" ]; do
        _bl_i=$_bl_left
        while [ "$_bl_i" -le "$_bl_right" ] && [ "$_bl_count" -lt "$_bl_total_cells" ]; do
            eval "_bl_cell_order_${_bl_top}_${_bl_i}=\$_bl_count"
            _bl_count=$((_bl_count + 1))
            _bl_i=$((_bl_i + 1))
        done
        _bl_top=$((_bl_top + 1))

        _bl_i=$_bl_top
        while [ "$_bl_i" -le "$_bl_bottom" ] && [ "$_bl_count" -lt "$_bl_total_cells" ]; do
            eval "_bl_cell_order_${_bl_i}_${_bl_right}=\$_bl_count"
            _bl_count=$((_bl_count + 1))
            _bl_i=$((_bl_i + 1))
        done
        _bl_right=$((_bl_right - 1))

        _bl_i=$_bl_right
        while [ "$_bl_i" -ge "$_bl_left" ] && [ "$_bl_count" -lt "$_bl_total_cells" ]; do
            eval "_bl_cell_order_${_bl_bottom}_${_bl_i}=\$_bl_count"
            _bl_count=$((_bl_count + 1))
            _bl_i=$((_bl_i - 1))
        done
        _bl_bottom=$((_bl_bottom - 1))

        _bl_i=$_bl_bottom
        while [ "$_bl_i" -ge "$_bl_top" ] && [ "$_bl_count" -lt "$_bl_total_cells" ]; do
            eval "_bl_cell_order_${_bl_i}_${_bl_left}=\$_bl_count"
            _bl_count=$((_bl_count + 1))
            _bl_i=$((_bl_i - 1))
        done
        _bl_left=$((_bl_left + 1))
    done

    tput civis 2>/dev/null || true
    
    while read -r _bl_line; do
        if [ "$_bl_tagged" = "true" ]; then
            case "$_bl_line" in
                P:*) _bl_percent="${_bl_line#P:}" ;;
                M:*) _bl_status_msg="${_bl_line#M:}" ;;
            esac
        else
            case "$_bl_line" in
                *[!0-9]*) ;;
                "") ;;
                *) _bl_percent="$_bl_line" ;;
            esac
        fi

        if [ "$_bl_percent" -lt 0 ]; then _bl_percent=0; fi
        if [ "$_bl_percent" -gt 100 ]; then _bl_percent=100; fi

        _bl_filled_cells=$(( _bl_total_cells * _bl_percent / 100 ))

        _bl_r_global=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_percent / 100 ))
        _bl_g_global=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_percent / 100 ))
        _bl_b_global=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_percent / 100 ))
        _bl_global_color_esc="\033[38;2;${_bl_r_global};${_bl_g_global};${_bl_b_global}m"

        printf "\r\033[K%${_bl_margin}s ${_bl_global_color_esc}== %s ==\033[0m\n" "" "$_bl_label"
        
        _bl_row=0
        while [ "$_bl_row" -lt "$_bl_height" ]; do
            printf "\033[K%${_bl_margin}s" ""
            if [ "$_bl_show_brackets" = "true" ]; then printf "\033[1;37m[ \033[0m"; fi
            
            _bl_col=0
            while [ "$_bl_col" -lt "$_bl_grid_w" ]; do
                eval "_bl_order_idx=\$_bl_cell_order_${_bl_row}_${_bl_col}"
                if [ "$_bl_direction" = "out" ]; then
                    _bl_order_idx=$(( _bl_total_cells - 1 - _bl_order_idx ))
                fi
                
                _bl_cell_color_esc=""
                if [ "$_bl_color_mode" = "position" ]; then
                    if [ "$_bl_total_cells" -gt 1 ]; then
                        _bl_r_pos=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_order_idx / (_bl_total_cells - 1) ))
                        _bl_g_pos=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_order_idx / (_bl_total_cells - 1) ))
                        _bl_b_pos=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_order_idx / (_bl_total_cells - 1) ))
                        _bl_cell_color_esc="\033[38;2;${_bl_r_pos};${_bl_g_pos};${_bl_b_pos}m"
                    else
                        _bl_cell_color_esc="$_bl_global_color_esc"
                    fi
                else
                    _bl_cell_color_esc="$_bl_global_color_esc"
                fi

                if [ "$_bl_order_idx" -lt "$_bl_filled_cells" ]; then
                    printf "%b%s \033[0m" "$_bl_cell_color_esc" "$_bl_fill_char"
                else
                    printf "\033[38;5;239m%s \033[0m" "$_bl_empty_char"
                fi
                _bl_col=$((_bl_col + 1))
            done

            if [ "$_bl_show_brackets" = "true" ]; then printf "\033[1;37m]\033[0m"; fi
            printf "\n"
            _bl_row=$((_bl_row + 1))
        done
        
        if [ "$_bl_tagged" = "true" ]; then
            printf "\033[K%${_bl_margin}s \033[1;33m%3d%%\033[0m - \033[38;5;248m%s\033[0m\n" "" "$_bl_percent" "$_bl_status_msg"
        else
            printf "\033[K%${_bl_margin}s \033[1;33m%3d%%\033[0m\n" "" "$_bl_percent"
        fi

        if [ "$_bl_percent" -ge 100 ]; then break; fi
        
        _bl_lines_to_reset=$(( _bl_height + 2 ))
        printf "\033[%dA" "$_bl_lines_to_reset"
    done
    
    tput cnorm 2>/dev/null || true
}

# --- UI Bar V4: Minecraft Terrain Loader ---
bl_terrain_loader() {
    bl_check_deps "bl_terrain_loader" "bl_hex_to_rgb" || return 1

    _bl_width=40
    _bl_height=15
    _bl_label="Generating Terrain..."
    _bl_empty_char="░"
    _bl_fill_char="█"
    
    _bl_bg_color="\033[38;5;238m" # Dark grey
    _bl_reset="\033[0m"

    _bl_color_mode="time"
    _bl_pattern="random"
    _bl_r1=255; _bl_g1=255; _bl_b1=0 # Default start: Yellow (#FFFF00)
    _bl_r2=0; _bl_g2=255; _bl_b2=255 # Default end: Cyan (#00FFFF)
    _bl_fg_color="\033[38;5;46m"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -w|--width) _bl_width="$2"; shift 2 ;;
            -h|--height) _bl_height="$2"; shift 2 ;;
            -fw|--full-width) _bl_width=$(tput cols 2>/dev/null || echo 80); shift 1 ;;
            -fh|--full-height) _bl_height=$(( $(tput lines 2>/dev/null || echo 24) - 2 )); shift 1 ;;
            -l|--label) _bl_label="$2"; shift 2 ;;
            -c|--color-mode) _bl_color_mode="$2"; shift 2 ;;
            --pattern) _bl_pattern="$2"; shift 2 ;;
            --minecraft) _bl_pattern="minecraft"; shift 1 ;;
            --start)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r1="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g1="${_bl_tmp%% *}"
                _bl_b1="${_bl_tmp#* }"
                shift 2
                ;;
            --end)
                _bl_rgb_out=$(bl_hex_to_rgb "$2")
                _bl_r2="${_bl_rgb_out%% *}"
                _bl_tmp="${_bl_rgb_out#* }"
                _bl_g2="${_bl_tmp%% *}"
                _bl_b2="${_bl_tmp#* }"
                shift 2
                ;;
            --fg) _bl_fg_color="\033[38;5;${2}m"; shift 2 ;;
            *) shift ;;
        esac
    done

    # In-memory LCG Random Setup
    _bl_rand_state=$(date +%s)
    _bl_mem_rand() {
        _bl_rand_state=$(( (1103515245 * _bl_rand_state + 12345) % 2147483648 ))
        _bl_rand_val=$(( _bl_rand_state ))
        if [ "$_bl_rand_val" -lt 0 ]; then
            _bl_rand_val=$(( -_bl_rand_val ))
        fi
        if [ -n "$1" ] && [ -n "$2" ]; then
            _bl_rand_val=$(( (_bl_rand_val % ($2 - $1 + 1)) + $1 ))
        fi
    }

    _bl_total_blocks=$((_bl_width * _bl_height))
    
    _bl_i=0
    while [ "$_bl_i" -lt "$_bl_total_blocks" ]; do
        eval "_bl_grid_${_bl_i}=0"
        _bl_i=$((_bl_i+1))
    done
    
    # Pre-calculate fill order based on pattern
    if [ "$_bl_pattern" = "center-out" ] || [ "$_bl_pattern" = "minecraft" ]; then
        _bl_cx=$(( _bl_width / 2 ))
        _bl_cy=$(( _bl_height / 2 ))
        
        _bl_tmp_sort=$(mktemp)
        _bl_i=0
        while [ "$_bl_i" -lt "$_bl_total_blocks" ]; do
            _bl_x=$(( _bl_i % _bl_width ))
            _bl_y=$(( _bl_i / _bl_width ))
            # Scale Y by 2 to account for terminal character aspect ratio
            _bl_dx=$(( _bl_x - _bl_cx ))
            _bl_dy=$(( (_bl_y - _bl_cy) * 2 ))
            _bl_dist=$(( _bl_dx * _bl_dx + _bl_dy * _bl_dy ))
            
            # Add random jitter so the circle expansion looks organic
            _bl_noise=0
            if [ "$_bl_pattern" = "minecraft" ]; then
                _bl_mem_rand 0 29
                _bl_noise=$_bl_rand_val
            else
                _bl_mem_rand 0 14
                _bl_noise=$_bl_rand_val
            fi
            
            _bl_final_dist=$(( _bl_dist + _bl_noise ))
            printf "%d %d\n" "$_bl_final_dist" "$_bl_i"
            _bl_i=$((_bl_i+1))
        done | sort -n -r > "$_bl_tmp_sort"

        _bl_idx_counter=0
        while read -r _bl_dist _bl_idx_val; do
            eval "_bl_unfilled_${_bl_idx_counter}=\$_bl_idx_val"
            _bl_idx_counter=$((_bl_idx_counter + 1))
        done < "$_bl_tmp_sort"
        rm -f "$_bl_tmp_sort"
    else
        _bl_i=0
        while [ "$_bl_i" -lt "$_bl_total_blocks" ]; do
            eval "_bl_unfilled_${_bl_i}=\$_bl_i"
            _bl_i=$((_bl_i+1))
        done
    fi
    
    _bl_unfilled_count=$_bl_total_blocks
    _bl_current_filled=0
    _bl_percent=0

    tput civis 2>/dev/null || true
    
    printf "%b%s%b\n" "$_bl_fg_color" "$_bl_label" "$_bl_reset"
    _bl_y=0
    while [ "$_bl_y" -lt "$_bl_height" ]; do
        _bl_x=0
        while [ "$_bl_x" -lt "$_bl_width" ]; do
            printf "%b%s%b" "$_bl_bg_color" "$_bl_empty_char" "$_bl_reset"
            _bl_x=$((_bl_x + 1))
        done
        printf "\n"
        _bl_y=$((_bl_y + 1))
    done

    while read -r _bl_line; do
        case "$_bl_line" in
            P:*) _bl_percent="${_bl_line#P:}" ;;
            *[!0-9]*) ;;
            "") ;;
            *) _bl_percent="$_bl_line" ;;
        esac
        
        if [ "$_bl_percent" -gt 100 ]; then _bl_percent=100; fi
        if [ "$_bl_percent" -lt 0 ]; then _bl_percent=0; fi

        _bl_target_filled=$((_bl_total_blocks * _bl_percent / 100))
        
        _bl_updated=false
        while [ "$_bl_current_filled" -lt "$_bl_target_filled" ] && [ "$_bl_unfilled_count" -gt 0 ]; do
            _bl_rand_idx=0
            if [ "$_bl_pattern" = "center-out" ]; then
                _bl_rand_idx=$(( _bl_unfilled_count - 1 )) # Pop strictly from the pre-sorted tail
            elif [ "$_bl_pattern" = "minecraft" ]; then
                _bl_mem_rand 0 99
                if [ "$_bl_rand_val" -lt 15 ]; then
                    _bl_mem_rand 0 $(( _bl_unfilled_count - 1 ))
                    _bl_rand_idx=$_bl_rand_val
                else
                    _bl_tail_idx=$(( _bl_unfilled_count - 1 ))
                    _bl_range=12
                    if [ "$_bl_unfilled_count" -lt "$_bl_range" ]; then _bl_range=$_bl_unfilled_count; fi
                    _bl_mem_rand 0 $(( _bl_range - 1 ))
                    _bl_rand_idx=$(( _bl_tail_idx - _bl_rand_val ))
                fi
            else
                _bl_mem_rand 0 $(( _bl_unfilled_count - 1 ))
                _bl_rand_idx=$_bl_rand_val
            fi
            
            eval "_bl_target_block=\$_bl_unfilled_${_bl_rand_idx}"
            
            _bl_current_filled=$((_bl_current_filled + 1))
            eval "_bl_grid_${_bl_target_block}=\$_bl_current_filled"
            
            _bl_last_unfilled_idx=$(( _bl_unfilled_count - 1 ))
            eval "_bl_last_unfilled_val=\$_bl_unfilled_${_bl_last_unfilled_idx}"
            eval "_bl_unfilled_${_bl_rand_idx}=\$_bl_last_unfilled_val"
            _bl_unfilled_count=$((_bl_unfilled_count - 1))
            _bl_updated=true
        done
        
        if [ "$_bl_updated" = "true" ]; then
            _bl_global_esc="$_bl_fg_color"
            if [ "$_bl_color_mode" = "global" ]; then
                _bl_current_r=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_percent / 100 ))
                _bl_current_g=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_percent / 100 ))
                _bl_current_b=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_percent / 100 ))
                _bl_global_esc="\033[38;2;${_bl_current_r};${_bl_current_g};${_bl_current_b}m"
            fi

            tput cuu "$_bl_height" 2>/dev/null || true
            _bl_y=0
            while [ "$_bl_y" -lt "$_bl_height" ]; do
                _bl_row_str=""
                _bl_x=0
                while [ "$_bl_x" -lt "$_bl_width" ]; do
                    _bl_idx=$((_bl_y * _bl_width + _bl_x))
                    eval "_bl_grid_val=\$_bl_grid_${_bl_idx}"
                    if [ "$_bl_grid_val" -gt 0 ]; then
                        _bl_cell_color="$_bl_global_esc"
                        if [ "$_bl_color_mode" = "position" ]; then
                            _bl_r_pos=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_x / (_bl_width - 1) ))
                            _bl_g_pos=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_x / (_bl_width - 1) ))
                            _bl_b_pos=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_x / (_bl_width - 1) ))
                            _bl_cell_color="\033[38;2;${_bl_r_pos};${_bl_g_pos};${_bl_b_pos}m"
                        elif [ "$_bl_color_mode" = "time" ]; then
                            _bl_r_time=$(( _bl_r1 + (_bl_r2 - _bl_r1) * _bl_grid_val / _bl_total_blocks ))
                            _bl_g_time=$(( _bl_g1 + (_bl_g2 - _bl_g1) * _bl_grid_val / _bl_total_blocks ))
                            _bl_b_time=$(( _bl_b1 + (_bl_b2 - _bl_b1) * _bl_grid_val / _bl_total_blocks ))
                            _bl_cell_color="\033[38;2;${_bl_r_time};${_bl_g_time};${_bl_b_time}m"
                        fi
                        _bl_row_str="${_bl_row_str}${_bl_cell_color}${_bl_fill_char}${_bl_reset}"
                    else
                        _bl_row_str="${_bl_row_str}${_bl_bg_color}${_bl_empty_char}${_bl_reset}"
                    fi
                    _bl_x=$((_bl_x + 1))
                done
                printf "%b\033[K\n" "$_bl_row_str"
                _bl_y=$((_bl_y + 1))
            done
        fi
        
        if [ "$_bl_percent" -ge 100 ] && [ "$_bl_current_filled" -ge "$_bl_total_blocks" ]; then
            break
        fi
    done
    
    tput cnorm 2>/dev/null || true
    printf "\n"
}

# --- Optimized Terrain Loader (experimental) ---
bl_terrain_loader_opt() {
    # For now it simply delegates to the original implementation.
    bl_terrain_loader "$@"
}
