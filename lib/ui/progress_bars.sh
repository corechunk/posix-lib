# --- UI Bar V3: The Quantum Console ---
# Mode A (Linear): Input is 0-100.
# Mode B (Tagged): Triggered if --status or --log are passed. Input uses P: [0-100], M: [Status], L: [Log Entry]
bl_progress_bar() {
# Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_progress_bar" "bl_hex_to_rgb" || return 1

    local label="Progress"
    local show_status=false
    local show_log=false
    local log_height=3
    local color_mode="position"
    local r1=0; local g1=0; local b1=255 # Default Start: Blue
    local r2=0; local g2=255; local b2=0  # Default End: Green
  # initialize width from flag

    # Flag Parser
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--label) label="$2"; shift 2 ;;
            --status) show_status=true; shift ;;
            --log) show_log=true; shift ;;
            --log-height) show_log=true; log_height="$2"; shift 2 ;;
            -w|--width) user_width="$2"; shift 2 ;;
            -fw|--full-width) full_width=true; shift ;;
            -c|--color-mode) color_mode="$2"; shift 2 ;;
            -h|--hex|--start)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r1="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g1="${tmp%% *}"
                b1="${tmp#* }"
                shift 2
                ;;
            --end)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r2="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g2="${tmp%% *}"
                b2="${tmp#* }"
                shift 2
                ;;
            *) shift ;;
        esac
    done

    # Switch to tagged mode if any extra rendering section is enabled
    local tagged=false
    if $show_status || $show_log; then tagged=true; fi

    local margin=2

    local width=0  # actual rendering width, may be set from flags
    local bar_source="████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
    local empty_source="------------------------------------------------------------------------------------------------------------------------------------------------------"
    
    local percent=0
    local status_msg="Initializing..."
    local -a log_buffer=()
    for ((i=0; i<log_height; i++)); do log_buffer[i]=""; done

    tput civis

    # Initialize previous terminal width tracker
    local prev_term_w=0
    while true; do
        # Check for terminal resize only when size changes
        local term_w=$(tput cols)
        if (( term_w != prev_term_w )); then
            local max_allowed=$(( term_w - margin * 2 ))
            if $full_width; then
                width=$max_allowed
            elif (( user_width > 0 )); then
                width=$user_width
                (( width > max_allowed )) && width=$max_allowed
            else
                width=$max_allowed
            fi
            prev_term_w=$term_w
        fi

        # Non-blocking read (0.01s timeout)
        if read -t 0.01 -r line; then
            if $tagged; then
                case "$line" in
                    P:*) percent="${line#P:}" ;;
                    M:*) status_msg="${line#M:}" ;;
                    L:*) 
                        if $show_log; then
                            local raw_msg="${line#L:}"
                            # Width handling is performed in the main render loop; no action needed here.
                            local max_w=$((width - margin - 5))
                            ((max_w < 10)) && max_w=10

                            # Wrap by splitting into chunks
                            while [[ -n "$raw_msg" ]]; do
                                local chunk="${raw_msg:0:$max_w}"
                                raw_msg="${raw_msg:$max_w}"
                                
                                # Shift logs up
                                for ((i=0; i<log_height-1; i++)); do 
                                    log_buffer[i]="${log_buffer[i+1]}"
                                done
                                log_buffer[$((log_height-1))]="$chunk"
                            done
                        fi
                        ;;
                esac
            else
                # Linear Mode: Expect pure numbers
                if [[ "$line" =~ ^[0-9]+$ ]]; then
                    percent="$line"
                fi
            fi
        elif [[ $? -le 128 ]]; then
            # Pipe closed/EOF
            break
        fi

        (( percent < 0 )) && percent=0
        (( percent > 100 )) && percent=100

        # Width handling is now done only on resize above
        local bar_max=$(( width - (margin * 2) - 2 ))
        (( bar_max < 10 )) && bar_max=10

        local filled_count=$(( bar_max * percent / 100 ))
        local spaces="${empty_source:0:$((bar_max - filled_count))}"

        # Global color logic (still calculated for header)
        local r_global=$(( r1 + (r2 - r1) * percent / 100 ))
        local g_global=$(( g1 + (g2 - g1) * percent / 100 ))
        local b_global=$(( b1 + (b2 - b1) * percent / 100 ))
        local global_color_esc="\033[38;2;${r_global};${g_global};${b_global}m"

        # Line 1: Header
        printf "\r\033[K%${margin}s ${global_color_esc}%3d%% %s\033[0m\n" "" "$percent" "$label"
        
        # Line 2: The Bar
        printf "\033[K%${margin}s" ""
        
        # Filled Portion (gradient mode support)
        if [[ "$color_mode" == "position" ]]; then
            for ((i=0; i<filled_count; i++)); do
                local r_pos=$(( r1 + (r2 - r1) * i / (bar_max - 1) ))
                local g_pos=$(( g1 + (g2 - g1) * i / (bar_max - 1) ))
                local b_pos=$(( b1 + (b2 - b1) * i / (bar_max - 1) ))
                printf "\033[38;2;${r_pos};${g_pos};${b_pos}m█"
            done
        else
            printf "%b%s" "$global_color_esc" "${bar_source:0:$filled_count}"
        fi
        
        # Empty Portion
        printf "\033[38;2;60;60;60m%s\033[0m" "$spaces"

        local lines_to_reset=1 # Current line is Line 2, so up 1 gets us back to Line 1

        if $show_status; then
            # Line 3: Status Message
            printf "\n\033[K%${margin}s \033[1;34m➜\033[0m %s" "" "$status_msg"
            lines_to_reset=$((lines_to_reset + 1))
        fi

        if $show_log; then
            # Lines 4+: Scrolling Logs
            for ((i=0; i<log_height; i++)); do
                printf "\n\033[K%${margin}s \033[2m│ %b\033[0m" "" "${log_buffer[i]}"
                lines_to_reset=$((lines_to_reset + 1))
            done
        fi

        [[ $percent -ge 100 ]] && break
        printf "\033[%dA" "$lines_to_reset" # Return to Line 1 start
        sleep 0.016
    done
    
    tput cnorm
    printf "\n"
}

