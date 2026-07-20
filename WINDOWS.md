# Windows (Git Bash) setup

These dotfiles are `stow`-based and assume Linux. On Windows there are no symlink
privileges by default (and `stow` needs them), and several tools are **native
Windows binaries** that don't understand MSYS/Cygwin `/c/...` paths. This guide
reproduces the Linux experience in **Git Bash** using junctions + a small shim
instead of stow.

Everything here is **per-user, no admin required**. Paths use `$USER` /
`%USERPROFILE%`; substitute your own where shown.

---

## 0. Prerequisites (install these first)

| Tool | How | Notes |
|------|-----|-------|
| **Git for Windows** | official installer | **Install per-user** (`%LOCALAPPDATA%\Programs\Git`), not system-wide — corporate policies often block writes to `C:\Program Files`. |
| **Neovim** | `winget install Neovim.Neovim` or portable | Native Windows build. |
| **Windows Terminal** | Store / `winget install Microsoft.WindowsTerminal` | Gives real truecolor via ConPTY. Use this, not the mintty "Git Bash" window. |
| **A Nerd Font** | e.g. [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) | Required for starship / nvim icons. Install per-user (double-click the TTFs → *Install*). |

Clone the repo **with submodules** (nvim config + tmux plugin manager):

```bash
git clone --recursive https://github.com/joel-scholl-amz/dotfiles.git ~/.dotfiles
```

---

## 1. Portable CLI tools → `~/.local/bin`

Download the Windows binaries (no installer) and drop them in `~/.local/bin`:

```bash
mkdir -p ~/.local/bin && cd "$(mktemp -d)"
# starship
curl -sL -o s.zip https://github.com/starship/starship/releases/latest/download/starship-x86_64-pc-windows-msvc.zip && unzip -o s.zip -d ~/.local/bin starship.exe
# zoxide
curl -sL -o z.zip "$(curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | grep -o 'https://[^\"]*x86_64-pc-windows-msvc.zip' | head -1)" && unzip -o z.zip -d ~/.local/zz && cp ~/.local/zz/zoxide.exe ~/.local/bin/ && rm -rf ~/.local/zz
# fzf
curl -sL -o f.zip "$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -o 'https://[^\"]*windows_amd64.zip' | head -1)" && unzip -o f.zip -d ~/.local/bin fzf.exe
```

`~/.local/bin` is already put on `PATH` by the repo's `bash/.bashrc`.

---

## 2. Config locations: junctions instead of symlinks

`stow` can't run, so link the config dirs manually. **Junctions** (`mklink /J`)
need no admin and no Developer Mode. Run in **PowerShell**:

```powershell
$repo = "$env:USERPROFILE\.dotfiles"
# nvim + tmux under ~/.config (Linux-style)
cmd /c mklink /J "$env:USERPROFILE\.config\nvim"  "$repo\nvim\.config\nvim"
cmd /c mklink /J "$env:USERPROFILE\.config\tmux"  "$repo\tmux\.config\tmux"
# ALSO nvim's native Windows location, so nvim finds your config no matter how
# it's launched (Explorer, VS Code, any terminal — not just Git Bash):
Move-Item "$env:LOCALAPPDATA\nvim" "$env:LOCALAPPDATA\nvim.stub-backup" -ErrorAction SilentlyContinue
cmd /c mklink /J "$env:LOCALAPPDATA\nvim" "$repo\nvim\.config\nvim"
```

> **Why the second nvim junction?** Neovim only uses `~/.config/nvim` when
> `XDG_CONFIG_HOME` is set. Launches outside Git Bash don't have it and fall back
> to `%LOCALAPPDATA%\nvim`. Junctioning both covers every launch context.

---

## 3. The Git Bash shim

Create these three files in your home directory. They source the repo copies and
add Windows-only fixes.

