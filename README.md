# cutshift worker

The worker for [cutshift](https://cutshift.hermes-technology.de): narrated product films from a spec. The studio is
hosted at [app.cutshift.hermes-technology.de](https://app.cutshift.hermes-technology.de); the worker is the one
thing you install. It runs on your machine, records your app in a real browser, speaks the narration and cuts the
film. Your media and project files stay on your machine.

cutshift is in **early access**: free, by invitation. [Ask for an invitation](mailto:cutshift@hermes-technology.de).

This repository holds the worker's releases, this README and its licence. The source code is not public.

## Install

Linux (x64, arm64) and macOS (Apple silicon, Intel). On Windows, in WSL2.

```sh
curl -fsSL https://cutshift.hermes-technology.de/install.sh | sh
```

The installer puts the worker in `~/.cutshift` without sudo, checks the download against its sha256 and asks before
it changes your PATH. Each release's `SHA256SUMS` is signed with minisign; `cutshift self update` checks that
signature before it installs an update.

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

```sh
cutshift init my-film          # a new project folder
cd my-film
cutshift worker login          # approve this machine once in your browser
cutshift worker --project <id> # your project in the studio shows this line with its id, ready to copy
```

Then open your project in the [studio](https://app.cutshift.hermes-technology.de).

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
