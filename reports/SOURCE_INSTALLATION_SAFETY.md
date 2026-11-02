# SOURCE INSTALLATION SAFETY — Read-Only Guarantees (Phase 1)

Date: 2026-10-23

## Guarantee

Phase 1 performed ZERO writes to anything under `C:\Games\steam` (Steam or game install). The mission is local-only, legal use of the user's own legally owned Steam install, and every phase stays read-only-first with respect to the install.

## What was touched

- READ ONLY, no writes:
  - `C:\Games\steam\steamapps\common\Cyberpunk 2077` recursive inventory (159 files / 61.81 GiB observed)
  - `bin\x64\Cyberpunk2077.exe` — version string + PE header read (no page modification)
  - `appmanifest_1091500.acf` — parsed and SHA-256 hashed (no modification)
  - `libraryfolders.vdf` — read
  - `%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077` — directory listing and names only; file contents never read
- CREATED (outside the install, on the working side):
  - `C:\CP2077-Android-Engineering\` and `reports\` — analysis workspace, fully separate from the install
- NOT TOUCHED: Steam registry keys, `loginusers.vdf`, saves' contents, REDlauncher, REDprelauncher, GameState store, CD Projekt red script files under `r6`, any mod/MMVSE or engine config (`Game.csproj`-like or otherwise).

## Standing rules

1. Never modify or push any game file, Steam config, save, or registry value.
2. No DRM circumvention activity of any kind.
3. No admin escalation without explicit user approval.
4. No game assets, binaries, or strings are copied to GitHub; only generic, non-asset findings and tool outputs are committed.
5. Hashes of the game executable and manifests are recorded so any future write-detection can compare against `53C28F0AC35D52A0081F3DEB5811EC28892695F7E58F56F3EC7F23F1C1F32004` (appmanifest_1091500.acf).

## Note on the anomalous file

`bin\x64\cyberpunk2077_addresses.json` (~132 MB) was detected but NOT opened or modified. Its origin is unknown; see `EVIDENCE_AND_UNKNOWNS.md`. If the user does not recognize this file, it should be investigated (e.g., produced by a debugging/RE tool) before any further action touching `bin\x64`.
