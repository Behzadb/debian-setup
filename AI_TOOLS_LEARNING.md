# IT Engineer Tools Learning Guide
# Feed this file into an AI to learn optimal usage of all tools in this workstation setup

## Context
This is a production-grade SRE/DevOps workstation on Debian Linux using:
- Display: Wayland + Sway (primary), X11 + i3 (secondary)
- Shell: Bash/Zsh with Starship prompt
- Theme: Catppuccin Mocha system-wide

---

## WINDOW MANAGERS & DESKTOP

### Sway (Wayland Compositor)
- Config: `~/.config/sway/config`
- Learn: keybindings, workspaces, input/output config, bar integration, `swaymsg` IPC, scratchpad, layout modes (split/tabbed/stacked), window rules (`for_window`), exec_always, multi-monitor setup

### Waybar (Wayland Status Bar)
- Config: `~/.config/waybar/config` + `~/.config/waybar/style.css`
- Learn: module configuration, custom scripts, click actions, CSS styling, dynamic modules, interval updates, IPC with Sway

### Wofi (Wayland App Launcher)
- Config: `~/.config/wofi/`
- Learn: `--show drun/run/dmenu`, custom styling, piping input, keybindings, `--prompt`, integration with scripts

### Mako (Wayland Notifications)
- Config: `~/.config/mako/config`
- Learn: `makoctl`, urgency levels, app-specific rules, timeout config, action buttons, `on-notify`

### i3 (X11 Window Manager)
- Config: `~/.config/i3/config`
- Learn: keybindings, workspace naming, layout containers, `i3-msg`, marks, scratchpad, multi-monitor with `xrandr`, startup programs, bar config

### Polybar (X11 Status Bar)
- Config: `~/.config/polybar/config.ini`
- Learn: modules (i3, date, network, cpu, memory, battery), IPC hooks, scripted modules, click actions, font icons

### Rofi (X11 App Launcher)
- Config: `~/.config/rofi/`
- Learn: `-show drun/run/window/ssh`, custom scripts, `-dmenu` mode, themes, keybindings, `rofi-calc`, `rofi-emoji`

---

## TERMINAL & SHELL

### Kitty (Terminal Emulator)
- Config: `~/.config/kitty/kitty.conf`
- Learn: `kitty @` remote control, layouts (splits/tabs/windows), `kitten` tools (icat, diff, ssh), font config, GPU acceleration options, `kitty +kitten clipboard`

### tmux (Terminal Multiplexer)
- Learn: sessions/windows/panes, prefix key, copy mode, `tmux new/attach/detach/kill`, scripting sessions, `tmux.conf` customization, plugins (tpm, resurrect, continuum), `send-keys`, layouts

### Starship (Shell Prompt)
- Config: `~/.config/starship.toml`
- Learn: module config (git, kubernetes, python, node, docker), custom modules, format strings, conditions, performance tuning, `starship explain`

### atuin (Shell History)
- Config: `~/.config/atuin/config.toml`
- Learn: `atuin search`, sync between machines, `atuin stats`, filtering by directory/exit code/duration, keybinding (Ctrl-R replacement), `atuin import`

### Zoxide (Smart cd)
- Learn: `z`, `zi` (interactive), `zoxide add/remove/query`, integration with fzf, frecency algorithm, `__zoxide_z` shell function

---

## MODERN CLI REPLACEMENTS

### eza (Modern ls)
- Learn: `eza -la`, `--tree`, `--git`, `--icons`, `--group-directories-first`, `--sort`, long format fields, color scheme config

### bat (Modern cat)
- Learn: `--language`, `--style`, `--theme`, `--diff`, `--paging`, integration as `MANPAGER`, `bat cache --build`, `batgrep`, `prettybat`

### delta (Git Diff Pager)
- Config: `~/.gitconfig` `[core] pager = delta`
- Learn: `--side-by-side`, `--diff-highlight`, themes, `--navigate`, line numbers, word diff, integration with `git diff/show/log`

### ripgrep (rg - Fast Search)
- Learn: regex patterns, `-t` file types, `-g` glob, `--hidden`, `--follow`, `--multiline`, `-A/-B/-C` context, `--replace`, `--json`, `.rgignore`, `--pcre2`

