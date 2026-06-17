function bl_bash_tutor() {
    local topics=(
        "01-toolchain-installation" "02-compilation-run-basics" "03-charset" "04-tokens-lexemes" "05-keywords-standards"
        "06-tuning-strictness" "07-comments-metadata" "08-variables-constants" "09-data-types" "10-string-escaping"
        "11-interpolation" "12-scope-lifetime" "13-storage-classes" "14-native-strings" "15-pattern-matching"
        "16-syntactic-automation" "17-operators" "18-precedence-associativity" "19-expressions-statements" "20-command-substitution"
        "21-type-casting" "22-truth-rule" "23-conditionals" "24-iteration-definite" "25-iteration-indefinite"
        "26-jump-statements" "27-function-basics" "28-return-types" "29-recursion" "30-passing-mechanisms"
        "31-closures-lambdas" "32-sequential-collections" "33-associative-collections" "34-structs-base" "35-procedural-mechanisms"
        "36-class-concept" "37-advanced-oop" "38-process-forking" "39-multi-threading" "40-async-coroutines"
        "41-synchronization-locks" "42-socket-basics" "43-tcp-udp-patterns" "44-http-client-api" "45-io-streams"
        "46-redirection-piping" "47-exit-codes-signals" "48-memory-management" "49-error-handling" "50-multi-file-projects"
        "51-build-tools" "52-linking-delivery" "53-standard-library" "bash" "bitwise"
        "expansion-manipulation" "floating-point" "null-safety" "overview" "overview-v2"
        "parameter-expansion"
    )

    bl_tutor_format_lesson() {
        local GREEN='\033[32m'
        local CYAN='\033[1;36m'
        local MAG='\033[1;35m'
        local RESET='\033[0m'
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^#\ .+$ ]]; then
                echo -e "${MAG}${line}${RESET}"
            elif [[ "$line" =~ ^###\ .+$ ]]; then
                echo -e "${CYAN}${line}${RESET}"
            elif [[ "$line" == *"\`"* ]]; then
                # Safe regex coloring for inline code blocks
                echo "$line" | sed -E "s/\`([^\`]+)\`/${GREEN}\1${RESET}/g"
            else
                echo "$line"
            fi
        done
    }

    bl_tutor_get_lesson() {
        case "$1" in
            03-charset)
cat <<'EOF'
# 🔴 Milestone 03: Character Sets (Charset) [SYSTEMS]

### 1. Bytes vs. Characters
A Character Set (Charset) is the map that turns binary numbers (bits) into human-readable symbols. Bash is a "Byte Stream" processor; it doesn't care what the bytes are until it hands them to the terminal.

```bash
# CONVENTIONAL: System-default interpretation
echo "🍎"                   # Displays correctly if locale is set

# VERIFICATION (Memory Layout)
printf "A" | xxd           # 41 (Single byte)
printf "🍎" | xxd          # f09f 8c8e (4 bytes in UTF-8)

# Logic: Bash treats characters as arbitrary byte sequences. 
# Multi-byte characters (like emojis) take up 2-4 slots in memory.
```

### 2. Locale & Encoding Control
The **Locale** is the system configuration that tells Bash how to sort, compare, and display those bytes. UTF-8 is the modern standard for internationalization.

```bash
# EXPLICIT: Environmental Control
export LANG=en_US.UTF-8     # Force UTF-8 interpretation
export LC_ALL=en_US.UTF-8    # Global override

# Logic: Bash relies on the system's C library (libc) to handle 
# charset mapping. These variables tell libc which map to load.
```
EOF
                ;;
            04-tokens-lexemes)
cat <<'EOF'
# 🟢 Milestone 04: Tokens & Lexemes [CORE]

### 1. Whitespace Significance
Tokens are the smallest units Bash understands. In the shell, **Whitespace is a Functional Separator**, not just a formatting choice. Its presence or absence changes the grammar entirely.

```bash
# CONVENTIONAL: Assignment (No spaces)
user="Alice"               # Assignment token

# INCORRECT: Assignment attempt with spaces
# user = "Alice"           # Bash looks for a command named 'user'

# Logic: The Lexer identifies the '=' token immediately followed 
# by text. If spaces exist, the '=' becomes a separate argument.
```

### 2. The Quoting Multiverse
Quoting is how you group multiple words into a single Token and control whether "Magic" characters (like `$`) are expanded or treated as literal text.

```bash
# EXPLICIT: Quoting Modes
echo 'No $user expansion'  # Single Quotes: Raw Literal text
echo "Hello $user"         # Double Quotes: Dynamic Expansion

# EXPLICIT: Multi-word tokens
name="Gemini CLI"          # Spaces are preserved inside quotes

# Logic: Double quotes tell the expansion engine to search for 
# $ markers. Single quotes disable the engine entirely for that block.
```
EOF
                ;;
            05-keywords-standards)
cat <<'EOF'
# 🟢 Milestone 05: Keywords & Standards [CORE]

### 1. Command Hierarchy
Not every command in Bash is a "Program" on your disk. Bash follows a specific lookup order to decide how to execute a word: **Keyword $\to$ Built-in $\to$ External**.

```bash
# CONVENTIONAL: General execution
if [[ -d /tmp ]]; then cd /tmp; ls; fi

# EXPLICIT: Resolving Command Source
type if                    # "if is a shell keyword" (Shell Grammar)
type cd                    # "cd is a shell builtin" (Internal to Bash)
type ls                    # "ls is /usr/bin/ls" (External Binary)

# Logic: Keywords control the parser. Built-ins run in the 
# current shell RAM. Externals require spawning a new process.
```

### 2. Standards & Portability
Bash has different "Modes" (like POSIX mode) that change its behavior to match older shell standards (like Sh or Dash).

```bash
# EXPLICIT: POSIX Enforcement
# bash --posix             # Start shell in strict POSIX mode

# Logic: Bash attempts to balance modern "Power" with legacy 
# "Compatibility." Standards mode disables Bash-only features 
# like [[ ]] or arrays.
```
EOF
                ;;
            06-tuning-strictness)
cat <<'EOF'
# 🔵 Milestone 06: Tuning & Strictness [PRO]

### 1. The "Lazy" Default
By default, Bash is optimized for interactive speed, not script safety. It will continue running even if a critical command (like `cd`) fails, leading to the "Snowball Effect" where one failure corrupts future operations.

```bash
# CONVENTIONAL: Loose execution
cd /nonexistent_dir
rm -rf *                   # WARNING: Deletes files in WRONG dir

# Logic: Without strictness, the shell ignores the non-zero exit 
# status of the 'cd' command and blindly executes the next line.
```

### 2. The "Unofficially-Official" Safe Mode
Tuning strictness enables "Guardrails" that force the shell to behave like a modern programming language, catching logical errors during the build process.

```bash
# EXPLICIT: The Golden Set
set -e                     # Fail-Fast: Exit on first error
set -u                     # Unbound Check: Error on unset variables
set -o pipefail            # Pipe Safety: Check ALL commands in a pipe

# BASH 4.0+ ENHANCEMENT
shopt -s inherit_errexit   # Pass -e into subshells ()

# Logic: These flags modify the Shell's internal Signal Table. 
# When 'set -e' is on, the shell internally wraps every command 
# in a check for the CPU's Status Register.
```
EOF
                ;;
            07-comments-metadata)
cat <<'EOF'
# 🟢 Milestone 07: Comments & Metadata [CORE]

### 1. Human-Readable Notes
Comments are sections of source code ignored by the shell. They should explain the *Reasoning* (the "Why") behind a specific implementation, not what the syntax already shows.

```bash
# CONVENTIONAL: Single line
# Calculate total excluding tax
echo "Logic"               # Inline comment

# Logic: When the parser encounters an unquoted '#', it discards 
# all remaining bytes on that line in its input buffer.
```

### 2. Machine-Readable Directives
Metadata provides "Out-of-band" instructions to the Kernel or the Shell itself. This includes identifying the interpreter and documenting script properties for maintenance.

```bash
# EXPLICIT: Mandatory Metadata
#!/usr/bin/env bash        # The Shebang (Kernel Directive)

# EXPLICIT: Block Documentation (Heredoc trick)
: '
  DESCRIPTION: Clean-up script for logs
  VERSION: 2.1.0
  DEPENDS: coreutils, grep
'

# Logic: The ':' (null command) treats the string as an argument 
# but does nothing with it, effectively creating a multi-line 
# block that is stored in RAM but never executed.
```
EOF
                ;;
            08-variables-constants)
cat <<'EOF'
# 🟢 Milestone 08: Variables & Constants [CORE]

### 1. Data Storage
A variable is a named pointer to a string of bytes in shell memory. In Bash, assignments are highly sensitive to whitespace; there must be NO SPACES around the assignment operator.

```bash
# CONVENTIONAL: Mutable assignment
user="alice"
count=5

# Logic: Bash creates an entry in its Global Hash Table, 
# dynamically allocating a buffer to hold the string "alice".
```

### 2. Data Protection
Constants are variables that are "Locked" in memory. They provide security for critical paths and ensure that global configuration remains stable.

```bash
# EXPLICIT: Constants (Immutable)
readonly PI=3.14           # C-style constant
declare -r APP_ROOT="/opt" # Attribute-style constant

# EXPLICIT: Global Visibility
export API_KEY="X-123"      # Shared with child processes

# Logic: 'readonly' marks the table entry with a write-protect 
# bit. Any attempt to re-assign triggers a "variable is readonly" 
# trap in the shell.
```
EOF
                ;;
            09-data-types)
cat <<'EOF'
# 🟢 Milestone 09: Data Types [CORE]

### 1. The Typeless Model
Bash is fundamentally "Typeless." Every variable is stored as a character stream (string). If you perform math, the shell "Interprets" the bytes as a number on the fly.

```bash
# CONVENTIONAL: String-based math
num="10"
res=$(( num + 5 ))         # Logic: 10 + 5 = 15

# Logic: When entering an arithmetic context $(( )), Bash scans 
# the string and attempts to convert it to a long integer in 
# temporary memory for the calculation.
```

### 2. Interpretation Flags
To avoid constant re-interpretation, you can set "Attributes" on a variable name. This tells the shell to treat specific names as integers or specialized structures (like arrays) permanently.

```bash
# EXPLICIT: Setting Attributes
declare -i x=10            # Integer flag (forces math context)
declare -a list=(1 2 3)    # Indexed Array flag
declare -A map=([k]=v)     # Associative Map flag
declare -n ref=var         # Nameref flag (The "Pointer")

# BEHAVIOR CHECK
x="string"                 # Logic: x becomes 0 (non-numeric)

# Logic: Attribute-based typing does not change the memory layout 
# (it is still a string), but it changes how the Assignment 
# Engine processes new values for that name.
```

## Deep-Dive Reference
For advanced manipulation and system internals:
- [Parameter Expansion](./data-type/parameter-expansion.md) | [Null Safety & Defaults](./data-type/null-safety.md)
- [Floating Point Limits](./data-type/floating-point.md) | [Attributes & Scoping](./12-scope-lifetime.md)
EOF
                ;;
            10-string-escaping)
cat <<'EOF'
# 🟢 Milestone 10: String Escaping [CORE]

