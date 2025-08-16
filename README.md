# 🧹 PWAclean

**pwaclean** is a cross-platform command-line utility for [FirefoxPWA (PWAsForFirefox)](https://github.com/filips123/FirefoxPWA). Rewritten in Python, this project helps you scan, clean, and manage cache files from your Progressive Web App (PWA) profiles to reclaim disk space and keep your system running smoothly by removing unnecessary temporary data.


## 🌟 Key Features

- **Cross-Platform Support**: Works seamlessly on Windows, macOS, and Linux, without relying on external Bash dependencies like `jq`.
- **Intelligent Profile Scanning**: Detects and displays all FirefoxPWA profiles, showing the size of their cache and the associated apps.
- **Interactive and Automated Cleaning**: Choose to clean specific profiles interactively or use command-line flags to clear all cache automatically.
- **Empty Profile Management**: Safely identifies and allows you to remove profiles that no longer have installed apps or cached data, using the official `firefoxpwa` tool.
- **Dry Run Mode (`--dry-run`)**: Simulates the cleanup process without deleting any files, so you can see what would be removed.
- **Customizable Cleanup**: You can easily customize which directories are targeted for cleaning by editing the `CLEAN_DIRS` variable in the script.

## ⚙️ Requirements

- **Python 3.6+**: The script is written in Python and is platform-independent.
- **FirefoxPWA**: The script requires Firefox PWA to be installed on your system.

## 🚀 Installation and Usage

**pwaclean** is a single-file Python script that works on **Linux**, **Windows**, and **macOS**.

### 1. Clone the repository

```bash
git clone https://github.com/your-username/pwaclean.git
cd pwaclean
```

### 2. Run the script

You can run it directly with Python:

```bash
python pwaclean.py
```

Or make it executable (Linux/macOS):

```bash
chmod +x pwaclean.py
./pwaclean.py
```

### 3. (Optional) Add to your PATH

For easier access on Linux/macOS:

```bash
sudo mv pwaclean.py /usr/local/bin/pwaclean
pwaclean
```

On Windows, you can:

- Move `pwaclean.py` to a folder included in your system's PATH.
- Optionally rename it to `pwaclean.py` or `pwaclean.exe` if bundled with `pyinstaller`.

> 💡 **Tip (Windows):** Use `python pwaclean.py` unless `.py` files are associated with Python in your system. You can check this by double-clicking the script — if it opens in Python, you're good to go.


### Command-Line Options

| Option      | Shorthand | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `--yes`     | `-y`      | Skips all confirmation prompts.                  |
| `--all`     | `-a`      | Cleans all profiles without needing to select.   |
| `--yes-all` | `-ya`     | Combines `--yes` and `--all` for full automation.|
| `--dry-run` |           | Simulates cleanup without deleting any files.    |
| `--empty`   | `-e`      | Removes empty profiles (no apps or cache).       |
| `--table`   | `-t`      | Displays profiles in a formatted table.          |
| `--help`    | `-h`      | Shows the full help message.                     |

### Usage Examples

Clear all cache automatically:

```bash
pwaclean --yes-all
```

Simulate removing empty profiles:

```bash
pwaclean --dry-run --empty
```

Display profiles in a table format:

```bash
pwaclean --table
```

## ⌨️ Interactive Prompts

When prompted, you can enter:

- Numbers (e.g., `1 2 4`) to clean specific profiles.
- `a` or `*` to clean all profiles.
- `n` to do nothing and exit.

## 🛠 Example Output
```bash
$ ./pwaclean.py -y

🔍 Scanning FirefoxPWA profiles and cache...

1) YouTube (K5G74N): 124M
2) Twitter (F4D21P): 98M
3) Work Tools (A9Q31T): 300M — 3 apps
    - Slack
    - Trello
    - Notion

📦 Total removable cache: 522M

Enter numbers to clean (e.g. 1 3 5, 'a' for all, 'n' for none): 1 3

🧹 Cleaning selected apps caches...
✔ YouTube cleaned
✔ Work Tools cleaned

✅ Total cache cleared: 424M
``` 

## ❗ Notes

- **Cache vs. Data**: The script only removes temporary cache files. Your app configurations and data remain intact.
- **`--empty` flag**: This is a specialized option for deleting profiles that have no apps or cache data. It does not perform cache cleaning.
- **Profile Deletion**: Profile removal is handled directly by `firefoxpwa profile remove` for a safer and official method.

## 📜 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 🙌 Credits

Created by **dmnmsc**. Feel free to open issues or contribute!
