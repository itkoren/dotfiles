#!/usr/bin/env bash

set -Eeufo pipefail

trap 'echo "Error at line $LINENO: $BASH_COMMAND"' ERR

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# shellcheck disable=SC2016
declare -r DOTFILES_LOGO='
                          /$$                                      /$$
                         | $$                                     | $$
     /$$$$$$$  /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$      /$$$$$$$| $$$$$$$
    /$$_____/ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$    /$$_____/| $$__  $$
   |  $$$$$$ | $$$$$$$$  | $$    | $$  | $$| $$  \ $$   |  $$$$$$ | $$  \ $$
    \____  $$| $$_____/  | $$ /$$| $$  | $$| $$  | $$    \____  $$| $$  | $$
    /$$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$//$$ /$$$$$$$/| $$  | $$
   |_______/  \_______/   \___/   \______/ | $$____/|__/|_______/ |__/  |__/
                                           | $$
                                           | $$
                                           |__/

             *** This is setup script for my dotfiles setup ***            
                     https://github.com/itkoren/dotfiles
'

declare -r DOTFILES_USER_OR_REPO_URL="itkoren"
declare -r BRANCH_NAME="${BRANCH_NAME:-main}"
declare -r DOTFILES_GITHUB_PAT="${DOTFILES_GITHUB_PAT:-}"
declare -r CI="${CI:-false}"

function is_ci() {
    [[ "${CI}" == "true" ]]
}

function is_tty() {
    # Check if the script is running in an interactive terminal
    if [ -t 1 ]; then
        echo "Interactive terminal detected"
        return 0 # true
    else
        echo "Non-interactive terminal detected"
        return 1 # false
    fi
}

function is_not_tty() {
    ! is_tty
}

# Improved check for CI or non-TTY
function is_ci_or_not_tty() {
    if is_ci; then
        echo "CI: true"
        return 0  # CI environment, no input needed
    elif is_not_tty; then
        echo "CI: false, Non-interactive terminal detected"
        return 0  # Non-interactive terminal
    else
        echo "CI: false, Interactive terminal detected"
        return 1  # Interactive terminal
    fi
}

function at_exit() {
    AT_EXIT+="${AT_EXIT:+$'\n'}"
    AT_EXIT+="${*?}"
    # shellcheck disable=SC2064
    trap "${AT_EXIT}" EXIT
}

function get_os_type() {
    uname
}

