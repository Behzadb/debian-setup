# Troubleshooting Guide

Common issues and solutions for debian-setup.

---

## Installation Issues

### Issue: "Permission denied" when running setup.sh

**Symptom**: `bash: ./setup.sh: Permission denied`

**Solution**:
```bash
chmod +x setup.sh
chmod +x scripts/*.sh
sudo ./setup.sh
```

---

### Issue: Setup fails with "E: Could not open lock file"

**Symptom**: `E: Could not open lock file /var/lib/apt/lists/lock`

**Causes**:
- Another apt process running
- Unfinished previous install

**Solution**:
```bash
# Wait for other apt processes to finish
sudo lsof /var/lib/apt/lists/lock

# Or remove lock
sudo rm /var/lib/apt/lists/lock

# Retry setup
sudo ./setup.sh
```

---

### Issue: "Unable to locate package" errors

**Symptom**: `E: Unable to locate package X`

**Cause**: Package lists not updated

**Solution**:
```bash
sudo apt update
sudo apt upgrade
sudo ./setup.sh
```

---

### Issue: Internet connection fails during setup

**Symptom**: `curl: (7) Failed to connect`

**Causes**:
- No internet connection
- DNS not working
- Firewall blocking

**Solution**:
```bash
# Test connectivity
ping 8.8.8.8

# Test DNS
nslookup google.com

# Check network configuration
ip a
ip route

# If DNS fails, try manual DNS
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

---

## Window Manager Issues

### Issue: i3 won't start / Black screen

**Symptom**: `startx` shows black screen, i3 doesn't load

**Solution**:
```bash
# Check X11 installation
sudo apt install xserver-xorg

# Check i3 installation
sudo apt install i3

# Try verbose X11 start
startx -- -verbose 2>&1 | tee ~/.startx-log

# Check for missing dependencies
ldd /usr/bin/i3
```

---

### Issue: i3status bar not showing

**Symptom**: i3 works but status bar (clock, CPU, etc.) missing

**Solution**:
```bash
# Verify i3status is installed
which i3status

# Check config path
ls -la ~/.config/i3status/config

# Restart i3
# Press Super+Shift+R

# Or manually start i3status
i3status
```

---

### Issue: Keyboard shortcuts not responding

**Symptom**: i3 keybindings (Super+Enter, etc.) don't work

**Causes**:
- Keyboard layout issue
- i3 not focused
- Custom bindings conflict

**Solution**:
```bash
# Check keyboard layout
setxkbmap -query

# Fix US layout
setxkbmap us

# Check i3 is running
ps aux | grep i3

# Reload i3 config
# Press Super+Shift+C in i3

# Or manually reload
i3-msg reload
```

---

### Issue: Mouse/Touchpad not working

**Symptom**: Mouse cursor visible but not responding

**Solution**:
```bash
# Check devices
xinput list

# Test mouse
xinput test 2  # Try different numbers

# Enable touchpad (if needed)
xinput set-prop "touchpad_name" "Device Enabled" 1

# Check X11 input drivers
ls /usr/lib/xorg/modules/input/
```

---

## Docker Issues

### Issue: "docker: Permission denied"

**Symptom**: `docker: permission denied while trying to connect`

**Cause**: User not in docker group

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group immediately (temporary)
newgrp docker

# Or log out and back in for permanent change

# Verify
docker ps
```

---

### Issue: Docker daemon won't start

**Symptom**: `Cannot connect to Docker daemon` or `Failed to start docker`

**Solution**:
```bash
# Check Docker service status
sudo systemctl status docker

# Start Docker service
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Check logs
sudo journalctl -u docker -n 50
```

---

### Issue: Docker image download timeout

**Symptom**: `Error response from daemon: manifest not found` or timeout

**Solution**:
```bash
# Increase timeout (edit /etc/docker/daemon.json)
{
    "registry-mirrors": [
        "https://mirror.gcr.io",
        "https://daocloud.io/mirror"
    ]
}

# Restart Docker
sudo systemctl restart docker

# Try pull again
docker pull ubuntu:latest
```

