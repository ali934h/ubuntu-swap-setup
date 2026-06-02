# 📖 Ubuntu Swap Setup — Full Guide

> For quick setup, see the [one-liner in README](../README.md).

---

## What is Swap?

Swap is a portion of hard drive storage reserved for the OS to temporarily store data when RAM is full. It acts as a safety net against **out-of-memory (OOM)** errors — especially useful on servers with limited RAM.

> ⚠️ Swap is slower than RAM. It's a fallback, not a replacement.

---

## Prerequisites

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

Look at the row with `/` in the `Mounted on` column.

**How much swap do you need?**

| RAM | Recommended Swap |
|-----|------------------|
| ≤ 2 GB | 2× RAM (e.g., 512MB RAM → 1GB swap) |
| 2–8 GB | Equal to RAM |
| > 8 GB | At least 4 GB |

---

## Step 3 — Create the Swap File

```bash
sudo fallocate -l 2G /swapfile
```

> If `fallocate` is unavailable:
> ```bash
> sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152
> ```

---

## Step 4 — Secure the Swap File

```bash
sudo chmod 600 /swapfile
```

Verify:

```bash
ls -lh /swapfile
# Expected: -rw------- 1 root root 2.0G ...
```

---

## Step 5 — Mark as Swap

```bash
sudo mkswap /swapfile
```

---

## Step 6 — Enable the Swap File

```bash
sudo swapon /swapfile
```

Verify:

```bash
sudo swapon --show
free -h
```

---

## Step 7 — Make Permanent (Survive Reboots)

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Step 8 — Tune Kernel Parameters (Optional)

### Swappiness

Controls how eagerly the OS uses swap (0 = avoid, 100 = aggressive).

| RAM | Recommended | Reason |
|-----|-------------|--------|
| ≤ 1 GB | 60 | Use swap early to avoid OOM |
| 1–4 GB | 30 | Balanced |
| > 4 GB | 10 | Keep data in RAM as long as possible |

```bash
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

### Cache Pressure

Controls how aggressively the OS clears cached filesystem data.

```bash
sudo sysctl vm.vfs_cache_pressure=50
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
```

Apply immediately:

```bash
sudo sysctl -p
```

---

## Remove Swap

```bash
sudo swapoff /swapfile
sudo rm /swapfile
sudo nano /etc/fstab  # remove the /swapfile line
```

---

## Quick Reference (Manual)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
