#!/usr/bin/env bash

# Installs from the local checkout if run from one, otherwise downloads the main branch:
# curl -fsSL https://raw.githubusercontent.com/JonasKnarbakk/steamos-desktop-update-notification/main/install.sh | bash

set -euo pipefail

REPO="JonasKnarbakk/steamos-desktop-update-notification"
TARBALL="https://github.com/${REPO}/archive/refs/heads/main.tar.gz"

# Wrapped in a function so a partially downloaded script never runs.
main() {
    local src
    src="$(dirname "${BASH_SOURCE[0]:-}")"

    if [[ ! -f "${src}/steamos-update-notify.sh" ]]; then
        local tmp
        tmp="$(mktemp -d)"
        trap 'rm -rf "${tmp}"' EXIT
        echo "Downloading ${TARBALL}"
        curl -fsSL "${TARBALL}" | tar -xz -C "${tmp}" --strip-components=1
        src="${tmp}"
    fi

    cd "${src}"

    install -Dm755 steamos-update-notify.sh "${HOME}/.local/bin/steamos-update-notify"
    install -Dm644 steamos-update-notify.desktop "${HOME}/.local/share/applications/steamos-update-notify.desktop"
    install -Dm644 steamos-update-notify.service "${HOME}/.config/systemd/user/steamos-update-notify.service"
    install -Dm644 steamos-update-notify.timer "${HOME}/.config/systemd/user/steamos-update-notify.timer"

    systemctl --user daemon-reload
    systemctl --user enable --now steamos-update-notify.timer

    echo "steamos-desktop-notification installed."
}

main "$@"