---

## Kubernetes Issues

### Issue: kubectl command not found

**Symptom**: `command not found: kubectl`

**Solution**:
```bash
# Check installation
which kubectl

# If not found, reinstall
curl -LOs "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

---

### Issue: kind create cluster fails

**Symptom**: `Failed to create cluster` or `docker error`

**Causes**:
- Docker not running
- Insufficient disk space
- Port already in use

**Solution**:
```bash
# Ensure Docker running
sudo systemctl start docker

# Check disk space
df -h | grep /var  # Need at least 5GB

# Check open ports
sudo lsof -i :6443  # kind uses 6443

# Create cluster with custom name
kind create cluster --name my-cluster

# Check cluster status
kind get clusters

# View logs
kind logs --name my-cluster
```

---

### Issue: kubectl fails to connect to cluster

**Symptom**: `Unable to connect to the server`

**Solution**:
```bash
# Check kubeconfig
cat ~/.kube/config

# Verify cluster running
kind get clusters

# Check cluster status
kubectl get nodes

# Explicitly set context
kubectl config use-context kind-my-cluster

# View all contexts
kubectl config get-contexts
```

---

## Security Issues

### Issue: fail2ban not banning attackers

**Symptom**: SSH brute-force attempts not blocked

**Solution**:
```bash
# Check fail2ban service
sudo systemctl status fail2ban

# View fail2ban logs
sudo fail2ban-client status sshd

# Monitor live
sudo tail -f /var/log/fail2ban.log

# Manual test (ban yourself then unban!)
sudo fail2ban-client set sshd banip YOUR_IP
sudo fail2ban-client set sshd unbanip YOUR_IP
```

---

### Issue: SSH keys not working

**Symptom**: `Permission denied (publickey)` despite key added

**Causes**:
- Wrong permissions on ~/.ssh
- Wrong key uploaded to server
- SSH agent not running

**Solution**:
```bash
# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key
ssh-add ~/.ssh/id_ed25519

# Verify key added
ssh-add -l

# Test connection
ssh -v user@host  # -v for verbose output
```

---

### Issue: UFW blocks legitimate traffic

**Symptom**: Can't reach service on open port

**Solution**:
```bash
# List all rules
sudo ufw status numbered

# Show detailed status
sudo ufw status verbose

# Delete problematic rule
sudo ufw delete NUM

# Add rule for port
sudo ufw allow 8080/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100 to any port 22
```

---

## Power Management Issues

### Issue: TLP battery thresholds not working

**Symptom**: Laptop charges to 100% despite threshold config

**Cause**: Laptop model doesn't support threshold (some ThinkPads, System76)

**Solution**:
```bash
# Check if supported
sudo cat /sys/class/power_supply/BAT0/charge_start_threshold

# If file doesn't exist, not supported

# Verify TLP configuration
sudo tlp-stat -p

# Some models need ACPI drivers
sudo apt install acpi acpid
```

---

### Issue: Laptop running hot despite TLP

**Symptom**: CPU temperature high even idle

**Cause**: 
- Thermal paste degraded
- Fan not running
- TLP not applying settings

**Solution**:
```bash
# Monitor temperature
watch -n1 'sensors'

# Check CPU frequency
watch -n1 'cat /proc/cpuinfo | grep MHz'

# Verify TLP is running
sudo systemctl status tlp

# Manually set power profile
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check thermal daemon
sudo systemctl status thermald
```

---

### Issue: Battery drains too quickly

**Symptom**: Battery lasts <3 hours

**Solution**:
```bash
# Calibrate power consumption analysis
sudo powertop --calibrate

# View power-hungry processes
sudo powertop

# Check powertop recommendations
# (generates report in ~/powertop.html)
sudo powertop --html=~/powertop.html

# Enable power saving
sudo tlp start