### 1. Functional Neutralization
Escaping is the act of stripping a character (like `$`, `"`, or `\`) of its "Magic" or functional role so it can be treated as literal text. This is essential for printing raw symbols or handling complex paths.

```bash
# CONVENTIONAL: Backslash escaping
echo "Total cost: \$5.00"   # Neutralizes the expansion operator

# Logic: The Lexer toggles a "Literal bit" for the NEXT character 
# when it sees a \, causing the parser to ignore its functional 
# meaning and pass the raw byte to the buffer.
```

### 2. Advanced Quoting & Control
For invisible characters (newlines, tabs) or literal blocks, Bash provides specialized quoting engines that handle the heavy lifting.

```bash
# EXPLICIT: ANSI-C Quoting
echo $'Line 1\nLine 2'      # Handle tabs (\t) and newlines (\n)
echo $'\x41'               # Hex code for 'A'

# EXPLICIT: Raw Literal Blocks
echo 'No $VAR expansion'   # Single quotes: Absolute safety

# Logic: $' ' triggers a specialized scan that handles escaped 
# sequences before the string is ever handed to the expansion 
# engine. Single quotes disable the expansion engine entirely.
```

---
*See also: [Terminal Physics & ANSI Escapes](../../OS/Linux/Terminal/ANSI-Escapes.md)*

EOF
                ;;
            11-interpolation)
cat <<'EOF'
# 🟢 Milestone 11: Interpolation [CORE]

### 1. Variable Substitution
Interpolation is the act of replacing a variable placeholder (like `$VAR`) with its actual content. In Bash, this happens during the "Expansion" phase of command processing.

```bash
# CONVENTIONAL: Simple expansion
user="Alice"
echo "Hello $user"         # Hello Alice

# EXPLICIT: Ambiguity prevention
echo "${user}_backup"      # Prevents looking for 'user_backup' var

# Logic: Bash scans the string for the '$' marker, lookups the 
# name in the symbol table, and replaces the marker with the 
# literal bytes of the value.
```

### 2. Advanced Fallbacks
Bash interpolation supports logic for handling unset or null variables. This is the "Pro" way to provide default configuration values without using `if` statements.

```bash
# EXPLICIT: Default Values
echo "${user:-Guest}"      # Use "Guest" if user is unset/null
echo "${user:=Admin}"      # Set user to "Admin" if unset, then return it

# EXPLICIT: Error on Missing
: "${user:?Error: User not defined}" # Exit script if unset

# Logic: These operators are handled by the shell's internal 
# Expansion Engine, allowing for conditional data injection 
# before the command is executed.
```
EOF
                ;;
            12-scope-lifetime)
cat <<'EOF'
# 🟢 Milestone 12: Scope & Lifetime [CORE]

### 1. Visibility Rules
Scope determines where a variable is "seen." In Bash, the default behavior is extreme: every variable is **Global** to the current shell process.

```bash
# CONVENTIONAL: Global pollution
x=10
function set_x() { x=20; }
set_x
echo $x                    # Logic: Output is 20 (Global overwritten)

# Logic: Variables are stored in a single process-wide hash table. 
# Functions share this same memory space by default.
```

### 2. Variable Isolation
To write safe, reusable scripts, you must explicitly manage scope. This prevents functions from accidentally corrupting global state or each other.

```bash
# EXPLICIT: Local Function Scope
function my_func() {
    local temp="secret"    # Isolated to this function
}

# EXPLICIT: Subshell Isolation
x=10
( x=20 )                   # Forked child process
echo $x                    # Logic: Still 10 (Parent is protected)

# Logic: 'local' creates a temporary entry on the function's 
# Activation Record (Stack). Subshells '( )' trigger a fork(), 
# creating an entire copy of the process memory.
```
EOF
                ;;
            13-storage-classes)
cat <<'EOF'
# 🔴 Milestone 13: Storage Classes [SYSTEMS]

### 1. External Visibility
Storage classes determine if a variable stays private to the script memory or is shared with external programs (child processes) like `grep`, `awk`, or other scripts.

```bash
# CONVENTIONAL: Script-local
token="123"                # Child programs cannot see this

# EXPLICIT: Environment Export
export API_KEY="X-99"      # Moves variable to Environment Block

# Logic: Exporting copies the variable from the Bash symbol table 
# into the process's Environment Array, which is passed to the 
# Kernel's execve() call when a child starts.
```

### 2. Lifetime Control
Unlike systems languages with `static` keywords, Bash manages lifetime through process persistence. You can simulate static storage or manage cleanup manually.

```bash
# EXPLICIT: Persistence
# Globals defined outside functions persist for the session.

# EXPLICIT: Manual Cleanup
large_data=$(cat giant.txt)
unset large_data           # Immediate deallocation (free())

# Logic: Bash has no Garbage Collector. It is strictly 
# deterministic. 'unset' triggers an immediate free() call in the 
# underlying C code to release the string buffer.
```
EOF
                ;;
            14-native-strings)
cat <<'EOF'
# 🔵 Milestone 14: Native Strings [PRO]

### 1. High-Speed Slicing
Bash can manipulate strings directly in memory without calling external binaries. This "Pure Bash" approach is orders of magnitude faster because it avoids process forking.

```bash
# CONVENTIONAL: Slow external call
echo "Hello" | cut -c 1-3

# EXPLICIT: Fast Native Slicing
str="Hello World"
echo "${str:0:5}"           # Logic: Start 0, Length 5 -> "Hello"
echo "${str: -5}"           # Logic: Last 5 characters

# Logic: The shell's internal C-engine performs pointer 
# arithmetic on the string buffer to extract slices instantly.
```

### 3. Trims and Strips (Parameter Expansion)
Bash provides surgical tools to "cut" strings from either the start or the end based on patterns.

#### The "Keyboard Position" Rule
- **`#`** (Shift+3) is on the **LEFT**: It removes from the **START** (left).
- **`%`** (Shift+5) is on the **RIGHT**: It removes from the **END** (right).

| Operator | Action | Greediness | Logical Description |
| :--- | :--- | :--- | :--- |
| `${var#pattern}` | Start -> | Shortest | Remove the smallest match from the left. |
| `${var##pattern}`| Start -> | **Longest** | **Greedy**: Remove the largest match from the left. |
| `${var%pattern}` | <- End | Shortest | Remove the smallest match from the right. |
| `${var%%pattern}`| <- End | **Longest** | **Greedy**: Remove the largest match from the right. |

#### Visualizing the "Eat" Direction (`*` as Discard)
The `*` acts as the "garbage" you want to throw away. Its position relative to the delimiter determines the result.

```bash
VAR="APPLE | BANANA | CHERRY"

# 1. DISCARD THE START (#) - * comes BEFORE delimiter
echo "${VAR#*|}"     # Result: " BANANA | CHERRY" (Ate first pipe and left)

# 2. DISCARD THE END (%) - * comes AFTER delimiter
echo "${VAR%|*}"     # Result: "APPLE | BANANA " (Ate last pipe and right)

# 3. GREEDY STRIP (##) - Eat everything to the absolute LAST delimiter
echo "${VAR##*|}"    # Result: " CHERRY" (Ate everything up to last pipe)
```

#### Surgical "Edge" Removal (No Wildcard)
If you omit the `*`, Bash only removes the match if it is at the **absolute tip** (index 0 or last index).

```bash
PATH="/home/user/"
echo "${PATH#/}"     # Result: "home/user/" (Only if it starts with /)
echo "${PATH%/}"     # Result: "/home/user" (Only if it ends with /)

# Logic: Without the *, Bash checks only the boundary character. 
# It will NOT "reach inside" the string.
```

EOF
                ;;
            15-pattern-matching)
cat <<'EOF'
# 🔵 Milestone 15: Pattern Matching [PRO]

### 1. Globbing (The Basics)
Pattern matching checks if a string conforms to a specific "Shape." Globbing is the simplest form, used primarily for file discovery.

```bash
# CONVENTIONAL: Basic wildcards
ls *.txt                    # Match any filename ending in .txt

# EXPLICIT: Extended Globs
shopt -s extglob            # Enable advanced features
if [[ $file == *.@(jpg|png) ]]; then 
    echo "Image found"
fi

# Logic: The shell's Glob Engine scans the directory or string 
# using simple state-machine matching (?, *, [ ]).
```

### 2. Regex (The Heavy Hitter)
For complex validation (like verifying an IP address or email), Bash provides native Regular Expression matching using the same engine as many systems languages.

```bash
# EXPLICIT: Native Regex
input="192.168.1.1"
if [[ $input =~ ^[0-9]{1,3}\.[0-9]{1,3} ]]; then
    echo "Valid prefix"
fi

# Logic: Bash uses the system's regex.h library. Match results 
# for capturing groups are stored in the BASH_REMATCH array.
```

### 3. Native Regex Breakdown (=~)
The `=~` operator allows for direct pattern testing within `[[ ]]`.

#### The Anatomy of `[[ $var =~ ^[0-9]+$ ]]`
- **`^`** (Caret): Start of string anchor.
- **`$`** (Dollar): End of string anchor.
- **`[ ]`** (Brackets): Character class (set of allowed characters).
    - `[0-9]` : Any digit.
    - `[a-z]` : Any lowercase letter.
- **`+`** (Plus): Quantifier - "One or more".
- **`*`** (Asterisk): Quantifier - "Zero or more".
- **`?`** (Question): Quantifier - "Zero or one" (Optional).

| Example | Matches | Logic |
| :--- | :--- | :--- |
| `^[0-9]+$` | "123", "7" | Numeric only, start-to-finish. |
| `^[0-9]$` | "5", "0" | **Exactly one** digit. |
| `^[a-zA-Z]+$`| "Hello" | Alphabetic only. |

**Pro Tip**: Do **not** quote the regex pattern on the right side if you want it to behave as a regex.

EOF
                ;;
            36-class-concept)
cat <<'EOF'
# 🟢 Milestone 36: Class Concept [CORE]

### 1. Dynamic Instances
A Class is a blueprint for objects. In Bash, we simulate this by generating **Unique Associative Arrays** for every "Instance" of the class at runtime.

```bash
# EXPLICIT: The Constructor Pattern
function User.new() {
    local id=$1; local name=$2
    local var_name="user_$id"
    
    declare -g -A "$var_name" # Logic: Create GLOBAL instance
    local -n self="$var_name"
    self[id]=$id; self[name]="$name"
    
    echo "$var_name"          # Return instance HANDLE
}

# Logic: This uses Metaprogramming to inject new entries into 
# the shell's global symbol table dynamically.
```

### 2. Object Access
To use the "Object," you capture its handle and bind it to a local nameref for easy field access.

```bash
# USAGE
handle=$(User.new 42 "Bob")
local -n bob="$handle"
echo "${bob[name]}"         # Logic: Bob
```
EOF
                ;;
            45-io-streams)
cat <<'EOF'
# 🟢 Milestone 45: I/O Streams [CORE]

### 1. The Standard Channels
Every process in Linux starts with three open "Files" (Streams) for communication. Understanding these channels is fundamental to mastering shell interaction.

```bash
# CONVENTIONAL: Implicit usage
echo "Hello"               # Mouth: Writes to stdout (1)
read input                 # Ear: Listens to stdin (0)

# Logic: When a process is spawned, the Kernel populates its 
# File Descriptor Table with pointers to the terminal's 
# keyboard and screen.
```

### 2. Explicit Targeting
To write professional scripts, you must control which stream carries your data. High-signal errors should always be routed to the error stream.

```bash
# EXPLICIT: Target Descriptors
echo "Critical Error!" >&2  # Route to stderr (2)
read -u 0 data              # Explicitly read from stdin (0)

# Logic: Redirection operators (>&) allow you to swap the destination 
# of a process's mouth or ear before the code executes.
```

---
*See also: [Standard I/O Streams](../../OS/Linux/Core/Standard-Streams.md)*

EOF
                ;;
            46-redirection-piping)
cat <<'EOF'
# 🔵 Milestone 46: Redirection & Piping [PRO]

### 1. Stream Rerouting
Redirection is the act of sending a process's mouth (stdout) or megaphone (stderr) to a file instead of the terminal.

```bash
# EXPLICIT: File Output
ls > files.txt              # Overwrite stdout
cat data.txt >> log.txt     # Append stdout
mkdir /tmp 2> errors.log    # Redirect stderr only

# Logic: Bash opens the file and replaces the process's file 
# descriptor 1 or 2 with the new file's descriptor.
```

### 2. Inter-Process Glue
Piping connects the mouth of one program to the ear of another, allowing you to build complex logic from small, specialized tools.

