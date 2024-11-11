{
  description = "A very basic flake";

  inputs = {
    typst.url = "github:Nxllpointer/typst?ref=rnote-tinymist-v0.12.0";
  };

  outputs = { typst, ... }: let
    system = "x86_64-linux";
    craneLib = typst.craneLib.${system};
    dependencies = typst.dependencies.${system};

    commonArgs = {
      pname = "tinymist";
      src = ./.;
    } // dependencies;
  in {

    packages.${system} = rec {
      tinymist = craneLib.buildPackage (commonArgs // {
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        doCheck = false;
      });
      default = tinymist;
    };

  };
}
