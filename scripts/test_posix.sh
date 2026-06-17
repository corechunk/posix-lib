#!/usr/bin/env sh
# Expressive test suite for verification of all posix.sh helpers
# Displays code snippets executed in each section before outputting results.

set -e

print_header() {
    printf "\n######################################################################\n"
    printf "  SECTION: %s\n" "$1"
    printf "######################################################################\n"
}

# ======================================================================
# SECTION 1: Syntax & Compatibility Verifications (Pre-Sourcing)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"
cat <<'EOF'
```sh
dash -n lib/core/posix.sh
posh -n lib/core/posix.sh
```
EOF

posix_lib_file="$(dirname "$0")/../lib/core/posix.sh"

echo "1. Checking syntax compatibility with 'dash':"
if command -v dash >/dev/null 2>&1; then
    dash -n "$posix_lib_file" && echo "  --> DASH: SYNTAX OK" || echo "  --> DASH: SYNTAX ERROR"
else
    echo "  --> 'dash' executable not found in PATH."
fi

echo "2. Checking syntax compatibility with 'posh':"
if command -v posh >/dev/null 2>&1; then
    posh -n "$posix_lib_file" && echo "  --> POSH: SYNTAX OK" || echo "  --> POSH: SYNTAX ERROR"
else
    echo "  --> 'posh' executable not found in PATH."
fi

# ======================================================================
# Source the POSIX helpers to proceed with execution tests
# ======================================================================
. "$posix_lib_file"

# ======================================================================
# SECTION 2: Scope & Registry Management
# ======================================================================
print_header "Scope, registry and dynamic naming"
cat <<'EOF'
```sh
_bl_gen_salt
salt=$_bl_salt_val
bl_var_init "USER_SHELL" "$salt"
bl_var_set "USER_SHELL" "/bin/sh" "$salt"
val=$(bl_var_get "USER_SHELL" "$salt")
```
EOF

_bl_gen_salt
salt=$_bl_salt_val
echo "Generated salt value: '$salt'"

bl_var_init "USER_SHELL" "$salt"
bl_var_set "USER_SHELL" "/bin/sh" "$salt"
val=$(bl_var_get "USER_SHELL" "$salt")
echo "Variable [USER_SHELL] set & retrieved: '$val' (Expected: '/bin/sh')"

# ======================================================================
# SECTION 3: Array Emulation Tests
# ======================================================================
print_header "Array management (Append, Get, Length index boundary)"
cat <<'EOF'
```sh
bl_arr_init "COLORS" "$salt"
bl_arr_append "COLORS" "Red" "$salt"
bl_arr_append "COLORS" "Green" "$salt"
bl_arr_append "COLORS" "Blue" "$salt"
bl_arr_append "COLORS" "Yellow" "$salt"
color0=$(bl_arr_get "COLORS" 0 "$salt")
color1=$(bl_arr_get "COLORS" 1 "$salt")
color2=$(bl_arr_get "COLORS" 2 "$salt")
color3=$(bl_arr_get "COLORS" 3 "$salt")
```
EOF

bl_arr_init "COLORS" "$salt"
bl_arr_append "COLORS" "Red" "$salt"
bl_arr_append "COLORS" "Green" "$salt"
bl_arr_append "COLORS" "Blue" "$salt"
bl_arr_append "COLORS" "Yellow" "$salt"

color0=$(bl_arr_get "COLORS" 0 "$salt")
color1=$(bl_arr_get "COLORS" 1 "$salt")
color2=$(bl_arr_get "COLORS" 2 "$salt")
color3=$(bl_arr_get "COLORS" 3 "$salt")

echo "Index 0: '$color0' (Expected: 'Red')"
echo "Index 1: '$color1' (Expected: 'Green')"
echo "Index 2: '$color2' (Expected: 'Blue')"
echo "Index 3: '$color3' (Expected: 'Yellow')"

# ======================================================================
# SECTION 4: Associative Map Tests
# ======================================================================
print_header "Associative Map emulation (Set, Get, Keys retrieval)"
cat <<'EOF'
```sh
bl_map_init "CONFIG" "$salt"
bl_map_set "CONFIG" "host" "127.0.0.1" "$salt"
bl_map_set "CONFIG" "port" "8080" "$salt"
bl_map_set "CONFIG" "timeout" "30" "$salt"
host_val=$(bl_map_get "CONFIG" "host" "$salt")
port_val=$(bl_map_get "CONFIG" "port" "$salt")
timeout_val=$(bl_map_get "CONFIG" "timeout" "$salt")
bl_map_keys "CONFIG" "$salt"
```
EOF

bl_map_init "CONFIG" "$salt"
bl_map_set "CONFIG" "host" "127.0.0.1" "$salt"
bl_map_set "CONFIG" "port" "8080" "$salt"
bl_map_set "CONFIG" "timeout" "30" "$salt"

host_val=$(bl_map_get "CONFIG" "host" "$salt")
port_val=$(bl_map_get "CONFIG" "port" "$salt")
timeout_val=$(bl_map_get "CONFIG" "timeout" "$salt")

echo "Map Key 'host': '$host_val' (Expected: '127.0.0.1')"
echo "Map Key 'port': '$port_val' (Expected: '8080')"
echo "Map Key 'timeout': '$timeout_val' (Expected: '30')"

echo "Listing Map Keys:"
bl_map_keys "CONFIG" "$salt"