### fd (Modern find)
- Learn: pattern matching, `-t` type filter, `-e` extension, `--exec`, `--hidden`, `-x` parallel exec, `--exclude`, `-d` depth, `--changed-within`

### fzf (Fuzzy Finder)
- Learn: `--preview`, `--multi`, key bindings (`Ctrl-T`, `Ctrl-R`, `Alt-C`), `FZF_DEFAULT_COMMAND`, piping, `--bind`, `fzf-tmux`, integration with vim/git/docker

### jq (JSON Processor)
- Learn: `.field`, `[]`, `|`, `select()`, `map()`, `keys`, `has()`, `@base64`, `@csv`, `--arg`, `--slurpfile`, `reduce`, `env`, `path()`, recursive descent `..`

### yq (YAML Processor)
- Learn: same operators as jq, `yq eval`, `yq eval-all` (multi-doc), `-i` in-place edit, converting between YAML/JSON/XML/TOML, `yq e '.key = "value"'`

### HTTPie (HTTP Client)
- Learn: `http GET/POST/PUT/DELETE`, `--json`, `--form`, headers (`Key:Value`), query params (`key==value`), auth (`--auth`), sessions, `--follow`, `--download`, `--stream`, `--verbose`

---

## VERSION CONTROL

### Git (with delta pager)
- Config: `~/.gitconfig`
- Learn: advanced rebase (`-i`, `--onto`), `reflog`, `worktree`, `bisect`, `stash`, `cherry-pick`, `rerere`, `git log --graph`, `--format`, `filter-branch` vs `filter-repo`, `sparse-checkout`, submodules

### lazygit (Git TUI)
- Config: `~/.config/lazygit/config.yml`
- Learn: keybindings (stage/unstage/commit/push/pull), interactive rebase, branch management, stash operations, `custom commands`, diff view, log filtering, bulk operations

### Chezmoi (Dotfiles Manager)
- Learn: `chezmoi add/edit/apply/diff/status`, templates (`.tmpl`), secrets integration (SOPS/age), `chezmoi cd`, `chezmoi update` (git pull + apply), `.chezmoiignore`, `run_` scripts, `once_` scripts, machine-specific config

### Git-LFS (Large File Storage)
- Learn: `git lfs track`, `git lfs ls-files`, `git lfs pull`, pointer files, `.gitattributes`, migrating existing repos, storage backends

---

## CONTAINERIZATION

### Docker
- Learn: multi-stage builds, `BuildKit` optimizations, layer caching, `.dockerignore`, `docker compose` v2, networks (bridge/host/overlay), volumes vs bind mounts, `docker system prune`, health checks, `--init`, resource limits, `docker buildx` multi-platform

### Docker Compose (v2 Plugin)
- Learn: `depends_on` with conditions, profiles, `extend`, environment variable files, secrets, `deploy` config, `docker compose watch`, override files, `--project-name`

### Dive (Docker Image Explorer)
- Learn: `dive <image>`, layer inspection, wasted space detection, `--ci` mode for CI pipelines, efficiency score, file tree navigation

### Trivy (Vulnerability Scanner)
- Learn: `trivy image`, `trivy fs`, `trivy repo`, `trivy config` (IaC scanning), severity filtering, `--ignore-unfixed`, SBOM generation, `trivy k8s`, output formats (json/sarif/table), `.trivyignore`

---

## KUBERNETES

### kubectl
- Learn: context/namespace management, `get/describe/logs/exec/port-forward`, `apply/delete`, `rollout`, `scale`, `patch` (merge/json/strategic), `cp`, `auth can-i`, `top`, `api-resources`, `explain`, JSONPath/custom columns, `--dry-run=client`, kustomize integration

### helm (K8s Package Manager)
- Learn: `install/upgrade/rollback/uninstall`, `helm template`, `values.yaml` override (`-f`, `--set`), chart development, `helm lint`, `helm test`, dependencies, OCI registry, `helm diff` plugin, `helmfile`

### kind (Kubernetes in Docker)
- Learn: multi-node cluster config, port mapping, custom node images, `kind load docker-image`, LoadBalancer with cloud-provider-kind, ingress setup, `kubeconfig` management