# Disable USB autosuspend if breaking devices
# Edit /etc/tlp.d/debian-setup.conf:
# USB_AUTOSUSPEND=0
sudo systemctl restart tlp
```

---

## Networking Issues

### Issue: No internet connection

**Symptom**: Can't reach any external hosts

**Solution**:
```bash
# Check interface status
ip a
ip link show

# Test routing
ip route

# Check DNS
cat /etc/resolv.conf
nslookup 8.8.8.8

# If no route, add default gateway
sudo ip route add default via 192.168.1.1

# Restart network
sudo systemctl restart networking
# or
sudo systemctl restart systemd-networkd
```

---

### Issue: DNS not resolving

**Symptom**: `nslookup google.com` fails but IP works

**Solution**:
```bash
# Check DNS configuration
cat /etc/systemd/resolved.conf

# Set DNS manually
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Restart resolver
sudo systemctl restart systemd-resolved

# Verify
nslookup google.com
dig google.com
```

---

### Issue: WireGuard VPN not connecting

**Symptom**: `wg show` shows no traffic

**Solution**:
```bash
# Check WireGuard status
sudo wg show
sudo wg-quick status wg0

# Check config
sudo cat /etc/wireguard/wg0.conf

# Start connection
sudo wg-quick up wg0

# View logs
sudo wg-quick down wg0
sudo wg show all

# Test connection through VPN
curl ifconfig.me  # Should show VPN IP
```

---

## Performance Issues

### Issue: System very slow

**Symptom**: Desktop feels laggy, slow to open apps

**Solution**:
```bash
# Check memory
free -h
ps aux --sort=-%mem | head

# Check disk I/O
iostat 1 5
iotop

# Check CPU load
uptime
top -b -n 1

# Check dmesg for errors
sudo dmesg | tail -20

# Clear page cache (temporary)
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

---

### Issue: High CPU temperature

**Symptom**: CPU temperature >80°C at idle

**Solution**:
```bash
# Monitor in real-time
watch -n1 'sensors'

# Check thermal throttling
cat /sys/class/thermal/thermal_zone0/trip_point_*/temp

# Verify CPU frequency scaling
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Force power-save
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check for runaway processes
ps aux --sort=-%cpu | head

# If thermal paste old, laptop needs service
```

---

## Configuration Issues

### Issue: Shell aliases not working

**Symptom**: Custom aliases like `ll` not available

**Cause**: Config file not sourced

**Solution**:
```bash
# Verify config exists
ls -la ~/.bashrc ~/.zshrc

# Source manually
source ~/.bashrc

# Check for syntax errors
bash -n ~/.bashrc

# Add to your shell startup if missing
echo 'source ~/.bashrc' >> ~/.bash_profile
```

---

### Issue: Git config not applied

**Symptom**: `git config --global user.name` shows nothing

**Solution**:
```bash
# Check config
cat ~/.gitconfig

# Set values
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Verify
git config --list --global
```

---

## Logging & Diagnostics

### Useful log locations:

```bash
# System logs
journalctl -n 50

# Docker logs
journalctl -u docker -n 50

# fail2ban logs
sudo tail -f /var/log/fail2ban.log

# SSH logs
sudo tail -f /var/log/auth.log

# Thermal logs
journalctl -u thermald -n 50

# Setup script logs
cat setup-*.log
```

---

## Camera / Microphone Issues

### Microphone not detected in Chromium

**Symptom**: Chromium shows "no microphone found" or permission prompt never appears.

**Diagnosis**:
```bash
# Check PipeWire is running and mic is visible
wpctl status
# Should show your input device under "Sources"

# Check ALSA sees the mic
arecord -l

# Check wireplumber is running
systemctl --user status wireplumber
```

**Solutions**:

1. **PipeWire not fully started** — start the user session services:
   ```bash
   systemctl --user enable --now pipewire pipewire-pulse wireplumber
   ```

