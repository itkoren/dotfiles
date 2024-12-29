#!/bin/bash
set -ex

if type op >/dev/null 2>&1; then
    echo "1Password CLI is already installed"
else
    case "$(uname -s)" in
    Darwin)
        brew install --cask 1password
        brew install 1password-cli
        ;;
    *)
        echo "unsupported OS"
        exit 1
        ;;
    esac
fi

echo "Please open 1Password, log into all accounts and set the following:"
echo " - Settings>Security>Unlock activate Touch ID"
echo " - Settings>Security>Unlock activate Apple Watch"
echo " - Settings>Developer>CLI activate Integrate with 1Password CLI"
echo " - Settings>Developer>SSH Agent Set up the SSH Agent"
read -p "Press any key to continue." -n 1 -r
echo