```bash
# EXPLICIT: The Pipe Chain
cat access.log | grep "404" | wc -l

# EXPLICIT: Advanced Redirection
command &> all.log          # Combined stdout/stderr
command > /dev/null 2>&1    # Silence (The "Void")

# Logic: '|' creates a Kernel Buffer (Pipe). The OS connects 
# FD 1 of the left process to the write-end and FD 0 of the right 
# process to the read-end in memory.
```
EOF
                ;;
            47-exit-codes-signals)
cat <<'EOF'
# 🔴 Milestone 47: Exit Codes & Signals [SYSTEMS]

### 1. Process Status
An Exit Code is a number (0-255) a process leaves behind when it dies. It is the final "Last Word" of a program to its parent.

```bash
# EXPLICIT: Returning Status
# exit 0 (Success) | exit 1 (General Error) | exit 127 (Not Found)

# Logic: The CPU register stores the exit status. Bash exposes 
# this value in the special '$?' variable immediately after 
# execution.
```

### 2. System Interruptions
A Signal is a "Tap on the shoulder" from the OS. Bash scripts can intercept these signals to perform cleanup or change behavior.

```bash
# EXPLICIT: Signal Interception
trap "echo 'Cleaning up...'; rm -f /tmp/lock" SIGINT SIGTERM

# Logic: 'trap' modifies the script's entry in the Kernel's 
# Signal Handler Table. When the signal arrives, execution jumps 
# to the defined code block.
```
EOF
                ;;
            49-error-handling)
cat <<'EOF'
# 🟢 Milestone 49: Error Handling [CORE]

### 1. Manual Checks
Error handling is the "Safety Net" of a script. Since Bash has no `try/catch`, you must manually verify the outcome of critical operations.

```bash
# CONVENTIONAL: Status Tracking
cp source.sh backup.sh
if (( $? != 0 )); then
    echo "Error: Backup failed" >&2
    exit 1
fi

# Logic: The exit status register must be checked immediately.
```

### 2. Global Guardrails
For production scripts, use a global "Trap" pattern to handle any unexpected failure without manual checks on every line.

```bash
# EXPLICIT: The Error Trap
set -e                      # Fail-fast mode
trap 'echo "Error on line $LINENO"' ERR

# Logic: The 'ERR' signal is triggered by the shell whenever a 
# command returns non-zero while 'set -e' is active.
```
EOF
                ;;
            expansion-manipulation)
cat <<'EOF'
# 🟢 Bash: Argument Handling & Array Expansion [CORE]

### 1. The Argument Array ($@)
When handling multiple inputs in a function or script, `$@` represents all positional parameters as separate words. Using it inside double quotes `"$@"` is the only safe way to preserve spaces in arguments.

```bash
# CONVENTIONAL: Simple iteration
function list_args() {
    for arg in $@; do
        echo "Arg: $arg"
    done
}

# Logic: Without quotes, an argument like "Hello World" is 
# split into two separate items by the shell's IFS engine.
```

```bash
# EXPLICIT: Safe Expansion
function list_args_safe() {
    for arg in "$@"; do
        echo "Arg: $arg"
    done
}

# USAGE: list_args_safe "A B" "C"
# Logic: "$@" ensures the Kernel sees "A B" as a single 
# pointer in the argument array, preventing word-splitting.
```

### 2. Mass Array Manipulation (${arr[@]})
The `@` symbol is a "Wildcard" for collection indices. It allows you to perform operations on every element of an array simultaneously without a loop.

```bash
# CONVENTIONAL: Loop-based manipulation
files=(data.txt logs.txt)
for f in "${files[@]}"; do
    mv "$f" "${f%.txt}.bak"
done

# Logic: Standard procedural approach to renaming.
```

```bash
# EXPLICIT: Direct Expansion Manipulation
files=(data.txt logs.txt)
echo "${files[@]%.txt}"     # Logic: data logs (removes suffix)
echo "${files[@]^^}"        # Logic: DATA.TXT LOGS.TXT (uppercase)

# Logic: Bash's expansion engine applies the pattern filter 
# to every string pointer in the array buffer before outputting 
# the resulting stream.
```

# The Logic Bridge
// Logic: The `@` expansion works by duplicating the expansion logic for every member of the array. It is fundamentally different from `*` which collapses all members into a single string. In the internal C implementation, `"$@"` is handled by a specialized loop that bypasses the standard string-collapse logic.
EOF
                ;;
            bash)
cat <<'EOF'
Bash is less of a standard programming language and more of a glue language. It operates by passing text streams between discrete tools. To master it, you need to separate **Pure Bash** (built-in syntax and expansion) from **External Commands** (sed, awk, grep).
Here is your comprehensive, compact master reference for Bash, covering the full 53-milestone lifecycle using dense implementation blocks.

### 1. Environment, Ritual & Strictness
Bash is an interpreter. Shebangs and permissions transform text into programs. Strictness flags act as the "Guardrails" to catch logical errors before they cause data loss.
```bash
#!/usr/bin/env bash  # Portable Shebang
# chmod +x script.sh # Grant Permission

set -euo pipefail    # SAFE MODE: Exit on error, unbound vars, and pipe failures
shopt -s inherit_errexit # Bash 4.0+: Pass -e into subshells

# INSTALL: mise use bash@latest | sudo apt install bash
# VERIFY: bash --version | which bash
```

### 2. Lexical Atoms, Charset & Metadata
"Everything is a string." Whitespace is a functional separator. Attributes like `Integer` or `Read-only` are interpretation flags. Locale determines how bytes become characters (UTF-8).
```bash
# LOCALE: export LANG=en_US.UTF-8 (Force UTF-8 interpretation)
# ASSIGNMENT: NO SPACES around '='
user="Alice" 

# TYPE (declare): Keywords vs Built-ins
type if     # Keyword
type cd     # Built-in
type ls     # External binary

# METADATA: Heredoc trick for blocks
: ' 
  DESCRIPTION: Master Script
  VERSION: 1.0.0
'
```

### 3. Variables, Constants & Attributes
Attributes are set in the symbol table to trigger specific shell behaviors. Constants are write-protected entries that cannot be unset or reassigned.
```bash
# ATTRIBUTES
declare -i age=25  # Integer (Triggers math context on assignment)
declare -r PI=3.14 # Read-only (Constant)
declare -l low="A" # Lowercase auto-convert
declare -u up="b"  # Uppercase auto-convert

# STORAGE (SYSTEMS)
export API_KEY="X" # Environment (Shared with children)
# declare -p age    # Inspect attributes
```

### 4. String Mastery & Interpolation
Bash performs high-performance text manipulation in-memory during the Expansion Phase, bypassing expensive external tools like `sed` or `awk`.
```bash
path="/var/log/app.log"

# EXPANSION (Interpolation)
echo "${user:-Guest}" # Fallback if empty
echo "${user:?Error}" # Exit if empty

# STRIPPING (Front/Back)
echo "${path##*/}" # Basename: "app.log" (Longest match front)
echo "${path%.*}"  # No Ext: "/var/log/app" (Shortest match back)

# SLICING & REPLACE
echo "${str:0:5}"      # Substring: offset 0, length 5
echo "${str//log/run}" # Replace ALL instances

# ESCAPING
echo $'Line 1\nLine 2' # ANSI-C Quoting
```

### 5. Scope, Subshells & Contexts
Scope determines visibility. Subshells create isolated process clones. Changes in a subshell cannot travel "backwards" to the parent process.
```bash
# GLOBAL: Default behavior
x=10 

function demo_scope() {
    local x=20 # Scoped to function
}

# ISOLATION (Fork)
( x=30; cd /tmp ) # Runs in child process
echo $x # Still 10
# Current Dir is unchanged
```

### 6. Operations & The Bracket Multiverse
Bash chooses between the Arithmetic Engine `(( ))` and the Logical Test Engine `[[ ]]`. Casting is implicit based on the evaluation context.
```bash
# ARITHMETIC (( )) - C-style math, no $ needed
(( sum = x + (5 * 2), count++ ))

# LOGIC [[ ]] - Modern test context, supports regex
if [[ -f $file && $user == "root" ]]; then :; fi
if [[ $path =~ ^/var/ ]]; then :; fi # Regex Match

# CASTING: Hex string to Int
hex="0x0A"
(( dec = hex )) # dec is now 10
```

### 7. Logical Flow & Truth Rules
Bash uses "Inverted Truth": **0 is Success (True)**. Decision points branch based on the process return status register.
```bash
# TRUTH RULE
# Success (0) is True; Error (1-255) is False
[ -d "/tmp" ] && echo "Exists" || exit 1 # Short-circuit

# CONDITIONALS
case "$1" in 
    (start) ./run ;; 
    (stop)  exit 0 ;; 
    (*)     echo "usage" ;;
esac

# JUMPS: break n (loop level), continue n, return 0 (func), exit 0 (script)
```

### 8. Iteration & File Parsing
Loops iterate over Words (for) or Success (while). Safe file parsing requires clearing the IFS to prevent whitespace trimming.
```bash
# SAFE FILE PARSING (while read)
while IFS= read -r line; do
    echo "$line"
done < "file.txt"

# ARRAY ITERATION (Always quote expansion!)
for item in "${list[@]}"; do
    echo "Item: $item"
done

# DEFINITE: for (( i=0; i<10; i++ )); do :; done
```

### 9. Function Engine & Data Passing
Functions return an **Exit Status**, not data; data is "Returned" via stdout. `nameref` allows pass-by-reference.
```bash
# ENGINE
function get_user() {
    local id=$1 # Positional Param
    local -n ref=$2 # Nameref (Pointer to variable name)
    echo "user_$id" # "Return" data via stdout
    ref="processed" # Modify original variable
    return 0 # Success status
}

# USAGE
my_status="none"
current_user=$(get_user 42 my_status) # Capture stdout, update status
```

### 10. Collections: Arrays & Maps
Grouping data into sequences or key-value hash tables. Bash arrays are sparse linked-lists of strings.
```bash
# INDEXED ARRAY (Sequence)
list=(a b c); list[100]="sparse"

# ASSOCIATIVE ARRAY (Map/Hash)
declare -A user_map=([name]="Bob" [id]=42)

# ACCESS
echo "${list[@]}"      # All values
echo "${!user_map[@]}" # All keys
echo "${#list[@]}"     # Count

# BULK LOAD: mapfile -t arr < file.txt
```

### 11. Architecture: Structs & Simulated OOP
Bash simulates OOP and Structs by dynamically generating uniquely named associative arrays and using namerefs for method dispatch.
```bash
# SIMULATED CONSTRUCTOR
function User.new() {
    local id=$1; local var_name="user_$id"
    declare -g -A "$var_name" # Global instance
    local -n self="$var_name"
    self[id]=$id; self[role]="User"
    echo "$var_name" # Return Handle
}

# METHOD
function User.set_role() {
    local -n self=$1
    self[role]=$2
}

handle=$(User.new 101); User.set_role "$handle" "Admin"
```

### 12. OS Bridge: Streams & Redirection
The "Whole Funda" of process communication. Bash manipulates the process file descriptor table to glue tools together.
```bash
# STREAMS: 0 (stdin), 1 (stdout), 2 (stderr)
echo "Error" >&2  # Write to Stderr
cmd > log 2>&1    # Combine Stdout/Stderr to one file
cmd &> all.log    # Bash shortcut for above

# PIPES & REDIRECTION
cat data | grep "x" # Connect FD 1 of A to FD 0 of B
cmd <<< "string"    # Herestring (stdin)
cmd <<EOM           # Heredoc
multi-line
EOM
```

### 13. Concurrency, Async & Locking
Bash manages the process lifecycle via forks. Locks ensure atomic access to shared system resources.
```bash
# FORK & WAIT
./task.sh & pid=$! # Background (fork)
wait $pid # Block parent until child finishes

# COPROCESS: Two-way pipe (Async)
coproc WORKER { bc; }
echo "10+10" >&"${WORKER[1]}"; read -r res <&"${WORKER[0]}"

# LOCKING (Advisory)
( flock -x 200; echo "Critical Logic" ) 200>/var/lock/mylock
```

