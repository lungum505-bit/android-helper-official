# android-helper-official
# 🤖 Android Helper Script (`android-helper`)

A robust, lightweight, and interactive shell script designed to streamline Android flashing, unbricking, TWRP recovery installation, and ADB sideloading using native command-line tools (`adb`, `fastboot`, and Samsung's `odin4`).

Built to avoid the random errors and bloatware of traditional GUI tools by giving you direct, transparent control over your device hardware.

---

## ✨ Features

- **📂 Drag-and-Drop Support:** Safely strips accidental terminal quotes from dragged files and directories automatically.
- **📱 Multi-Protocol Device Detection (`Option 7`):** Instantly scans and verifies connections across ADB, Fastboot, and Samsung Download Mode channels.
- **⚡ ADB Sideload (`Option 1`):** Seamlessly push updates, custom ROMs, or ZIP packages via recovery mode.
- **🛠️ TWRP & Fastboot Recovery Flashing (`Option 2`):** Quickly flash custom recovery images (`.img`) in bootloader mode.
- **🧱 Standard Unbrick (`Option 3`):** Automates flashing partition maps or OEM scripts (`flash-all.sh`) for standard devices.
- **🔥 Stable Samsung Odin4 Engine (`Option 4`):** Natively flash single custom packages (`.tar/.tar.md5`) or multi-file stock firmware packages (BL, AP, CP, CSC / HOME_CSC) without relying on fragile compatibility wrappers. Automatically unloads kernel USB conflicts (`cdc_acm`) to prevent dropped sessions.

---

## 📋 Prerequisites

Make sure you have the standard Android platform tools installed on your operating system:

1. **Android Platform Tools (`adb` and `fastboot`):** Available via your system's package manager or directly from the official Android Developer web portal.
2. **Git:** Required to clone and manage this repository.

### For Samsung Users (`Odin4`):
Samsung's native `odin4` binary is required for Option 4. 
1. Download `odin4` for Linux from official developer channels or community repositories.
2. Make it executable and place it in your system's binary path (e.g., `/usr/local/bin/odin4`).

---

## 🚀 Installation & Usage

1. **Clone this repository using Git:**
   ```bash
git clone https://github.com/lungum505-bit/android-helper-official.git
