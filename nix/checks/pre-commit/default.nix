{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.git-hooks.flakeModule
  ];
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    cfg = config.pre-commit;
  in {
    devshells = {
      base = {
        # This startup script configures `pre-commit` (ie. symlinks `.pre-commit-config.yaml`)
        devshell.startup.install-git-hooks.text = config.pre-commit.shellHook;
        packages = [cfg.settings.package];
      };
    };

    packages.install-pre-commit =
      pkgs.writeShellScriptBin "install-pre-commit" config.pre-commit.installationScript;

    jail.additionalCombinators = cs:
      with cs; [
        (add-pkg-deps [cfg.settings.package])
        (add-pkg-deps cfg.settings.enabledPackages)
        (readonly cfg.settings.configFile)
      ];

    pre-commit.settings = {
      hooks = {
        actionlint.enable = true;
        deadnix.enable = true;
        markdownlint = {
          enable = true;
          package = pkgs.markdownlint-cli2;
          entry = lib.getExe pkgs.markdownlint-cli2;
          files = "\\.md$";
          pass_filenames = false;
        };
        shellcheck.enable = true;
        statix.enable = true;
        treefmt = {
          enable = true;
          package = config.packages.treefmt;
        };
      };
    };
  };
}