### k9s (Kubernetes TUI)
- Learn: navigation (`:`, `/` filter, `Ctrl-A` aliases), pod logs/exec/describe, resource deletion, port-forward, `pulses` view, `xray` view, `popeye` integration, custom skins, `~/.config/k9s/`

### kubectx + kubens
- Learn: `kubectx` (list/switch contexts), `kubens` (list/switch namespaces), `fzf` integration for interactive selection

### stern (Multi-pod Log Viewer)
- Learn: pod regex matching, `--container`, `--since`, `--output` (raw/json/extjson/ppextjson), `--exclude`, `--include`, `--tail`, `--color`, multi-namespace with `-n`

### kustomize
- Learn: `kustomization.yaml`, bases and overlays, `namePrefix/nameSuffix`, `commonLabels`, `patches` (strategic merge vs JSON 6902), `configMapGenerator`, `secretGenerator`, `vars`, `components`

---

## INFRASTRUCTURE AS CODE

### Terraform
- Learn: providers, `init/plan/apply/destroy`, state management (`tfstate`, remote backends), modules, `for_each` vs `count`, `data` sources, `locals`, `outputs`, `terraform.tfvars`, workspaces, `moved` blocks, `import`, `terraform console`, locking, `tflint`, `terragrunt`

### Ansible
- Learn: inventory (static/dynamic), playbooks, roles, `ansible-vault`, `when` conditions, `register`/`vars`, handlers, `block/rescue/always`, `delegate_to`, `connection: local`, `ansible-galaxy`, modules (apt, template, copy, service, file, user), `--check --diff`, `ansible-lint`

---

## SECRETS MANAGEMENT

### SOPS (Secrets OPerationS)
- Guide: `docs/SOPS_GUIDE.md`
- Learn: `sops --encrypt/--decrypt`, `.sops.yaml` config, age vs PGP keys, `creation_rules` by path regex, partial encryption (`encrypted_regex`), `updatekeys`, CI/CD integration, `sops exec-env`, AWS KMS / GCP KMS backends

### age (Encryption Tool)
- Learn: `age-keygen`, `age --encrypt/--decrypt`, `-r` recipient (public key), `-i` identity file, passphrase encryption, `-a` ASCII armor, piping, integration with SOPS

### gnupg (GPG)
- Learn: `gpg --gen-key`, `--list-keys`, `--export/--import`, `--sign/--verify`, `--encrypt/--decrypt`, `--keyserver`, trust levels, `gpg-agent`, `pinentry`, SSH key from GPG subkey, `git` signing integration

---

## SECURITY TOOLS

### UFW (Firewall)
- Learn: `ufw enable/disable/status verbose`, `allow/deny/limit`, app profiles (`/etc/ufw/applications.d/`), logging, `ufw route`, IPv6, reset

### fail2ban
- Learn: `fail2ban-client status`, `jail.conf` vs `jail.local`, custom filters (regex), custom actions, `findtime/maxretry/bantime`, `fail2ban-regex` testing, whitelist, `unbanip`

### AIDE (File Integrity Monitor)
- Learn: `aide --init/--check/--update`, `aide.conf` rules, `NORMAL/PERMS/FULL` groups, scheduling with cron/systemd, reading reports, excluding paths

### auditd (Audit Logging)
- Learn: `auditctl -l/-a/-d`, `ausearch`, `aureport`, `audit.rules`, key labels, `pam_tty_audit`, watching files (`-w`), syscall auditing (`-a always,exit`), `auparse`

### lynis (Security Auditing)
- Learn: `lynis audit system`, `lynis show controls`, hardening index, custom profiles, `--tests`, `--skip-tests`, reading reports, suggested hardening steps

### nmap (Network Scanner)
- Learn: `-sS/-sU/-sV/-sC` scan types, `-O` OS detection, `-p` port ranges, `-A` aggressive, `--script` NSE scripts, `-oX/-oN/-oG` output, timing templates (`-T`), `ndiff`, zenmap, firewall evasion techniques

