#!/usr/bin/env bash
# Wrapper around tmux-resurrect's save.sh, used as the systemd ExecStop.
#
# save.sh legitimately fails when the server is already gone (systemd tears down
# the control group while the stop job runs), and in doing so it can leave `last`
# pointing at a 0-byte save that kills tmux on the next boot. So: ignore save.sh's
# exit status, then validate the result from outside tmux, where it still works.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resurrect_save="${script_dir}/../plugins/tmux-resurrect/scripts/save.sh"

if [ -x "$resurrect_save" ]; then
	"$resurrect_save" "$@" || true
fi

"${script_dir}/repair-resurrect-last.sh" || true

exit 0
