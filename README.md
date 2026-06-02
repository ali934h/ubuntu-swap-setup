# 🐧 Ubuntu Swap Space Setup Guide

A step-by-step guide to adding and configuring swap space on Ubuntu servers (20.04 / 22.04 / 24.04).

> **Reference:** [DigitalOcean – How to Add Swap Space on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04)

---

## ⚡ One-Line Setup

Run this on your server to set up swap automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/ali934h/ubuntu-swap-setup/main/setup.sh | sudo bash
```

The script will:
- Detect your RAM and recommend the right swap size
- Ask for confirmation before doing anything
- Auto-select `swappiness` based on your RAM (low-RAM servers get higher values to avoid OOM)
- Make swap permanent across reboots
- Tune kernel parameters for best performance

> ✅ Safe to run on servers with as little as **512MB RAM**

---

## 📖 What is Swap?

Swap is a portion of hard drive storage reserved for the OS to temporarily store data when RAM is full. It acts as a safety net against **out-of-memory (OOM)** errors — especially useful on servers with limited RAM.

> ⚠️ Swap is slower than RAM. It's a fallback, not a replacement.

---

## ✅ Prerequisites

- Ubuntu server (20.04 / 22.04 / 24.04)
- A user with `sudo` privileges

---

## Step 1 — Check Existing Swap

```bash
sudo swapon --show
```

If there's no output, no swap is currently configured. Verify with:

```bash
free -h
```

---

## Step 2 — Check Available Disk Space

```bash
df -h
```

Look at the row with `/` in the `Mounted on` column. Make sure you have enough free space before proceeding.

**How much swap do you need?**

| RAM | Recommended Swap |
|-----|-----------------|
| ≤ 2 GB | 2x RAM (e.g., 1GB RAM → 2GB swap) |
| 2–8 GB | Equal to RAM |
| > 8 GB | At least 4 GB |

---

## Step 3 — Create the Swap File

Create a **2 GB** swap file (adjust size as needed):

```bash
sudo fallocate -l 2G /swapfile
```

> If `fallocate` is not available, use `dd` instead:
> ```bash
> sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152
> ```

---

## Step 4 — Secure the Swap File

Set correct permissions so only root can read/write it:

```bash
sudo chmod 600 /swapfile
```

Verify:

```bash
ls -lh /swapfile
# Expected: -rw------- 1 root root 2.0G ...
```

---

## Step 5 — Mark the File as Swap

```bash
sudo mkswap /swapfile
```

---

## Step 6 — Enable the Swap File

```bash
sudo swapon /swapfile
```

Verify it's active:

```bash
sudo swapon --show
free -h
```

---

## Step 7 — Make Swap Permanent (Survive Reboots)

Add the swap entry to `/etc/fstab`:

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Step 8 — Tune Swap Settings (Optional)

### 🔧 Swappiness

Controls how often the OS uses swap (0 = avoid swap, 100 = use swap aggressively).

The right value depends on your available RAM:

| RAM | Recommended Swappiness | Reason |
|-----|------------------------|--------|
| ≤ 1 GB | 60 | Avoid OOM — use swap early |
| 1–4 GB | 30 | Balanced |
| > 4 GB | 10 | Keep data in RAM as long as possible |

Check current value:

```bash
cat /proc/sys/vm/swappiness
```

Set and persist (example for low-RAM servers):

```bash
sudo sysctl vm.swappiness=60
echo 'vm.swappiness=60' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 🔧 Cache Pressure

Controls how aggressively the OS clears cached filesystem data from memory.

Check current value:

```bash
cat /proc/sys/vm/vfs_cache_pressure
```

Set it to `50` (recommended for all servers):

```bash
sudo sysctl vm.vfs_cache_pressure=50
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## 🗑️ How to Remove Swap (If Needed)

```bash
sudo swapoff /swapfile
sudo rm /swapfile
# Also remove the line from /etc/fstab
sudo nano /etc/fstab
```

---

## 📋 Quick Reference (Manual)

```bash
# Full setup — adjust swap size as needed
SWAP_SIZE=2G
sudo fallocate -l $SWAP_SIZE /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tune — adjust swappiness based on your RAM (see table above)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## 📚 References

- [DigitalOcean – How to Add Swap Space on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04)
- [Ubuntu Documentation – Swap FAQ](https://help.ubuntu.com/community/SwapFaq)
