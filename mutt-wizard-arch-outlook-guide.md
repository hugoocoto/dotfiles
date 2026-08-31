# mutt-wizard + Outlook/Microsoft 365 on Arch Linux (no AUR)

Microsoft has disabled basic authentication (plain username + password,
including app passwords) for IMAP/POP/SMTP on **Outlook.com personal
accounts** and **Microsoft 365 / Exchange Online accounts** (this includes
many Microsoft-hosted university mailboxes, even under a custom domain).

`mutt-wizard`'s built-in account wizard only tests logins with plain password
auth, so it will always report `Log-on not successful` for these accounts,
correct credentials or not. This guide sets it up with OAuth2 instead, and
builds every non-official-repo piece from source since you're not using the
AUR.

---

## Part 0 — What's official vs. what needs building from source

Arch's official repos (`pacman`) cover the core mail stack:

```bash
sudo pacman -S neomutt isync msmtp pass gnupg notmuch libnotify cronie base-devel
```

- `neomutt` — the mail client
- `isync` — provides `mbsync`, syncs IMAP to a local maildir
- `msmtp` — sends mail via SMTP
- `pass` — password store (still used for any non-Microsoft accounts)
- `gnupg` — encryption backend for `pass` and for the OAuth2 token file
- `notmuch` — mail indexing/search
- `libnotify` — desktop notifications on new mail
- `cronie` — cron daemon, for automatic background sync
- `base-devel` — compilers and build tools, needed for everything below

These three are **AUR-only**, so we build them from their upstream git/tarball
source instead:

| Package | Why it's needed |
|---|---|
| `mutt-wizard` | The tool itself |
| `cyrus-sasl-xoauth2` | SASL plugin that lets `mbsync` speak XOAUTH2 |
| `abook` (optional) | Terminal address book, integrates with neomutt |
| `pam-gnupg` (optional) | Auto-unlocks your GPG key at login, needed for unattended cron sync |

---

## Part 1 — First-time setup

### 1. Build mutt-wizard from source

```bash
cd ~/Downloads
git clone https://github.com/LukeSmithxyz/mutt-wizard
cd mutt-wizard
sudo make install
```

### 2. Build the XOAUTH2 SASL plugin from source

```bash
cd ~/Downloads
git clone https://github.com/moriyoshi/cyrus-sasl-xoauth2.git
cd cyrus-sasl-xoauth2
./autogen.sh
./configure
make
sudo make install
```

Verify it installed by checking for `libxoauth2.so` under `/usr/lib/sasl2/`.

> **If `make` complains about a missing `aclocal-X.Y`:** the shipped
> `Makefile` was generated against a different automake version than what
> you have installed. Regenerate against your actual version:
> ```bash
> autoreconf --install --force
> ./configure
> make
> ```

### 3. Get `mutt_oauth2.py`

This script handles the OAuth2 device-code login and refreshes tokens
automatically afterward.

```bash
mkdir -p ~/.local/bin
curl -o ~/.local/bin/mutt_oauth2.py \
  https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py
chmod +x ~/.local/bin/mutt_oauth2.py
```

### 4. Patch the script

Open `~/.local/bin/mutt_oauth2.py` and make two edits:

**a) Set your GPG identity** (encrypts the token file locally):
```python
ENCRYPTION_PIPE = ['gpg', '--encrypt', '--recipient', 'YOUR_GPG_IDENTITY']
```
Replace `'YOUR_GPG_IDENTITY'` with your GPG key's email or key ID (reuse the
same key you use for `pass` if you have one).

**b) Set a Microsoft `client_id`** — this ships blank, which causes
`AADSTS900144: client_id` errors. Use Mozilla Thunderbird's public,
unrestricted client ID (works even on tenants that lock down custom app
registrations):
```python
'microsoft': {
    ...
    'client_id': '9e5f94bc-e8a4-4e73-b8be-63364c29d753',
    'client_secret': '',
},
```

