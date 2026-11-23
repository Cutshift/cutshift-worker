# cutshift worker

> **The beta branch.** This branch's flake builds the beta worker 0.4.0-beta.2: the package `cutshift-worker-beta`, the command
> `cutshift-beta`, installed beside the stable worker (`nix profile install github:Cutshift/cutshift-worker/beta`).
> The stable worker is on the main branch.

The worker for [cutshift](https://cutshift.hermes-technology.de): narrated product films from a spec. The studio is
hosted at [app.cutshift.hermes-technology.de](https://app.cutshift.hermes-technology.de); the worker is the one
thing you install. It runs on your machine, records your app in a real browser, speaks the narration and cuts the
film. Your media and project files stay on your machine.

cutshift is in **early access**: free, by invitation. [Ask for an invitation](mailto:cutshift@hermes-technology.de).

This repository holds the worker's releases, this README and its licence. The source code is not public.

## Install

Linux (x64, arm64) and macOS (Apple silicon, Intel). On Windows, in WSL2. On an Intel Mac the voices cannot run
locally (PyTorch publishes no macOS x86_64 wheels since 2.2.2): use an Azure voice there.

```sh
curl -fsSL https://cutshift.hermes-technology.de/install.sh | sh
```

The installer puts the worker in `~/.cutshift` without sudo, checks the download against its sha256 and asks before
it changes your PATH. Each release's `SHA256SUMS` is signed with minisign; `cutshift self update` checks that
signature before it installs an update.

The installer adds one line to the file your login shell reads (zsh: `~/.zshrc`; bash: `~/.bashrc` and
`~/.profile` or `~/.bash_profile`; fish: `conf.d/cutshift.fish`). A file that is a symlink or not writable, such as
a dotfile managed by home-manager, stays untouched: the installer prints the line to add there yourself.

### Nix and NixOS

On NixOS the installer installs nothing and points here: the worker is a Nix flake. Its `cutshift` uses nixpkgs'
ffmpeg, Chromium, Python and uv, and the release's video renderer patched for Nix, so nothing it runs needs nix-ld.
The flake builds the release named in `sources.json` and pins nixpkgs; it allows this one unfree package and nothing
else.

```sh
nix profile install github:Cutshift/cutshift-worker          # into your user profile
nix run github:Cutshift/cutshift-worker -- --version          # or try it without installing
```

Declaratively, add the input to your flake and the package to your configuration (pass `inputs` to your modules
through `specialArgs` or `extraSpecialArgs`):

```nix
# flake.nix
inputs.cutshift-worker.url = "github:Cutshift/cutshift-worker";   # a fixed version: …/cutshift-worker/v0.2.2 (0.2.2 is the first with the flake)

# home-manager
home.packages = [ inputs.cutshift-worker.packages.${pkgs.stdenv.hostPlatform.system}.default ];

# or NixOS
environment.systemPackages = [ inputs.cutshift-worker.packages.${pkgs.stdenv.hostPlatform.system}.default ];
```

The flake has packages for x86_64-linux (tested on NixOS) and, built the same way but not tested yet, aarch64-linux,
aarch64-darwin and x86_64-darwin (on macOS only ffmpeg comes from nixpkgs). It also has an overlay (`overlays.default`, `pkgs.cutshift-worker`). Update with `nix flake update
cutshift-worker` (or `nix profile upgrade`), not with `cutshift self update`. The speech environment (Python packages
and voice models) is still set up in `~/.cutshift` on first use.

The beta worker (for the beta studio, installed beside the stable one) is the same flake on the `beta` branch: its
package is `cutshift-worker-beta` (the overlay's `pkgs.cutshift-worker-beta`), its command `cutshift-beta`, its home
`~/.cutshift-beta`:

```sh
nix profile install github:Cutshift/cutshift-worker/beta
```

```nix
inputs.cutshift-worker-beta.url = "github:Cutshift/cutshift-worker/beta";
home.packages = [ inputs.cutshift-worker-beta.packages.${pkgs.stdenv.hostPlatform.system}.default ];
```

To check a download by hand:

```sh
minisign -Vm SHA256SUMS -P <the public key below>
sha256sum -c SHA256SUMS --ignore-missing
```

Release-signing public key:

```
RWRi0BMtdbIquQFTMETvDUY/DbNnpKTlaTLiAhpOW6k9PrVWhPJpqaJS
```

## First steps

1. Create a project in the [studio](https://app.cutshift.hermes-technology.de). Its id is in the address,
   `…/p/<id>/`; the project's page shows the next commands with the id filled in, ready to copy.
2. On your computer:

```sh
cutshift init my-film                  # the project folder (skip this if you have one)
cd my-film
cutshift worker login                  # once per computer: approve it in your browser (it opens by itself)
cutshift worker --project <id>         # links the folder to your studio project, once, and starts the worker
```

One worker per computer serves all your linked project folders. It asks once whether to start by itself at login
(`cutshift worker autostart on` later); without that, `cutshift worker` starts it for every linked folder.

The first start downloads ffmpeg and a headless browser (about 280 MB) in the background; the first narration sets
up the voices (about 450 MB more). The worker shows what it downloads and when it is ready.

Updating and removing:

```sh
cutshift self update
cutshift self uninstall
```

## What the worker sends, and where

- **To the hosted studio:** the structure and state of your projects (names, paths, sizes, checksums, jobs and
  their times, members and devices). Never your written text in plain, never your media. When your browser cannot
  reach the worker directly, the studio relays an end-to-end encrypted connection and sees ciphertext only.
  Optional sealed storage keeps an encrypted copy only you and your team can read.
- **Downloads on first use** (pinned versions, checked against their checksums): FFmpeg (GitHub: BtbN/FFmpeg-Builds
  for Linux; ffmpeg.martin-riedl.de for macOS), a headless Chromium (cdn.playwright.dev), uv and Python (GitHub:
  astral-sh), a part of the video renderer (registry.npmjs.org), Python packages (PyPI) and voice models
  (huggingface.co). These servers see your IP address; the worker sends them none of your content.
- **Azure speech, only if you set it up:** with your own Azure OpenAI endpoint and key in a project (`tts.azure`),
  the narration lines of Azure voices go to your endpoint at Microsoft. Otherwise all voices run on your machine.

Details: [privacy policy](https://cutshift.hermes-technology.de/datenschutz/)
([Deutsch](https://cutshift.hermes-technology.de/de/datenschutz/)).

## Licence

The worker is proprietary software, free to use with the hosted cutshift service during early access, under the
[end-user licence agreement](LICENSE.txt) (English and German; the German version is binding). It ships third-party
components under their own licences: `THIRD_PARTY_NOTICES` and `licences/` in each release archive (installed under
`~/.cutshift/current/`).

## Contact

[cutshift@hermes-technology.de](mailto:cutshift@hermes-technology.de) ·
[Legal notice](https://cutshift.hermes-technology.de/impressum/) ·
[Impressum](https://cutshift.hermes-technology.de/de/impressum/)

Issues are welcome in this repository's issue tracker; please never paste secrets, keys or private project text.
