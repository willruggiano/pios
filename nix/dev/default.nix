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
      default = {
        motd = lib.mkForce "";
        packages = with pkgs;
          config.devshells.minimal.packages
          ++ [
            namespace-cli # TODO: move to packages/devctl once it exists
            procps
          ];
      };
      minimal = {
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
          nodejs
          patch
          prettier
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
      namespace = {
        motd = lib.mkForce "";
        packages = with pkgs;
          config.devshells.minimal.packages
          ++ [
            config.packages.pi-unwrapped
            git
          ];
      };
    };

    jail.additionalCombinators = cs:
      with cs; [
        (add-pkg-deps config.devshells.minimal.packages)
        (readonly (noescape "~/.config/ns"))
        (readwrite (noescape "~/.config/ns/token.cache"))
      ];
  };
}
