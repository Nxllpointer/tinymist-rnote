{
  description = "A very basic flake";

  inputs = {
    typst.url = "github:Nxllpointer/typst?ref=rnote";
  };

  outputs = {typst, ...}: let
    system = "x86_64-linux";
    lib = typst.inputs.nixpkgs.lib;
    craneLib = typst.craneLib.${system};
    dependencies = typst.dependencies.${system};

    parseSource = deps: let
      sourceString = (builtins.elemAt deps 0).source;
      url = builtins.elemAt (builtins.split "#" sourceString) 0;
      parsed = builtins.parseFlakeRef url;
    in
      parsed;

    mkFetchGitOverrideAttrs = parsedSource: attrs: {
      src = builtins.fetchGit (
        {inherit (parsedSource) url rev;} // attrs
      );
    };

    isTypstTs = parsedSource: parsedSource.url == "https://github.com/Nxllpointer/typst.ts.git";

    commonArgs =
      {
        pname = "tinymist";
        src = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./Cargo.toml
            ./Cargo.lock
            ./crates
            ./tests
            ./contrib
          ];
        };
        doCheck = false;
      }
      // dependencies;

    cargoVendorDir = craneLib.vendorCargoDeps (commonArgs
      // {
        overrideVendorGitCheckout = deps: drv: let
          parsedSource = parseSource deps;
        in
          if isTypstTs parsedSource
          then
            builtins.trace "Patching typst.ts fetchGit!"
            (drv.overrideAttrs (mkFetchGitOverrideAttrs parsedSource {submodules = false;}))
          else drv;
      });

    cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {inherit cargoVendorDir;});

    tinymist = craneLib.buildPackage (commonArgs
      // {
        inherit cargoArtifacts cargoVendorDir;
        cargoExtraArgs = "--bin tinymist";
      });
  in {
    packages.${system} = {
      inherit tinymist;
      default = tinymist;
    };
  };
}