### tcpdump (Packet Capture)
- Learn: `-i` interface, BPF filters (`host`, `port`, `net`, `tcp/udp`), `-w/-r` pcap files, `-n` no DNS, `-v/-vv/-vvv` verbosity, `-A/-X` hex/ASCII, `and/or/not` filter logic

### Wireshark / tshark
- Learn: display filters vs capture filters, `tshark -r/-w/-Y/-T`, `tshark -z` statistics, following streams, decrypting TLS (with key log), `editcap`, `mergecap`, `capinfos`

---

## NETWORK TOOLS

### mtr (Network Path Analysis)
- Learn: `mtr --report`, `--report-cycles`, `--tcp/--udp`, `-P` port, `--json`, reading output (loss%, avg latency, jitter), interpreting hops

### doggo (Modern dig)
- Learn: `doggo @resolver`, `--type`, `--class`, query types (A/AAAA/MX/TXT/CNAME/NS/SOA/PTR), `--json`, `--color`, DoH/DoT resolvers (`--strategy`)

### trippy (Modern mtr)
- Learn: `trip`, TUI navigation, `--protocol tcp/udp/icmp`, `--target-port`, `--output json`, reading statistics columns

### WireGuard
- Learn: `wg genkey/pubkey`, `wg show`, `wg-quick up/down`, `wg0.conf` format (`[Interface]`/`[Peer]`), `AllowedIPs`, `PersistentKeepalive`, split tunneling, `PostUp/PostDown` hooks, `wg set` dynamic peer management

### iperf3 (Bandwidth Testing)
- Learn: `-s` server, `-c` client, `-u` UDP, `-b` bandwidth, `-t` duration, `-P` parallel streams, `-R` reverse, `-J` JSON output, `-f` format

### socat (Relay Tool)
- Learn: `socat TCP-LISTEN:port,fork EXEC:cmd`, `socat - TCP:host:port`, SSL/TLS relay, Unix socket to TCP, file transfer, `socat -d -d` debug

---

## SYSTEM MONITORING

### btop (System Monitor)
- Config: `~/.config/btop/btop.conf`
- Learn: navigation, process tree, network/disk/memory/CPU views, `vim_keys`, filtering, kill signals, preset configs, Catppuccin theme

