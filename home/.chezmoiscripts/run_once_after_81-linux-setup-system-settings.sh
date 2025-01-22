{{ if eq .chezmoi.os "linux" -}}
#!{{ lookPath "sh" }}

set -ex

# Setup zsh shell
echo "> Using zsh shell"

# Check if zsh is the default shell
if [ "$SHELL" != "/bin/zsh" ]; then
    command -v zsh | sudo tee -a /etc/shells
    sudo chsh -s $(which zsh) $USER
    source .zshrc
fi
{{ else if eq .chezmoi.os "darwin" -}}
#!{{ lookPath "sh" }}

set -eufo pipefail

# Setup zsh shell for macOS
echo "> Using zsh shell on macOS by default"
{{ end -}}
