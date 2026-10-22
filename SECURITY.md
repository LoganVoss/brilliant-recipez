# Security

Brilliant! Recipez is an open-source prototype. It processes recipes and photos on the device using Apple frameworks. It has no app account, hosted model endpoint, or shared credential.

## Report a problem

Use private vulnerability reporting in the repository’s **Security** tab if available. Otherwise, open an issue requesting a private contact method without disclosing the vulnerability or private data.

Include the affected version or commit, impact, and a minimal reproduction with synthetic data. Do not include personal photos, private recipe prompts, device backups, signing materials, or account details.

## Boundaries to preserve

- Treat model output and recognized photo text as untrusted input; validate before display and persistence.
- Treat ingredient input as data, not instructions that can override the recipe task.
- Keep generation and photo analysis local. Review any dependency that adds networking or telemetry.
- Do not log raw image content or private prompts.
- Preserve local file protection and do not overwrite an unreadable recipe collection.
- Keep test-only fixtures and availability overrides out of production behavior.
- Recheck availability, failure handling, and output validation after changing OS or model APIs.

Local processing does not protect data from a compromised device or code running with the app’s privileges. System backups and user-selected sharing are separate data paths.

Generated recipes and recognized ingredients can be wrong. This app does not certify allergies, nutrition, or food safety. Report ordinary recipe-quality issues publicly with synthetic examples; use a private channel for vulnerabilities that could expose data or bypass security boundaries.
