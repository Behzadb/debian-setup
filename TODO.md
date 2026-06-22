# TODO

## Lock screen: full Catppuccin theme via i3lock-color
Currently the lock uses **plain i3lock** (solid/blurred background, default white
indicator — works and is secure). The blurred Catppuccin ring + clock + colors
require **i3lock-color**, which is not installed:

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
   The i3 lock fallback already tries 6-digit first then 8-digit, so it keeps
   working on either i3lock variant.
