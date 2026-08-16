{
  perSystem = {
    config,
    inputs',
    lib,
    pkgs,
    ...
  }: {
    devshells.default.packages = [config.packages.pi];

    jail = {
      programs.pi = {
        additionalCombinators = cs:
          with cs; [
            (add-pkg-deps [config.packages.pi-unwrapped])
            (readwrite (noescape "~/.pi"))
          ];
        git = {
          user.email = "noreply@pi.dev";
          user.name = config.packages.pi-unwrapped.name;
        };
        package = config.packages.pi-unwrapped;
      };
    };

    packages = lib.mkMerge [
      {
        pi-unwrapped = inputs'.agents.packages.pi;
      }
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        pi = config.jail.programs.pi.build.wrapped;
      })
    ];
  };
}
