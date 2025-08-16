#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# -----------------------------------------------------------------------------
# Config & defaults
# -----------------------------------------------------------------------------

# The ULID for the default FirefoxPWA profile. Do not change this value.
DEFAULT_PROFILE_ULID = "00000000000000000000000000"

# User can add, remove, or modify directories here to customize cleaning.
CLEAN_DIRS = [
    "cache2", "startupCache", "offlineCache", "jumpListCache",
    "minidumps", "saved-telemetry-pings", "datareporting"
]

# User can set custom paths here if autodetect fails or if installed elsewhere.
CUSTOM_BASE_DIR = ""
CUSTOM_CONFIG_FILE = ""

# -----------------------------------------------------------------------------
# Paths validation
# -----------------------------------------------------------------------------

# Helper function needed to validate profiles and other stuff
def ask_yn(prompt: str, default_yes: bool = True) -> bool:
    suffix = " (Y/n): " if default_yes else " (y/N): "
    while True:
        try:
            ans = input(f"{prompt}{suffix}").strip().lower()
        except EOFError:
            return default_yes
        if not ans:
            return default_yes
        if ans in {"y", "yes"}:
            return True
        if ans in {"n", "no"}:
            return False
        print("⚠️ Please answer y or n.")

# Autodetect Paths
def get_firefox_pwa_profiles_path() -> Path:
    if sys.platform.startswith("win"):
        return Path(os.environ.get("APPDATA", "")) / "firefoxpwa/profiles"
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/firefoxpwa/profiles"
    return Path.home() / ".local/share/firefoxpwa/profiles"

def get_firefox_pwa_config_path() -> Path:
    if sys.platform.startswith("win"):
        return Path(os.environ.get("APPDATA", "")) / "firefoxpwa/config.json"
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/firefoxpwa/config.json"
    return Path.home() / ".local/share/firefoxpwa/config.json"

# Validate custom BASE_DIR
if CUSTOM_BASE_DIR:
    custom_base_dir_path = Path(CUSTOM_BASE_DIR)
    if custom_base_dir_path.exists():
        BASE_DIR = custom_base_dir_path
    else:
        print(f"⚠️ Warning: The custom profiles directory does not exist: {CUSTOM_BASE_DIR}")
        if ask_yn("❓ Do you want to use the default path instead?", default_yes=True):
            BASE_DIR = get_firefox_pwa_profiles_path()
        else:
            sys.exit("❌ Operation cancelled by the user.")
else:
    BASE_DIR = get_firefox_pwa_profiles_path()

# Validate custom CONFIG_FILE
if CUSTOM_CONFIG_FILE:
    custom_config_file_path = Path(CUSTOM_CONFIG_FILE)
    if custom_config_file_path.exists():
        CONFIG_FILE = custom_config_file_path
    else:
        print(f"⚠️ Warning: The custom config file does not exist: {CUSTOM_CONFIG_FILE}")
        if ask_yn("❓ Do you want to use the default path instead?", default_yes=True):
            CONFIG_FILE = get_firefox_pwa_config_path()
        else:
            sys.exit("❌ Operation cancelled by the user.")
else:
    CONFIG_FILE = get_firefox_pwa_config_path()

AUTO_CONFIRM = CLEAN_ALL = DRY_RUN = REMOVE_EMPTY = TABLE_MODE = False

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

def sh_escape(s: str) -> str:
    if not s:
        return "''"
    return s if all(c.isalnum() or c in "-._/:@%" for c in s) else "'" + s.replace("'", "'\"'\"'") + "'"

def humanize_size(n: int) -> str:
    size = float(n)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB", "PiB"):
        if size < 1024 or unit == "PiB":
            return f"{int(size)} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{n} B"

def dir_size_bytes(path: Path) -> int:
    if not path.is_dir():
        return 0
    total = 0
    for root, _, files in os.walk(path, followlinks=False):
        for f in files:
            fp = Path(root) / f
            try:
                if not fp.is_symlink():
                    total += fp.stat().st_size
            except Exception:
                pass
    return total

