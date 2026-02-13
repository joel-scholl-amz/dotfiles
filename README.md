# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

- `git`
- `stow` (e.g., `sudo apt install stow` or `nix-env -iA nixpkgs.stow`)
- `nvim`
- `starship`
- `zoxide`
- `tmux`
- `cargo`

## Setup

```bash
git clone --recursive https://github.com/joel-scholl-amz/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow */
```

This creates symlinks from your home directory into the repo. For example, `~/.bashrc` will point to `~/.dotfiles/bash/.bashrc`.

To install only specific packages:

```bash
stow bash git tmux
```

To uninstall a package (removes its symlinks):

```bash
stow -D tmux
```

> **Note:** If stow reports conflicts, it means a real file already exists at the target location. Back it up or remove it, then re-run `stow`.
## Software Dependencies
- zoxide
- starship
- rustup

## Packages

| Package    | What it configures                  |
|------------|-------------------------------------|
| `bash`     | `.bashrc`, `.bash_aliases`          |
| `git`      | `.gitconfig`                        |
| `starship` | Starship prompt (`starship.toml`)   |
| `tmux`     | tmux config and plugin manager      |
| `nvim`     | Neovim (kickstart.nvim, submodule)  |
| `k9s`      | K9s Kubernetes TUI                  |
| `dlv`      | Delve Go debugger                   |
| `uv`       | uv Python package manager           |

## Neovim (kickstart.nvim)

The `nvim` package is a [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) pointing to a fork of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).

### Editing your Neovim config

Since `~/.config/nvim` is a symlink into the submodule, any edits you make are inside the submodule's repo. To commit changes:

```bash
cd ~/.dotfiles/nvim/.config/nvim
git add -A && git commit -m "your message"
git push
```

Then update the parent repo to track the new submodule commit:

```bash
cd ~/.dotfiles
git add nvim/.config/nvim
git commit -m "update nvim config"
```

### Pulling upstream kickstart.nvim updates

```bash
cd ~/.dotfiles/nvim/.config/nvim
git remote add upstream https://github.com/nvim-lua/kickstart.nvim.git  # only needed once
git fetch upstream
git merge upstream/master
```

Resolve any conflicts, then commit and push as above.

## Tmux plugins

Tmux plugins are managed by [TPM](https://github.com/tmux-plugins/tpm). After stowing, install plugins by starting tmux and pressing `prefix + I` (default prefix is `Ctrl+Space`).
