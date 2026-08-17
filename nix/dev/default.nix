{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
    ./pi
  ];

  perSystem = {
    config,
    inputs',
    lib,
    pkgs,
    ...
  }: {
    devshells = {
      # The devshell used by human/NixOS operators.
      default = {
        devshell = {
          inherit (config.devshells.base.devshell) startup;
        };
        motd = lib.mkForce "";
        inherit (config.devshells.base) packages;
      };
      # Shared base for common package dependencies.
      base = {
        motd = lib.mkForce "";
        packages = with pkgs; [
          bash
          coreutils
          curl
          diffutils
          fd
          file
          findutils
          gawk
          gnugrep
          gnumake
          gnused
          gnutar
          go # TODO: move to packages/devctl once it exists
          gzip
          inputs'.cpd.packages.default
          jq
          jujutsu
          less
          namespace-cli # TODO: move to packages/devctl once it exists
          nodejs
          patch
          prettier
          procps
          python3
          ripgrep
          scc
          sd
          sqlite
          tree
          unzip
          wget
          which
        ];
      };
      # The devshell used to bootstrap remote development environments.
      remote = {
        motd = lib.mkForce "";
        packages = with pkgs;
          config.devshells.base.packages
          ++ [
            config.packages.pi-unwrapped
            git # n.b. intentionally not in `base`
          ];
      };
    };

    jail.additionalCombinators = cs:
      with cs; [
        (add-pkg-deps config.devshells.base.packages)
        (readonly (noescape "~/.config/ns"))
        (readwrite (noescape "~/.config/ns/token.cache"))
      ];
  };
}