### 14. Networking: Raw Streams & APIs
Direct socket communication via the virtual file system. APIs are integrated using the Unix Philosophy (curl + jq).
```bash
# RAW TCP (SYSTEMS)
exec 3<>/dev/tcp/google.com/80
echo -e "GET / HTTP/1.1\n\n" >&3
head -n 1 <&3; exec 3>&- # Close

# API (PRO)
# Uses external tools as "Standard Library"
json=$(curl -s https://api.github.com/users/netchunk)
name=$(echo "$json" | jq -r '.name')
```

### 15. Lifecycle, Memory & Delivery
Project orchestration and maintenance. Memory is managed via unsetting. Delivery often uses self-extracting polyglots.
```bash
# MEMORY: unset var (Immediate free)
# LINTER: shellcheck script.sh (Essential for PRO scripts)

# MULTI-FILE: Relative sourcing
readonly ROOT=$(dirname "$(readlink -f "$0")")
source "$ROOT/lib/core.sh"

# ERROR TRAP
trap 'echo "Error at $LINENO"' ERR
trap 'rm /tmp/lock' EXIT # Signal cleanup
```
EOF
                ;;
            50-multi-file-projects)
cat <<'EOF'
# 🔵 Milestone 50: Multi-File Projects [PRO]

### 1. Project Orchestration
Large scripts are impossible to maintain. Professional architecture separates configuration, libraries, and logic into discrete files.

```bash
# CONVENTIONAL: Relative Sourcing
source "./lib/api.sh"

# Logic: 'source' performs textual inclusion in the current 
# shell context, allowing you to build modular library suites.
```

### 2. Robust Entry Points
To ensure your script finds its dependencies regardless of where it is executed, you must resolve the absolute root path.

```bash
# EXPLICIT: Root Resolution
readonly ROOT_DIR=$(dirname "$(readlink -f "$0")")
source "$ROOT_DIR/config/settings.conf"

# Logic: 'readlink -f' resolves the physical path on the disk, 
# providing a canonical anchor for relative sourcing.
```
EOF
                ;;
            51-build-tools)
cat <<'EOF'
# 🔵 Milestone 51: Build Tools [PRO]

### 1. Quality Control
Since Bash is interpreted, there is no compiler to catch syntax errors. We use "Static Analysis" to find bugs before the script ever runs.

```bash
# EXPLICIT: Linting & Formatting
shellcheck script.sh        # Find logic/syntax bugs
shfmt -i 4 -w script.sh     # Enforce consistent style

# Logic: ShellCheck builds an Abstract Syntax Tree (AST) of the 
# code to identify patterns known to cause security or logic 
# failures.
```

### 2. Deployment
Preparing a script for distribution involves setting correct permissions and placing it in the system path.

```bash
# EXPLICIT: The install tool
sudo install -m 755 app.sh /usr/local/bin/my-app

# Logic: 'install' combines 'cp', 'chmod', and 'chown' into a 
# single atomic operation, ensuring a consistent deployment state.
```
EOF
                ;;
            52-linking-delivery)
cat <<'EOF'
# 🔴 Milestone 52: Linking & Delivery [SYSTEMS]

### 1. Packaging
Linking in Bash often means creating "Fat Scripts" that contain all their own assets (images, binaries, libraries) in a single file.

```bash
# EXPLICIT: Self-Extracting Archive
#!/bin/bash
# ... extraction logic ...
exit 0
__ARCHIVE__
# (Binary data appended here)

# Logic: Bash reads scripts sequentially. By exiting at a 
# marker, we can hide arbitrary bytes at the end of the file.
```

### 2. Delivery Checks
Ensuring the script environment is correct before execution is the final stage of delivery.

```bash
# EXPLICIT: Environment Guard
[[ -z $BASH_VERSION ]] && { echo "Bash required"; exit 1; }

# Logic: This verifies the interpreter environment before 
# triggering complex logic, preventing polyglot-related errors.
```
EOF
                ;;
            53-standard-library)
cat <<'EOF'
# 🔵 Milestone 53: Standard Library [PRO]

### 1. The Built-in Toolbox
Bash doesn't have a single `stdlib` file. Its "Standard Library" is the collection of built-ins and core utilities that are guaranteed to exist on a POSIX-compliant system.

```bash
# CONVENTIONAL: Core Utilities
ls, cp, mv, rm, mkdir      # File Ops
grep, sed, awk, cut, tr    # Text Ops
env, export, set, alias    # Environment Ops

# Logic: These tools are the building blocks of the shell 
# language, providing the "Functional Muscle" for script logic.
```

### 2. Shell Built-ins
Built-ins are commands that live *inside* the Bash binary. They are faster and have direct access to shell memory.

```bash
# EXPLICIT: Using Built-ins
type cd                    # "cd is a shell builtin"
help echo                  # Documentation for built-ins

# Logic: Built-ins run in the shell's memory space, bypassing 
# the Kernel's exec() overhead.
```
EOF
                ;;
            38-process-forking)
cat <<'EOF'
# 🔴 Milestone 38: Process Forking [SYSTEMS]

### 1. Parallel Execution
Forking is the act of the shell creating an identical clone of its current process to run a command without stopping the main script. This allows for parallel background tasks.

```bash
# CONVENTIONAL: Simple backgrounding
./backup_db.sh &            # Logic: Immediate return to prompt
echo "Backup started..."

# Logic: The '&' operator triggers the fork() system call. The 
# child process inherits a copy of the parent's file descriptors 
# and variables.
```

### 2. Job Synchronization
To build reliable scripts, you must track child processes and ensure they finish before the parent script terminates or proceeds to dependent steps.

```bash
# EXPLICIT: Job Tracking
./task1.sh & pid1=$!        # Grab PID of last child

./task2.sh & pid2=$!

wait $pid1 $pid2            # Block until BOTH finish

# Logic: 'wait' pauses the parent shell until a SIGCHLD signal is 
# received from the specific process IDs, ensuring linear 
# reliability in a parallel environment.
```
EOF
                ;;
            39-multi-threading)
cat <<'EOF'
# 🔴 Milestone 39: Multi-Threading [SYSTEMS]

### 1. Parallel Task Spreading
Since Bash is strictly single-threaded, parallelism is achieved by spreading tasks across multiple independent sub-processes. This mimics "Threading" by utilizing multiple CPU cores.

```bash
# CONVENTIONAL: Manual spread
for i in {1..4}; do
    ./worker.sh "$i" &
done
wait

# Logic: This launches 4 separate Bash processes simultaneously. 
# They share no memory but run in parallel.
```

### 2. Managed Thread Pools
For processing large lists, you should use tools that limit the number of active processes to avoid overloading the system scheduler.

```bash
# EXPLICIT: Controlled Parallelism
# Run 4 tasks at a time from a list of 20
printf "%s\n" {1..20} | xargs -n 1 -P 4 ./process.sh

# Logic: 'xargs -P' manages a process queue. It spawns new 
# children only when existing ones finish, maximizing throughput 
# while maintaining system stability.
```
EOF
                ;;
            40-async-coroutines)
cat <<'EOF'
# 🔵 Milestone 40: Async Coroutines [PRO]

### 1. Asynchronous Two-Way Talk
A Co-process (`coproc`) is a background command that stays connected to the main script via two anonymous pipes. This allows the script to send data to and receive results from a persistent worker.

```bash
# EXPLICIT: Starting a Coprocess
coproc WORKER { ./logic_engine.sh; }

# Logic: Bash creates an array '${WORKER[@]}' containing two 
# file descriptors: [1] for writing to the child's stdin and 
# [0] for reading from its stdout.
```

### 2. Stream Interfacing
Communicating with a coprocess requires precise redirection to the specific file descriptors created by the shell.

```bash
# EXPLICIT: Communication Pattern
# 1. Send data
echo "INPUT_DATA" >&"${WORKER[1]}"

# 2. Receive result
read -r result <&"${WORKER[0]}"

# Logic: coproc is a high-level wrapper around the pipe() system 
# call, providing an asynchronous "Service" within your script.
```
EOF
                ;;
            41-synchronization-locks)
cat <<'EOF'
# 🔴 Milestone 41: Synchronization Locks [SYSTEMS]

### 1. Resource Mutual Exclusion
Locks prevent "Race Conditions" when multiple script instances attempt to access the same file or database simultaneously.

```bash
# CONVENTIONAL: Lock Directory (Fragile)
if mkdir /tmp/mylock; then
    # Do work
    rmdir /tmp/mylock
fi

# Logic: If the script crashes, the directory remains, 
# permanently blocking future executions.
```

### 2. Advisory File Locking
The professional way to synchronize is using Kernel-level advisory locks. These are automatically cleaned up by the OS if the process terminates.

```bash
# EXPLICIT: Kernel-level Locking (flock)
(
    flock -x 200            # Wait for EXCLUSIVE lock on FD 200
    echo "Writing to shared resource..."
    sleep 2
) 200>/var/lock/my_app.lock

# Logic: 'flock' uses the system's flock() call. The lock lives 
# in the Kernel's Open File Table, ensuring atomic access even 
# across different users/sessions.
```
EOF
                ;;
            floating-point)
cat <<'EOF'
# 🟢 Bash: Floating Point (The Limitation) [CORE]

### 1. The Integer Boundary
Bash is strictly an Integer-based language. It cannot natively process decimal numbers (floats) in its arithmetic engine.

```bash
# CONVENTIONAL: The Error
# x=$(( 10.5 + 2 ))         # Logic: syntax error: invalid arithmetic operator
```

### 2. The External Bridge (bc)
To perform decimal math, you must hand the data to an external processor like `bc` (Binary Calculator).

```bash
# CONVENTIONAL: Simple division
echo "10 / 3" | bc          # Logic: 3 (Default scale is 0)

# EXPLICIT: Precision Math
val=$(echo "scale=2; 10 / 3" | bc)
echo $val                   # Logic: 3.33

# Logic: Since Bash cannot store the float, the result is 
# captured as a STRING. Any subsequent math must again use 
# an external tool.
```

# The Logic Bridge
// Logic: Bash's internal arithmetic is performed using the `long` type in C. Decimal support was intentionally excluded from the shell's core to keep it lightweight and focused on process management. High-performance scripts should use `awk` or `python` for math-intensive logic.
EOF
                ;;
            null-safety)
cat <<'EOF'
# 🟢 Bash: Null Safety & Default Values [CORE]

### 1. Default Value Substitution
Handling variables that might be empty or unset is critical for script stability.

```bash
# CONVENTIONAL: If-check for empty
if [ -z "$user" ]; then
    user="guest"
fi

# Logic: Procedural check for string length.
```

```bash
# EXPLICIT: Native Null-Coalescing
echo "${user:-guest}"      # Logic: guest (If unset/empty)
echo "${user:=guest}"      # Logic: sets user="guest" if empty

# Logic: The ':' prefix ensures the check applies to BOTH unset 
# variables AND empty strings ("").
```

### 2. Mandatory Variable Checks
Ensuring a variable exists before proceeding to destructive operations.

```bash
# CONVENTIONAL: Manual exit
if [ -z "$TARGET_DIR" ]; then
    echo "Error: TARGET_DIR not set"
    exit 1
fi
rm -rf "$TARGET_DIR"/*

# Logic: Manual verification of state.
```

```bash
# EXPLICIT: Assertion Expansion
rm -rf "${TARGET_DIR:?Error: Var not set}"/*

# Logic: The ':?' syntax triggers a shell-level abortion and 
# prints the message to stderr if the variable is null, 
# preventing accidental 'rm -rf /*' scenarios.
```

# The Logic Bridge
// Logic: Parameter expansion "Coalescing" happens entirely within the shell's parser. It allows for declarative error handling and state initialization, reducing the "Surface Area" for bugs caused by unexpected empty strings.
EOF
                ;;
            parameter-expansion)
cat <<'EOF'
# 🟢 Bash: Parameter Expansion [CORE]

### 1. Simple Variable Access
The standard way to retrieve a variable's value.

