#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

mkdir -p "${HOME}/.local/bin/"
mkdir -p "${HOME}/.local/share/applications/"
mkdir -p "${HOME}/.config/systemd/user/"

install -Dm755 steamos-update-notify.sh "${HOME}/.local/bin/steamos-update-notify"
install -Dm644 steamos-update-notify.desktop "${HOME}/.local/share/applications/steamos-update-notify.desktop"
install -Dm644 steamos-update-notify.service "${HOME}/.config/systemd/user/steamos-update-notify.service"
install -Dm644 steamos-update-notify.timer "${HOME}/.config/systemd/user/steamos-update-notify.timer"

systemctl --user daemon-reload
systemctl --user enable --now steamos-update-notify.timer

echo "steamos-desktop-notification installed."
