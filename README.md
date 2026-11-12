# Nixbox

## installation

1. clone this repo, e.g., `git clone https://github.com/JyJyJcr/nixbox.git`
2. link `bin/nixboxctl` to anywhere in your PATH, e.g., `ln -s $(pwd)/nixboxctl ~/.local/bin/`
3. run `nixboxctl install`

you can now run `nixboxctl login bash -l` to enter an environment where `/nix` is available.

## update

1. `git pull` to update this repository.
2. `nixboxctl install` to apply any updates.

## appendix 1: single user nix setup

1. enter the nixbox environment, e.g., `nixboxctl login bash -l`
2. install single user nix, e.g., `curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon`
3. create user nix conf dir, e.g., `mkdir -p ~/.config/nix`
4. edit the nix conf, e.g., `vim ~/.config/nix/nix.conf`

    ```conf
    experimental-features = nix-command flakes
    substituters = https://cache.nixos.org/ https://cache.nixos-cuda.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=
    sandbox = true
    sandbox-fallback = false
    ```

    (this example includes customization for cuda users)

you can now use the single user nix installation within the nixbox environment.

## appendix 2: home-manager setup

1. init home-manager conf, e.g., `nix run home-manager/master init`
2. edit `flake.nix`, e.g., `vim .config/home-manager/flake.nix`

    ```nix
    nixos-26.05
    release-26.05
    ```

3. edit `home.nix` as desired, e.g., `vim .config/home-manager/home.nix`
4. run `nix run home-manager/master -- switch`

you can now use the home-manager managed user profile within the nixbox environment.

## appendix 3: bash profile patching

1. edit `home.nix` as

    ```nix
    {
      home.file = {
        ".bashrc".force = true;
        ".bash_profile".force = true;
        ".profile".force = true;
      };
      home.activation.patchBashProfile = let
        homedir = lib.strings.escapeShellArg config.home.homeDirectory;
      in
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        for rcfile in .bash_profile .bashrc .profile; do
          target=${homedir}/"$rcfile"
          managed="''${target}.hm"
          master="''${target}.master"

          if [ ! -e "$master" ]; then
            if [ -z "''${DRY_RUN:-}" ]; then
              run cat > "$master" << EOF
        if [ -f "\$HOME/$rcfile.hm" ]; then
          . "\$HOME/$rcfile.hm"
        elif [ -f "\$HOME/$rcfile.bare" ]; then
          . "\$HOME/$rcfile.bare"
        fi
        EOF
            fi
          fi

          run rm -rf "$managed"
          run mv "$target" "$managed"
          run ln -sfn "$master" "$target"
        done
      '';
      home.shell.enableBashIntegration = true;
      programs.bash = {
        enable = true;

        profileExtra = ''
          if [ -e "$HOME"/.nix-profile/etc/profile.d/nix.sh ]; then . "$HOME"/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix MANUAL install
        '';
      };
    }
    ```

2. run `mv .profile .profile.bare; mv .bashrc .bashrc.bare`
3 create `.bash_profile.bare` as:
    ```bash
    # we are not in sandbox

    if [[ ! -f "$HOME/.no_nixbox" && "$DENY_NIXBOX" != 1 ]] || [[ "$FORCE_NIXBOX" = 1 ]]; then
      # Enter sandbox.
      exec "$HOME/.local/bin/nixboxctl" login "$HOME/.nix-profile/bin/bash" -l
    fi
    # use bare environment.

    # temporary use: `ssh quetta -t "DENY_NIXBOX=1 bash -l"`
    # permanent use: `touch ~/.no_nixbox`

    # originally there's no .bash_profile, so redirect to .profile.
    [[ -f ~/.profile ]] && . ~/.profile
    ```
4. run `home-manager switch`

you are now set up to automatically enter the nixbox environment upon login.

## appendix 4: slurm

inside nixbox, you should run `srun nixboxctl recover` to restore your environment on the compute node.
