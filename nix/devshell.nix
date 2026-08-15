{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {
    config,
    inputs',
    lib,
    pkgs,
    ...
  }: {
    devshells = let
      minimal = {
        packages = with pkgs; [
          bash
          coreutils
          curl
          diffutils
          fd
          file
          findutils
          gawk
          git
          gnugrep
          gnumake
          gnused
          gnutar
          go # TODO: move to nix/packages once it exists
          gzip
          inputs'.cpd.packages.default
          jq
          less
          nodejs
          patch
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
    in {
      default = {
        imports = [minimal];
        motd = lib.mkForce "";
      };
      minimal = {
        imports = [minimal];
        motd = lib.mkForce "";
      };
    };

    jail.additionalCombinators = cs:
      with cs; [
        (add-pkg-deps config.devshells.minimal.packages)
      ];
  };
}