2. **`pipewire-alsa` missing** — needed as the ALSA bridge:
   ```bash
   sudo apt install pipewire-alsa
   # Then restart session or reboot
   ```

3. **Portal missing** — Chromium routes mic access through `xdg-desktop-portal`:
   ```bash
   sudo apt install xdg-desktop-portal xdg-desktop-portal-gtk
   # Restart and retry
   ```

4. **Chromium site permission** — even with working hardware, per-site permissions may be blocked:
   - In Chromium: `chrome://settings/content/microphone` → check blocked list

---

### Webcam not working in Chromium

**Symptom**: Chromium shows no camera, or video call shows black screen.

**Diagnosis**:
```bash
# Check kernel sees the camera
v4l2-ctl --list-devices

# Check device permissions (should be video group)
ls -la /dev/video*

# Quick test — if ffplay opens a camera feed, the device works
ffplay -f v4l2 /dev/video0
```

**Solutions**:

1. **`v4l-utils` missing**:
   ```bash
   sudo apt install v4l-utils
   ```

2. **User not in `video` group**:
   ```bash
   sudo usermod -aG video $USER
   # Log out and back in
   ```

3. **Portal not handling camera requests** — `xdg-desktop-portal-gtk` is required:
   ```bash
   sudo apt install xdg-desktop-portal xdg-desktop-portal-gtk
   ```

4. **Confirm portal is running**:
   ```bash
   systemctl --user status xdg-desktop-portal
   systemctl --user status xdg-desktop-portal-gtk
   # If inactive, start them:
   systemctl --user enable --now xdg-desktop-portal
   ```

---

### Camera / mic broken on Wayland specifically

**Symptom**: Works on X11 but not on Wayland session.

**Root cause**: Chromium needs explicit flags to use PipeWire for WebRTC on Wayland. Without them it falls back to X11 XCB path and ignores PipeWire entirely.

**Fix**: Check `/etc/chromium/flags` exists and contains:
```
--ozone-platform=wayland
--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform
```

> ⚠️ The two features **must** be on a single comma-separated `--enable-features`
> line. Chromium keeps only the *last* `--enable-features` flag it sees, so
> writing them on separate lines silently drops `WebRTCPipeWireCapturer` and
> breaks camera/mic over PipeWire.

If the file doesn't exist, re-run the Wayland setup script:
```bash
sudo bash scripts/01b-wayland-manager.sh
```

Or create it manually:
```bash
sudo mkdir -p /etc/chromium
cat | sudo tee /etc/chromium/flags << 'EOF'
--ozone-platform=wayland
--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform
EOF
```

**Also verify both portal backends are active** (WLR = screenshare, GTK = camera/mic):
```bash
systemctl --user status xdg-desktop-portal-wlr
systemctl --user status xdg-desktop-portal-gtk
```

---

### Screen sharing broken in browser (Wayland)

**Symptom**: Browser screen share shows empty source list.

**Cause**: `xdg-desktop-portal-wlr` missing (handles screen capture on Sway/wlroots).

```bash
sudo apt install xdg-desktop-portal-wlr
systemctl --user enable --now xdg-desktop-portal-wlr
```

---

## Getting Help

If issue persists:

1. **Check logs**: `journalctl`, `setup-*.log`
2. **Search documentation**: [SELECTIONS.md](SELECTIONS.md)
3. **Run diagnostics**: `sudo lynis audit system`
4. **Open issue** with:
   - Error message (full output)
   - Debian version: `cat /etc/os-release`
   - Hardware: `lscpu`, `lsmem`, `lsblk`
   - Relevant logs

---

## Prevention Tips

1. **Keep system updated**: `sudo apt update && sudo apt upgrade`
2. **Monitor disk space**: `df -h` (keep >10% free)
3. **Check logs regularly**: `journalctl -n 100`
4. **Backup configs**: `cp ~/.config ~/.config.backup`
5. **Test before deploying**: Use `kind` for K8s testing

