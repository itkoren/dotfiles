{
  packageOverrides = pkgs: with pkgs; {
    packages = pkgs.buildEnv {
      name = "itkoren-tools";
      paths = [
        iterm2
        htop
        direnv
        jetbrains-mono
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        curl
        gnupg
        neofetch
        sops
        fluxcd
        wget
        unzip
        bat
        lua
        rustup
        jq
        yq
        zsh
        zsh-powerlevel10k
        antigen
        zoxide
        tmux
        gnumake
        python3
        tmuxinator
        wezterm
        docker
        go
        nodejs_22
        tmuxifier
        fd
        ripgrep
        fzf
        lazygit
        kubectl
        kubectx
        yarn
      ];
    };
  };
}
