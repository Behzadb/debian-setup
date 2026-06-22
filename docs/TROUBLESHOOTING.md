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

### Issue: Login lands in the wrong desktop (not i3)

**Symptom**: After logging in through the lightdm greeter you get a default/empty
session instead of i3.

**Solution**: The setup writes a lightdm drop-in that defaults the session to i3.
Verify it and the i3 xsession exist:
```bash
cat /etc/lightdm/lightdm.conf.d/50-debian-setup.conf   # should contain: user-session=i3
ls /usr/share/xsessions/i3.desktop                      # ships with i3-wm
```
You can also pick "i3" from the session menu (gear/icon) on the greeter — lightdm
remembers your last choice per user. Note: the old `session=i3` key does **not**
exist in lightdm; the correct key is `user-session` under `[Seat:*]`.

---

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

### Issue: Polybar status bar not showing

**Symptom**: i3 works but the status bar (clock, CPU, workspaces, etc.) is missing.
This setup uses **Polybar**, not i3status.

**Solution**:
```bash
# Verify polybar is installed
which polybar

# Check the config and launch script are symlinked
ls -la ~/.config/polybar/config.ini ~/.config/polybar/launch.sh

# Launch it manually to see any errors
~/.config/polybar/launch.sh

# Or restart i3 (it runs the launch script via exec_always)
# Press Super+Shift+R

# Common cause: missing Nerd Font glyphs (boxes instead of icons)
fc-list | grep -i "nerd"   # FiraCode/JetBrainsMono Nerd Font must be present
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

## Audio, Microphone & Webcam Issues

### Issue: Microphone or webcam doesn't work in Chromium

**Symptom**: A site (Meet, Zoom web, etc.) shows no microphone/camera, or Chromium's
device list is empty.

**Checklist** (most → least common):
```bash
# 1. Group membership — you must be in 'video' (camera) and 'audio' (USB mic).
#    The setup adds these, but they only take effect after a re-login.
groups | tr ' ' '\n' | grep -E 'video|audio'
#    If missing:  sudo usermod -aG video,audio $USER   then log out and back in.

# 2. Is the camera visible to the OS?
v4l2-ctl --list-devices            # from v4l-utils; should list /dev/videoN
ls -l /dev/video*                  # you should have read/write access

# 3. Is the microphone visible to the audio server?
pactl list sources short           # should list at least one input (not just monitors)
wpctl status                       # PipeWire: shows sinks/sources + default

# 4. Are the PipeWire user services running?
systemctl --user status pipewire pipewire-pulse wireplumber

# 5. Site permissions in Chromium:
#    chrome://settings/content/camera  and  .../microphone  → allow the site
```

**Notes**:
- This is an **X11** session, so Chromium uses webcams directly via V4L2 and audio
  via the PipeWire PulseAudio layer — no xdg-desktop-portal is required.
- Pick the active input/output device in **pavucontrol** (right-click the Polybar
  volume module) if the wrong one is selected.

---

### Issue: USB webcam or headset cuts out / disconnects during calls

**Symptom**: A USB webcam or headset works at first, then drops mid-call.

**Cause**: USB autosuspend (TLP) powered the device down.

**Solution**: The setup already excludes audio/bluetooth from autosuspend. If a
*webcam* still drops, deny-list it by USB id:
```bash
lsusb                               # find your webcam, e.g. "046d:0825 Logitech Webcam C270"
sudoedit /etc/tlp.d/debian-setup.conf
#   set:  USB_DENYLIST="046d:0825"
sudo tlp start                      # reapply
```

---

### Issue: Bluetooth headset connects but has no sound or no microphone

**Symptom**: BT headset pairs, but no audio output or the mic is missing.

**Solution**: PipeWire needs the Bluetooth SPA plugin (installed by the setup).
Verify and restart the audio stack:
```bash
dpkg -s libspa-0.2-bluetooth >/dev/null && echo "BT audio plugin present"
systemctl --user restart wireplumber pipewire pipewire-pulse
# Then re-select the headset profile (HSP/HFP for mic) in pavucontrol or:
bluetoothctl                        # power on, pair, connect, trust
```

---

## Fingerprint & Mobile Broadband (WWAN)

The setup installs these **only if the hardware is detected** (`03-security.sh`
for the fingerprint reader, `05-networking.sh` for a cellular modem). If your
hardware wasn't picked up, the detection (USB vendor IDs) may have missed it —
install manually as shown below.

### Issue: Fingerprint reader — set it up / not working
```bash
# Was a reader detected & fprintd installed?
lsusb | grep -iE 'fingerprint|synaptics|goodix|elan|validity'   # find the reader
command -v fprintd-enroll || sudo apt install -y fprintd libpam-fprintd

# Enroll YOUR finger (as your user, NOT root), then verify:
fprintd-enroll          # swipe/touch several times
fprintd-verify

# Enable fingerprint for login/sudo (adds it alongside the password):
sudo pam-auth-update    # tick "fprintd", or non-interactive: sudo pam-auth-update --enable fprintd
```
Notes: sudo and the lightdm greeter accept the fingerprint (or password). **Plain
i3lock does not do fingerprint** — use your password at the lock screen.

### Issue: Mobile broadband / WWAN modem — set it up / not working
```bash
# Is the modem seen?
mmcli -L                                   # lists modems (from ModemManager)
lsusb | grep -iE 'fibocom|quectel|sierra|huawei|modem'
# If ModemManager isn't installed (detection missed it):
sudo apt install -y modemmanager libmbim-utils libqmi-utils usb-modeswitch
sudo systemctl enable --now ModemManager

