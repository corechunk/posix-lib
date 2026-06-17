#!/usr/bin/env bash

# Enhanced matrix filler animation with multiple modes, color gradients, and language character sets.
# Supports start/end colors as either tput index or hexadecimal (e.g., "#00FF00").
# Dependencies: tput, bl_check_deps (project utility)

# Helper: Convert hex color to RGB components
hex_to_rgb() {
  local hex=$1
  hex=${hex#"#"}
  printf "%d %d %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Helper: Build ANSI escape sequence for truecolor foreground
rgb_seq() {
  local r=$1 g=$2 b=$3
  printf "\e[38;2;%s;%s;%sm" "$r" "$g" "$b"
}

bl_matrix_filler() {
    # Parse options
    local mode="classic"        # classic | rain | fade
    local start_color=2          # default tput color index (green)
    local end_color=7            # default tput color index (white)
    local start_hex=""          # optional hex overrides
    local end_hex=""
    local langs=""              # combination of j,c,k for Japanese, Chinese, Korean
    local density=50            # default spawn probability (lower = denser)
    local duration=0            # 0 = run until key press
    
    while (( "$#" )); do
        case "$1" in
            --mode) mode="$2"; shift 2;;
            --start-color) start_color="$2"; shift 2;;
            --end-color) end_color="$2"; shift 2;;
            --start-hex) start_hex="$2"; shift 2;;
            --end-hex) end_hex="$2"; shift 2;;
            --lang) langs+="$2,"; shift 2;;
            --density) density="$2"; shift 2;;
            --duration) duration="$2"; shift 2;;
            *) break;;
        esac
    done

    # Build character set based on language flags
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()_+{}[]"
    if [[ $langs == *j* ]]; then
        chars+=" あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
    fi
    if [[ $langs == *c* ]]; then
        chars+=" 一二三四五六七八九十百千万"
    fi
    if [[ $langs == *k* ]]; then
        chars+=" 가각간갇갈갉감갑갓갔강갖갗같"
    fi
    local char_len=${#chars}

    # Ensure dependencies are present
    bl_check_deps "bl_matrix_filler" "tput" || return 1

    local cols lines
    cols=$(tput cols)
    lines=$(tput lines)
    local start_time=$(date +%s)

    # Resize handling
    trap 'cols=$(tput cols); lines=$(tput lines)' WINCH
    # Cleanup on exit
    trap 'tput sgr0; tput cnorm; clear; trap - WINCH INT TERM RETURN; return' INT TERM RETURN

    tput civis
    clear

    # Initialize drop arrays
    local -a drops speeds lengths
    local i
    for ((i=0; i<cols; i++)); do
        drops[i]=0
        speeds[i]=$((RANDOM % 3 + 1))
        lengths[i]=$((10 + RANDOM % 10))
    done

    # Prepare color sequences
    local sr sg sb er eg eb
    local start_seq dark_seq darker_seq end_seq end_dark_seq end_darker_seq
    
    if [[ -n $start_hex ]]; then
        read sr sg sb <<<$(hex_to_rgb "$start_hex")
        start_seq=$(rgb_seq $sr $sg $sb)
        dark_seq=$(rgb_seq $((sr/3)) $((sg/3)) $((sb/3)))
        darker_seq=$(rgb_seq $((sr/8)) $((sg/8)) $((sb/8)))
    else
        start_seq=$(tput setaf $start_color)
        dark_seq="\e[2m${start_seq}"
        darker_seq="\e[2m\e[38;5;22m"
    fi
    
    if [[ -n $end_hex ]]; then
        read er eg eb <<<$(hex_to_rgb "$end_hex")
        end_seq=$(rgb_seq $er $eg $eb)
        end_dark_seq=$(rgb_seq $((er/3)) $((eg/3)) $((eb/3)))
        end_darker_seq=$(rgb_seq $((er/8)) $((eg/8)) $((eb/8)))
    else
        end_seq=$(tput setaf $end_color)
        end_dark_seq="\e[2m${end_seq}"
        end_darker_seq="\e[2m\e[38;5;53m"
    fi

    while true; do
        if (( duration > 0 )) && (( $(date +%s) - start_time >= duration )); then
            break
        fi

        local frame_buffer=""
        for ((i=0; i<cols; i++)); do
            # Possibly start a new drop
            if (( drops[i] == 0 && RANDOM % density == 0 )); then
                drops[i]=1
                speeds[i]=$((RANDOM % 3 + 1))
            fi

            if (( drops[i] > 0 )); then
                # Move down based on speed
                if (( RANDOM % speeds[i] == 0 )); then
                    local rand_char="${chars:RANDOM%char_len:1}"

                    # Determine colors for head and middle based on mode
                    local head_color middle_color dark_color darker_color
                    case "$mode" in
                        rain)
                            # Head turns to end_color when it hits the bottom 20%
                            if (( drops[i] > lines*8/10 )); then
                                head_color=$end_seq
                            else
                                head_color=$start_seq
                            fi
                            middle_color=$start_seq
                            dark_color=$dark_seq
                            darker_color=$darker_seq
                            ;;
                        fade)
                            if [[ -n $start_hex && -n $end_hex ]]; then
                                # Smooth RGB mathematical blend
                                local fraction=$((drops[i] * 100 / lines))
                                if (( fraction > 100 )); then fraction=100; fi
                                local br=$(( sr + (er - sr) * fraction / 100 ))
                                local bg=$(( sg + (eg - sg) * fraction / 100 ))
                                local bb=$(( sb + (eb - sb) * fraction / 100 ))
                                
                                head_color=$(rgb_seq $br $bg $bb)
                                middle_color=$head_color
                                dark_color=$(rgb_seq $((br/3)) $((bg/3)) $((bb/3)))
                                darker_color=$(rgb_seq $((br/8)) $((bg/8)) $((bb/8)))
                            else
                                # Fallback if standard colors are used
                                local fraction=$((drops[i] * 100 / lines))
                                if (( fraction > 50 )); then
                                    head_color=$end_seq
                                    middle_color=$end_seq
                                    dark_color=$end_dark_seq
                                    darker_color=$end_darker_seq
                                else
                                    head_color=$start_seq
                                    middle_color=$start_seq
                                    dark_color=$dark_seq
                                    darker_color=$darker_seq
                                fi
                            fi
                            ;;
                        *)
                            # Classic Matrix
                            head_color=$end_seq
                            middle_color=$start_seq
                            dark_color=$dark_seq
                            darker_color=$darker_seq
                            ;;
                    esac

                    # 1. Print head character (Bright White/End Color)
                    if (( drops[i] <= lines )); then
                        frame_buffer+="\e[$((drops[i]+1));$((i+1))H${head_color}\e[1m${rand_char}"
                    fi

                    # 2. Print middle character (Bright Trail)
                    local mid=$((drops[i] - 1))
                    if (( mid > 0 && mid <= lines )); then
                        frame_buffer+="\e[$((mid+1));$((i+1))H\e[0m${middle_color}${rand_char}"
                    fi

                    # 3. Fade to Dark (Mutating character)
                    local dark_pos=$((drops[i] - 6))
                    if (( dark_pos > 0 && dark_pos <= lines )); then
                        local rand_char_dark="${chars:RANDOM%char_len:1}"
                        frame_buffer+="\e[$((dark_pos+1));$((i+1))H\e[0m${dark_color}${rand_char_dark}"
                    fi

                    # 4. Fade to Very Dark (Mutating character, persists forever)
                    local darker_pos=$((drops[i] - 14))
                    if (( darker_pos > 0 && darker_pos <= lines )); then
                        local rand_char_darker="${chars:RANDOM%char_len:1}"
                        frame_buffer+="\e[$((darker_pos+1));$((i+1))H\e[0m${darker_color}${rand_char_darker}"
                    fi

                    # Never erase - characters stay on screen until overwritten by next drop

                    ((drops[i]++))
                    if (( drops[i] > lines + 20 )); then
                        drops[i]=0
                    fi
                fi
            fi
        done
        printf "%b" "$frame_buffer"
        read -t 0.05 -n 1 && break
    done

    tput sgr0
    tput cnorm
    clear
    trap - WINCH INT TERM RETURN
}