def load_config() -> Dict:
    try:
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.exit(f"❌ Config file not found: {CONFIG_FILE}")
    except json.JSONDecodeError as e:
        sys.exit(f"❌ Failed to parse config.json: {e}")

def firefoxpwa_remove_profile(ulid: str, name: str = "") -> str:
    """Run firefoxpwa interactively and return status: 'removed', 'aborted' or 'failed'"""
    try:
        rc = subprocess.call(["firefoxpwa", "profile", "remove", ulid])
        if not (BASE_DIR / ulid).exists():
            return "removed"
        return "aborted" if rc == 0 else "failed"
    except FileNotFoundError:
        print("❌ 'firefoxpwa' is required (e.g. pip install firefoxpwa).")
    except Exception as e:
        print(f"⚠ Error removing {ulid}: {e}")
    return "failed"

# -----------------------------------------------------------------------------
# Table formatting
# -----------------------------------------------------------------------------

def _print_table(headers: List[str], rows: List[List[str]]) -> None:
    widths = [max(len(str(c)) for c in col) for col in zip(headers, *rows)] if rows else [len(h) for h in headers]
    def row_fmt(vals: List[str]) -> str:
        return "|" + "|".join(f" {str(v)}{' '*(w-len(str(v))+1)}" for v,w in zip(vals, widths)) + "|"
    bar = "+" + "+".join("-"*(w+2) for w in widths) + "+"
    print(bar); print(row_fmt(headers)); print(bar)
    for r in rows:
        print(row_fmt(r))
    print(bar)

# -----------------------------------------------------------------------------
# Profiles
# -----------------------------------------------------------------------------

def _profile_size(profile_id: str) -> int:
    return sum(dir_size_bytes(BASE_DIR / profile_id / d) for d in CLEAN_DIRS)

def collect_profiles(cfg: Dict) -> List[Tuple[str, str, int, int, List[str]]]:
    profiles = cfg.get("profiles") or {}
    out: List[Tuple[str, str, int, int, List[str]]] = []
    for pid, pdata in profiles.items():
        sites = pdata.get("sites")
        app_ids = sites if isinstance(sites, list) else list(sites or [])
        out.append((pid, pdata.get("name", "(unnamed)"), _profile_size(pid), len(app_ids), app_ids))
    return out

def list_app_names(cfg: Dict, app_ids: List[str]) -> List[str]:
    sites = cfg.get("sites", {}) or {}
    names: List[str] = []
    for app_id in app_ids:
        s = sites.get(app_id) or {}
        names.append(
            (s.get("manifest") or {}).get("name")
            or (s.get("config") or {}).get("name")
            or "(unnamed)"
        )
    return names

def _is_dir_empty(path: Path) -> bool:
    try:
        return not path.exists() or (path.is_dir() and not any(path.iterdir()))
    except Exception:
        return True

# Only remove profiles that are truly empty AND are not the default profile
def remove_empty_profiles_mode(profiles, dry_run=False):
    empties = [(ulid, name) for ulid, name, size, apps, ids in profiles if size == 0 and apps == 0 and ulid != DEFAULT_PROFILE_ULID]

    if not empties:
        print(" No empty profiles found.")
        return []

    print("\n Found", len(empties), "empty profile(s):")
    for ulid, name in empties:
        print(f" - {name} ({ulid})")

    if not ask_yn("\n❓ Delete these profiles?", default_yes=False):
        print("🚫 Skipping empty profile removal.")
        return profiles

    for ulid, name in empties:
        if dry_run:
            print(f" Would remove profile: {name} ({ulid})")
        else:
            print(f"\n➡ Removing profile '{name}' ({ulid})...")
            subprocess.call(["firefoxpwa", "profile", "remove", ulid])

    return profiles

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="FirefoxPWA cache cleaner.", add_help=False)
    p.add_argument("--yes", "-y", action="store_true")
    p.add_argument("--all", "-a", action="store_true")
    p.add_argument("--yes-all", "-ya", dest="yes_all", action="store_true")
    p.add_argument("-ay", dest="ay", action="store_true", help=argparse.SUPPRESS)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--empty", "-e", action="store_true")
    p.add_argument("--table", "-t", action="store_true", help="Show profiles in a table")
    p.add_argument("--help", "-h", action="store_true")
    return p.parse_args()