# Connect as a user (NetworkManager drives it — no root needed via polkit):
nmtui                                      # → Add → Mobile broadband → enter your APN
# or CLI:
nmcli c add type gsm ifname '*' con-name mobile apn YOUR_APN
nmcli c up mobile
mmcli -m 0                                 # modem status / signal
```
Tip: a SIM PIN or carrier APN is usually required; `modem-manager-gui` gives a
GUI for signal/SMS/USSD.

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

### Issue: Does closing the lid suspend? / It doesn't lock on resume

**Behavior**: Closing the lid **suspends** the laptop — this is handled by
systemd-logind's default `HandleLidSwitch=suspend` (the setup does not override
logind), and it works under i3/X11. On resume the screen is **locked** because
i3 runs `xss-lock` at startup, which locks (betterlockscreen) before the system
sleeps.

**Verify / debug**:
```bash
# Confirm logind's lid action (default is 'suspend'):
grep -i HandleLidSwitch /etc/systemd/logind.conf /etc/systemd/logind.conf.d/* 2>/dev/null
# (no override => the built-in default 'suspend' applies)

# Confirm the locker is running in your i3 session:
pgrep -a xss-lock

# Test suspend + lock manually:
systemctl suspend          # should lock then sleep; resume shows the lock screen
```

**Notes / gotchas**:
- **Docked** (external monitor connected): by design logind uses
  `HandleLidSwitchDocked=ignore`, so lid-close does **not** suspend while an
  external display is attached. To force suspend anyway, set
  `HandleLidSwitchDocked=suspend` in `/etc/systemd/logind.conf` and
  `sudo systemctl restart systemd-logind`.
- To change what the lid does (e.g. just lock, never suspend), set
  `HandleLidSwitch=lock` (or `ignore`) in `/etc/systemd/logind.conf`.
- Power button: handled by logind (`HandlePowerKey=poweroff` by default). The
  setup intentionally does **not** wire acpid to the power button.
- Sleep mode: the setup prefers **S3 "deep"** sleep when the firmware supports it
  (lower drain), via `suspend-deep-sleep.service`. See the next entry.

---

### Issue: Laptop drains too much while suspended (or resume fails)

**Lower the drain**: s2idle ("Modern Standby") can lose ~1–2%/h asleep; S3 "deep"
loses ~0.3%/h. `04-power-management.sh` installs `suspend-deep-sleep.service`,
which switches to deep at boot **only if the firmware offers it**:
```bash
cat /sys/power/mem_sleep          # [deep] => using S3 ; [s2idle] only => S3 not offered
systemctl status suspend-deep-sleep.service
```
If your machine shows only `[s2idle]`, the firmware doesn't expose S3 (some BIOS
have a "Sleep State" option to enable it) — the service is a safe no-op there.

**If resume ever fails** after enabling deep sleep (rare; buggy firmware S3):
```bash
sudo systemctl disable --now suspend-deep-sleep.service
echo s2idle | sudo tee /sys/power/mem_sleep     # revert immediately
# then reboot
```
This setup never edits the GRUB cmdline for sleep, so reverting is just disabling
the service — no bootloader surgery.

**Near-zero drain for long suspends** (opt-in): `suspend-then-hibernate` sleeps
first, then hibernates to swap and powers off. Needs swap ≥ RAM and usually
Secure Boot disabled. Enable with `HandleLidSwitch=suspend-then-hibernate` in
`/etc/systemd/logind.conf` and tune `HibernateDelaySec` in `/etc/systemd/sleep.conf`.

---

### Issue: TLP battery thresholds not working

**Symptom**: Laptop charges to 100% despite threshold config

**Cause**: Model doesn't support thresholds, or the `thinkpad_acpi` driver isn't loaded

**Solution**:
```bash
# ThinkPad T14 uses the native thinkpad_acpi attribute (note the name):
cat /sys/class/power_supply/BAT0/charge_control_start_threshold
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
# If these files don't exist, ensure the driver is loaded:
lsmod | grep thinkpad_acpi || sudo modprobe thinkpad_acpi

# Verify TLP picked up the thresholds (look for "charge_control_*"):
sudo tlp-stat -b

# Defaults are START=75 STOP=80 (longevity). For maximum runtime per charge,
# set STOP_CHARGE_THRESH_BAT0=100 in /etc/tlp.d/debian-setup.conf, then:
sudo tlp start
```

---

### Issue: Switching power profiles / CPU feels capped on battery

**Symptom**: You want max performance now, or to stretch battery as far as
possible, without editing config files.

**Solution**: Use the `power-profile` switcher (installed by the power module).
It sets the ThinkPad ACPI platform profile + CPU EPP + turbo:
```bash
power-profile status        # show platform profile / governor / EPP / turbo / battery
sudo power-profile performance   # max speed
sudo power-profile powersave     # max battery
sudo power-profile balanced      # default
sudo power-profile auto          # hand back to TLP's automatic AC/BAT settings
```
- In i3: **Super+Shift+P** → then `p`/`b`/`s`/`a`. Polybar shows the ⚡ profile
  and **left-click cycles** it.
- A manual profile lasts until the next AC↔battery change, when TLP re-applies
  its baseline. Run `power-profile auto` (or just replug) to return to automatic.
- Note: on the T14, `intel_pstate`/`amd_pstate` only expose the `powersave` and
  `performance` governors (not `schedutil`) — this is normal; the real pacing is
  done via EPP and the platform profile, not the governor name.

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

# Drop to the low-power profile (platform profile + EPP + turbo off)
sudo power-profile powersave

# Check thermal daemon (Intel T14; on AMD the platform profile handles thermals)
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

