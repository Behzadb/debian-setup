# SOPS Secrets Management Guide

SOPS (Secrets OPerationS) is installed by `02-development-tools.sh` but requires a one-time key setup before it is usable. This guide covers the recommended setup using **age** encryption (simpler than GPG for personal/team use).

---

## Why SOPS?

SOPS encrypts only the **values** in structured files (YAML, JSON, .env), leaving keys readable. This means encrypted secrets can live safely in git, and diffs remain meaningful.

```yaml
# Before encryption
db_password: "supersecret123"

# After encryption
db_password: ENC[AES256_GCM,data:abc123...,iv:...,tag:...,type:str]
```

---

## 1. Install `age`

`age` is a simple, modern encryption tool. Install it:

```bash
# Debian 12/13
sudo apt install age

# Or from GitHub releases (latest)
AGE_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -fsSL "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" | \
    tar xz -C /usr/local/bin --strip-components=1 age/age age/age-keygen
```

Verify:

```bash
age --version
age-keygen --version
```

---

## 2. Generate Your age Key

```bash
# Generate a key pair (keep the private key secret!)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Output will look like:
# Public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# (private key is in keys.txt — never commit this file)
```

Set correct permissions:

```bash
chmod 600 ~/.config/sops/age/keys.txt
```

---

## 3. Configure SOPS

Create a `.sops.yaml` in your project root to tell SOPS which key to use. Replace the public key with your own:

```bash
cat > .sops.yaml << 'EOF'
creation_rules:
  # Encrypt all .yaml and .env files in this repo
  - path_regex: .*\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - path_regex: .*\.env$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
```

> **Tip**: For team use, list multiple `age` public keys separated by commas — any key holder can decrypt.

---

## 4. Environment Variable

Tell SOPS where your private key lives. Add this to `~/.bashrc` or `~/.zshrc`:

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```

Reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

---

## 5. Basic Usage

### Encrypt a new file

```bash
# Create encrypted file from scratch
sops secrets.yaml

# Encrypt an existing plaintext file (in-place)
sops --encrypt --in-place secrets.yaml
```

### Edit an encrypted file

```bash
# Opens decrypted content in $EDITOR, re-encrypts on save
sops secrets.yaml
```

### Decrypt for use in scripts

```bash
# Decrypt to stdout (pipe to another command)
sops --decrypt secrets.yaml

# Export as environment variables
export $(sops --decrypt .env | xargs)
```

### Encrypt specific values in a Kubernetes secret

```bash
# Encrypt only the 'data' key in a K8s secret
sops --encrypt --encrypted-regex '^(data|stringData)$' k8s-secret.yaml
```

---

## 6. Typical Workflow

```bash
# 1. Create .sops.yaml in project root (once per repo)
# 2. Encrypt your secrets file
sops --encrypt .env.local > .env.enc

# 3. Add to .gitignore
echo ".env.local" >> .gitignore
echo "!.env.enc" >> .gitignore

# 4. Commit the encrypted version
git add .env.enc .sops.yaml
git commit -m "Add encrypted secrets"

# 5. Decrypt when needed
sops --decrypt .env.enc > .env.local
```

---

## 7. Team / CI Setup

For CI pipelines, store the age private key as a CI secret (e.g., GitHub Actions `SOPS_AGE_KEY`):

```yaml
# GitHub Actions example
- name: Decrypt secrets
  env:
    SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
  run: |
    echo "$SOPS_AGE_KEY" > /tmp/age-key.txt
    SOPS_AGE_KEY_FILE=/tmp/age-key.txt sops --decrypt secrets.yaml
```

---

## 8. Integration with Kubernetes / Helm

Use `helm-secrets` plugin for transparent SOPS decryption in Helm:

```bash
helm plugin install https://github.com/jkroepke/helm-secrets

# Use encrypted values file
helm secrets upgrade myapp ./chart -f secrets.enc.yaml
```

---

## Security Checklist

- [ ] Private key (`keys.txt`) is **never** committed to git
- [ ] Private key file has `600` permissions
- [ ] `.sops.yaml` is committed (it only contains public keys)
- [ ] `.gitignore` excludes plaintext secrets (`*.env.local`, `*.dec.yaml`)
- [ ] CI uses ephemeral key file, not the developer's personal key

---

## References

- [SOPS GitHub](https://github.com/getsops/sops)
- [age GitHub](https://github.com/FiloSottile/age)
- [helm-secrets](https://github.com/jkroepke/helm-secrets)
