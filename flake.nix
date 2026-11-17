# The cutshift worker as a Nix package, for NixOS and Nix users:
#   nix profile install github:Cutshift/cutshift-worker
#   home.packages = [ inputs.cutshift-worker.packages.${pkgs.stdenv.hostPlatform.system}.default ];
#
# It installs the release's tarball (sources.json: its version, URLs and sha256, written by the release) and wraps
# `cutshift` so the worker uses parts that run on NixOS instead of downloading its own on first use:
#   ffmpeg + ffprobe   nixpkgs' ffmpeg                        (CUTSHIFT_FFMPEG_DIR)
#   the browser        nixpkgs' chromium (Linux)              (BROWSER_BIN)
#   the compositor     the release's pinned Remotion compositor, patched for Nix (CUTSHIFT_COMPOSITOR_DIR)
#   the TTS env        nixpkgs' uv and Python 3.12; the PyPI wheels find libstdc++ and zlib (LD_LIBRARY_PATH)
# The worker's Node runtime and native modules are patched to Nix's loader (autoPatchelfHook), so nix-ld is not needed.
# On macOS only ffmpeg is replaced; the browser and the TTS env are fetched as on any Mac.
{
  description = "The cutshift worker: records your app, speaks the narration and cuts the film, on your machine";

  # Pinned to a nixos-26.05 revision; `nix flake update` moves it.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/6fcc160353f63555b560f25588925133c8f61f2a";

  outputs =
    { self, nixpkgs }:
    let
      sources = builtins.fromJSON (builtins.readFile ./sources.json);
      targetOf = {
        x86_64-linux = "linux-x64";
        aarch64-linux = "linux-arm64";
        aarch64-darwin = "darwin-arm64";
        x86_64-darwin = "darwin-x64";
      };
      # the systems this release has a tarball for
      systems = builtins.filter (s: sources.targets ? ${targetOf.${s}}) (builtins.attrNames targetOf);
      # the worker is unfree (its EULA): allowed here for itself alone
      forSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f system (
            import nixpkgs {
              inherit system;
              config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "cutshift-worker";
            }
          )
        );

      worker =
        system: pkgs:
        let
          inherit (pkgs) lib stdenv;
          target = targetOf.${system};
          src = sources.targets.${target};
          linux = stdenv.hostPlatform.isLinux;
          name = "cutshift-worker-${sources.version}-${target}";
          tarball = pkgs.fetchurl {
            url = "${sources.releasesUrl}/v${sources.version}/${name}.tar.xz";
            sha256 = src.sha256;
          };
          # the Remotion compositor the release pins (an npm tarball, its sha512 from the lockfile): its binaries and
          # ffmpeg libraries are patched to Nix's loader
          compositor = stdenv.mkDerivation {
            pname = "cutshift-remotion-compositor";
            version = src.compositor.version;
            src = pkgs.fetchurl {
              url = src.compositor.url;
              hash = src.compositor.integrity;
            };
            nativeBuildInputs = lib.optionals linux [ pkgs.autoPatchelfHook ];
            buildInputs = lib.optionals linux [
              stdenv.cc.cc.lib
              pkgs.zlib
            ];
            dontConfigure = true;
            dontBuild = true;
            dontStrip = true;
            installPhase = ''
              mkdir -p $out
              cp -r . $out/
            '';
          };
          ttsLibs = lib.makeLibraryPath [
            stdenv.cc.cc.lib
            pkgs.zlib
          ];
          wrapArgs = [
            "--set-default"
            "CUTSHIFT_FFMPEG_DIR"
            "${lib.getBin pkgs.ffmpeg}/bin"
          ]
          ++ lib.optionals linux [
            "--set-default"
            "BROWSER_BIN"
            "${pkgs.chromium}/bin/chromium"
            "--set-default"
            "CUTSHIFT_COMPOSITOR_DIR"
            "${compositor}"
            "--set-default"
            "CUTSHIFT_UV"
            "${pkgs.uv}/bin/uv"
            # uv builds the TTS env from nixpkgs' Python (a downloaded Python does not run on NixOS)
            "--prefix"
            "PATH"
            ":"
            "${pkgs.python312}/bin"
            "--set-default"
            "UV_PYTHON_PREFERENCE"
            "only-system"
            "--set-default"
            "UV_PYTHON_DOWNLOADS"
            "never"
            # torch's and the other wheels' libstdc++ and zlib
            "--suffix"
            "LD_LIBRARY_PATH"
            ":"
            ttsLibs
          ];
        in
        stdenv.mkDerivation {
          pname = "cutshift-worker";
          version = sources.version;
          src = tarball;
          nativeBuildInputs = [ pkgs.makeWrapper ] ++ lib.optionals linux [ pkgs.autoPatchelfHook ];
          buildInputs = lib.optionals linux [ stdenv.cc.cc.lib ];
          dontConfigure = true;
          dontBuild = true;
          # the Node runtime is the release's own binary: keep it byte for byte apart from its loader
          dontStrip = true;
          installPhase = ''
            runHook preInstall
            # the keyring's musl build is never loaded on glibc
            rm -rf node_modules/@napi-rs/keyring-*-musl
            mkdir -p $out/libexec/cutshift-worker $out/bin
            cp -r . $out/libexec/cutshift-worker/
            makeWrapper $out/libexec/cutshift-worker/bin/cutshift $out/bin/cutshift ${lib.escapeShellArgs wrapArgs}
            runHook postInstall
          '';
          passthru = { inherit compositor; };
          meta = {
            description = "The cutshift worker (records your app, speaks the narration, cuts the film)";
            homepage = "https://cutshift.hermes-technology.de";
            license = lib.licenses.unfree;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            platforms = [ system ];
            mainProgram = "cutshift";
          };
        };
    in
    {
      packages = forSystems (
        system: pkgs: rec {
          cutshift-worker = worker system pkgs;
          default = cutshift-worker;
        }
      );
      overlays.default = final: _prev: {
        cutshift-worker = self.packages.${final.stdenv.hostPlatform.system}.default;
      };
    };
}
