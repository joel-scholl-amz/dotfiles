#!/usr/bin/env bash
# tmux-resurrect post-save-layout hook.
#
# Bug it works around: resurrect's save_all() re-points the `last` symlink to
# whatever it just wrote, with no check for empty content. If a save fires while
# the server has no panes (teardown, or the boot/restore race with
# @continuum-boot), it writes a 0-byte file and `last` ends up pointing at it.
# On next boot @continuum-restore reads the empty `last` and tmux crashes.
#
# This hook runs immediately before the symlink swap and receives the path to
# the file resurrect just wrote ($1). If that file is empty, we overwrite it
# with the contents of the current good `last` save. resurrect then sees the two
# files as identical (files_differ == false), deletes the new file, and leaves
# `last` pointing at the good save instead of clobbering it.
set -euo pipefail

new_file="${1:-}"
[ -n "$new_file" ] || exit 0

# Non-empty save: nothing to do, let resurrect proceed normally.
[ -s "$new_file" ] && exit 0

last_link="$(dirname "$new_file")/last"

# Only intervene if we have a previous, non-empty save to fall back to.
if [ -e "$last_link" ] && [ -s "$last_link" ]; then
	cat "$last_link" > "$new_file"
fi

exit 0
