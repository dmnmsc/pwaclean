# Changelog

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
