#!/bin/bash
set -ex

# Function to generate Brewfile content
function generate_brewfile() {
    local prerequisite="$1"
    local is_tap="$2"
    local is_cask="$3"

    if [ -n "$is_tap" ]; then
        echo "tap \"$prerequisite\"\n"
    elif [ -n "$is_cask" ]; then
        echo "cask \"$prerequisite\"\n"
    else
        echo "brew \"$prerequisite\"\n"
    fi
}

# Create a temporary Brewfile content
brewfile_content=""

case "$(uname -s)" in
Darwin)
    # Collect necessary Brewfile content
    brewfile_content+=$(generate_brewfile "1password/tap" 1 "")
    brewfile_content+=$(generate_brewfile "1password" "" 1)
    brewfile_content+=$(generate_brewfile "1password-cli" "" "")
    brewfile_content+=$(generate_brewfile "git-delta" "" "")

    # Use a here document to pass the Brewfile content to brew bundle
    brew bundle --no-lock --file=/dev/stdin <<EOF
$brewfile_content
EOF
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac

# Post-installation instructions
echo "Please open 1Password, log into all accounts and set the following:"
echo " - Settings>Security>Unlock activate Touch ID"
echo " - Settings>Security>Unlock activate Apple Watch"
echo " - Settings>Developer>CLI activate Integrate with 1Password CLI"
echo " - Settings>Developer>SSH Agent Set up the SSH Agent"
read -p "Press any key to continue." -n 1 -r
echo