# ======================================================================
# SECTION 5: Glob & Regex Pattern Matching
# ======================================================================
print_header "Pattern and Regex match engines"
cat <<'EOF'
```sh
posix_match_glob "posix.sh" "*.sh"
posix_match_regex "user-1024" "^[a-z]+-[0-9]+$"
```
EOF

if posix_match_glob "posix.sh" "*.sh"; then
    echo "Glob 'posix.sh' matches '*.sh': MATCHED"
else
    echo "Glob 'posix.sh' matches '*.sh': FAILED"
fi

if posix_match_regex "user-1024" "^[a-z]+-[0-9]+$"; then
    echo "Regex 'user-1024' matches '^[a-z]+-[0-9]+$': MATCHED"
else
    echo "Regex 'user-1024' matches '^[a-z]+-[0-9]+$': FAILED"
fi

# ======================================================================
# SECTION 6: Conjunction & Disjunction Tests
# ======================================================================
print_header "Logical combinators (all_true, any_true)"
cat <<'EOF'
```sh
posix_all_true "10 -eq 10" "20 -gt 15" "'test' = 'test'"
posix_any_true "5 -ne 5" "10 -eq 12" "7 -gt 3"
```
EOF

if posix_all_true "10 -eq 10" "20 -gt 15" "'test' = 'test'"; then
    echo "posix_all_true evaluation: SUCCESS (Expected)"
else
    echo "posix_all_true evaluation: FAILURE"
fi

if posix_any_true "5 -ne 5" "10 -eq 12" "7 -gt 3"; then
    echo "posix_any_true evaluation: SUCCESS (Expected)"
else
    echo "posix_any_true evaluation: FAILURE"
fi

# ======================================================================
# SECTION 7: Arithmetic & Loops
# ======================================================================
print_header "Arithmetic context & loops"
cat <<'EOF'
```sh
posix_arith_test "((5 * 5) / 2) > 10"
posix_for "i=1" "\$i -le 10" "i=\$(( i+1 ))" 'printf " %d" "\$i"'
```
EOF

if posix_arith_test "((5 * 5) / 2) > 10"; then
    echo "posix_arith_test '((5 * 5) / 2) > 10': TRUE (Expected)"
else
    echo "posix_arith_test '((5 * 5) / 2) > 10': FALSE"
fi

echo "Running C-style loop (1 to 10):"
posix_for "i=1" "\$i -le 10" "i=\$(( i+1 ))" 'printf " %d" "$i"'
printf "\n"

# ======================================================================
# SECTION 8: String manipulation & conversions
# ======================================================================
print_header "Substrings & Hex conversions"
cat <<'EOF'
```sh
posix_substr "StandardPOSIXLibrary" 8 5
posix_hex_to_dec "#FF0000"
posix_hex_to_dec "0x0000FF"
```
EOF

sub_test=$(posix_substr "StandardPOSIXLibrary" 8 5)
echo "Substring from index 8 (len 5): '$sub_test' (Expected: 'POSIX')"

dec_color1=$(posix_hex_to_dec "#FF0000")
dec_color2=$(posix_hex_to_dec "0x0000FF")
echo "Hex conversion '#FF0000' -> '$dec_color1' (Expected: 16711680)"
echo "Hex conversion '0x0000FF' -> '$dec_color2' (Expected: 255)"

# ======================================================================
# SECTION 9: Range validation of random values
# ======================================================================
print_header "Pseudo-random integer generator ranges"
cat <<'EOF'
```sh
posix_random 1 0
posix_random 20 10
posix_random 105 100
posix_random 1000 500
posix_random 100 1
posix_random 9999 999
posix_random 8 2
posix_random 47 45
```
EOF

test_rand_range() {
    min=$1
    max=$2
    out=$(posix_random "$max" "$min")
    if [ "$out" -ge "$min" ] && [ "$out" -le "$max" ]; then
        echo "Random Range [$min, $max] -> generated: $out (OK)"
    else
        echo "Random Range [$min, $max] -> generated: $out (OUT OF BOUNDS!)"
    fi
}

test_rand_range 0 1
test_rand_range 10 20
test_rand_range 100 105
test_rand_range 500 1000
test_rand_range 1 100
test_rand_range 999 9999
test_rand_range 2 8
test_rand_range 45 47

# ======================================================================
# SECTION 10: Scope Cleanup Verification
# ======================================================================
print_header "Scope isolation & Cleanup check"
cat <<'EOF'
```sh
bl_cleanup_scope "$salt"
bl_var_get "USER_SHELL" "$salt"
bl_map_get "CONFIG" "host" "$salt"
```
EOF

bl_cleanup_scope "$salt"
echo "Executed bl_cleanup_scope on salt: '$salt'"

cleaned_var=$(bl_var_get "USER_SHELL" "$salt")
if [ -z "$cleaned_var" ]; then
    echo "Cleanup Check: USER_SHELL var was successfully released (OK)"
else
    echo "Cleanup Check: USER_SHELL variable still leaked values: '$cleaned_var'"
fi

cleaned_map_dir=$(bl_map_get "CONFIG" "host" "$salt" 2>/dev/null || echo "UNSET")
if [ "$cleaned_map_dir" = "UNSET" ]; then
    echo "Cleanup Check: CONFIG Map directory was successfully purged (OK)"
else
    echo "Cleanup Check: CONFIG directory was NOT deleted: '$cleaned_map_dir'"
fi

printf "\n======================================================================\n"
echo "  Expressive test suite execution completed successfully."
printf "======================================================================\n"
