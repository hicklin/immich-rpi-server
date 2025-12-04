{ config, pkgs, ... }:

{
    environment.systemPackages = [
        pkgs.zsh
    ];

    environment.shells = [ pkgs.zsh ];

    # Enable zsh and the oh-my-zsh module
    programs.zsh = {
        enable = true;
        syntaxHighlighting.enable = true;
        autosuggestions.enable = true;
        autosuggestions.highlightStyle = "fg=cyan";

        # Adds History Substring Search plugin
        interactiveShellInit = ''
            source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

            # Key bindings for history search
            bindkey "$terminfo[kcuu1]" history-substring-search-up
            bindkey "$terminfo[kcud1]" history-substring-search-down

            HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
            HISTORY_SUBSTRING_SEARCH_PREFIXED=1
            unset HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND
            unset HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND
        '';

        histSize = 1000;

        # Using the dedicated 'shellAliases' option.
        shellAliases = {
            switch = "sudo nixos-rebuild switch";

            ll = "ls -l";
            la = "ls -la";

            mv="mv -iv";
            cp="cp -iv";
            rm="rm -iv";
            df="df -h";
            du="du -h";
            mkdir="mkdir -p";

            k9="kill -9";
        };
    };

    users.defaultUserShell = pkgs.zsh;
}