### htop (Process Monitor)
- Learn: F-key actions, tree view (`t`), sorting, filtering (`\`), `--pid`, kill/renice, columns customization, `strace` from htop, `lsof` integration

### lm-sensors + sensors
- Learn: `sensors-detect`, `sensors` output, `watch sensors`, coretemp vs acpitz, fan speed monitoring, kernel modules

### TLP (Power Management)
- Learn: `tlp start/stop/stat`, `tlp-stat -b` (battery), `tlp-stat -p` (CPU), `/etc/tlp.conf` parameters, `CHARGE_THRESH_BAT*`, USB autosuspend, SATA power, `tlp fullcharge/discharge`

---

## DEVELOPMENT TOOLS

### Neovim + LazyVim
- Learn: `lazy.nvim` plugin manager, LSP setup (`nvim-lspconfig`), Treesitter, `telescope.nvim`, `neo-tree`, `which-key`, motions, macros, `vim.keymap.set`, `autocmd`, `vim.diagnostic`, DAP (debugger), formatters (`conform.nvim`)

### uv (Python Package Manager)
- Learn: `uv pip install`, `uv venv`, `uv run`, `uv sync`, `pyproject.toml`, `uv lock`, `uv tool install`, `uv python install` (version management), workspaces, `uv add/remove`

### fnm (Node Version Manager)
- Learn: `fnm install/use/list/default`, `.nvmrc` / `.node-version` auto-switching, `fnm env` shell integration, `fnm alias`, global vs local versions

### Python Development
- Learn: `venv` workflow with `uv`, `pyproject.toml` vs `setup.py`, `ruff` (linter+formatter), `mypy` type checking, `pytest` + fixtures/parametrize, `pdb`/`ipdb` debugging, `logging` module, `dataclasses`, `asyncio`

### Go Development
- Learn: `go mod init/tidy/vendor`, `go build/run/test`, `go vet`, `golangci-lint`, build tags, `go generate`, testing with `t.Run`/`testify`, goroutines/channels, `pprof` profiling

---

## PACKAGE & BINARY MANAGEMENT

### versions.env (Binary Version Pinning)
- Tools tracked: `kubectl`, `helm`, `kind`, `k9s`, `stern`, `lazygit`, `atuin`, `trivy`, `dive`, `sops`, `trippy`, `doggo`, `activitywatch`
- Learn: `update-binaries.sh` script workflow, checksum verification, GitHub Releases API (`gh release list`), `curl -fsSL`, binary installation to `/usr/local/bin`

### apt + unattended-upgrades
- Learn: `apt-cache policy/show/search`, pinning (`/etc/apt/preferences.d/`), `apt-mark hold`, `sources.list.d/` third-party repos, `apt-key` deprecation (use signed-by), `unattended-upgrades` config, `apt-listchanges`

---

## PRODUCTIVITY

### ActivityWatch (Time Tracking)
- Learn: `aw-server`, `aw-watcher-afk`, `aw-watcher-window`, web UI at `localhost:5600`, buckets API, query language (`aw-query`), event types, `aw-client` Python library, custom watchers

### tealdeer / tldr (Quick Man Pages)
- Learn: `tldr <command>`, `tldr --update`, `tldr --list`, custom pages in `~/.local/share/tealdeer/tldr-pages/`, platform filter `--platform`

---

## ORCHESTRATION SCRIPTS

### setup.sh (Main Orchestrator)
- Learn: module selection flags, parallel execution, `--dry-run`, log file location, idempotency guarantees, prerequisite checks

### setup-helpers.sh (Shared Library)
- Functions: `log_info/warn/error/success`, `check_command`, `install_if_missing`, `backup_file`, `add_apt_repo`, `download_binary`

### Key Script Patterns Used
- `set -euo pipefail` — strict mode
- Idempotency checks: `command -v`, `dpkg -l`, `systemctl is-enabled`
- Colored output with ANSI codes
- Parallel execution with `&` + `wait`
- `tee -a` logging to file

---

## DOTFILES PATTERNS

### Shell Aliases (`.bashrc`/`.zshrc`)
- Replacements: `ls` → `eza`, `cat` → `bat`, `find` → `fd`, `grep` → `rg`, `cd` → `z`
- K8s: `k` = `kubectl`, `kx` = `kubectx`, `kn` = `kubens`
- Git: `gs` = `git status`, `gl` = `git log --oneline`
- Docker: `d` = `docker`, `dc` = `docker compose`

### Environment Variables to Learn
- `FZF_DEFAULT_COMMAND`, `FZF_CTRL_T_COMMAND`, `FZF_DEFAULT_OPTS`
- `KUBECONFIG`, `KUBE_EDITOR`
- `EDITOR`, `VISUAL`, `PAGER`
- `BAT_THEME`, `BAT_STYLE`
- `RIPGREP_CONFIG_PATH`

---

## SUGGESTED AI LEARNING PROMPTS

Use these prompts with an AI to deepen your knowledge:

1. "Show me 10 advanced `kubectl` one-liners for debugging production issues"
2. "Explain Terraform state locking and how to handle state drift"
3. "Write a `sway` config snippet for a 3-monitor setup with per-workspace assignments"
4. "Show me `jq` recipes for processing Kubernetes `kubectl get -o json` output"
5. "How do I use `fzf` with `kubectl` to interactively select pods and exec into them?"
6. "Create a `docker compose` setup with SOPS-encrypted secrets for local dev"
7. "Write an Ansible role that's idempotent for Docker installation"
8. "Show `tmux` scripting to create a reproducible dev environment layout"
9. "How do I configure `delta` for optimal git diff readability?"
10. "Explain `auditd` rules to detect privilege escalation attempts"
11. "Write a `stern` command to tail logs from all pods in a namespace matching a pattern"
12. "How do I use `trivy` in a GitLab CI pipeline with SARIF output?"
13. "Show `chezmoi` template syntax for machine-specific dotfile sections"
14. "How do I set up WireGuard split tunneling with specific routes?"
15. "Write a `nmap` NSE script for checking open ports on a local subnet"