def _render_profiles(cfg: Dict, kept: List[Tuple[str, str, int, int, List[str]]], table: bool, header: bool=True) -> Tuple[int, Dict[int, Tuple[str, str, int]]]:
    if header:
        print("\n🔍Scanning FirefoxPWA caches...\n")

    total = 0
    index_map: Dict[int, Tuple[str, str, int]] = {}
    if not table:
        for i, (ulid, name, size, apps, app_ids) in enumerate(kept, 1):
            total += size
            print(f"{i}) {name} ({ulid}): {humanize_size(size)}")
            if apps > 1:
                for n in list_app_names(cfg, app_ids):
                    print(f" - {n}")
            index_map[i] = (ulid, name, size)
    else:
        headers = ["#", "Name", "ULID", "Size", "Apps"]
        rows: List[List[str]] = []
        for i, (ulid, name, size, apps, app_ids) in enumerate(kept, 1):
            total += size
            rows.append([str(i), name, ulid, humanize_size(size), str(apps)])
            if apps > 1:
                rows += [["", f"- {n}", "", "", ""] for n in list_app_names(cfg, app_ids)]
            index_map[i] = (ulid, name, size)
        _print_table(headers, rows)
    return total, index_map

# -----------------------------------------------------------------------------
# Clean profile cache
# -----------------------------------------------------------------------------

def clean_profile(profile_id: str) -> None:
    profile_path = BASE_DIR / profile_id
    if not profile_path.exists():
        print(f"⚠️ Profile folder does not exist: {profile_id}, skipping")
        return
    for d in CLEAN_DIRS:
        dir_path = profile_path / d
        if dir_path.exists():
            try:
                shutil.rmtree(dir_path)
            except Exception as e:
                print(f"⚠️ Failed to remove {dir_path}: {e}")

# -----------------------------------------------------------------------------
# Main function definition
# -----------------------------------------------------------------------------

