# FINAL ARCHITECTURE DECISION — Cyberpunk 2077 on Android (SM7450 / Snapdragon 7 Gen 1)

Deliverable A | Status: DRAFT v1.0 | Date: 2026-10-23 | Workspace: `C:\CP2077-Android-Engineering`

## 1. Decision summary

**Decision: Route B is the recommended primary architecture, combined with useful Route C helper components. Route A (native port) is BLOCKED and is not pursued, and must never be represented as feasible.**

Routes under consideration:

- **Route A — Native port of the game to Android/ARM64.** BLOCKED. Rejected on evidence from Phases 1–3.
- **Route B — Running the Windows x86-64 game inside a compatibility/virtualization environment on Android.** PARTIALLY VERIFIED as the only structurally possible direction; gated by hard blockers that are documented below and are legitimately untestable without DRM circumvention (permanently out of scope).
- **Route C — Custom Android helper components.** Supported and buildable now; contributes project-owned, legally redistributable value regardless of Route B outcome.

Labeling convention per `reports/EVIDENCE_AND_UNKNOWNS.md`: VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / BLOCKED.

## 2. Target facts (VERIFIED)

| Item | Value | Source |
|---|---|---|
| Steam AppID | 1091500 | appmanifest VERIFIED |
| Timeline version | 2.31, buildid 20383525 | appmanifest VERIFIED |
| Depot 1091501 manifest | 5294808 | appmanifest VERIFIED |
| On-disk size | 66,366,228,927 B (~61.81 GiB / ~70 GB) | appmanifest VERIFIED |
| Executable | `bin\x64\Cyberpunk2077.exe`, PE+ x64, 59,945,608 B | Phase 1 VERIFIED |
| DRM stack | Steam DRM + Denuvo (per public release history; runtime details unknown) | PARTIALLY VERIFIED (public) |
| Scope | Base game only, no Phantom Liberty, no dlc dir | Phase 1 VERIFIED |
| Device | HONOR REA-NX9, SM7450 (Snapdragon 7 Gen 1 Accel. Ed.), ARMv8/AArch64, Adreno 644, Android 15 | Phase 3 VERIFIED |
| Device free storage | ~18 GiB at `/storage/emulated/0/Android/obb` (92% used), no removable volume | Phase 3 VERIFIED |
| Serial | ANAVVB3901010779 (may need reconnection) | Phase 3 VERIFIED |

## 3. Route A — Native port: REJECTED (BLOCKED)

Blocking reasons, each independently sufficient:

1. **Proprietary engine.** The game engine is proprietary CDPR software. Recreating engine source from binaries/assets is not permitted under this mission's legal guardrails. VERIFIED constraint (mission directive).
2. **Protection tier.** v2.31 ships with Denuvo + Steam DRM. A native port would require protected-exe internals that cannot be legitimately obtained without DRM circumvention. Out of scope permanently. VERIFIED constraint.
3. **Architecture.** Game binaries are x86-64 PE; device CPU is ARMv8 (AArch64, SM7450). No recompilation or translation mechanism exists that is applicable without protected-code access. VERIFIED (Phase 1 + Phase 3 facts combine).
4. **Graphics.** The game requires DX12 (and DX11) with a modern driver stack; device GPU is Adreno 644. No mechanism is known to satisfy these requirements natively on Android. UNVERIFIED-to-BLOCKED per Phase 2 research; no verified public mechanism.
5. **Storage.** ~70 GB game vs ~18 GiB device free space with no removable volume: a shortfall of roughly ~52 GB even before builds. VERIFIED (Phase 3).

**Conclusion:** Route A is BLOCKED and permanently out of scope. Any artifact, document, or claim must never present Route A results as a native port.

## 4. Route B — Windows-in-compatibility-environment: the only structurally open direction

### What is possible (evidence-based)

- **Generic translation-layer facts (VERIFIED, PUBLISHED literature):**
  - Wine/FEX emulation of Windows x86-64 applications on ARM is a real, published technology family, but the combination required here (DX12 titles + Denuvo-protected executables + heavy CPU/GPU replay) has no verified public success case on this GPU (Adreno 644).
  - VKD3D-Proton capability history is VERIFIED as published knowledge; its applicability here remains UNVERIFIED.
  - Winlator G6 (or equivalent) support for this workload: **NOT FOUND** in Phase 2 research (VERIFIED as "not found", which is not the same as "does not exist").
  - Section 13 graded claims (Denuvo-under-Proton generic, Winlator 10.1 Steam login, VKD3D-Proton 2.1 history, etc.) remain UNVERIFIED.
