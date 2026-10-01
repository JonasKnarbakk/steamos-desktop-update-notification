#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

if systemctl --user list-unit-files steamos-update-notify.timer &>/dev/null; then
    systemctl --user disable --now steamos-update-notify.timer
fi

rm -f "${HOME}/.local/bin/steamos-update-notify"
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/applications/steamos-update-notify.desktop"
rm -f "${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user/steamos-update-notify.service"
rm -f "${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user/steamos-update-notify.timer"
rm -rf "${XDG_STATE_HOME:-${HOME}/.local/state}/steamos-update-notify"

echo "steamos-desktop-notification uninstalled."
