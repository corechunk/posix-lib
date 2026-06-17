#!/usr/bin/env sh
# Test verification for compile.sh using POSIX-compliant syntax

set -e

print_header() {
    printf "\n######################################################################\n"
    printf "  SECTION: %s\n" "$1"
    printf "######################################################################\n"
}

# ======================================================================
# Source requirements first
# ======================================================================
. "$(dirname "$0")/../lib/core/posix.sh"
. "$(dirname "$0")/../lib/core/import.sh"

# ======================================================================
# SECTION 1: Syntax compatibility verifications (-n checks)
# ======================================================================
print_header "External Compatibility Syntax Checks (-n checks)"

compile_file="$(dirname "$0")/../lib/dev/compile.sh"

if command -v dash >/dev/null 2>&1; then
    dash -n "$compile_file" && echo "  --> DASH: SYNTAX OK"
fi
if command -v posh >/dev/null 2>&1; then
    posh -n "$compile_file" && echo "  --> POSH: SYNTAX OK"
fi

# ======================================================================
# Source the target script
# ======================================================================
. "$compile_file"

# ======================================================================
# SECTION 2: Functional verification of bl_compile
# ======================================================================
print_header "Verifying bl_compile Building"

# Setup temporary source folder
src_temp=$(mktemp -d)
build_temp=$(mktemp -d)

# Write dummy files
cat <<'EOF' > "$src_temp/file1.sh"
#!/usr/bin/env sh
# This is a comment in file1.sh
echo "File 1 Executed"

EOF

cat <<'EOF' > "$src_temp/file2.sh"
#!/usr/bin/env sh

# Comment in file2.sh
echo "File 2 Executed"
EOF

echo "Created test source files in: $src_temp"

# 1. Compile without stripping
echo "Running compilation (no strip)..."
bl_compile --dir "$src_temp" --out-dir "$build_temp" --out-name "compiled_raw.sh" --verbose

if [ -f "$build_temp/compiled_raw.sh" ] && [ -x "$build_temp/compiled_raw.sh" ]; then
    echo "  --> Default Compilation: SUCCESS"
else
    echo "  --> Default Compilation: FAILED" >&2
    exit 1
fi

# 2. Compile with strip all
echo "Running compilation (strip all)..."
bl_compile --dir "$src_temp" --out-dir "$build_temp" --out-name "compiled_stripped.sh" --strip all --verbose

if [ -f "$build_temp/compiled_stripped.sh" ]; then
    # Ensure shebang exists but comment lines are removed
    if grep -q "Comment in file2.sh" "$build_temp/compiled_stripped.sh"; then
        echo "  --> Strip Compilation: FAILED (comment found)" >&2
        exit 1
    else
        echo "  --> Strip Compilation: SUCCESS (comments successfully stripped)"
    fi
else
    echo "  --> Strip Compilation: FAILED" >&2
    exit 1
fi

# 3. Compile with remote URL inlining
echo "Running compilation (with remote URL)..."
bl_compile --dir "$src_temp" \
           --out-dir "$build_temp" \
           --out-name "compiled_remote.sh" \
           --lib-curl "https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/colors.sh" \
           --verbose

if grep -q "BL_RED" "$build_temp/compiled_remote.sh"; then
    echo "  --> Remote Sourcing: SUCCESS (inlined BL_RED)"
else
    echo "  --> Remote Sourcing: FAILED" >&2
    exit 1
fi

# Clean up
rm -rf "$src_temp" "$build_temp"

printf "\n======================================================================\n"
echo "  Compiler test suite execution completed successfully."
printf "======================================================================\n"
