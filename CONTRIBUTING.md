# Contributing to Cyberpunk 2077 Android Engineering

Thank you for your interest in contributing to this engineering research repository.

## Guiding Principles & Non-Negotiable Rules

1. **Zero Proprietary Assets:** Never submit pull requests that include game executables (`.exe`), CDPR archives (`.archive`), dynamic link libraries (`.dll`), audio/video files, textures, models, saves, or proprietary DRM components.
2. **No DRM Circumvention:** Do not contribute cracks, bypasses, or instructions intended to defeat anti-tamper mechanisms or copyright protection.
3. **Strict Read-Only Safety:** Scripts that interact with local game directories must treat them as strictly read-only and enforce explicit overwrite guards.
4. **Verifiable & Honest Findings:** Ground all compatibility benchmarks, translation findings, and hardware tests in reproducible logs. Do not submit speculative or exaggerated playability claims.

## Contribution Workflow

1. Fork the repository and create a feature branch (`git checkout -b feature/improvement`).
2. Make your changes adhering to the existing code and documentation style.
3. Run the automated test suite locally:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File tests/Test-HardenedStaging.ps1
   ```
4. Ensure all unit tests pass (10/10).
5. Open a Pull Request describing your changes, motivation, test results, and any relevant device/driver specifications.

## Code Style

- **PowerShell:** Use standard Cmdlet binding, explicit parameters, path canonicalization, and structured JSON output.
- **Java:** Target modern standard Java (LTS 17/21) with zero unnecessary third-party runtime dependencies.
- **Documentation:** Follow GitHub Flavored Markdown with precise path references and clear distinction between verified evidence and unverified claims.
