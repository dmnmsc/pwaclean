## 📝 Changelog 

## [v4] – 2025-08-10 (Refactor & safer profile deletion)
### 🚀 Improvements

* **Cleaner and more maintainable code**:
  * Replaced redundant `find` usage with a direct loop over the `CLEAN_DIRS` array, ensuring consistency if new directories are added.
  * Removed unnecessary `awk` calls and duplicated conditions.
  * Changed profile removal from `rm -rf` to `firefoxpwa profile remove` for safer, tool-managed deletion.

* **Better readability**:
  * More concise and specific comments.
  * Consistent block separation with clear section titles.

* **More structured design**:
  * Associative arrays (`PROFILE_IDS`, `PROFILE_NAMES`, `PROFILE_SIZES`) declared at the start for better data handling.
  * Variables initialized at the beginning of their section.

* **Simplified execution flow**:
  * Shorter numeric validation (`[[ "$SIZE" =~ ^[0-9]+$ ]] || SIZE=0`).
  * Simplified app counting without extra conditional checks.

* **Maintained compatibility**:
  * Preserves `AUTO_CONFIRM` and `DRY_RUN` handling.
  * Keeps the same logic for removing empty profiles.

### 🗑️ Removed
* Duplicate cache size calculations (previously using both `find` and array iteration).
* Redundant checks for application count.
* Overly verbose or repetitive comments.

### 📦 Result
* Fewer lines of code, easier to read and maintain.
* Safer profile deletion via `firefoxpwa profile remove`.
* More predictable behavior if new cleanable directories are added.
* Same overall functionality, but with faster and clearer execution.

---

## [v3.1] – 2025-08-09 (Efficiency-Focused)

### Enhancements
- Optimized cache size calculation using a single `find` per profile.
- Added `--empty` / `-e` option to detect and remove empty profiles.
- `config.json` backup: Auto-created before modifications; aborts if backup fails.
- Streamlined terminal relaunch detection logic.
- Minor prompt and output cleanup.

---

## [v2] – 2025-08-08

### Enhancements
- **Terminal relaunch improvement**: The terminal window now stays open after the script finishes, so the user can review the output before it closes.
- **New command-line options**:
  - `--yes` / `-y`: Automatically confirm actions without prompting.
  - `--all` / `-a`: Clean all profiles without prompting for selection.
  - `--yes-all` / `-ya` / `-ay`: Combine `--yes` and `--all`—clean everything automatically.
  - `--dry-run`: Show what would be cleaned without performing deletions.
  - `--help` / `-h`: Display usage information and exit.
- **Dry-run mode**: Preview cleanup actions to be taken without modifying any files.
- **Per-profile confirmation**: Prompt the user to confirm before cleaning each profile (unless `--yes` is used).

---

## [v1] – 2025‑08‑07 *(initial release)*
- Base functionality:
  - Relaunches in a terminal if run non-interactively.
  - Scans FirefoxPWA profiles and lists cache folder sizes.
  - Deletes content from known cache directories.
  - Displays total cache size before and after cleaning.

---
