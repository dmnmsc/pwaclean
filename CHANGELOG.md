
# 📝 Changelog

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

### ✨ New Features

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

#### **Improved User Interface**
- Includes a **table view option (`--table`)** for structured profile visualization.
- Features **interactive prompts with confirmation** (`ask_yn`).

#### **Terminal Relaunch Logic**
- Adds logic to **relaunch the script in a terminal** on Windows, macOS, and Linux if executed from a GUI.

