{ nixpkgs ? <nixpkgs>
, supportedSystems ? [ "x86_64-darwin" ]
, scrubJobs ? true
}:

let
  inherit (release) mapTestOn packagePlatforms pkgs all linux darwin;

  mapPlatforms = systems: pkgs.lib.mapAttrs (n: v: systems);

  genExample = configuration: pkgs.lib.genAttrs [ "x86_64-darwin" ] (system:
    (import ./. { inherit nixpkgs configuration system; }).system
  );

  makeTest = test:
    let
      configuration =
        { config, lib, pkgs, ... }:
        with lib;
        {
          imports = [ test ];

          options = {
            out = mkOption {
              type = types.package;
            };

            test = mkOption {
              type = types.lines;
            };
          };

          config = {
            system.build.run-test = pkgs.runCommand "darwin-test"
              { allowSubstitutes = false; preferLocalBuild = true; }
              ''
                #! ${pkgs.stdenv.shell}
                set -e

                echo >&2 "running tests for system ${config.out}"
                echo >&2
                ${config.test}
                echo >&2 ok
                touch $out
              '';

            out = config.system.build.toplevel;
          };
        };

      system = "x86_64-darwin";
    in
      (import ./. { inherit nixpkgs configuration system; }).config.system.build.run-test;

  release = import <nixpkgs/pkgs/top-level/release-lib.nix> {
    inherit supportedSystems scrubJobs;
    packageSet = import nixpkgs;
  };

  packageSet = {
    inherit (pkgs)
      stdenv bash zsh nix
      tmux reattach-to-user-namespace
      nano emacs vim;
  };

  jobs = {

    unstable = pkgs.releaseTools.aggregate {
      name = "darwin-${pkgs.lib.nixpkgsVersion}";
      constituents =
        [ jobs.stdenv.x86_64-darwin
          jobs.bash.x86_64-darwin
          jobs.zsh.x86_64-darwin
          jobs.nix.x86_64-darwin
          jobs.reattach-to-user-namespace.x86_64-darwin
          jobs.tmux.x86_64-darwin
          jobs.nano.x86_64-darwin
          jobs.vim.x86_64-darwin
          jobs.emacs.x86_64-darwin
          jobs.examples.hydra.x86_64-darwin
          jobs.examples.lnl.x86_64-darwin
          jobs.examples.simple.x86_64-darwin
        ];
      meta.description = "Release-critical builds for the darwin channel";
    };

    examples.hydra = genExample ./modules/examples/hydra.nix;
    examples.lnl = genExample ./modules/examples/lnl.nix;
    examples.simple = genExample ./modules/examples/simple.nix;

    tests.activation-scripts = makeTest ./tests/activation-scripts.nix;
    tests.checks-nix-gc = makeTest ./tests/checks-nix-gc.nix;
    tests.environment-path = makeTest ./tests/environment-path.nix;
    tests.launchd-daemons = makeTest ./tests/launchd-daemons.nix;
    tests.launchd-setenv = makeTest ./tests/launchd-setenv.nix;
    tests.networking-hostname = makeTest ./tests/networking-hostname.nix;
    tests.networking-networkservices = makeTest ./tests/networking-networkservices.nix;
    tests.nixpkgs-overlays = makeTest ./tests/nixpkgs-overlays.nix;
    tests.programs-ssh = makeTest ./tests/programs-ssh.nix;
    tests.programs-zsh = makeTest ./tests/programs-zsh.nix;
    tests.security-pki = makeTest ./tests/security-pki.nix;
    tests.services-activate-system = makeTest ./tests/services-activate-system.nix;
    tests.services-buildkite-agent = makeTest ./tests/services-buildkite-agent.nix;
    tests.services-nix-daemon = makeTest ./tests/services-nix-daemon.nix;
    tests.sockets-nix-daemon = makeTest ./tests/sockets-nix-daemon.nix;
    tests.services-nix-gc = makeTest ./tests/services-nix-gc.nix;
    tests.services-ofborg = makeTest ./tests/services-ofborg.nix;
    tests.services-offlineimap = makeTest ./tests/services-offlineimap.nix;
    tests.services-skhd = makeTest ./tests/services-skhd.nix;
    tests.services-synapse-bt = makeTest ./tests/services-synapse-bt.nix;
    tests.services-synergy = makeTest ./tests/services-synergy.nix;
    tests.services-privoxy = makeTest ./tests/services-privoxy.nix;
    tests.system-defaults-write = makeTest ./tests/system-defaults-write.nix;
    tests.system-environment = makeTest ./tests/system-environment.nix;
    tests.system-keyboard-mapping = makeTest ./tests/system-keyboard-mapping.nix;
    tests.system-packages = makeTest ./tests/system-packages.nix;
    tests.system-path = makeTest ./tests/system-path.nix;
    tests.system-shells = makeTest ./tests/system-shells.nix;
    tests.users-groups = makeTest ./tests/users-groups.nix;
    tests.users-packages = makeTest ./tests/users-packages.nix;
    tests.fonts = makeTest ./tests/fonts.nix;

  }
  // (mapTestOn (packagePlatforms packageSet));

in
  jobs