```bash
# CONVENTIONAL: Shorthand access
name="Corechunk"
echo $name

# Logic: The '$' triggers a lookup in the local scope hash table.
```

```bash
# EXPLICIT: Braced Expansion
name="Corechunk"
echo "${name}"

# Logic: Braces '{}' define the boundary of the variable name, 
# preventing ambiguity (e.g., "${name}_v2" vs "$name_v2").
```

### 2. Advanced Slicing & Substitution
Parameter expansion allows you to modify the string during the retrieval process without changing the original variable.

```bash
# CONVENTIONAL: External tool (sed/cut)
path="/home/user/file.txt"
filename=$(basename "$path")

# Logic: Spawns a subshell and executes an external binary.
```

```bash
# EXPLICIT: Native String Logic
path="/home/user/file.txt"
echo "${path##*/}"         # Logic: file.txt (Remove longest prefix)
echo "${path%/*}"          # Logic: /home/user (Remove shortest suffix)
echo "${path/user/root}"   # Logic: /home/root/file.txt (Replace)

# Logic: Native expansion is performed inside the shell's memory 
# space, making it thousands of times faster than calling 
# external tools like 'basename' or 'dirname'.
```

# The Logic Bridge
// Logic: Parameter expansion is the most powerful "Native" feature of Bash. It operates directly on the string pointers in the shell's memory, allowing for complex parsing and manipulation without the overhead of process creation.
EOF
                ;;
            48-memory-management)
cat <<'EOF'
# 🔴 Milestone 48: Memory Management [SYSTEMS]

### 1. Variable Cleanup
Bash uses automatic memory management for strings, but in long-running scripts with large data sets, you must manually release memory to avoid system slowdowns.

```bash
# EXPLICIT: Manual free()
large_payload=$(cat giant.txt)
# ... process data ...
unset large_payload         # Immediate deallocation

# Logic: 'unset' triggers a free() call in the underlying C 
# code, releasing the string buffer back to the system allocator.
```

### 2. High-Speed Storage
For tasks requiring zero-latency memory or IPC, use the system's Ramdisk—a part of the disk that actually lives in RAM.

```bash
# EXPLICIT: Ramdisk Usage
echo "temp_data" > /dev/shm/my_app_state

# Logic: /dev/shm is a virtual file system (tmpfs) that maps 
# file operations directly to physical memory addresses, 
# bypassing the physical disk controller.
```
EOF
                ;;
            42-socket-basics)
cat <<'EOF'
# 🔴 Milestone 42: Socket Basics [SYSTEMS]

### 1. Network Streams
Bash can open raw network connections without external tools like `curl`. It uses a virtual path system to map TCP/UDP addresses to standard shell file descriptors.

```bash
# EXPLICIT: Opening a Raw TCP Stream
# Syntax: /dev/tcp/HOST/PORT
exec 3<>/dev/tcp/google.com/80 # Logic: Assign stream to FD 3

# Logic: /dev/tcp is an internal Bash interceptor. It triggers 
# the socket() and connect() system calls during the redirection 
# phase.
```

### 2. Socket Communication
Once a descriptor is bound to a network stream, you can use standard shell built-ins (`echo`, `read`) to interact with the remote server.

```bash
# EXPLICIT: HTTP Request
echo -e "GET / HTTP/1.1\r\nHost: google.com\r\n\r\n" >&3
head -n 1 <&3               # Logic: Read first line of response

# CLEANUP
exec 3>&-                   # Close the descriptor
```
EOF
                ;;
            43-tcp-udp-patterns)
cat <<'EOF'
# 🔴 Milestone 43: TCP/UDP Patterns [SYSTEMS]

### 1. Reliable Streams (TCP)
TCP is a connection-oriented protocol that ensures every byte arrives in order. In Bash, this is used for reliable data transfers or simple HTTP interaction.

```bash
# EXPLICIT: TCP Send & Receive
{
    echo "MSG" >&3          # Write
    read -r resp <&3        # Read
} 3<>/dev/tcp/localhost/1234

# Logic: TCP uses a 3-way handshake to establish a persistent 
# virtual circuit in the Kernel's network stack.
```

### 2. Fast Datagrams (UDP)
UDP is a "Fire and Forget" protocol. It is faster than TCP but does not guarantee delivery. In Bash, this is ideal for high-speed logging or DNS queries.

```bash
# EXPLICIT: UDP Fire-and-Forget
echo "<14>System Alert" >/dev/udp/syslog.local/514

# Logic: UDP creates a socket (SOCK_DGRAM) and sends a packet 
# directly to the destination IP without waiting for an 
# acknowledgment.
```
EOF
                ;;
            44-http-client-api)
cat <<'EOF'
# 🔵 Milestone 44: HTTP Client API [PRO]

### 1. The Standard Interface
Bash has no native HTTP engine. It relies on the **Unix Philosophy** of piping data between specialized tools. `curl` is the industry-standard "HTTP Library" for the shell.

```bash
# CONVENTIONAL: Data Fetch
curl -s https://api.github.com/zen

# Logic: curl handles the complex HTTP protocol (TLS, headers, 
# redirects) and returns a raw text stream to the shell.
```

### 2. API Integration
Modern web APIs return JSON data. In Bash, professional integration requires a combination of `curl` for transport and `jq` for data structure parsing.

```bash
# EXPLICIT: JSON API Parsing
response=$(curl -s "https://api.github.com/users/netchunk")
name=$(echo "$response" | jq -r '.name')

# Logic: The shell acts as the "Glue," piping the bytes from the 
# network tool into the structured-data tool to achieve 
# high-level programming goals.
```
EOF
                ;;
            37-advanced-oop)
cat <<'EOF'
# 🔵 Milestone 37: Advanced OOP [PRO]

### 1. Data Encapsulation
Encapsulation involves hiding internal state from the user. In Bash, this is achieved by convention and by restricting access through specialized "Method" functions.

```bash
# EXPLICIT: Private Convention
# Use '__' prefix for internal fields
declare -A User=( [__db_id]="12345" [name]="Alice" )

# Logic: Since Bash has no true private scope, encapsulation is 
# enforced by the programmer's discipline and naming rules.
```

### 2. Method Dispatch
Methods are functions that act specifically on an object instance. We use **Namespace Prefixing** to associate logic with a simulated class.

```bash
# EXPLICIT: Class Method
function User.set_role() {
    local -n self=$1         # The 'this' pointer
    local new_role=$2
    self[role]="$new_role"
}

# CALLING
User.set_role "user_42" "Admin"

# Logic: Namespace prefixing (User.xxx) prevents collision in the 
# global function table and mimics the 'dot notation' of 
# systems languages.
```
EOF
                ;;
            bitwise)
cat <<'EOF'
# 🟢 Bash: Bitwise Operators [CORE]

### 1. Shift & Mask
Bitwise operations allow you to manipulate data at the bit level inside an arithmetic context `$(( ))`.

```bash
# CONVENTIONAL: Left/Right Shift
x=1
echo $(( x << 2 ))          # Logic: 4 (0001 -> 0100)
echo $(( 8 >> 1 ))          # Logic: 4 (1000 -> 0100)

# Logic: Shifts work on 64-bit signed integers in modern Bash.
```

```bash
# EXPLICIT: Bitwise Logic (AND/OR/XOR/INV)
mask=0x0F
val=0xFF

echo $(( val & mask ))      # Logic: 15 (0x0F)
echo $(( 1 | 2 ))           # Logic: 3
echo $(( 5 ^ 3 ))           # Logic: 6
echo $(( ~1 ))              # Logic: -2 (Two's complement)

# Logic: Bash performs bitwise operations directly on the CPU's 
# integer registers, making it the most efficient way to handle 
# flags and low-level data filters.
```

# The Logic Bridge
// Logic: Bitwise operators in Bash are inherited from C. They operate on the underlying bit representation of the long integer stored in memory. Note that Bash only supports bitwise operations on integers; strings must be converted or interpreted in an arithmetic context first.
EOF
                ;;
            overview-v2)
cat <<'EOF'
# 🧭 Bash Wiki: Tiered Learning (v2)

This roadmap groups the 53 universal language topics by **Mastery Tier**. Use this to focus on the Foundation, Idiomatic Power, or Systems Internals.

---

## 🟢 Tier 1: The Foundation [CORE]
*The non-skippable essentials. Master these to write functional, correct code.*

### Environment & Setup
- [01-toolchain-installation.md](./setup/01-toolchain-installation.md) (Installation, `mise`, PATH)
- [02-compilation-run-basics.md](./setup/02-compilation-run-basics.md) (Execution ritual, Shebangs)

### Lexical & Data
- [04-tokens-lexemes.md](./04-tokens-lexemes.md) (Atoms of the language, Whitespace)
- [05-keywords-standards.md](./05-keywords-standards.md) (Keywords vs Built-ins)
- [07-comments-metadata.md](./07-comments-metadata.md) (Doc-strings, Metadata)
- [08-variables-constants.md](./08-variables-constants.md) (Declaration, `readonly`)
- [09-data-types.md](./09-data-types.md) (String model, `declare -i`)
    - [Parameter Expansion](./data-type/parameter-expansion.md)
    - [Null Safety & Defaults](./data-type/null-safety.md)
    - [Floating Point Limits](./data-type/floating-point.md)
- [10-string-escaping.md](./10-string-escaping.md)
- [11-interpolation.md](./11-interpolation.md) (Variable Substitution)
- [12-scope-lifetime.md](./12-scope-lifetime.md) (Global, `local`)

### Logic & Control
- [17-operators.md](./17-operators.md)
    - [Bitwise Operators](./operator/bitwise.md)
- [18-precedence-associativity.md](./18-precedence-associativity.md)
- [19-expressions-statements.md](./19-expressions-statements.md) (Exit statuses)
- [21-type-casting.md](./21-type-casting.md) (Contextual evaluation)
- [22-truth-rule.md](./22-truth-rule.md) (0 = Success)
- [23-conditionals.md](./23-conditionals.md) (`if`, `case`)
- [24-iteration-definite.md](./24-iteration-definite.md) (For loops)
- [25-iteration-indefinite.md](./25-iteration-indefinite.md) (While, Until)

### The Function Engine
- [27-function-basics.md](./27-function-basics.md)
    - [Argument Array ($@)](./array/expansion-manipulation.md)
- [28-return-types.md](./28-return-types.md) (Exit codes, Stdout)
- [29-recursion.md](./29-recursion.md)
- [30-passing-mechanisms.md](./30-passing-mechanisms.md) (Positional params, Namerefs)

### Architecture & Environment
- [32-sequential-collections.md](./32-sequential-collections.md) (Indexed Arrays)
    - [Expansion & Manipulation](./array/expansion-manipulation.md)
- [33-associative-collections.md](./33-associative-collections.md) (Hashmaps)

- [34-structs-base.md](./34-structs-base.md) (Simulated via Associative Arrays)
- [36-class-concept.md](./36-class-concept.md) (Namerefs + Associative Arrays)
- [45-io-streams.md](./45-io-streams.md) (0, 1, 2)
- [49-error-handling.md](./49-error-handling.md) (`set -e`, `trap ERR`)

---

## 🔵 Tier 2: Idiomatic Power [PRO]
*Native techniques and efficiency. Master these to write "Professional" code.*

### Efficiency & Native Power
- [06-tuning-strictness.md](./06-tuning-strictness.md) (Safe Mode flags)
- [14-native-strings.md](./14-native-strings.md) (Parameter Expansion slicing)
- [15-pattern-matching.md](./15-pattern-matching.md) (Regex, Globbing)
- [20-command-substitution.md](./20-command-substitution.md) (`$( )`)
- [26-jump-statements.md](./26-jump-statements.md) (Break, Continue)
- [31-closures-lambdas.md](./31-closures-lambdas.md)

### Advanced Redirections
- [35-procedural-mechanisms.md](./procedural/35-procedural-mechanisms.md) **[START FILE]**
    - Modular scripts, `source`.