def main() -> None:
    global AUTO_CONFIRM, CLEAN_ALL, DRY_RUN, REMOVE_EMPTY, TABLE_MODE

    args = parse_args()
    if args.help:
        print("Usage: pwaclean.py [--yes|-y] [--all|-a] [--yes-all|-ya|-ay] "
              "[--dry-run] [--empty|-e] [--help|-h] [--table|-t]")
        return

    AUTO_CONFIRM = bool(args.yes or args.yes_all or args.ay)
    CLEAN_ALL    = bool(args.all or args.yes_all or args.ay)
    DRY_RUN      = bool(args.dry_run)
    REMOVE_EMPTY = bool(args.empty)
    TABLE_MODE   = bool(getattr(args, "table", False))

    cfg = load_config()
    profiles = collect_profiles(cfg)

    print("\n🔍 Scanning FirefoxPWA caches...\n")

    empties = [
        (ulid, name) for ulid, name, size, apps, _ in profiles
        if size == 0 and apps == 0 and ulid != DEFAULT_PROFILE_ULID
    ]

    if not REMOVE_EMPTY and empties:
        for ulid, name in empties:
            print(f"⚠️  Empty profile detected: {name} ({ulid})")
            print("❌  Not removed because -e not set\n")
        print("─────────────────────────────\n")

    # Remove empty profiles if -e is set
    if REMOVE_EMPTY:
        profiles = remove_empty_profiles_mode(profiles, DRY_RUN)
        print()

    # Keep only profiles with cache/apps
    kept: List[Tuple[str, str, int, int, List[str]]] = [
        (ulid, name, size, apps, app_ids)
        for ulid, name, size, apps, app_ids in profiles
        if size > 0 or apps > 0
    ]

    if not kept:
        print("\nℹ️  No profiles available to clean.\n")
        return

    # Render profiles table/list without printing scanning again
    total_size, index_map = _render_profiles(cfg, kept, TABLE_MODE, header=False)
    print(f"\n📦 Total removable cache: {humanize_size(total_size)}\n")

    # Selection & cleaning
    selection = ["a"] if CLEAN_ALL else []
    if not selection:
        try:
            selection = (input("Enter numbers to clean (e.g. 1 3 5, 'a' for all, 'n' for none): ").strip() or "").split()
        except EOFError:
            selection = ["n"]
        print()

    print("🧹 Cleaning selected apps caches...\n")
    cleared = 0

    if selection and selection[0].lower() in ("a", "*"):
        if not AUTO_CONFIRM and not ask_yn("❓ Clean *all* apps?", default_yes=True):
            print("❌ Cancelled.")
            return
        for _, (ulid, name, size) in index_map.items():
            if DRY_RUN:
                print(f"🕵️ Would clean: {name}")
            else:
                if (BASE_DIR / ulid).exists():
                    clean_profile(ulid)
                else:
                    print(f"⚠️ Profile folder does not exist: {ulid}, skipping")
                cleared += size
                print(f"✔ {name} cleaned")
    elif selection and selection[0].lower() == "n":
        print("🚫 No apps selected.\nNothing was cleaned.\n")
        return
    else:
        for tok in selection:
            try:
                num = int(tok)
            except ValueError:
                print(f"⚠️ Invalid selection: {tok}")
                continue
            if num not in index_map:
                print(f"⚠️ Invalid selection: {num}")
                continue
            ulid, name, size = index_map[num]
            if AUTO_CONFIRM or ask_yn(f"❓ Clean '{name}'?", default_yes=True):
                if DRY_RUN:
                    print(f"🕵️ Would clean: {name}")
                else:
                    if (BASE_DIR / ulid).exists():
                        clean_profile(ulid)
                    else:
                        print(f"⚠️ Profile folder does not exist: {ulid}, skipping")
                    cleared += size
                    print(f"✔ {name} cleaned")
            else:
                print(f"⏭ Skipped: {name}")

    print(f"\n✅ Total cache cleared: {humanize_size(cleared)}\n")


# -----------------------------------------------------------------------------
# Relaunch in terminal
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    script_path = os.path.abspath(__file__)
    if not sys.stdout.isatty():
        terminal_cmd = []

        if sys.platform.startswith("win"):
            base_exec_cmd = f"python \"{script_path}\" & pause > nul"
            cmd_option = "/c"
        else:
            base_exec_cmd = f"python3 '{script_path}'; read -n 1 -s -r -p 'Press any key to exit.'"
            cmd_option = "-c"

        if sys.platform.startswith("win"):
            terminal_cmd = ["cmd.exe", cmd_option, base_exec_cmd]
        elif sys.platform == "darwin":
            terminal_cmd = ["osascript", "-e", f'tell application "Terminal" to do script "{base_exec_cmd}"']
        else:
            if shutil.which("konsole"):
                terminal_cmd = ["konsole", "-e", "bash", cmd_option, base_exec_cmd]
            elif shutil.which("gnome-terminal"):
                terminal_cmd = ["gnome-terminal", "--", "/bin/bash", cmd_option, base_exec_cmd]
            elif shutil.which("xfce4-terminal"):
                terminal_cmd = ["xfce4-terminal", "-e", "bash", cmd_option, base_exec_cmd]
            elif shutil.which("xterm"):
                terminal_cmd = ["xterm", "-e", "bash", cmd_option, base_exec_cmd]

        if terminal_cmd:
            subprocess.Popen(terminal_cmd)
            sys.exit(0)
        else:
            print("Error: No compatible terminal emulator found.", file=sys.stderr)
            sys.exit(1)

    main()