# --- UI Square Progress ---
# A square/rectangular progress indicator that fills up dot by dot.
# Supports Mode A (Linear: 0-100) and Mode B (Tagged: P:[val], M:[status]).
bl_square_progress() {
# Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_square_progress" "bl_hex_to_rgb" || return 1

    local label="Progress"
    local tagged=false
    local r1=0; local g1=0; local b1=255 # Default Start: Blue
    local r2=0; local g2=255; local b2=0  # Default End: Green
    
    local width=10
    local height=10
    local full_width=false
    local show_brackets=false
    local color_mode="global"

    # Flag Parser
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--label) label="$2"; shift 2 ;;
            -t|--tagged) tagged=true; shift ;;
            -w|--width) width="$2"; shift 2 ;;
            -H|--height) height="$2"; shift 2 ;;
            -fw|--full-width) full_width=true; shift ;;
            --brackets) show_brackets=true; shift ;;
            -c|--color-mode) color_mode="$2"; shift 2 ;;
            -h|--hex|--start)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r1="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g1="${tmp%% *}"
                b1="${tmp#* }"
                shift 2
                ;;
            --end)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r2="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g2="${tmp%% *}"
                b2="${tmp#* }"
                shift 2
                ;;
            *) shift ;;
        esac
    done

    local margin=2
    local percent=0
    local status_msg="Initializing..."
    local empty_char="·"
    local fill_char="■"

    tput civis
    
    while true; do
        if read -t 0.01 -r line; then
            if $tagged; then
                case "$line" in
                    P:*) percent="${line#P:}" ;;
                    M:*) status_msg="${line#M:}" ;;
                esac
            else
                if [[ "$line" =~ ^[0-9]+$ ]]; then
                    percent="$line"
                fi
            fi
        elif [[ $? -le 128 ]]; then
            break
        fi

        (( percent < 0 )) && percent=0
        (( percent > 100 )) && percent=100

        # Math for grid sizing
        local term_cols=${COLUMNS:-$(tput cols)}
        local grid_w=$width
        local extra_chars=$margin
        
        if $show_brackets; then
            extra_chars=$(( extra_chars + 3 )) # "[ " and "]" takes 3 visual spaces
        fi

        if $full_width; then
            grid_w=$(( (term_cols - extra_chars) / 2 )) # divide by 2 because "■ " is 2 chars wide
            (( grid_w < 5 )) && grid_w=5
        fi

        local total_cells=$(( grid_w * height ))
        local filled_cells=$(( total_cells * percent / 100 ))

        # Global Color Calc
        local r_global=$(( r1 + (r2 - r1) * percent / 100 ))
        local g_global=$(( g1 + (g2 - g1) * percent / 100 ))
        local b_global=$(( b1 + (b2 - b1) * percent / 100 ))
        local global_color_esc="\033[38;2;${r_global};${g_global};${b_global}m"

        # Render Header
        printf "\r\033[K%${margin}s ${global_color_esc}== %s ==\033[0m\n" "" "$label"
        
        # Render Grid
        for ((row=0; row<height; row++)); do
            printf "\033[K%${margin}s" ""
            if $show_brackets; then
                printf "\033[1;37m[ \033[0m"
            fi
            
            for ((col=0; col<grid_w; col++)); do
                local cell=$(( row * grid_w + col ))
                
                local cell_color_esc
                if [[ "$color_mode" == "position" ]]; then
                    if (( total_cells > 1 )); then
                        local r_pos=$(( r1 + (r2 - r1) * cell / (total_cells - 1) ))
                        local g_pos=$(( g1 + (g2 - g1) * cell / (total_cells - 1) ))
                        local b_pos=$(( b1 + (b2 - b1) * cell / (total_cells - 1) ))
                        cell_color_esc="\033[38;2;${r_pos};${g_pos};${b_pos}m"
                    else
                        cell_color_esc="$global_color_esc"
                    fi
                else
                    cell_color_esc="$global_color_esc"
                fi

                if (( cell < filled_cells )); then
                    printf "%b%s \033[0m" "$cell_color_esc" "$fill_char"
                else
                    printf "\033[38;5;239m%s \033[0m" "$empty_char"
                fi
            done

            if $show_brackets; then
                printf "\033[1;37m]\033[0m"
            fi
            printf "\n"
        done
        
        # Render Status Footer
        if $tagged; then
            printf "\033[K%${margin}s \033[1;33m%3d%%\033[0m - \033[38;5;248m%s\033[0m\n" "" "$percent" "$status_msg"
        else
            printf "\033[K%${margin}s \033[1;33m%3d%%\033[0m\n" "" "$percent"
        fi

        [[ $percent -ge 100 ]] && break
        
        local lines_to_reset=$(( height + 2 ))
        printf "\033[%dA" "$lines_to_reset" # Return to top
        sleep 0.016
    done
    
    tput cnorm
}