- [37-advanced-oop.md](./oop/37-advanced-oop.md) **[START FILE]**
    - Encapsulation, Dynamic Dispatch.
- [40-async-coroutines.md](./concurrency/40-async-coroutines.md) (`coproc`)
- [44-http-client-api.md](./network/44-http-client-api.md) (`curl`, `wget`)
- [46-redirection-piping.md](./46-redirection-piping.md) (Pipes, Heredocs)

### Project Lifecycle & Build
- [50-multi-file-projects.md](./build/50-multi-file-projects.md)
- [51-build-tools.md](./build/51-build-tools.md) (Shellcheck)
- [53-standard-library.md](./build/53-standard-library.md) (Coreutils)

---

## 🔴 Tier 3: Advanced Internals [SYSTEMS]
*The engine and the OS. Master these to build systems, compilers, or drivers.*

### Internals & Memory
- [03-charset.md](./03-charset.md) (UTF-8, Locale)
- [13-storage-classes.md](./13-storage-classes.md) (Env variables)
- [16-syntactic-automation.md](./16-syntactic-automation.md) (Aliases)
- [48-memory-management.md](./memory/48-memory-management.md) **[START FILE]**
    - Unset, Ramdisk logic.
- [05-pointer-mastery.md](./30-passing-mechanisms.md) (Namerefs / `declare -n`)
- [47-exit-codes-signals.md](./47-exit-codes-signals.md) (`trap`, `kill`)

### Low-Level Concurrency
- [38-process-forking.md](./concurrency/38-process-forking.md) (Backgrounding)
- [39-multi-threading.md](./concurrency/39-multi-threading.md) (GNU Parallel)
- [41-synchronization-locks.md](./concurrency/41-synchronization-locks.md) (`flock`)

### Low-Level Networking
- [42-socket-basics.md](./network/42-socket-basics.md) (`/dev/tcp`)
- [43-tcp-udp-patterns.md](./network/43-tcp-udp-patterns.md) (Raw streams)

### Toolchain Lifecycle
- [52-linking-delivery.md](./build/52-linking-delivery.md)
    - Self-contained scripts.
EOF
                ;;
            overview)
cat <<'EOF'
# 🧭 Bash Wiki: The Full Picture

This is the **Chronological Path**. Topics are ordered by the natural learning progression, with status tags to indicate their level.

---

## 🗺️ The Roadmap

### Phase 1: Environment & Setup
1. [01-toolchain-installation.md](./setup/01-toolchain-installation.md) **[CORE]** (OS-specific setup, `mise`, PATH)
2. [02-compilation-run-basics.md](./setup/02-compilation-run-basics.md) **[CORE]** (Execution ritual, Shebangs)

### Phase 2: Lexical Foundations
3. [03-charset.md](./03-charset.md) **[SYSTEMS]** (UTF-8, Locale, LANG)
4. [04-tokens-lexemes.md](./04-tokens-lexemes.md) **[CORE]** (Atoms of the language, Whitespace)
5. [05-keywords-standards.md](./05-keywords-standards.md) **[CORE]** (Keywords vs Built-ins vs Externals)
6. [06-tuning-strictness.md](./06-tuning-strictness.md) **[PRO]** (Safe Mode: `set -euo pipefail`)
7. [07-comments-metadata.md](./07-comments-metadata.md) **[CORE]** (Doc-strings, Metadata)

### Phase 3: Primitive Data
8. [08-variables-constants.md](./08-variables-constants.md) **[CORE]** (Declaration, `readonly`)
9. [09-data-types.md](./09-data-types.md) **[CORE]** (String model, `declare -i`)
    - [Parameter Expansion](./data-type/parameter-expansion.md)
    - [Null Safety & Defaults](./data-type/null-safety.md)
    - [Floating Point Limits](./data-type/floating-point.md)
10. [10-string-escaping.md](./10-string-escaping.md) **[CORE]** (Escape sequences, `echo -e`)
11. [11-interpolation.md](./11-interpolation.md) **[CORE]** (Variable Substitution, Defaults)
12. [12-scope-lifetime.md](./12-scope-lifetime.md) **[CORE]** (`local`, `export`, Subshells)
13. [13-storage-classes.md](./13-storage-classes.md) **[SYSTEMS]** (Env variables, Static simulation)

### Phase 4: Native Power (Efficiency)
14. [14-native-strings.md](./14-native-strings.md) **[PRO]** (Parameter Expansion, Slicing)
15. [15-pattern-matching.md](./15-pattern-matching.md) **[PRO]** (Globbing, Regex `=~`)
16. [16-syntactic-automation.md](./16-syntactic-automation.md) **[SYSTEMS]** (Aliases, Functions)

### Phase 5: Operations & Logic
17. [17-operators.md](./17-operators.md) **[CORE]** (Math, Logic, Bitwise)
    - [Bitwise Operators](./operator/bitwise.md)
18. [18-precedence-associativity.md](./18-precedence-associativity.md) **[CORE]** (Order of operations)
19. [19-expressions-statements.md](./19-expressions-statements.md) **[CORE]** (Exit statuses)
20. [20-command-substitution.md](./20-command-substitution.md) **[PRO]** (Capturing output `$( )`)
21. [21-type-casting.md](./21-type-casting.md) **[CORE]** (Contextual interpretation)

### Phase 6: Control Flow
22. [22-truth-rule.md](./22-truth-rule.md) **[CORE]** (0 = Success)
23. [23-conditionals.md](./23-conditionals.md) **[CORE]** (`if`, `case`)
24. [24-iteration-definite.md](./24-iteration-definite.md) **[CORE]** (`for` loops)
25. [25-iteration-indefinite.md](./25-iteration-indefinite.md) **[CORE]** (`while`, `until`)
26. [26-jump-statements.md](./26-jump-statements.md) **[PRO]** (`break`, `continue`, `exit`)

### Phase 7: The Function Engine
27. [27-function-basics.md](./27-function-basics.md) **[CORE]** (Declaration, `local`)
    - [Argument Array ($@)](./array/expansion-manipulation.md)
28. [28-return-types.md](./28-return-types.md) **[CORE]** (Exit status, capturing stdout)
29. [29-recursion.md](./29-recursion.md) **[CORE]** (Call limits, `BASHPID`)
30. [30-passing-mechanisms.md](./30-passing-mechanisms.md) **[CORE]** (Positional parameters, `nameref`)
31. [31-closures-lambdas.md](./31-closures-lambdas.md) **[PRO]** (Dynamic function simulation)

### Phase 8: Procedural Architecture
32. [32-sequential-collections.md](./32-sequential-collections.md) **[CORE]** (Indexed Arrays)
    - [Expansion & Manipulation](./array/expansion-manipulation.md)
33. [33-associative-collections.md](./33-associative-collections.md) **[CORE]** (Hashmaps `declare -A`)
34. [34-structs-base.md](./34-structs-base.md) **[CORE]** (Simulated via Associative Arrays)
35. [35-procedural-mechanisms.md](./procedural/35-procedural-mechanisms.md) **[PRO]** (Modular scripts, `source`)

### Phase 9: Object-Oriented Programming
36. [36-class-concept.md](./36-class-concept.md) **[CORE]** (Namerefs + Associative Arrays)
37. [37-advanced-oop.md](./oop/37-advanced-oop.md) **[PRO]** (Encapsulation, Dynamic Dispatch)

### Phase 10: Concurrency & Async
38. [38-process-forking.md](./concurrency/38-process-forking.md) **[SYSTEMS]** (Backgrounding `&`, `wait`)
39. [39-multi-threading.md](./concurrency/39-multi-threading.md) **[SYSTEMS]** (GNU Parallel, Background jobs)
40. [40-async-coroutines.md](./concurrency/40-async-coroutines.md) **[PRO]** (`coproc`)
41. [41-synchronization-locks.md](./concurrency/41-synchronization-locks.md) **[SYSTEMS]** (`flock`, Lock files)

### Phase 11: Network Handling
42. [42-socket-basics.md](./network/42-socket-basics.md) **[SYSTEMS]** (`/dev/tcp`, `/dev/udp`)
43. [43-tcp-udp-patterns.md](./network/43-tcp-udp-patterns.md) **[SYSTEMS]** (Raw streams)
44. [44-http-client-api.md](./network/44-http-client-api.md) **[PRO]** (`curl`, `wget`)

### Phase 12: OS Bridge & Memory
45. [45-io-streams.md](./45-io-streams.md) **[CORE]** (0, 1, 2)
46. [46-redirection-piping.md](./46-redirection-piping.md) **[PRO]** (Redirection, Pipes, Heredocs)
47. [47-exit-codes-signals.md](./47-exit-codes-signals.md) **[SYSTEMS]** (`trap`, `kill`, SIGINT)
48. [48-memory-management.md](./memory/48-memory-management.md) **[SYSTEMS]** (`unset`, Ramdisk logic)
49. [49-error-handling.md](./49-error-handling.md) **[CORE]** (`trap ERR`, `set -e`)

### Phase 13: Project Lifecycle & Build
50. [50-multi-file-projects.md](./build/50-multi-file-projects.md) **[PRO]** (Source orchestration)
51. [51-build-tools.md](./build/51-build-tools.md) **[PRO]** (Shellcheck, `install`)
52. [52-linking-delivery.md](./build/52-linking-delivery.md) **[SYSTEMS]** (Self-contained scripts)
53. [53-standard-library.md](./build/53-standard-library.md) **[PRO]** (Coreutils, Built-ins)


---

## 🏷️ Tier Definitions
- **[CORE]**: Fundamental logic. Essential for beginners.
- **[PRO]**: Native power and idiomatic efficiency.
- **[SYSTEMS]**: Low-level internals and OS integration.
EOF
                ;;
            35-procedural-mechanisms)
cat <<'EOF'
# 🔵 Milestone 35: Procedural Mechanisms [PRO]

### 1. Modular Scripts
Modularity is the act of splitting logic into specialized files (libraries). In Bash, the `source` command is the primary mechanism for procedural orchestration.

```bash
# CONVENTIONAL: Execution
./lib/utils.sh              # Logic: Runs in child process (NO sharing)

# EXPLICIT: Textual Inclusion (Import)
source "./lib/utils.sh"      # Logic: Runs in CURRENT process (Shares all)

# Logic: 'source' (or '.') tells the Bash parser to open the 
# target file and interpret its content as if it were typed 
# directly into the current line.
```

### 2. Reliable Discovery
To ensure your script can find its libraries regardless of where it is called from, you must resolve the absolute path of the script's origin.

```bash
# EXPLICIT: Relative Orchestration
readonly LIB_DIR="$(dirname "$(readlink -f "$0")")/lib"
source "${LIB_DIR}/core.sh"

# Logic: 'readlink -f' resolves symlinks and relative paths to 
# a canonical absolute path on the disk.
```
EOF
                ;;
            01-toolchain-installation)
cat <<'EOF'
# 🟢 Milestone 01: Toolchain Installation [CORE]

### 1. The Shell Interpreter
Bash (Bourne Again SHell) is an interpreter that acts as both a command language and a programming language. Unlike compiled languages, the "Toolchain" is simply the `bash` binary itself, which reads and executes scripts line-by-line.

```bash
# CONVENTIONAL: System-native installation
sudo apt install bash      # Linux (Debian/Ubuntu)
sudo pacman -S bash        # Linux (Arch)
brew install bash          # macOS (Latest v5+)

# WINDOWS: The Git Bash way
# Download "Git for Windows" from git-scm.com.
# It includes a MinGW-based Bash environment.

# Logic: The shell binary is loaded into memory by the Kernel 
# to process text streams as functional instructions.
```

### 2. Version Management
Because Bash evolves (e.g., Bash 4.0 added associative arrays), managing specific versions is critical for script portability and consistency across environments.

