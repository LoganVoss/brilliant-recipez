# Security

This repository is an open-source prototype. It contains no shared API credential. Each user supplies a key, which the app stores in the iOS Keychain for direct requests to xAI.

## Report a problem

Use private vulnerability reporting from the repository's **Security** tab if it is available. If no private channel is offered, open an issue asking for a secure contact method without publishing the vulnerability, an exploit, or private data.

Include the affected version or commit, the impact, and a minimal reproduction using synthetic data. Do not include API keys, personal photos, provider account details, or unrelated sensitive information.

## If a key is exposed

Revoke or rotate it in the [xAI Console](https://console.x.ai/) immediately. Removing a key from source, a screenshot, or local Settings does not revoke it. Git history and published artifacts may retain earlier copies.

Do not use a shared production key in an iOS binary. A production service should keep that credential on a controlled backend with authentication and usage limits. A per-user key stored on a device also remains accessible to code running with the app's privileges or to a compromised device; Keychain storage does not eliminate those risks.

## Boundaries worth preserving

- Send credentials only to the intended HTTPS provider endpoint.
- Do not log authorization headers, raw image payloads, or sensitive request content.
- Treat provider text and JSON as untrusted input. Validate before persistence or display.
- Keep API model selection separate from credential storage.
- Review networking and privacy behavior when adding dependencies or changing providers.
- Keep demo fixtures and automated tests free of live credentials.

AI-generated recipes and recognized ingredients can be wrong. The app is not an allergy certification, food-safety system, or medical tool. Report implementation errors through normal issues; use a private channel for vulnerabilities that could expose data or credentials.
