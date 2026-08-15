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
          go # TODO: move to packages/devctl once it exists
          gzip
          inputs'.cpd.packages.default
          jq
          less
          namespace-cli # TODO: move to packages/devctl once it exists
          nodejs
          patch
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
        (readonly (noescape "~/.config/ns"))
        (readwrite (noescape "~/.config/ns/token.cache"))
      ];
  };
}