```bash
# EXPLICIT: Manage versions via 'mise'
mise use bash@latest       # Set local/global version

# VERIFICATION
which bash                 # Locate binary path in PATH
bash --version             # Confirm exact version string

# Logic: The OS looks through the PATH variable to find the first 
# executable named 'bash'. Version managers like mise manipulate 
# this PATH to point to your desired version.
```
EOF
                ;;
            02-compilation-run-basics)
cat <<'EOF'
# 🟢 Milestone 02: Execution Ritual [CORE]

### 1. Basic Invocation
Execution is the act of telling the Operating System to hand your text file to the `bash` interpreter. Since scripts are just text, you can call the interpreter and pass the file name as a "payload."

```bash
# CONVENTIONAL: Run as an argument (No permissions needed)
bash my_script.sh

# Logic: This bypasses the Shebang and uses the 'bash' binary 
# currently in your focus to read the text file.
```

### 2. First-Class Executables
To make a script act like a "Real" program, you must tell the OS which interpreter to use and grant the file "Execution" permission bits.

```bash
# EXPLICIT: The Shebang (Line 1 of the file)
#!/usr/bin/env bash        # Portable path via 'env'

# EXPLICIT: Granting Permissions
# chmod +x my_script.sh    # Add the 'x' bit to the file metadata

# EXECUTION
./my_script.sh             # Execute directly as a command

# Logic: The Kernel reads the first two bytes (#!). If they match, 
# it treats the rest of the line as the path to the loader (bash) 
# and hands it the file.
```
EOF
                ;;
            17-operators)
cat <<'EOF'
# 🟢 Milestone 17: Operators [CORE]

### 1. The Engine Choice
Operators are the symbols that perform actions on data. In Bash, you must choose the right "Evaluation Engine" based on the data type.

```bash
# CONVENTIONAL: String comparison
if [[ $a == $b ]]; then :; fi

# Logic: [[ ]] triggers the shell's Logical Test Engine, which 
# treats operands as strings unless a specific operator 
# (like -eq) is used.
```

### 2. Specialized Operators
Bash provides two distinct sets of operators: one for C-style math and one for high-level logical tests.

```bash
# EXPLICIT: Arithmetic Operators (Inside (( )))
# Math: +, -, *, /, % | Bitwise: <<, >>, &, |, ^
(( res = (5 + 2) << 1 ))    # Logic: 7 shifted left -> 14

# EXPLICIT: Logical/File Operators (Inside [[ ]])
# Logic: &&, ||, ! | File: -f (file), -d (dir), -z (empty)
if [[ -f "/etc/passwd" && ! -z $USER ]]; then :; fi

# Logic: Arithmetic operators work on binary representations. 
# Logical operators work on string attributes and file metadata.
```

## Deep-Dive Reference
For low-level bit manipulation and math:
- [Bitwise Operators](./operator/bitwise.md)
EOF
                ;;
            18-precedence-associativity)
cat <<'EOF'
# 🟢 Milestone 18: Precedence & Associativity [CORE]

### 1. Evaluation Order
When an expression contains multiple operators, Precedence determines which action happens first. Bash follows standard C-style precedence rules, but relying on defaults is an anti-pattern.

```bash
# CONVENTIONAL: Linear arithmetic
(( res = 5 + 2 * 3 ))       # Logic: 2*3 happens first -> 11

# EXPLICIT: Forced Priority
(( res = (5 + 2) * 3 ))     # Logic: Addition happens first -> 21

# Logic: The Bash parser builds an Abstract Syntax Tree (AST). 
# Multiplication nodes are placed deeper in the tree than 
# addition nodes, ensuring they are evaluated first.
```

### 2. Logical Precedence
In test contexts, the order of `&&` (AND) and `||` (OR) is critical for short-circuiting logic and error handling.

```bash
# EXPLICIT: Grouped Logic
[[ ($a == "1" || $b == "2") && $c == "3" ]]

# Logic: Parentheses force the parser to evaluate the OR block 
# as a single atomic status before checking the AND condition.
```
EOF
                ;;
            19-expressions-statements)
cat <<'EOF'
# 🟢 Milestone 19: Expressions vs Statements [CORE]

### 1. Functional Actions (Statements)
A Statement is a command that performs an action (e.g., creating a directory). In Bash, every statement results in a status code in the CPU's register.

```bash
# CONVENTIONAL: Simple action
mkdir "/tmp/backup"

# Logic: The command executes and populates the '$?' variable 
# with the success/failure code from the Kernel.
```

### 2. Evaluative Logic (Expressions)
An Expression is logic that produces a boolean-like result. In Bash, expressions are often used to decide whether to execute a following statement via "Short-circuiting."

```bash
# EXPLICIT: Logical Chain
[[ -d "/tmp" ]] && echo "Exists" || exit 1

# Logic: Bash treats '&&' and '||' as flow control. It only 
# executes the next statement if the current status matches the 
# operator's requirement (0 for &&, non-zero for ||).
```
EOF
                ;;
            20-command-substitution)
cat <<'EOF'
# 🔵 Milestone 20: Command Substitution [PRO]

### 1. Output Capture
Command substitution is the act of running a program and capturing its text output into a variable. This is the primary way Bash scripts process data from external tools.

```bash
# CONVENTIONAL: Captured status
now=$(date)
echo "Current time is $now"

# Logic: Bash forks a subshell, connects its stdout to a pipe, 
# and reads the data into the parent's memory buffer.
```

### 2. Nesting & Performance
Modern Bash allows for nested substitutions, providing a way to build complex data structures from multiple command outputs in a single line.

```bash
# EXPLICIT: Nested Capture
# 1. List files 2. Count them 3. Prepend metadata
info="Count: $(ls -1 | wc -l) (at $(date +%H:%M))"

# Logic: Nesting triggers multiple forks. Each internal $( ) 
# must complete and pass its bytes to the enclosing expansion 
# engine before the final command is constructed.
```
EOF
                ;;
            21-type-casting)
cat <<'EOF'
# 🟢 Milestone 21: Type Casting [CORE]

### 1. Contextual Interpretation
Bash does not have a "cast" keyword. Instead, it uses **Contextual Interpretation**: a string "becomes" a number only when you place it inside a context that *expects* a number.

```bash
# CONVENTIONAL: String-to-Int
num="10"
res=$(( num + 5 ))          # Logic: Interpreted as 10 + 5

# Logic: The Arithmetic Engine performs a Lexical Scan. If the 
# string looks like a number (Dec/Hex/Oct), it is converted to 
# a 64-bit integer for the calculation.
```

### 2. Explicit Formatting
To "Cast" data for output (e.g., converting a number to a hex string), use the `printf` built-in, which mimics the systems-level C function of the same name.

```bash
# EXPLICIT: Format Casting
val=10
hex_str=$(printf "0x%X" $val) # Logic: Casts 10 to 0xA

# Logic: printf reads the internal integer representation and 
# maps it to a new string format based on the provided specifier.
```
EOF
                ;;
            22-truth-rule)
cat <<'EOF'
# 🟢 Milestone 22: Truth Rule [CORE]

### 1. Inverted Boolean Logic
In most programming languages, `1` is True and `0` is False. In Bash, the logic is **Exactly Inverted**. Bash cares about process outcomes, not boolean literals.

```bash
# SUCCESS (True)
# A return code of 0 means "Success" or "No Errors".

# FAILURE (False)
# Any return code from 1 to 255 means "Error".

# Logic: Bash flow control keywords (if, while) execute a 
# command and look at the CPU's Status Register. A zero in the 
# register triggers the "True" branch.
```

### 2. Manual Verification
You can inspect the success or failure of the last executed command using the special `$?` variable. This is the "Manual" way to verify logic.

```bash
# EXPLICIT: Status Inspection
grep -q "pattern" file.txt
status=$?

if (( status == 0 )); then
    echo "Pattern Found (Success/True)"
fi

# Logic: $? is a temporary placeholder that is overwritten by 
# every single command execution. Always capture it immediately.
```
EOF
                ;;
            23-conditionals)
cat <<'EOF'
# 🟢 Milestone 23: Conditionals [CORE]

### 1. Simple Branching (if)
Conditionals are decision points that direct execution based on command success. The `if` statement is the primary tool for binary (Yes/No) logic.

```bash
# CONVENTIONAL: File check
if [[ -f "config.sh" ]]; then
    source "config.sh"
fi

# Logic: 'if' executes the [[ ]] keyword. If [[ ]] returns 0 
# (success), the 'then' block is executed.
```

### 2. Pattern Branching (case)
The `case` statement is the "Switch" equivalent in Bash. It is optimized for matching a single string against multiple patterns (globbing), making it significantly cleaner than nested `elif` blocks.

```bash
# EXPLICIT: Multi-branch Match
case "$1" in
    start|run)
        ./app --daemon
        ;;
    stop)
        kill $(cat pid.file)
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

# Logic: 'case' uses a jump-table logic internally. It performs 
# a Lexical Match of the input string against each pattern until 
# it finds a success or hits the '*' default.
```
EOF
                ;;
            24-iteration-definite)
cat <<'EOF'
# 🟢 Milestone 24: Iteration - Definite [CORE]

### 1. List Iteration
A Definite loop runs a specific number of times based on a provided list of items. In Bash, `for` loops iterate over **Words** separated by whitespace.

```bash
# CONVENTIONAL: Literal list
for fruit in apple banana cherry; do
    echo "I like $fruit"
done

# Logic: The expansion engine replaces 'apple banana cherry' with 
# three separate tokens before the loop begins.
```

### 2. Structured Iteration
For arrays or numeric ranges, you must use specific expansion rules or C-style syntax to avoid word-splitting bugs and ensure precise control.

```bash
# EXPLICIT: Array Iteration (Safe)
declare -a list=("Item 1" "Item 2")
for item in "${list[@]}"; do    # Logic: Always quote for safety
    echo "Processing $item"
done

# EXPLICIT: C-Style Numeric Loop
for (( i=0; i<10; i++ )); do
    echo "Count: $i"
done

# Logic: "${arr[@]}" expands to a set of perfectly isolated 
# strings. C-style loops use the arithmetic engine for counting.
```
EOF
                ;;
            25-iteration-indefinite)
cat <<'EOF'
# 🟢 Milestone 25: Iteration - Indefinite [CORE]

### 1. Success-Based Loops
An Indefinite loop runs as long as a command succeeds (`while`) or fails (`until`). This is primarily used for monitoring processes or reading continuous data streams.

```bash
# CONVENTIONAL: Variable check
while [[ $ans != "y" ]]; do
    read -p "Continue? [y/n] " ans
done

# Logic: The loop executes the [[ ]] test before every turn. If 
# it returns non-zero, the loop terminates immediately.
```

### 2. Stream Processing
The "Golden Standard" for processing files or command output line-by-line is the `while read` loop. It is safer and more memory-efficient than `for` loops on file contents.

```bash
# EXPLICIT: Safe File Reading
while IFS= read -r line; do
    echo "Line: $line"
done < "data.txt"

# Logic: 'read' returns success (0) for every line read and 
# failure (non-zero) when it hits EOF (End of File), providing 
# a natural termination for the loop.
```
EOF
                ;;
            26-jump-statements)
cat <<'EOF'
# 🔵 Milestone 26: Jump Statements [PRO]

### 1. Loop Control
Jump statements redirect the flow of execution within loops. They allow you to skip iterations or break out of nested structures when a specific condition is met.

```bash
# EXPLICIT: Skip & Terminate
for i in {1..10}; do
    if (( i % 2 == 0 )); then continue; fi # Skip evens
    if (( i > 7 )); then break; fi          # Stop at 7
    echo "Odd: $i"
done

# Logic: 'continue' jumps back to the loop header; 'break' jumps 
# to the memory address immediately following the 'done' keyword.
```

### 2. Script Termination
To stop execution of a function or the entire script, Bash provides `return` and `exit`. These pass a status code back to the parent environment.

```bash
# EXPLICIT: Global Exit
if [[ -z $API_KEY ]]; then
    echo "Error: Missing key" >&2
    exit 1 # Terminate entire process with error status
fi

# Logic: 'exit' triggers the Kernel's _exit() call, passing the 
# argument to the parent process's Wait Status register.
```
EOF
                ;;
            27-function-basics)
