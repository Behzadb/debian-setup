# TODO

## Lock screen: full Catppuccin theme via i3lock-color
Currently the lock uses **plain i3lock** with a solid Catppuccin background
(`i3lock -c 1e1e2e`, wired directly in `config/i3/config` for both `Super+Shift+X`
and the xss-lock idle/suspend locker — reliable, no betterlockscreen). The blurred
Catppuccin ring + clock + colors require **i3lock-color**, which is not installed:

- The setup's `scripts/01-window-manager.sh` builds i3lock-color with the old
  **autotools** method (`autoreconf && ./configure && make`), but current
  i3lock-color uses **meson** (`./build.sh`) — so the build fails and it falls
  back to plain i3lock.
- A prebuilt i3lock-color binary is NOT a fix on Debian: those link
  `libjpeg.so.8` (Ubuntu), while Debian ships `libjpeg.so.62`.

**To do:**
1. Fix `01-window-manager.sh` to build i3lock-color with meson on Debian:
   - deps: `meson ninja-build` + the existing xcb/cairo/pam/xkbcommon `-dev` libs
     and `libjpeg-dev` (→ links the system `libjpeg.so.62`).
   - build: `./build.sh && sudo ./install-i3lock-color.sh` (verify script names
     against the installed i3lock-color version).
2. After i3lock-color is installed, uncomment the i3lock-color color block in
   `config/betterlockscreen/betterlockscreenrc` (8-digit `rrggbbaa`, no `#`).
3. Then switch the two lock commands in `config/i3/config` from
   `i3lock -c 1e1e2e` back to `betterlockscreen -l blur` (the `Super+Shift+X`
   bind and the `xss-lock ... --` locker) to get the blurred themed lock.
