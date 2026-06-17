# 🌐 Online Sourcing Showcase

This guide demonstrates patterns for sourcing library components dynamically from remote URLs in a POSIX-compliant manner.

## 1. Sourcing Individual Files via curl

You can fetch and source specific files directly using `eval` with `curl` to remain fully POSIX-compliant without process substitutions:

```sh
# Sourcing the core dependency and importer
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/posix.sh)"
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/import.sh)"

# Sourcing diagnostics utility individually via curl (optional include)
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/info/diagnostics.sh)"

# Sourcing tutor utility individually via curl (optional include)
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/info/tutor.sh)"
```

## 2. Sourcing All Files Dynamically

Initialize the importer and source the entire library matching all files:

```sh
# Source importer and import all modules dynamically
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/posix.sh)"
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/import.sh)"
bl_import "*"

# Alternatively, import in strict mode to exit early on network failures
bl_import --strict "*"
```

## 3. Sourcing Categories/Folders

Source groups of modules using category glob patterns:

```sh
# Source everything inside the ui/ category
bl_import "ui/*"

# Source everything inside the info/ category
bl_import "info/*"
```

## 4. Sourcing Specific Files under a Category Individually

You can source each specific file under its respective category individually:

```sh
# Sourcing Core components
bl_import "core/colors.sh"
bl_import "core/import.sh"

# Sourcing Info/Diagnostics components
bl_import "info/diagnostics.sh"
bl_import "info/tutor.sh"

# Sourcing UI components
bl_import "ui/progress_bars.sh"   # bl_progress_bar, bl_square_progress, bl_spiral_progress, bl_terrain_loader
bl_import "ui/matrix_filler.sh"   # bl_matrix_filler
```

## 5. Using bl_terrain_loader

After sourcing `ui/progress_bars.sh`, pipe progress values (0-100) to `bl_terrain_loader`:

```sh
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/posix.sh)"
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/import.sh)"
bl_import "ui/progress_bars.sh"

# Random pattern (POSIX-compliant loop)
i=1; while [ "$i" -le 100 ]; do echo "$i"; i=$((i+1)); sleep 0.02; done | bl_terrain_loader -l "Loading World..."

# Full-screen Minecraft-style chunk loading
i=1; while [ "$i" -le 100 ]; do echo "$i"; i=$((i+1)); sleep 0.02; done | bl_terrain_loader --minecraft -fw -fh --color-mode time
```

## 6. All File Includes

```sh
# Core importer and dependency
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/posix.sh)"
eval "$(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/import.sh)"

# Core components
bl_import "core/colors.sh"
bl_import "core/import.sh"
# UI components
bl_import "ui/progress_bars.sh"
bl_import "ui/matrix_filler.sh"
# Info components
bl_import "info/diagnostics.sh"
bl_import "info/tutor.sh"
```
