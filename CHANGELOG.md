
# 📝 Changelog

## [Python v2.1] - 2025-08-16 (Message Logic & Help Menu Refinement)

## ✅ **Fixed**

- **Corrected misleading success message**  
  Fixed a logical error where the script would print a `"cleaned"` message for a profile even when it was skipped due to a non-existent folder.  
  Now, the script only prints a success message (`✔ ... cleaned`) if the cleaning operation was actually performed.

- **Improved message logic in `remove_empty_profiles_mode`**  
  The message `"No empty profiles found."` will now only be displayed when the script is run with the `-e` flag, providing better context and improving user experience.

## 🚀 **Improvements**

#### **Empty Profile Awareness**
- Added a new section at the start of the script that warns users about **empty profiles**.
- Suggests using the `-e` flag to remove them, offering a **clear call to action** and making the tool more intuitive.

#### **Help Menu Enhancement**
- Updated the help menu (`-h` flag) with:
  - More **detailed descriptions** of command-line options.
  - A **friendlier tone** and clearer guidance for new users.



## [Python v2] - 2025-08-16 (Enhanced Profile Handling & Path Validation)

### 🚀 Improvements

#### **Smarter Profile Management**
- The script now correctly handles the **Default profile (`00000000000000000000000000`)**:
  - Included for cache cleaning operations.
  - **Excluded** from "empty profile" detection and removal logic.
  - Prevents misleading warnings and incorrect removal attempts.
- Added a **clear comment** to the `DEFAULT_PROFILE_ULID` constant:
  - Explains its purpose.
  - Warns users **not to modify it**.

#### **Improved User Experience**
- Added **robust validation** for custom paths:
  - If a user provides a custom `BASE_DIR` or `CONFIG_FILE` that doesn't exist, the script now **prompts to use the default path** instead of exiting with an error.
- Streamlined logic for detecting and reporting empty profiles:
  - The script **no longer shows a warning** about the Default profile when the `--empty` flag is not used.
  - Results in **cleaner output**.

#### **Enhanced Code Reliability**
- Fixed a bug where the script would **incorrectly identify the Default profile as "empty"**, causing a continuous loop when attempting deletion.
- New logic correctly identifies the profile as a **system file** and **does not attempt to remove it**.



## [Python v1] - First Python release of the FirefoxPWA cleanup script

### ✨ Features

#### **Basic Cleanup Functionality**
- Allows users to **scan FirefoxPWA profiles** and clean specific cache directories such as:
  - `cache2`
  - `startupCache`
  - `offlineCache`
  - ...and others

#### **Profile Identification**
- Detects profiles from the `config.json` file used by FirefoxPWA.
- Displays **cache size** and **number of associated applications** per profile.

#### **Operation Modes**
- **Manual Selection**: Users can choose specific profiles to clean.
- **Full Cleanup (`--all` / `-a`)**: Cleans cache from all profiles with a single confirmation.
- **Dry Run Mode (`--dry-run`)**: Shows what the script would do **without making any changes**.

#### **Empty Profile Detection**
- Identifies profiles with **no applications and no cache**.
- Warns the user and suggests removal using the `--empty` option.

#### **Path Handling**
- Automatically detects configuration and profile paths on:
  - **Windows**
  - **macOS**
  - **Linux**
    
## [Bash v4] – 2025-08-10 (Refactor & safer profile deletion)
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

## [Bash v3.1] – 2025-08-09 (Efficiency-Focused)

### Enhancements
- Optimized cache size calculation using a single `find` per profile.
- Added `--empty` / `-e` option to detect and remove empty profiles.
- ~~- `config.json` backup: Auto-created before modifications; aborts if backup fails.~~
- Streamlined terminal relaunch detection logic.
- Minor prompt and output cleanup.

---

## [Bash v2] – 2025-08-08

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

## [Bash v1] – 2025‑08‑07 *(initial release)*
- Base functionality:
  - Relaunches in a terminal if run non-interactively.
  - Scans FirefoxPWA profiles and lists cache folder sizes.
  - Deletes content from known cache directories.
  - Displays total cache size before and after cleaning.

---

#### **Improved User Interface**
- Includes a **table view option (`--table`)** for structured profile visualization.
- Features **interactive prompts with confirmation** (`ask_yn`).

#### **Terminal Relaunch Logic**
- Adds logic to **relaunch the script in a terminal** on Windows, macOS, and Linux if executed from a GUI.

