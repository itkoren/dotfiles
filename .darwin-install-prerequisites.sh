#!/bin/bash
set -ex

function install_prerequisite() {
    local prerequisite = "$1"
    local is_tap = "$2"
    local is_cask = "$3"

    if [ -n "$is_tap" ]; then
        brew tap "$prerequisite"
    elif [ -n "$is_cask" ]; then
        if ! brew list --cask "$prerequisite" > /dev/null 2>&1; then
            brew install --cask "$prerequisite"
        else
            read -p "$prerequisite is already installed, would you like to re-install it? (y/n): " yn
            if [[ "$yn" =~ ^[Yy]$ ]]; then
                brew install --cask --force "$prerequisite"
            fi
        fi
    else
        if ! brew list "$prerequisite" > /dev/null 2>&1; then
            brew install "$prerequisite"
        else
            read -p ""$prerequisite" is already installed, would you like to re-install it? (y/n): " yn
            if [[ "$yn" =~ ^[Yy]$ ]]; then
                brew install --force "$prerequisite"
            fi
        fi
    fi
}

case "$(uname -s)" in
Darwin)
    install_prerequisite "1password/tap" "true"
    install_prerequisite "1password" "" "true"
    install_prerequisite "1password-cli"
    install_prerequisite "git-delta"
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac

echo "Please open 1Password, log into all accounts and set the following:"
echo " - Settings>Security>Unlock activate Touch ID"
echo " - Settings>Security>Unlock activate Apple Watch"
echo " - Settings>Developer>CLI activate Integrate with 1Password CLI"
echo " - Settings>Developer>SSH Agent Set up the SSH Agent"
read -p "Press any key to continue." -n 1 -r
echo