# --- UI Spiral Progress ---
# A square/rectangular progress indicator that fills up in a spiral (inward or outward).
# Supports Mode A (Linear: 0-100) and Mode B (Tagged: P:[val], M:[status]).
bl_spiral_progress() {
# Rule: This function has dependencies — bl_check_deps is called as the first statement.
    bl_check_deps "bl_spiral_progress" "bl_hex_to_rgb" || return 1

    local label="Progress"
    local tagged=false
    local r1=0; local g1=0; local b1=255
    local r2=0; local g2=255; local b2=0
    
    local width=10
    local height=10
    local full_width=false
    local show_brackets=false
    local color_mode="global"
    local direction="in"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--label) label="$2"; shift 2 ;;
            -t|--tagged) tagged=true; shift ;;
            -w|--width) width="$2"; shift 2 ;;
            -H|--height) height="$2"; shift 2 ;;
            -fw|--full-width) full_width=true; shift ;;
            --brackets) show_brackets=true; shift ;;
            -c|--color-mode) color_mode="$2"; shift 2 ;;
            --direction) direction="$2"; shift 2 ;;
            -h|--hex|--start)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r1="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g1="${tmp%% *}"
                b1="${tmp#* }"
                shift 2
                ;;
            --end)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r2="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g2="${tmp%% *}"
                b2="${tmp#* }"
                shift 2
                ;;
            *) shift ;;
        esac
    done

    local margin=2
    local percent=0
    local status_msg="Initializing..."
    local empty_char="·"
    local fill_char="■"

    local term_cols=${COLUMNS:-$(tput cols)}
    local grid_w=$width
    local extra_chars=$margin
    
    if $show_brackets; then extra_chars=$(( extra_chars + 3 )); fi
    if $full_width; then
        grid_w=$(( (term_cols - extra_chars) / 2 ))
        (( grid_w < 5 )) && grid_w=5
    fi

    local total_cells=$(( grid_w * height ))
    
    # Pre-calculate spiral mapping
    local -A cell_order
    local top=0 bottom=$((height - 1)) left=0 right=$((grid_w - 1))
    local count=0

    while (( count < total_cells )); do
        for ((i=left; i<=right && count < total_cells; i++)); do
            cell_order["$top,$i"]=$count; ((count++))
        done
        ((top++))
        for ((i=top; i<=bottom && count < total_cells; i++)); do
            cell_order["$i,$right"]=$count; ((count++))
        done
        ((right--))
        for ((i=right; i>=left && count < total_cells; i--)); do
            cell_order["$bottom,$i"]=$count; ((count++))
        done
        ((bottom--))
        for ((i=bottom; i>=top && count < total_cells; i--)); do
            cell_order["$i,$left"]=$count; ((count++))
        done
        ((left++))
    done

    tput civis
    
    while true; do
        if read -t 0.01 -r line; then
            if $tagged; then
                case "$line" in
                    P:*) percent="${line#P:}" ;;
                    M:*) status_msg="${line#M:}" ;;
                esac
            else
                if [[ "$line" =~ ^[0-9]+$ ]]; then percent="$line"; fi
            fi
        elif [[ $? -le 128 ]]; then
            break
        fi

        (( percent < 0 )) && percent=0
        (( percent > 100 )) && percent=100

        local filled_cells=$(( total_cells * percent / 100 ))

        local r_global=$(( r1 + (r2 - r1) * percent / 100 ))
        local g_global=$(( g1 + (g2 - g1) * percent / 100 ))
        local b_global=$(( b1 + (b2 - b1) * percent / 100 ))
        local global_color_esc="\033[38;2;${r_global};${g_global};${b_global}m"

        printf "\r\033[K%${margin}s ${global_color_esc}== %s ==\033[0m\n" "" "$label"
        
        for ((row=0; row<height; row++)); do
            printf "\033[K%${margin}s" ""
            if $show_brackets; then printf "\033[1;37m[ \033[0m"; fi
            
            for ((col=0; col<grid_w; col++)); do
                local order_idx=${cell_order["$row,$col"]}
                if [[ "$direction" == "out" ]]; then
                    order_idx=$(( total_cells - 1 - order_idx ))
                fi
                
                local cell_color_esc
                if [[ "$color_mode" == "position" ]]; then
                    if (( total_cells > 1 )); then
                        local r_pos=$(( r1 + (r2 - r1) * order_idx / (total_cells - 1) ))
                        local g_pos=$(( g1 + (g2 - g1) * order_idx / (total_cells - 1) ))
                        local b_pos=$(( b1 + (b2 - b1) * order_idx / (total_cells - 1) ))
                        cell_color_esc="\033[38;2;${r_pos};${g_pos};${b_pos}m"
                    else
                        cell_color_esc="$global_color_esc"
                    fi
                else
                    cell_color_esc="$global_color_esc"
                fi

                if (( order_idx < filled_cells )); then
                    printf "%b%s \033[0m" "$cell_color_esc" "$fill_char"
                else
                    printf "\033[38;5;239m%s \033[0m" "$empty_char"
                fi
            done

            if $show_brackets; then printf "\033[1;37m]\033[0m"; fi
            printf "\n"
        done
        
        if $tagged; then
            printf "\033[K%${margin}s \033[1;33m%3d%%\033[0m - \033[38;5;248m%s\033[0m\n" "" "$percent" "$status_msg"
        else
            printf "\033[K%${margin}s \033[1;33m%3d%%\033[0m\n" "" "$percent"
        fi

        [[ $percent -ge 100 ]] && break
        
        local lines_to_reset=$(( height + 2 ))
        printf "\033[%dA" "$lines_to_reset"
        sleep 0.016
    done
    
    tput cnorm
}

