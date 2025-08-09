# 🧹 PWAclean

**pwaclean** is a Bash script to **scan and clean cache files** from [FirefoxPWA](https://github.com/filips123/FirefoxPWA) profiles. It helps reclaim disk space by removing unnecessary cached data associated with web apps installed via FirefoxPWA.

---

## 📂 What It Does

- Detects all FirefoxPWA profiles on your system
- Displays the name, size, and associated apps for each profile
- Shows total potential space savings
- Lets you interactively select which profiles to clean
- Deletes the following folders:
  - `cache2`
  - `startupCache`
  - `offlineCache`
  - `jumpListCache`
  - `minidumps`
  - `saved-telemetry-pings`
  - `datareporting`

---

## ⚙ Requirements

- Linux or WSL (Bash required)
- [`jq`](https://stedolan.github.io/jq/) for JSON parsing
- Standard Unix utilities: `du`, `awk`, and `numfmt` (usually preinstalled on most distros)
- FirefoxPWA with default profile and config paths:
  - `~/.local/share/firefoxpwa/profiles`
  - `~/.local/share/firefoxpwa/config.json`

---

## 📦 Installation

Clone the repository:

```bash
git clone https://github.com/dmnmsc/pwaclean.git
cd pwaclean
```

Make the script executable:

```bash
chmod +x pwaclean.sh
```

(Optional) Move it to a directory in your `$PATH`:

```
sudo mv pwaclean.sh /usr/local/bin/pwaclean
```
---

## 🚀 Usage

To run the script:

```
./pwaclean.sh
```

If installed globally:

```
pwaclean
```


You can also use command-line options for automation or scripting:

| Option         | Description                                 |
|----------------|---------------------------------------------|
| `--all`, `-a`  | Clean all profiles                          |
| `--yes`, `-y`  | Skip all confirmation prompts               |
| `--yes-all`    | Clean all profiles without prompts          |
| `-ya`, `-ay`   | Same as `--yes-all`                         |
| `--dry-run`    | Show what would be cleaned (no deletion)    |
| `--empty`, `e` | Show what would be cleaned (no deletion)    |
| `--help`, `-h` | Show usage instructions                     |

---

## ⌨️ Input Options

When prompted:

- Enter numbers (e.g. `1 2 4`) to clean specific profiles
- Enter `a` or `*` to clean **all** profiles
- Enter `n` to do **nothing** and exit

---

## 🛠 Example Output
```bash
$ ./pwaclean.sh

🔍 Scanning FirefoxPWA cache...

1) YouTube (K5G74N): 124M
2) Twitter (F4D21P): 98M
3) Work Tools (A9Q31T): 300M — 3 apps
    - Slack
    - Trello
    - Notion

📦 Total cache that can be cleared: 522M

Enter the numbers of the profiles to clean (e.g. 1 3 5, 'a' for all, 'n' for none): 1 3

🧹 Cleaning selected profile caches...
✔ YouTube cleaned
✔ Work Tools cleaned

✅ Total cache cleared: 424M
``` 

---

## ❗ Notes

- Only temporary/cache files are removed.
- App configuration, data, and profiles remain intact.
- When run in a GUI terminal (e.g. from a desktop launcher), the window will remain open after completion so you can review the output.
- Use at your own risk if modifying paths.

---

## 📁 File Structure

- `~/.local/share/firefoxpwa/profiles/` – Contains app profiles
- `~/.local/share/firefoxpwa/config.json` – Metadata and app info

---

## 📝 License

This project is licensed under the **GNU General Public License v3.0**.  
See the [LICENSE](LICENSE) file for details.

---

## 🙌 Credits

Created by [dmnmsc](https://github.com/dmnmsc).  
Feel free to open issues or contribute!

