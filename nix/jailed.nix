{
  inputs,
  flake-parts-lib,
  ...
}: {
  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.jail;

    gitconfigFor = programCfg:
      lib.generators.toGitINI (lib.recursiveUpdate cfg.git programCfg.git);

    combinatorsType = lib.mkOptionType {
      name = "combinators";
      description = "jail.nix combinator function (cs -> [combinators])";
      check = builtins.isFunction;
      merge = _loc: defs: cs: lib.concatMap (def: def.value cs) defs;
    };

    programModule = lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options = {
        package = lib.mkOption {
          type = lib.types.package;
          description = "The unwrapped package to jail.";
        };

        git = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = "Per-program gitconfig overrides, merged with jail.git.";
        };

        additionalCombinators = lib.mkOption {
          type = combinatorsType;
          default = _: [];
          description = "Additional jail.nix combinators for this program.";
        };

        build.wrapped = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "The jailed package (read-only, computed).";
        };
      };

      config.build.wrapped = let
        jail = inputs.jail.lib.extend {
          inherit pkgs;
          basePermissions = cs:
            with cs; [
              base
              bind-nix-store-runtime-closure
              fake-passwd
              gpu
              mount-cwd
              network
              open-urls-in-browser
              readonly-runtime-args
              time-zone
              (ro-bind "${pkgs.coreutils}/bin/env" "/usr/bin/env")
              (set-env "SHELL" "${lib.getExe pkgs.bash}")
              (write-text "/etc/gitconfig" (gitconfigFor config))
              # ensure isolated workspaces have access to the root git/jj db
              (add-runtime ''
                git_root=$(git rev-parse --git-common-dir 2>/dev/null)
                git_root=$(dirname "$git_root")
                if [ -n "$git_root" ] && [ "$git_root" != "$PWD" ]; then
                  for f in .git .jj; do
                    [ -d "$git_root/$f" ] && RUNTIME_ARGS+=(--bind "$git_root/$f" "$git_root/$f")
                  done
                fi
              '')
            ];
        };

        combinators = cs:
          (cfg.additionalCombinators cs) ++ (config.additionalCombinators cs);

        drv = jail name config.package combinators;
      in
        drv
        // {
          name = "${config.package.name}-jailed";
          unjailed = config.package;
        };
    });
  in {
    options.jail = {
      git = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Gitconfig attrset, passed directly to lib.generators.toGitINI.";
      };

      additionalCombinators = lib.mkOption {
        type = combinatorsType;
        default = _: [];
        description = "Additional jail.nix combinators applied to all programs.";
      };

      programs = lib.mkOption {
        type = lib.types.attrsOf programModule;
        default = {};
        description = "Programs to jail.";
      };
    };
  });
}
