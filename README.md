# 🐧 Ubuntu Swap Setup

Add and configure swap space on Ubuntu 20.04 / 22.04 / 24.04.

---

## ⚡ One-Line Setup

```bash
curl -fsSL https://raw.githubusercontent.com/ali934h/ubuntu-swap-setup/main/setup.sh | sudo bash
```

The script auto-detects your RAM, recommends the right swap size, and tunes kernel parameters.

> ✅ Works on servers with as little as **512MB RAM**

---

## 🔍 Useful Commands

```bash
# Check current swap
sudo swapon --show
free -h

# Check disk space before setup
df -h

# Remove swap (if needed)
sudo swapoff /swapfile
sudo rm /swapfile
# Then remove the /swapfile line from /etc/fstab
```

---

## 📖 Full Guide

See [docs/full-guide.md](docs/full-guide.md) for step-by-step instructions, swappiness tuning, and reference tables.

---

## 📚 References

- [DigitalOcean – How to Add Swap Space on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04)
- [Ubuntu Documentation – Swap FAQ](https://help.ubuntu.com/community/SwapFaq)