**`~/.bashrc`**
```bash
# Windows shim for ~/.dotfiles (stow needs symlinks; this sources the repo copy).
export STARSHIP_CONFIG="$HOME/.dotfiles/starship/.config/starship.toml"
# XDG must be WINDOWS-form: native nvim.exe can't read a POSIX "/c/..." value and
# would silently load no config.
export XDG_CONFIG_HOME="$(cygpath -m "$HOME/.config")"

. "$HOME/.dotfiles/bash/.bashrc"

# mintty needs winpty for native console apps like nvim.exe; skip it elsewhere.
if [ "$TERM_PROGRAM" = "mintty" ]; then
    alias nvim="winpty '/c/Program Files/Neovim/bin/nvim.exe'"   # adjust if nvim is per-user
fi

# fzf keybindings (the repo's Debian path doesn't exist on Windows)
command -v fzf >/dev/null && eval "$(fzf --bash)"

# Fix zoxide's broken __zoxide_pwd under MSYS (it ships `cygpath -w "\builtin pwd -L"`
# — the literal string, missing $() — so it never records any directory).
if declare -f __zoxide_pwd >/dev/null 2>&1; then
    __zoxide_pwd() { \command cygpath -w "$(\builtin pwd -L)"; }
    __zoxide_oldpwd="$(__zoxide_pwd)"
fi
```

**`~/.bash_aliases`**
```bash
. "$HOME/.dotfiles/bash/.bash_aliases"
```

**`~/.inputrc`**
```bash
$include /c/Users/<you>/.dotfiles/bash/.inputrc
```

Set `XDG_CONFIG_HOME` as a **persistent user env var** too (for apps launched
outside bash), in PowerShell:
```powershell
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
```

Open a fresh Git Bash: you should have the starship prompt, aliases, zoxide, and
nvim loading your real config.

---

## 4. tmux (optional)

Git for Windows ships no tmux. Grab the **MSYS2** build (runs on Git's runtime if
you drop it into Git's `usr\bin`). You don't need a full MSYS2 install — just the
package files:

```bash
cd "$(mktemp -d)"
base=https://mirror.msys2.org/msys/x86_64
curl -sLO $base/tmux-3.6.a-1-x86_64.pkg.tar.zst
curl -sLO $base/libevent-2.1.12-4-x86_64.pkg.tar.zst
for f in *.zst; do zstd -d "$f"; done
for f in *.pkg.tar; do tar -xf "$f"; done
GIT="$LOCALAPPDATA/Programs/Git"          # your per-user Git
cp usr/bin/tmux.exe usr/bin/msys-event*-2-1-7.dll "$GIT/usr/bin/"
# terminfo entry the tmux.conf asks for (Git's terminfo db is sparse):
# copy tmux/tmux-256color/tmux-direct from any MSYS2 install into $GIT/usr/share/terminfo/74/
```

First run installs plugins via TPM: `tmux` then `prefix + I` (prefix is
`Ctrl+Space`). Repo has `core.autocrlf false` set locally — **keep it**, or a
checkout will CRLF-poison `tmux.conf` and tmux won't parse it.

---

## 5. Windows Terminal

Make Git Bash the default and use a Nerd Font. In WT **Settings → JSON**:

```jsonc
"defaultProfile": "{2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b}",   // the Git Bash profile
"profiles": { "defaults": { "font": { "face": "JetBrainsMono Nerd Font" } } }
```

(The Git Bash profile GUID is auto-created by Git's WT fragment; find it under
`profiles.list`.) Use Windows Terminal or the VS Code terminal — **not** the
mintty Git Bash window — for correct truecolor.

---

## Gotchas (the "why" behind the fixes)

- **POSIX vs Windows paths.** Native Windows exes (`nvim.exe`, `zoxide.exe`) can't
  read `/c/...` paths. Anything you hand them (`XDG_CONFIG_HOME`, zoxide's pwd)
  must be Windows-form — use `cygpath -m` / `cygpath -w`.
- **`C:\Program Files` is often locked down.** Install Git/Neovim **per-user**.
- **CRLF.** Keep `core.autocrlf false` in this repo; CRLF breaks `tmux.conf`.
- **mintty vs ConPTY.** In mintty, nvim runs via winpty (imperfect colors); in
  Windows Terminal / VS Code it runs directly with full truecolor.
- **Antivirus.** Behavioral AV (e.g. Defender) sometimes false-positives on
  MSYS2 processes — if a binary "disappears" or a spawn hangs, check quarantine
  before assuming corruption.
```
