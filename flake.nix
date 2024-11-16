{
  description = "A very basic flake";

  inputs = {
    typst.url = "github:Nxllpointer/typst?ref=rnote";
  };

  outputs = {typst, ...}: let
    system = "x86_64-linux";
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
        src = ./.;
      }
      // dependencies;

    cargoVendorDir = craneLib.vendorCargoDeps (commonArgs
      // {
        overrideVendorGitCheckout = deps: drv: let
          parsedSource = parseSource deps;
        in
          # builtins.trace "Git checkout: ${builtins.toString (builtins.map (d: (builtins.map (n: "${n}: ${builtins.getAttr n d}") (builtins.attrNames d))) deps)}"
          # builtins.trace "${source} | ${url} | ${ref.url}"
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
        doCheck = false;
      });
  in {
    packages.${system} = {
      inherit tinymist;
      default = tinymist;
    };
  };
}
