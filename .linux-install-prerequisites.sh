if type op >/dev/null 2>&1; then
    echo "1Password CLI is already installed"
else
    case "$(uname -s)" in
    Linux*)
        nix-env -iA nixpkgs.1password-cli
        nix-env -iA nixpkgs.git
        nix-env -iA nixpkgs.git-delta
        nix-env -iA nixpkgs.age
        ;;
    *)
        echo "unsupported OS"
        exit 1
        ;;
    esac
fi