cat <<'EOF'
# 🟢 Milestone 27: Function Basics [CORE]

### 1. Reusable Logic
A function is a named block of code that acts like a miniature script residing in the current shell's memory. Functions allow you to modularize logic without spawning new processes.

```bash
# CONVENTIONAL: Standard syntax
greet() {
    echo "Hello $1"
}

# Logic: Functions must be defined BEFORE they are called. 
# They are stored in the shell's Global Function Table.
```

### 2. Scoped Execution
To write professional-tier scripts, functions should be self-contained and descriptive. The `function` keyword is preferred for readability in large projects.

```bash
# EXPLICIT: Modern syntax & Safety
function greet_user() {
    local name="$1"         # Scope isolation
    echo "Hello $name"
}

# Logic: 'local' creates a temporary entry on the function's 
# Activation Record (Stack), which is automatically popped 
# (destroyed) when the function returns.
```

## Deep-Dive Reference
For advanced argument handling and array expansion:
- [Argument Array ($@)](./array/expansion-manipulation.md)
EOF
                ;;
            28-return-types)
cat <<'EOF'
# 🟢 Milestone 28: Return Types [CORE]

### 1. Status Returns
Bash functions **cannot return data** (like strings or objects) directly. They can only return an **Exit Status** (a number from 0 to 255).

```bash
# EXPLICIT: Success/Failure Logic
function is_active() {
    [[ $STATUS == "RUNNING" ]] && return 0 || return 1
}

# Logic: The 'return' keyword only populates the shell's 
# internal '$?' variable for immediate logical checking.
```

### 2. Data "Returns" (Stdout)
To "Return" text or data structures, you must print them to the standard output and capture that stream using command substitution.

```bash
# EXPLICIT: Data Return Pattern
function get_config_val() {
    echo "api_v1_live"      # Result printed to stdout
}

# CAPTURE
result=$(get_config_val)

# Logic: Command substitution $( ) works by capturing the 
# Standard Output Stream (FD 1) of the function execution context.
```
EOF
                ;;
            29-recursion)
cat <<'EOF'
# 🟢 Milestone 29: Recursion [CORE]

### 1. Self-Reference
Recursion is when a function calls itself to solve a problem by breaking it into smaller sub-tasks. While possible in Bash, it is subject to strict memory and process limits.

```bash
# CONVENTIONAL: Numeric recursion
function factorial() {
    local n=$1
    if (( n <= 1 )); then
        echo 1
    else
        local prev=$(factorial $(( n - 1 )))
        echo $(( n * prev ))
    fi
}

# Logic: Every call pushes a new layer of shell memory (Activation 
# Frame) onto the internal stack.
```

### 2. Recursion Limits
Bash is not optimized for deep recursion (no tail-call optimization). You must manually monitor depth to prevent script crashes or "Stack Overflow" equivalents.

```bash
# EXPLICIT: Depth Guard
function recurse() {
    local depth=$1
    if (( depth > 100 )); then
        echo "Error: Max depth reached" >&2
        return 1
    fi
    recurse $(( depth + 1 ))
}

# Logic: Recursion depth is tracked by the BASH_SUBSHELL or 
# manual counters. Exceeding limits triggers a segmentation 
# fault in the shell's C-engine.
```
EOF
                ;;
            30-passing-mechanisms)
cat <<'EOF'
# 🟢 Milestone 30: Passing Mechanisms [CORE]

### 1. Pass by Value (Default)
When you hand data to a function, Bash creates a **Copy** of that data. Changes made to the copy do not affect the original variable.

```bash
# CONVENTIONAL: Positional params
function update() {
    local val=$1
    val="new"               # Original variable is UNCHANGED
}

# Logic: Arguments are passed as a list of strings. The local 
# assignment creates a new string buffer in the function scope.
```

### 2. Pass by Reference (Nameref)
Modern Bash (4.3+) allows you to pass a **Link** to a variable name. This allows a function to directly manipulate the memory of a variable outside its scope.

```bash
# EXPLICIT: The Nameref Pattern
function update_global() {
    local -n ref=$1         # 'ref' points to the NAME passed
    ref="new_value"         # Modifies original variable!
}

# USAGE
x="old"
update_global x             # Pass NAME, not $x
echo $x                     # Logic: x is now "new_value"

# Logic: 'declare -n' creates a Symbolic Map in the symbol table. 
# Any access to 'ref' triggers a secondary lookup for the target 
# variable name.
```

### 3. Flag Parsing (The Conveyor Belt)
For professional CLIs, non-positional arguments (flags) are preferred over strictly ordered arguments.

```bash
# EXPLICIT: while/shift pattern
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--mode)
            install_mode="$2"
            shift 2 # Consume flag AND value
            ;;
        install|update)
            ACTION="$1"
            shift # Consume only the command
            ;;
        *)
            echo "Unknown: $1"; exit 1 ;;
    esac
done

# Logic: $@ is treated as a stack. 'shift' pops the top item 
# off, moving the next item to index $1.
```

EOF
                ;;
            31-closures-lambdas)
cat <<'EOF'
# 🔵 Milestone 31: Closures & Lambdas [PRO]

### 1. Lambda Simulation
Bash has no native syntax for anonymous functions (lambdas). However, you can simulate them by passing strings of code and evaluating them dynamically.

```bash
# EXPLICIT: Dynamic Execution
function map() {
    local code=$1; shift
    for item in "$@"; do
        eval "$code \"$item\""
    done
}

map 'echo "Item:"' "a" "b"

# Logic: 'eval' forces the shell to run its Parser and Lexer on 
# a string at runtime, treating it as functional code.
```

### 2. Closure Simulation
A closure is a function that "Closes over" the variables of its parent. In Bash, we simulate this using subshells to "Freeze" the current environment state.

```bash
# EXPLICIT: Scoped Snapshot
x=10
generate_callback() {
    ( echo "Frozen X: $x" ) # Snapshot at time of creation
}

# Logic: Because subshells ( ) perform a fork(), they receive a 
# complete copy of all parent variables at that specific 
# moment in time.
```
EOF
                ;;
            32-sequential-collections)
cat <<'EOF'
# 🟢 Milestone 32: Sequential Collections [CORE]

### 1. The Indexed Array
A sequential collection is a list of values indexed by integers (0, 1, 2...). In Bash, arrays are "Sparse," meaning you can assign value to index 100 without filling indices 0-99.

```bash
# CONVENTIONAL: Simple list
fruits=(apple banana cherry)
echo "${fruits[1]}"         # Logic: banana

# Logic: Sequential arrays are stored internally as a linked-list 
# of string pointers indexed by integer keys.
```

### 2. High-Performance Loading
For large data sets, Bash provides optimized built-ins that bypass the slow word-splitting engine to load file contents directly into memory arrays.

```bash
# EXPLICIT: Declaration & Loading
declare -a log_lines
mapfile -t log_lines < access.log

# SAFE ITERATION
for line in "${log_lines[@]}"; do
    echo "Processing: $line"
done

# Logic: 'mapfile' (readarray) uses an optimized C-loop to read 
# bytes into the array structure, providing significant speed 
# gains over 'while read' for static data.
```

## Deep-Dive Reference
For advanced manipulation and expansion techniques:
- [Expansion & Manipulation](./array/expansion-manipulation.md)
EOF
                ;;
            33-associative-collections)
cat <<'EOF'
# 🟢 Milestone 33: Associative Collections [CORE]

### 1. Key-Value Maps
An associative collection (Map/Dictionary) is a hash table where keys are strings instead of numbers. This is the primary tool for configuration and data lookup in Bash.

```bash
# EXPLICIT: Mandatory Declaration
declare -A config           # MUST be declared as -A

# ASSIGNMENT
config=([port]=8080 [host]="localhost")
config[theme]="dark"

# Logic: Bash runs a hashing algorithm on the string key to 
# determine the memory bucket for the value, providing O(1) 
# lookup performance.
```

### 2. Advanced Inspection
Associative arrays allow you to iterate over keys, values, or both. This is essential for building dynamic configuration loaders.

```bash
# EXPLICIT: Key/Value Iteration
for key in "${!config[@]}"; do
    echo "Key: $key | Value: ${config[$key]}"
done

# Logic: The '!' marker tells the expansion engine to return 
# the index list (keys) rather than the contents of the buckets.
```
EOF
                ;;
            16-syntactic-automation)
cat <<'EOF'
# 🔴 Milestone 16: Syntactic Automation [SYSTEMS]

### 1. Macro Simulation (Aliases)
Automation in Bash often begins with Aliases—simple word replacements that act like preprocessor macros. They are ideal for interactive shortcuts but have strict limitations in scripts.

```bash
# CONVENTIONAL: Interactive shortcut
alias ll='ls -la'

# EXPLICIT: Scripted Expansion
shopt -s expand_aliases     # Aliases are DISABLED in scripts by default
alias log='echo "[$(date)]"'

# Logic: During the Parsing Phase, Bash checks the first word of 
# every command against the Alias Hash Table and textually 
# replaces it before the Lexer continues.
```

### 2. Functional Shortcuts
Functions are the primary tool for automation in Bash scripts. Unlike aliases, they support parameters and complex logic, acting as "First-class commands" within the shell environment.

```bash
# EXPLICIT: Automated Wrapper
function backup() {
    local target=$1
    tar -czf "${target}.tar.gz" "$target"
}

# Logic: Functions are stored in the Global Function Table. 
# Calling a function jumps execution to that memory address 
# within the current process context.
```
EOF
                ;;
            34-structs-base)
cat <<'EOF'
# 🟢 Milestone 34: Structs - Base [CORE]

### 1. Record Grouping
A Struct is a way to group related data (like a User's ID, Name, and Email) into a single logical unit. Since Bash has no native `struct` keyword, we use **Associative Arrays** to create record namespaces.

```bash
# CONVENTIONAL: Loose prefixing (Anti-pattern)
user1_name="Bob"; user1_id=42 # Logic: Fragile and unscalable

# EXPLICIT: Associative Record
declare -A User1=(
    [name]="Bob"
    [id]=42
    [role]="Admin"
)

# Logic: By using a single array name for all related fields, 
# you create a memory-managed record that can be passed as a 
# single handle.
```

### 2. Struct Handlers
To act on these simulated structs, pass the **Name** of the array to a function and use a nameref to dereference it.

```bash
# EXPLICIT: Struct "Method"
function print_user() {
    local -n u=$1           # 'u' points to the array name passed
    echo "User: ${u[name]} (ID: ${u[id]})"
}

print_user User1            # Logic: Passes "User1" string
```
EOF
                ;;
        *)
            echo "Topic not found."
            ;;
        esac
    }

    if [[ -n "$1" ]]; then
        bl_tutor_get_lesson "$1" | bl_tutor_format_lesson
        return 0
    fi

    while true; do
        clear
        echo -e "\033[1;35m=========================================\033[0m"
        echo -e "\033[1;36m          BASH INTERPRETER TUTOR         \033[0m"
        echo -e "\033[1;35m=========================================\033[0m"
        echo -e "Select a lesson topic to learn:\n"
        
        local i=1
        for topic in "${topics[@]}"; do
            printf "  \033[1;33m%2d)\033[0m %s\n" "$i" "$topic"
            ((i++))
        done
        echo -e "\n  \033[1;31mx)\033[0m Exit Tutor"
        echo -e "\033[1;35m-----------------------------------------\033[0m"
        read -rp "Select an option: " choice

        if [[ "$choice" == "x" || "$choice" == "X" ]]; then
            break
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#topics[@]} ]]; then
            local selected="${topics[$((choice-1))]}"
            clear
            bl_tutor_get_lesson "$selected" | bl_tutor_format_lesson
            echo -e "\n\033[1;35m=========================================\033[0m"
            read -rp "Press Enter to return to lesson menu..."
        else
            echo "Invalid option."
            sleep 1
        fi
    done
}
