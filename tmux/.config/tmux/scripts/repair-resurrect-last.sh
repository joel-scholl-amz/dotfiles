#!/usr/bin/env bash
# Validate (and if needed repair) the tmux-resurrect `last` symlink.
#
# Bug it works around: resurrect's check_saved_session_exists() tests `-f`, not
# `-s`, so an empty save file passes. Restore then finds nothing to restore and
# handle_session_0() kills session `0` -- which, on a @continuum-boot start, is
# the only session there is. The server drops to zero sessions and exits, and
# tmux appears to "crash" ~1.6s into boot.
#
# Empty saves get written when save.sh races the server teardown at shutdown
# (KillMode=control-group), dumping nothing and then repointing `last` at it.
#
# Deliberately depends on nothing but the filesystem: the case that matters most
# is precisely the one where no tmux server is running, so anything routed
# through `tmux show-option` (i.e. resurrect's own hook mechanism) cannot help.
#
# Used from two places:
#   - save-and-verify.sh, after every save
#   - @resurrect-hook-pre-restore-all, before restore reads `last`
set -uo pipefail

resurrect_dir="${TMUX_RESURRECT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect}"
last_link="$resurrect_dir/last"

[ -d "$resurrect_dir" ] || exit 0

# Healthy: `last` resolves to a non-empty file. Nothing to do.
[ -s "$last_link" ] && exit 0

# Remember what the broken link pointed at so we can clean it up afterwards.
broken_target=""
[ -L "$last_link" ] && broken_target="$(readlink -f "$last_link" 2>/dev/null || true)"

good="$(find "$resurrect_dir" -maxdepth 1 -name 'tmux_resurrect_*.txt' -type f -size +0c \
	-printf '%T@ %f\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"

if [ -n "$good" ]; then
	ln -fs "$good" "$last_link"
	echo "repair-resurrect-last: repointed 'last' -> $good" >&2
else
	# No usable save at all. Drop `last` so check_saved_session_exists() returns
	# 1 and restore is skipped cleanly, rather than proceeding into
	# handle_session_0() with nothing restored.
	rm -f "$last_link"
	echo "repair-resurrect-last: no non-empty save found, removed 'last'" >&2
fi

# Bin the empty file so it can never be selected again.
if [ -n "$broken_target" ] && [ -f "$broken_target" ] && [ ! -s "$broken_target" ]; then
	rm -f "$broken_target"
fi

# Never fail a systemd stop job or a restore.
exit 0