# --- UI Bar V4: Minecraft Terrain Loader ---
bl_terrain_loader() {
    bl_check_deps "bl_terrain_loader" "bl_hex_to_rgb" || return 1

    local width=40
    local height=15
    local label="Generating Terrain..."
    local empty_char="░"
    local fill_char="█"
    
    local bg_color="\e[38;5;238m" # Dark grey
    local reset="\e[0m"

    local color_mode="time"
    local pattern="random"
    local r1=255; local g1=255; local b1=0 # Default start: Yellow (#FFFF00)
    local r2=0; local g2=255; local b2=255 # Default end: Cyan (#00FFFF)
    local fg_color="\e[38;5;46m"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--width) width="$2"; shift 2 ;;
            -h|--height) height="$2"; shift 2 ;;
            -fw|--full-width) width=$(tput cols); shift 1 ;;
            -fh|--full-height) height=$(( $(tput lines) - 2 )); shift 1 ;;
            -l|--label) label="$2"; shift 2 ;;
            -c|--color-mode) color_mode="$2"; shift 2 ;;
            -w|--width) width="$2"; shift 2 ;;
            -fw|--full-width) full_width=true; shift ;;
            --pattern) pattern="$2"; shift 2 ;;
            --minecraft) pattern="minecraft"; shift 1 ;;
            --start)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r1="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g1="${tmp%% *}"
                b1="${tmp#* }"
                shift 2
                ;;
            --end)
                local rgb_out
                rgb_out=$(bl_hex_to_rgb "$2")
                r2="${rgb_out%% *}"
                local tmp="${rgb_out#* }"
                g2="${tmp%% *}"
                b2="${tmp#* }"
                shift 2
                ;;
            --fg) fg_color="\e[38;5;${2}m"; shift 2 ;;
            *) shift ;;
        esac
    done

    local total_blocks=$((width * height))
    local -a grid
    local -a unfilled
    
    for ((i=0; i<total_blocks; i++)); do
        grid[i]=0
    done
    
    # Pre-calculate fill order based on pattern
    if [[ "$pattern" == "center-out" || "$pattern" == "minecraft" ]]; then
        local cx=$(( width / 2 ))
        local cy=$(( height / 2 ))
        local -a sort_buffer
        for ((i=0; i<total_blocks; i++)); do
            local x=$(( i % width ))
            local y=$(( i / width ))
            # Scale Y by 2 to account for terminal character aspect ratio
            local dx=$(( x - cx ))
            local dy=$(( (y - cy) * 2 ))
            local dist=$(( dx * dx + dy * dy ))
            
            # Add random jitter so the circle expansion looks organic
            local noise=0
            if [[ "$pattern" == "minecraft" ]]; then
                noise=$(( RANDOM % 30 )) # High noise for more chaotic edge
            else
                noise=$(( RANDOM % 15 )) # Low noise for center-out
            fi
            
            local final_dist=$(( dist + noise ))
            sort_buffer[i]="$final_dist $i"
        done
        
        # Sort in descending order so the closest blocks (smallest distance) 
        # end up at the end of the array, allowing us to pop them efficiently.
        local idx_counter=0
        while read -r dist idx_val; do
            unfilled[idx_counter]=$idx_val
            ((idx_counter++))
        done < <(printf "%s\n" "${sort_buffer[@]}" | sort -n -r)
    else
        for ((i=0; i<total_blocks; i++)); do
            unfilled[i]=$i
        done
    fi
    
    local unfilled_count=$total_blocks
    
    local current_filled=0
    local percent=0

    tput civis
    
    echo -e "${fg_color}${label}${reset}"
    for ((y=0; y<height; y++)); do
        for ((x=0; x<width; x++)); do
            echo -ne "${bg_color}${empty_char}${reset}"
        done
        echo ""
    done

    while true; do

        if read -t 0.05 -r line; then
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                percent="$line"
            elif [[ "$line" == P:* ]]; then
                percent="${line#P:}"
            fi
            
            if [[ "$percent" -gt 100 ]]; then percent=100; fi
            if [[ "$percent" -lt 0 ]]; then percent=0; fi
        else
            local ret=$?
            if [[ $ret -gt 128 ]]; then
                :
            else
                break
            fi
        fi

        local target_filled=$((total_blocks * percent / 100))
        
        local updated=false
        while [[ $current_filled -lt $target_filled && $unfilled_count -gt 0 ]]; do
            local rand_idx
            if [[ "$pattern" == "center-out" ]]; then
                rand_idx=$(( unfilled_count - 1 )) # Pop strictly from the pre-sorted tail
            elif [[ "$pattern" == "minecraft" ]]; then
                # Minecraft loading behavior:
                # 15% chance to pick a completely random block anywhere (simulate network/disk lag or spawn chunks)
                # 85% chance to pick from the nearest 12 blocks for a fuzzy expanding edge
                if (( RANDOM % 100 < 15 )); then
                    rand_idx=$(( RANDOM % unfilled_count ))
                else
                    local tail_idx=$(( unfilled_count - 1 ))
                    local range=12
                    if (( unfilled_count < range )); then range=$unfilled_count; fi
                    rand_idx=$(( tail_idx - (RANDOM % range) ))
                fi
            else
                rand_idx=$(( RANDOM % unfilled_count )) # Pick random
            fi
            
            local target_block=${unfilled[$rand_idx]}
            
            ((current_filled++))
            grid[$target_block]=$current_filled
            
            unfilled[$rand_idx]=${unfilled[$((unfilled_count - 1))]}
            ((unfilled_count--))
            updated=true
        done
        
        if $updated; then
            local global_esc="$fg_color"
            if [[ "$color_mode" == "global" ]]; then
                local current_r=$(( r1 + (r2 - r1) * percent / 100 ))
                local current_g=$(( g1 + (g2 - g1) * percent / 100 ))
                local current_b=$(( b1 + (b2 - b1) * percent / 100 ))
                global_esc="\033[38;2;${current_r};${current_g};${current_b}m"
            fi

            tput cuu $height
            for ((y=0; y<height; y++)); do
                local row_str=""
                for ((x=0; x<width; x++)); do
                    local idx=$((y * width + x))
                    if [[ ${grid[$idx]} -gt 0 ]]; then
                        local cell_color="$global_esc"
                        if [[ "$color_mode" == "position" ]]; then
                            local r_pos=$(( r1 + (r2 - r1) * x / (width - 1) ))
                            local g_pos=$(( g1 + (g2 - g1) * x / (width - 1) ))
                            local b_pos=$(( b1 + (b2 - b1) * x / (width - 1) ))
                            cell_color="\033[38;2;${r_pos};${g_pos};${b_pos}m"
                        elif [[ "$color_mode" == "time" ]]; then
                            local fill_time=${grid[$idx]}
                            local r_time=$(( r1 + (r2 - r1) * fill_time / total_blocks ))
                            local g_time=$(( g1 + (g2 - g1) * fill_time / total_blocks ))
                            local b_time=$(( b1 + (b2 - b1) * fill_time / total_blocks ))
                            cell_color="\033[38;2;${r_time};${g_time};${b_time}m"
                        fi
                        row_str+="${cell_color}${fill_char}${reset}"
                    else
                        row_str+="${bg_color}${empty_char}${reset}"
                    fi
                done
                echo -ne "${row_str}\e[K\n"
            done
        fi
        
        if [[ $percent -ge 100 && $current_filled -ge $total_blocks ]]; then
            break
        fi
    done
    
    tput cnorm
    echo ""
}

# --- Optimized Terrain Loader (experimental) ---
bl_terrain_loader_opt() {
    # Placeholder for a 3‑D‑optimized rendering version.
    # Future work: redraw only changed rows, batch colour calculations, etc.
    # For now it simply delegates to the original implementation.
    bl_terrain_loader "$@"
}

