# 🌟 posix-lib

###### a posix porting of corechunk/bash-lib

A premium, lightweight, dependency-free POSIX shell library for modular scripting. Load UI elements, async processes, and diagnostic utilities instantly, directly in-memory from remote URLs or local clones.

---

## 🚀 Quick Start (Online Sourcing)

To source remote modules dynamically directly in-memory without installing anything locally:

```sh
# 1. Source the POSIX helpers and importer
. <(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/posix.sh)
. <(curl -fsSL https://raw.githubusercontent.com/corechunk/posix-lib/main/lib/core/import.sh)

# 2. Source selectively on-demand (e.g. only UI progress bars)
bl_import "ui/*"

# 3. Use the components
# Loop syntax depends on loaded modules. E.g. using posix_for:
posix_for "i=1" "$i -le 100" "i=$(( i+1 ))" 'printf " %d" "$i"; sleep 0.01' | bl_progress_bar -l "Syncing Data"
```

### 💡 Optional Diagnostics & Tutorials (Online)
You can optionally pull down only diagnostics or the interactive tutorial:

```sh
# Sourcing the environment check diagnostics (Optional Include)
bl_import "info/diagnostics.sh" && bl_info_check

# Sourcing the interactive tutor lessons guide (Optional Include)
bl_import "info/tutor.sh" && bl_bash_tutor
```

---

## 🛠️ Diagnostics & Interactive Explorer
posix-lib includes built-in tools to verify your environment and explore library functions:

```sh
# 1. Run the namespace diagnostic checker (verifies dependencies and loaded state)
bl_info_check

# 2. Launch the interactive library explorer menu
bl_info_menu
```

## 📦 Local Sourcing & Bundling

If you prefer to source files locally from your clone:

```sh
# 1. Clone the repository
git clone https://github.com/corechunk/posix-lib.git
cd posix-lib

# 2. Source POSIX helpers and core importer
. lib/core/posix.sh
. lib/core/import.sh

# 3. Dynamically import everything else!
import lib/*

# Or conditionally import specific modules
import lib/ui/* lib/info/diagnostics.sh
```

## 📚 Documentation & Reference

*   [Master Porting Notes & Progress](PORTING.md) — Porting architecture, dependency structure and checklist.
*   [API Reference & Module Map](doc/api-reference.md) — Comprehensive variables and functions checklist.
*   [Local Sourcing Showcase](doc/local-usage.md) — How to source library files locally.
*   [Online Sourcing Showcase](doc/online-usage.md) — Comprehensive guide to curl and glob sourcing online.


