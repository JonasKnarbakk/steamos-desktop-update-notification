#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

systemctl --user disable --now steamos-update-notify.timer

rm "${HOME}/.local/bin/steamos-update-notify"
rm "${HOME}/.local/share/applications/steamos-update-notify.desktop"
rm "${HOME}/.config/systemd/user/steamos-update-notify.service"
rm "${HOME}/.config/systemd/user/steamos-update-notify.timer"

echo "steamos-desktop-notification uninstalled."
