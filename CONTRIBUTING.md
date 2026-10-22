# Contributing

Brilliant! Recipez is a starting point for builders. Improvements that make the app clearer, easier to test, or easier to adapt are welcome.

## Start small

Open an issue for a substantial change so the scope can be discussed. For a focused fix, a pull request with a clear explanation is enough. Describe the user-visible problem, the resulting behavior, and how you checked it. Include screenshots for interface changes.

Use the **BrilliantRecipez** scheme in `BrilliantRecipez.xcodeproj`. Use Xcode 16 or newer; the app targets iOS 17+. Core functionality lives in the local `RecipeCore` Swift package.

```sh
./scripts/verify.sh
```

Run `./scripts/test-ui.sh` when changing a flow covered by the UI tests. See the scripts for simulator selection. Use the offline demo and mocked transport for repeatable tests; CI should never require a live API key.

## Keep the foundation useful

- Keep provider calls behind the core service boundary and iOS-specific code in the app.
- Preserve manual ingredient entry and a clearly labeled offline demo.
- Explain changes to model defaults, API payloads, dependencies, costs, and data handling.
- Give unavailable models, malformed responses, cancellation, and missing credentials useful failure states.
- Add meaningful tests for behavior changes. Include regression coverage for a bug when practical.
- Keep accessible labels, Dynamic Type, and readable contrast in mind when editing the interface.
- Update documentation when setup, storage, privacy, or compatibility changes.

Do not commit API keys, `.env` files, signing identities, provisioning profiles, account screenshots, personal photos, or private prompts. Use synthetic fixtures. If a test uses a live provider during local development, say so in the pull request without including credentials or sensitive content.

## Pull requests

Keep each pull request focused. State what changed and why, list the checks you actually ran, and call out anything you could not verify. Avoid presenting a mocked API test as proof that a live model works.

Contributions are provided under the repository's [MIT License](LICENSE). Use assets and code that you have permission to contribute, and include any required attribution.
