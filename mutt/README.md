# neomutt Email Client Configuration

## Overview

This package provides neomutt configuration with OAuth2 authentication for Gmail and Microsoft/Outlook accounts.

## Quick Start

### 1. Install Dependencies

```sh
sudo pacman -S neomutt isync
```

### 2. Deploy Configuration

```sh
stow -t ~ mutt
```

### 3. Create Gmail Account Config

```sh
# Copy template and edit
cp ~/.config/mutt/account-gmail.muttrc.example ~/.config/mutt/account-gmail.muttrc
# Edit: replace YOUR_EMAIL@gmail.com with your Gmail address
```

### 4. Create isyncrc for Mail Sync

```sh
# Copy template and edit
cp ~/.config/isyncrc-gmail.example ~/.config/isyncrc
# Edit: replace YOUR_EMAIL@gmail.com with your Gmail address
```

### 5. Create Maildir

```sh
mkdir -p ~/doc/mail/account-gmail
```

### 6. Generate GPG Key (if not exists)

```sh
gpg --full-generate-key
# Choose: RSA and RSA (default)
# Key size: 4096
# Expiration: 0 (never expires)
```

### 7. Get Google OAuth2 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select a project
3. Enable **Gmail API** → APIs & Services → Library → Gmail API → Enable
4. Create OAuth 2.0 Client ID:
   - APIs & Services → Credentials → Create Credentials → OAuth client ID
   - Application type: **Desktop app**
   - Name: "neomutt"
5. Save the **Client ID** and **Client Secret**

### 8. Initialize OAuth2 Token

```sh
# Get your GPG key ID
gpg --list-keys --keyid-format long | grep 'uid' | head -1

# Run authorization (interactive)
/usr/share/neomutt/oauth2/mutt_oauth2.py \
    --verbose --authorize --provider google \
    --authflow authcode \
    --email YOUR_EMAIL@gmail.com \
    --client-id YOUR_GOOGLE_CLIENT_ID \
    --client-secret YOUR_GOOGLE_CLIENT_SECRET \
    --encryption-pipe "gpg --encrypt --recipient YOUR_GPG_KEY_ID" \
    ~/.cache/mutt/oauth-gmail
```

This will open a browser for Google authorization. After approval, the token is encrypted and saved.

### 9. Test Configuration

```sh
# Test OAuth2 token refresh
/usr/share/neomutt/oauth2/mutt_oauth2.py ~/.cache/mutt/oauth-gmail

# Test mail sync
mbsync -a

# Test neomutt
mutt
```

## Account Switching

In mutt:
- `,1` — Switch to Gmail account
- `,2` — Switch to account-public (if configured)
- `,3` — Switch to account-unixchad (if configured)

## Mail Sync

```sh
# Sync all accounts
mbsync -a

# Sync specific account
mbsync account-gmail

# Or use the wrapper script (updates damblocks status)
mbs
```

## File Structure

```
mutt/
├── .config/mutt/
│   ├── muttrc                      # Main config
│   ├── bindings.muttrc             # Keybindings
│   ├── colors.neomuttrc            # Color scheme
│   ├── account-gmail.muttrc.example # Gmail template
│   ├── account-unixchad.muttrc     # Example account
│   └── mailcap                     # (auto-created)
├── .config/isyncrc-gmail.example   # Gmail sync template
└── .local/bin/
    ├── mutt                        # Wrapper (updates damblocks on exit)
    ├── muttauth                    # OAuth2 token manager
    └── mbs                         # Mailbox sync wrapper
```

## Security Notes

- **No secrets in git**: Tokens, passwords, and credentials are generated locally
- **OAuth2 tokens**: Stored encrypted at `~/.cache/mutt/oauth-*`
- **GPG encryption**: Used for OAuth2 token storage and optional password storage
- **Account configs**: Contain email addresses only, safe for dotfiles repo

## Troubleshooting

### "Authentication failed" in mutt
- Verify OAuth2 token is valid: `/usr/share/neomutt/oauth2/mutt_oauth2.py ~/.cache/mutt/oauth-gmail`
- Check account config has correct email and token path
- Ensure Gmail API is enabled in Google Cloud Console

### "Permission denied" for GPG
- Ensure GPG agent is running: `gpg-connect-agent /bye`
- Verify key ID matches: `gpg --list-keys --keyid-format long`

### mbsync fails
- Check `~/.config/isyncrc` has correct paths
- Verify maildir exists: `ls ~/doc/mail/account-gmail/`
- Test with: `mbsync -l` (list channels)

## Adding More Accounts

1. Create `account-xxx.muttrc` in `~/.config/mutt/`
2. Add channel to `~/.config/isyncrc`
3. Create maildir: `mkdir -p ~/doc/mail/account-xxx`
4. For OAuth2: run `muttauth --provider {google,microsoft}`
5. For password: `echo 'set my_pass = "pass"' | gpg -e > ~/.cache/mutt/account-xxx.gpg`

## Uninstall

```sh
stow -D -t ~ mutt
rm -rf ~/.config/mutt/account-*.muttrc
rm -f ~/.config/isyncrc
rm -rf ~/doc/mail/account-*
```
