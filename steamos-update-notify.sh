#!/usr/bin/env bash

# Check for SteamOS updates and show a persistent KDE notification with action buttons.
# Set STEAMOS_NOTIFY_DEBUG=1 to also get a notification when no update is available.

# Runs inside the Konsole window: performs the update and prints extra context around
# atomupd-manager's progress output. Handled before the lock, which the parent holds.
if [[ "$1" == "--run-update" ]]; then
    local id="$2"
    local bold=$'\e[1m' green=$'\e[32m' red=$'\e[31m' reset=$'\e[0m'
    source /etc/os-release 2>/dev/null

    echo "${bold}=== SteamOS Update ===${reset}"
    echo
    echo "Current version:  ${VERSION_ID:-unknown} (build ${BUILD_ID:-unknown})"
    echo "Target build:     ${id:-unknown}"
    if [[ -n "${UPDATE_DETAILS}" ]]; then
        echo
        echo "${bold}Update details:${reset}"
        sed 's/^/  /' <<< "${UPDATE_DETAILS}"
    fi
    echo
    echo "Started at $(date '+%H:%M:%S'). Downloading and applying the update."
    echo

    start=${SECONDS}
    atomupd-manager update ${id}
    rc=$?
    elapsed=$(( SECONDS - start ))
    status=$(atomupd-manager get-update-status 2>/dev/null)

    echo
    echo "Finished at $(date '+%H:%M:%S') after $(( elapsed / 60 ))m $(( elapsed % 60 ))s."
    echo "atomupd-manager exit code: ${rc}, update status: ${status:-unknown}"
    echo
    if [[ "${status}" == "successful" ]]; then
        echo "${green}${bold}Update installed successfully.${reset}"
        echo "Close this window, then use the notification to reboot into build ${id}."
    else
        echo "${red}${bold}Update did not complete.${reset}"
        echo "Check the output above, or the logs with: journalctl -b -u atomupd"
    fi
    echo
    read -rp "Press Enter to close"
    exit 0
fi

# Only one instance at a time. The lock is held while a notification is waiting for a click.
# Additional instances triggered by the systemd timer exit early.
LOCK="${XDG_RUNTIME_DIR:-/tmp}/steamos-update-notify.lock"
exec 9> "${LOCK}"
flock -n 9 || { echo "Another instance is running, exiting."; exit 0; }

APP_NAME="SteamOS Updates"
NOTIFY_ARGS=(
  -a "${APP_NAME}"
  -h string:desktop-entry:steamos-update-notify
  -h boolean:transient:false
  -u normal
  -t 0
)

notify()
{
    notify-send "${NOTIFY_ARGS[@]}" "$@";
}

# Shows a notification with actions and blocks until one is clicked or it is dismissed.
# Prints the chosen action key (empty if dismissed).
ask()
{
    notify --wait "$@" 2>/dev/null;
}

offer_reboot() {
    local choice
    choice=$(ask -i system-reboot \
        -A reboot="Reboot now" \
        "SteamOS update installed" "Reboot to finish applying the update.")
    if [[ "${choice}" == "reboot" ]]; then
        systemctl reboot
    fi
}

run_update() {
    local id="$1"
    local cmd="atomupd-manager update ${id}"
    if command -v konsole >/dev/null; then
        # --separate so the call blocks until the window is closed
        konsole --separate -p tabtitle="SteamOS Update" -e "$(realpath "$0")" --run-update "${id}"
    else
        notify -i system-software-update "${APP_NAME}" "Installing update ${id}..."
        ${cmd}
    fi

    case "$(atomupd-manager get-update-status 2>/dev/null)" in
        successful) offer_reboot ;;
        *) notify -i dialog-error "SteamOS update failed" \
               "Update ${id} did not complete. Run 'atomupd-manager update ${id}' manually for details." ;;
    esac
}

# An update was already applied but the system has not been rebooted yet.
case "$(atomupd-manager get-update-status 2>/dev/null)" in
    successful)
        offer_reboot
        exit 0
        ;;
    in_progress)
        echo "Update already in progress."
        exit 0
        ;;
esac

UPDATE_STATUS=$(atomupd-manager check 2>/dev/null) || exit 0

if [[ -z "${UPDATE_STATUS}" || "${UPDATE_STATUS}" == *"No update available"* ]]; then
    echo "No update available"
    if [[ -n "${STEAMOS_NOTIFY_DEBUG}" ]]; then
        notify -i system-software-update "SteamOS" "No update available"
    fi
    exit 0
fi

ID=$(grep -oP 'ID:\s*\K\S+' <<< "${UPDATE_STATUS}" | head -n1)

choice=$(ask -i system-software-update \
    -A update="Update now" \
    "SteamOS update available" "Build ${ID:-unknown} is ready to install.")

if [[ "${choice}" == "update" ]]; then
    run_update "${ID}"
fi

exit 0
