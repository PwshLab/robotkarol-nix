{
  description = "Robotkarol nix flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    { nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, lib, self', ... }: {
        packages = {
          robotkarol-jar = pkgs.stdenv.mkDerivation {
            pname = "robotkarol-jar";
            version = "0.1.0";

            src = pkgs.fetchFromGitHub {
              # https://github.com/bschlangaul-sammlung/javakarol
              owner = "bschlangaul-sammlung";
              repo = "javakarol";
              rev = "155f74bdbf6d120b6437badea4acfbaeff07d0ac";
              sha256 = "bGr4cPFhTgvnPa0Xkwwro86DEeRESwXSiQwsP1aTwSc=";
            };

            nativeBuildInputs = with pkgs; [
              javaPackages.compiler.temurin-bin.jdk-25
              mill
              stripJavaArchivesHook
            ];

            postPatch = 
              let 
                buildFile = pkgs.writeText "build.mill.yaml" ''
                  mill-jvm-version: system
                  extends: JavaModule
                '';
              in
                ''
                  cp ${buildFile} build.mill.yaml

                  mkdir src
                  mv RobotKarol.java src/
                  mv javakarol src/
                  mv karoleditor src/
                  mv robotkarol src/

                  mkdir resources
                  mv help resources/
                  mv icons resources/
                  mv imgs resources/
                '';

            buildPhase = ''
              runHook preBuild

              mill assembly

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out
              cp ./out/assembly.dest/out.jar $out/robotkarol.jar

              runHook postInstall
            '';

            outputHashMode = "recursive";
            outputHash = "sha256-PNfHUfWte2D7me9an8XA8OL/5er8UNzPpBqFjYWsx28=";
          };

          robotkarol = pkgs.stdenv.mkDerivation {
            pname = "robotkarol";
            version = "0.1.0";
            dontUnpack = true;

            nativeBuildInputs = with pkgs; [
              makeWrapper
            ];

            buildInputs = [
              self'.packages.robotkarol-jar
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              makeWrapper ${pkgs.javaPackages.compiler.temurin-bin.jdk-25}/bin/java $out/bin/robotkarol \
                --add-flags "-jar ${self'.packages.robotkarol-jar}/robotkarol.jar"

              runHook postInstall
            '';
          };

          default = self'.packages.robotkarol;
        };
      };

      flake = {};
    };
}