function keepalive_sudo_linux() {
    # Might as well ask for password up-front, right?
    echo "Checking for \`sudo\` access which may request your password."
    sudo -v || { echo "sudo failed!"; exit 1; }

    # Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

function keepalive_sudo_macos() {
    # ref. https://github.com/reitermarkus/dotfiles/blob/master/.sh#L85-L116
    (
        builtin read -r -s -p "Password: " </dev/tty
        builtin echo "add-generic-password -U -s 'dotfiles' -a '${USER}' -w '${REPLY}'"
    ) | /usr/bin/security -i
    printf "\n"
    at_exit "
                echo -e '\033[0;31mRemoving password from Keychain …\033[0m'
                /usr/bin/security delete-generic-password -s 'dotfiles' -a '${USER}'
            "
    SUDO_ASKPASS="$(/usr/bin/mktemp)"
    at_exit "
                echo -e '\033[0;31mDeleting SUDO_ASKPASS script …\033[0m'
                /bin/rm -f '${SUDO_ASKPASS}'
            "
    {
        echo "#!/bin/sh"
        echo "/usr/bin/security find-generic-password -s 'dotfiles' -a '${USER}' -w"
    } >"${SUDO_ASKPASS}"

    /bin/chmod +x "${SUDO_ASKPASS}"
    export SUDO_ASKPASS

    if ! /usr/bin/sudo -A -kv 2>/dev/null; then
        echo -e '\033[0;31mIncorrect password.\033[0m' 1>&2
        exit 1
    fi
}

function keepalive_sudo() {

    local ostype
    ostype="$(get_os_type)"

    if [ "${ostype}" == "Darwin" ]; then
        keepalive_sudo_macos
    elif [ "${ostype}" == "Linux" ]; then
        keepalive_sudo_linux
    else
        echo "Invalid OS type: ${ostype}" >&2
        exit 1
    fi
}

function initialize_os_macos() {
    function is_homebrew_exists() {
        command -v brew &>/dev/null
    }

    # Install the Xcode Command Line Tools.
    if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
        echo "===> Installing Xcode Command Line Tools"

        # Check if the softwareupdate --list command includes CLT, but just in case it's missing, fall back to `xcode-select`
        softwareupdate_output=$(softwareupdate --list)
        echo "softwareupdate output: $softwareupdate_output"  # Debugging line
    
        # Try installing Command Line Tools using xcode-select if they're not listed
        #if [[ "$softwareupdate_output" =~ "Command Line Tools" ]]; then
            # Attempt to install CLT from softwareupdate if it's listed
        #    CLT_PACKAGE=$(echo "$softwareupdate_output" | grep -B 1 "Command Line Tools" \
        #        | awk -F"*" '/^ *\*/ {print $2}' \
        #        | sed -e 's/^ *Label: //' -e 's/^ *//' \
        #        | sort -V \
        #        | tail -n1)
            
        #    if [ -z "$CLT_PACKAGE" ]; then
        #        echo "No CLT package found. Triggering install via xcode-select."
        #        xcode-select --install
        #    else
        #        echo "Installing Command Line Tools package: $CLT_PACKAGE"
        #        sudo softwareupdate --install "$CLT_PACKAGE" || { echo "Failed to install Command Line Tools"; exit 1; }
        #    fi
        #else
            # If no CLT package found, just trigger install via xcode-select
            echo "Command Line Tools not listed in softwareupdate output. Installing via xcode-select..."
            xcode-select --install
        #fi
    
        # Check if xcode-select --install succeeded
        if [ $? -eq 0 ]; then
            # Wait for user to manually complete installation
            echo "You may need to manually complete the installation of Xcode Command Line Tools. Press [Enter] to continue once installation is complete."
            
            # Wait for user input after installation is completed
            read -p "Press [Enter] once you've installed Xcode Command Line Tools and are ready to continue."
        
            # Verify if the installation was successful
            until [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]; do
                echo "Waiting for Command Line Tools to be installed..."
                sleep 5
            done
        
            echo "Successfully installed Xcode Command Line Tools."
        else
            echo "Failed to trigger installation of Command Line Tools. Please install manually."
            exit 1
        fi

        # Accept T&Cs
        if /usr/bin/xcrun clang 2>&1 | grep $Q license; then
          sudo xcodebuild -license
        fi
    fi

    # Instal Homebrew if needed.
    if ! is_homebrew_exists; then
        echo '🍺  Installing Homebrew'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is already installed"
    fi

    # Setup Homebrew envvars.
    if [[ $(arch) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ $(arch) == "i386" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        echo "Invalid CPU arch: $(arch)" >&2
        exit 1
    fi
}

function initialize_os_linux() {
    :
}

function initialize_os_env() {
    local ostype
    ostype="$(get_os_type)"

    if [ "${ostype}" == "Darwin" ]; then
        initialize_os_macos
    elif [ "${ostype}" == "Linux" ]; then
        initialize_os_linux
    else
        echo "Invalid OS type: ${ostype}" >&2
        exit 1
    fi
}

function run_chezmoi() {
    function is_chezmoi_exists() {
        command -v chezmoi &>/dev/null
    }

    local chezmoi_cmd
    local no_tty_option
    echo "going to check chezmoi requirements"
    if ! is_chezmoi_exists; then
        # install chezmoi via brew or download the chezmoi binary from the URL
        if ! is_ci_or_not_tty; then
            read -p "Do you wish to skip install chezmoi? (y/n): " yn
        else
            yn="n" # If non-interactive, assume they want to skip
        fi
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            # Download chezmoi binary
            echo '👊  Temporary downloading chezmoi binary'
            sh -c "$(curl -fsLS get.chezmoi.io)"
            chezmoi_cmd="./bin/chezmoi"
        else
            # Install chezmoi using brew
            echo '👊  Installing chezmoi'
            brew install chezmoi
            chezmoi_cmd=$(which chezmoi)
        fi
    fi    

    if is_ci_or_not_tty; then
        no_tty_option="--no-tty" # /dev/tty is not available (especially in the CI)
    else
        no_tty_option="" # /dev/tty is available OR not in the CI
    fi
    if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
      echo "🚸  chezmoi already initialized"
    else
      echo "🚀  Initialize dotfiles with:"
    fi

    # run `chezmoi init` to setup the source directory,
    # generate the config file, and optionally update the destination directory
    # to match the target state.
    "${chezmoi_cmd}" init -v "${DOTFILES_USER_OR_REPO_URL}" \
        --force \
        --branch "${BRANCH_NAME}" \
        --use-builtin-git true \
        ${no_tty_option}

    # the `age` command requires a tty, but there is no tty in the github actions.
    # Therefore, it is currnetly difficult to decrypt the files encrypted with `age` in this workflow.
    # I decided to temporarily remove the encrypted target files from chezmoi's control.
    if is_ci_or_not_tty; then
        find "$(${chezmoi_cmd} source-path)" -type f -name "encrypted_*" -exec rm -fv {} +
    fi

    # Add to PATH for installing the necessary binary files under `$HOME/.local/bin`.
    export PATH="${PATH}:${HOME}/.local/bin"
    
    if [[ -n "${DOTFILES_GITHUB_PAT}" ]]; then
        export DOTFILES_GITHUB_PAT
    fi

    # run `chezmoi apply` to ensure that target... are in the target state,
    # updating them if necessary.
    "${chezmoi_cmd}" apply ${no_tty_option}

    if [[ "$yn" =~ ^[Yy]$ ]]; then
        # purge the binary of the chezmoi cmd
        rm -fv "${chezmoi_cmd}"
    fi
}

function initialize_dotfiles() {
    if ! is_ci_or_not_tty; then
        # - /dev/tty of the github workflow is not available.
        # - We can use password-less sudo in the github workflow.
        # Therefore, skip the sudo keep alive function.
        keepalive_sudo
    fi
    run_chezmoi
}

function get_system_from_chezmoi() {
    local system
    system=$(chezmoi data | jq -r '.system')
    echo "${system}"
}

function restart_shell_system() {
    local system
    system=$(get_system_from_chezmoi)

    # exec shell as login shell (to reload the .zprofile or .profile)
    if [ "${system}" == "client" ]; then
        /bin/zsh --login

    elif [ "${system}" == "server" ]; then
        /bin/bash --login

    else
        echo "Invalid system: ${system}; expected \`client\` or \`server\`" >&2
        exit 1
    fi
}

function restart_shell() {

    # Restart shell if specified "bash -c $(curl -L {URL})"
    # not restart:
    #   curl -L {URL} | bash
    if [ -p /dev/stdin ]; then
        echo "Now continue with Rebooting your shell"
    else
        echo "Restarting your shell..."
        restart_shell_system
    fi
}

function main() {

    echo ""
    echo "🤚  This script will setup .dotfiles for you."

    if ! is_ci_or_not_tty; then
        echo "Interactive terminal detected, waiting for input."
        
        # Ask the user if they want to continue, but only in interactive environments
        if is_tty; then
            # Prompt user for input
            read -p "Do you wish to continue? (y/n): " response
        
            # Convert response to lowercase for case-insensitive comparison
            response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
            echo "User input: $response"  # Debugging output
            
            # Handle response validation
            if [[ "$response" == "y" ]]; then
                echo "Continuing with dotfiles setup..."
            else
                echo "Exiting the script."
                exit 0
            fi
        else
            echo "Skipping prompt, as this is a non-interactive terminal."
        fi
    else
        echo "Skipping prompt in non-interactive or CI environment."
    fi
    
    echo "$DOTFILES_LOGO"

    echo "Initializing OS environment..."
    initialize_os_env
    echo "Setting up dotfiles..."
    initialize_dotfiles

    # restart_shell # Disabled because the at_exit function does not work properly.
}

main