> If your tenant *also* rejects this client ID (`AADSTS650053`, "admin
> consent required"), you'll need your own Entra app registration — see the
> `mutt_oauth2.py` README for that process.

### 5. Authorize your first account

```bash
mutt_oauth2.py ~/.myaccount_oauth_token --verbose --authorize
```
- Registration: `microsoft`
- Flow: `devicecode`
- Email: your full address

Open the printed `microsoft.com/devicelogin` URL, enter the code, log in.

Sanity-check it works standalone (should print a token with no prompts):
```bash
mutt_oauth2.py ~/.myaccount_oauth_token
```

### 6. Scaffold the account with mw

```bash
mw -a your.address@outlook.com -i outlook.office365.com -s smtp.office365.com -x placeholder -f
```
- `-x placeholder` — dummy password, gets replaced by OAuth2
- `-f` — **critical.** Without it, mw deletes the config it just created when
  the login test fails (which it always will here, since it tests plain
  auth). `-f` forces mw to keep the files and guess standard mailbox names
  instead of testing the connection.

Confirm the files exist:
```bash
find ~ -name "*mbsyncrc"
```

### 7. Point mbsync at the OAuth2 script

In `~/.mbsyncrc`, find the `IMAPAccount` block mw generated, and change:
```
AuthMechs LOGIN
PassCmd "pass show mw-your.address@outlook.com"
```
to:
```
AuthMechs XOAUTH2
PassCmd "~/.local/bin/mutt_oauth2.py ~/.myaccount_oauth_token"
```

### 8. Point msmtp at the OAuth2 script

In `~/.config/msmtp/config` (or `~/.msmtprc`), find this account's stanza and
change:
```
auth on
passwordeval "pass show mw-your.address@outlook.com"
```
to:
```
auth xoauth2
passwordeval "~/.local/bin/mutt_oauth2.py ~/.myaccount_oauth_token"
```

### 9. Test the sync

```bash
mbsync -a -Da
```
If it hangs on a GPG passphrase prompt, run `export GPG_TTY=$(tty)` (add it
to your shell rc file) and retry.

### 10. Open neomutt

```bash
neomutt
```
No OAuth-specific muttrc changes are needed — neomutt reads the local
maildir mbsync already synced, and sends through the already-patched msmtp.

### 11. Automatic background sync

```bash
mw -t 15
```
Installs a cron job that runs `mailsync` every 15 minutes for all accounts.

Because both `pass` and the OAuth2 token need GPG to decrypt, and cron has no
terminal for an interactive prompt, unattended syncs will silently fail
unless your GPG key is already unlocked. Fix with `pam-gnupg`:

```bash
cd ~/Downloads
git clone https://github.com/cruegge/pam-gnupg.git
cd pam-gnupg
./autogen.sh
./configure --libexecdir=/usr/lib/pam-gnupg
make
sudo make install
```
Then follow the project's README for the PAM config lines to add (they go in
your login manager's PAM file, e.g. `/etc/pam.d/system-local-login` for tty
login, or your display manager's file for graphical login).

Test manually first (while logged into your normal session, so GPG is
already unlocked):
```bash
mailsync
```

To change the interval later: `mw -t <n>` (replaces the old cron entry). To
remove: `mw -t 0`.

---

## Part 2 — Adding another Microsoft/Outlook account

Once the tooling above exists, adding more accounts is fast — no rebuilding
anything.

### 1. Authorize the new account, with its own token file

```bash
mutt_oauth2.py ~/.newaccount_oauth_token --verbose --authorize
```
`microsoft` / `devicecode`, then the new address. **Use a distinct token
filename per account.**

### 2. Scaffold it with mw

```bash
mw -a new.address@outlook.com -i outlook.office365.com -s smtp.office365.com -x placeholder -f
```

### 3. Edit the new mbsyncrc block

```
AuthMechs XOAUTH2
PassCmd "~/.local/bin/mutt_oauth2.py ~/.newaccount_oauth_token"
```

### 4. Edit the new msmtp block

```
auth xoauth2
passwordeval "~/.local/bin/mutt_oauth2.py ~/.newaccount_oauth_token"
```

### 5. Test

```bash
mbsync new.address@outlook.com
```

### 6. Automatic sync already covers it

No need to rerun `mw -t` — `mailsync` loops over every account in
`~/.mbsyncrc` automatically.

### 7. Switching between accounts in neomutt

- `i1`, `i2`, `i3`, … — jump to account #1, #2, #3 (mw numbers them in the
  order added)
- `gi` / `gs` / `ga` / `gS` / `gd` — inbox / sent / archive / spam / drafts,
  within whichever account you're in

---

## Optional — abook (terminal address book), building from source

```bash
sudo pacman -S ncurses readline    # build deps beyond base-devel
cd ~/Downloads
git clone https://git.code.sf.net/p/abook/git abook
cd abook
autoreconf --install --force
./configure
make
sudo make install
```

If `make` fails with `implicit declaration of function 'isalnum'` in
`database.c`, the tarball/git snapshot is missing a header include:
```bash
sed -i '23a #include <ctype.h>' database.c
make
```

If `make` fails with `conflicting types for 'wcwidth'` in `mbswidth.c`, it's
a stale gnulib fallback prototype clashing with your glibc's own
declaration:
```bash
sed -i '66s/^int wcwidth ();$/\/* int wcwidth (); removed: conflicts with wchar.h *\//' mbswidth.c
make
```
(Check `sed -n '60,70p' mbswidth.c` first to confirm line 66 is still the
right line before patching — line numbers can shift between snapshots.)

---

## Troubleshooting reference

| Symptom | Cause | Fix |
|---|---|---|
| `Log-on not successful` from `mw -a` | mw tests plain username/password auth, which Microsoft rejects outright | Expected — this is why we patch to OAuth2; don't chase this error further |
| Config files vanish after a failed `mw -a` | mw discards account config when its login test fails | Re-run with `-f` |
| `gpg --encrypt --recipient YOUR_GPG_IDENTITY` fails, exit 2 | Placeholder never replaced in `mutt_oauth2.py` | Edit `ENCRYPTION_PIPE` with your real GPG identity |
| `AADSTS900144: client_id` missing | Script ships with an empty `client_id` for `microsoft` | Fill in a client_id (e.g. Thunderbird's public one) |
| `AADSTS650053` / admin consent required | Institution's tenant blocks even public client IDs | Requires a self-service Entra app registration, if allowed |
| Cron sync silently does nothing | GPG can't decrypt non-interactively without a terminal | Install and configure `pam-gnupg` |
| `make` fails: `aclocal-X.Y: command not found` | Tarball/snapshot was generated against a different automake version than installed | `autoreconf --install --force`, then `./configure && make` |
| `make` fails: `implicit declaration of function` | Modern GCC treats this as an error; source file is missing a standard header include | Add the missing `#include` the compiler suggests |
| `make` fails: `conflicting types for 'wcwidth'` (or similar) | Old gnulib compatibility shim conflicts with a function your glibc already declares | Comment out the standalone fallback prototype, keep the real usage |
