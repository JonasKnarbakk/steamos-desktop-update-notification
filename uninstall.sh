#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

systemctl --user disable --now steamos-update-notify.timer

rm -f "${HOME}/.local/bin/steamos-update-notify"
rm -f "${HOME}/.local/share/applications/steamos-update-notify.desktop"
rm -f "${HOME}/.config/systemd/user/steamos-update-notify.service"
rm -f "${HOME}/.config/systemd/user/steamos-update-notify.timer"
rm -f "${XDG_STATE_HOME:-${HOME}/.local/state}/steamos-update-notify"

echo "steamos-desktop-notification uninstalled."
