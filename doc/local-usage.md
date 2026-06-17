# 💻 Local Sourcing Showcase

This guide demonstrates how to source library components locally from the project root using the POSIX-compliant `. ` operator.

## 1. Sourcing Individual Files via local path

You can source specific files directly using the POSIX dot (`.`) command:

```sh
# Sourcing the core registry dependency and importer
. lib/core/posix.sh
. lib/core/import.sh

# Sourcing diagnostics utility individually (optional)
. lib/info/diagnostics.sh

# Sourcing tutor utility individually (optional)
. lib/info/tutor.sh
```

## 2. Sourcing All Files Dynamically

Initialize the importer and source the entire library matching all files:

```sh
# Source importer and import all modules dynamically
. lib/core/posix.sh
. lib/core/import.sh
import "*"
```

## 3. Sourcing Categories/Folders

Source groups of modules using category glob patterns:

```sh
# Source everything inside the ui/ category
import "ui/*"

# Source everything inside the info/ category
import "info/*"

# Source in strict mode to fail early on errors
import --strict "core/*"
```

## 4. Sourcing Specific Files under a Category Individually

You can source each specific file under its respective category individually:

```sh
# Sourcing Core components
import "core/colors.sh"
import "core/import.sh"

# Sourcing Info/Diagnostics components
import "info/diagnostics.sh"
import "info/tutor.sh"

# Sourcing UI components
import "ui/progress_bars.sh"   # bl_progress_bar, bl_square_progress, bl_spiral_progress, bl_terrain_loader
import "ui/matrix_filler.sh"   # bl_matrix_filler
```

## 5. Using bl_terrain_loader Locally

`bl_terrain_loader` is included in `lib/ui/progress_bars.sh`. Once sourced, pipe numbers 0–100 into it:

```sh
. lib/core/posix.sh
. lib/core/import.sh
import "ui/progress_bars.sh"

# Default random fill with yellow→cyan gradient (POSIX-compliant loop)
i=1; while [ "$i" -le 100 ]; do echo "$i"; i=$((i+1)); sleep 0.02; done | bl_terrain_loader -l "Building..."

# Full-screen Minecraft-style chunk loading
i=1; while [ "$i" -le 100 ]; do echo "$i"; i=$((i+1)); sleep 0.02; done | bl_terrain_loader --minecraft -fw -fh

# Custom gradient (blue → red), center-out pattern
i=1; while [ "$i" -le 100 ]; do echo "$i"; i=$((i+1)); sleep 0.02; done | \
    bl_terrain_loader --pattern center-out --color-mode time --start "#0000FF" --end "#FF0000"
```


## Sourcing Files Dynamically

Instead of manually sourcing files and risking duplicates or missing dependencies, simply source the core loader and use the `import` command to handle everything else!

```sh
#!/usr/bin/env sh

# 1. Source the core dependency and importer
. lib/core/posix.sh
. lib/core/import.sh

# 2. Dynamically import the entire library (recursively loads all components)
import "*"

# Or import specific components or directories seamlessly:
import "ui/*" "info/diagnostics.sh"
```

## 6. All File Includes

```sh
# Core importer and dependency
. lib/core/posix.sh
. lib/core/import.sh
# UI components
import "ui/progress_bars.sh"
import "ui/matrix_filler.sh"
# Info components
import "info/diagnostics.sh"
import "info/tutor.sh"
```