- **Device facts:** RAM (per Phase 1 assessment ~4.8–5.3 GB available to an app) sits below the practical floor reported for this class of heavy Windows emulation. This is PARTIALLY VERIFIED (theoretical, from device specs; not load-tested).

### What blocks Route B (and cannot be tested within scope)

1. **Denuvo under any translation layer** — the #1 blocker, legitimately untestable without DRM circumvention. Out of scope permanently. VERIFIED as out-of-scope.
2. **DX12 + Adreno 644** — no verified public mechanism exists for this GPU tier on this game's requirements. UNVERIFIED, near-BLOCKED.
3. **Storage** — ~70 GB headroom is absent on the device; no removable volume exists to divert to. VERIFIED shortfall.
4. **CPU translation performance** — unmeasured (G4, no Adreno 644 platform benchmarks). UNVERIFIED.

**Conclusion:** Route B is the only structurally compatible direction and should be recommended as the primary candidate — but is NOT described as a native port. It must be labeled CONDITIONAL GO at best, contingent on unmeasured runtime variables, and the report must not imply practical playability without verified device-side launch evidence.

## 5. Route C — Custom Android helper components: buildable now

The helper route does NOT require Route B success to deliver value. Components to build (Deliverables B–E):

1. **Environment/device capability checker** (`app`-level or CLI): reads selective `ro.*` props, storage layout, and reports a structured capability verdict with no privileged operations. Scope: read-only adb shell commands only. VERIFIED-feasible (Phase 3 used the exact command patterns).
2. **Config templates** for Phase B runtime assumptions: CPU-count replica counts, base app paths, art-caps notes (device-relative paths only; no assets in repo).
3. **Validation scripts** with production-ready semantics: preflight check (device storage free-space vs required, storage-authority correctness `chroot`-free, package/cmd availability at clean install, `apk` path, PATH, binary context, requirements). Log-based verification output.
4. **Versioned deployment bundle**: only legally redistributable + project-authored files (scripts, binaries we author, docs). Never any game files, assets, credentials, or borderline items. This excludes ("Denuvo") code and never includes any proprietary game support files.

**Conclusion:** Route C is GO for building (files-only, source work now on the laptop). It is NOT conditional on Route B.

## 6. Storage math for the report (required-space conclusion)

- Required (Phase 3 VERIFIED, from appmanifest): 66,366,228,927 B (~61.81 GiB) on-disk base game; Unreal-compressed ~70 GB working estimate.
- Available device public storage: ~18 GiB free at `/storage/emulated/0/Android/obb`. No removable volume. No cloud-offload mechanism in-scope.
- **Honest fit conclusion: the game cannot fit on the verified device storage layout without external changes the user must make (e.g., deleting data, offloading, or a device swap). Closing this gap is out of scope for the engineering laptop unless the user requests a plan.**

## 7. What this decision is NOT

- Not a claim of playability.
- Not a claim of native port.
- Not an instruction to modify/patch/rename/move/delete anything in `C:\Games\steam\steamapps\common\Cyberpunk 2077`.
- Not an invitation to DRM circumvention or Denuvo bypass.

## 8. Action items feeding Deliverables B–F

- [x] Reports review complete (Phases 1–3).
- [x] This decision (Deliverable A).
- [ ] Deliverable B: real project files (checker, configs, validation scripts) — no commits/pushes without explicit instruction.
- [ ] Deliverable C: GitHub Actions automation (no assets/secrets in repo).
- [ ] Deliverable D: versioned offline deployment bundle (legally redistributable only).
- [ ] Deliverable E: validation run log — must label verified vs package vs compatibility vs game-launch vs full-gameplay levels.
- [ ] Deliverable F: `reports/BUILD_READINESS.md` with GO / CONDITIONAL GO / NO-GO verdict against device readiness, after laptop-side work is complete.

## 9. Open residuals (tracked in `EVIDENCE_AND_UNKNOWNS.md`)

- G3: unresolved item from earlier phases (carried forward).
- G4: no Adreno 644 platform benchmarks (unresolved).
- Device reconnection: `ANAVVB3901010779` OFFLINE at Phase 3 report-write time; must `adb devices -l` via `tools\platform-tools\adb.exe` before any new device command.
- Machine hash drift check on `appmanifest_1091500.acf` if/when write-detection is re-run.
