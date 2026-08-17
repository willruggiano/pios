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
        inherit (config.devshells.minimal) packages;
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
      namespace = {
        motd = lib.mkForce "";
        packages = with pkgs;
          config.devshells.minimal.packages
          ++ [
            config.packages.pi-unwrapped
            git # n.b. intentionally not in `minimal`
          ];
      };
    };

    jail.additionalCombinators = cs:
      with cs; [
        (add-pkg-deps config.devshells.namespace.packages)
        (readonly (noescape "~/.config/ns"))
        (readwrite (noescape "~/.config/ns/token.cache"))
      ];
  };
}
