# Contributing

Brilliant! Recipez is a foundation for builders. Contributions that make it easier to use, test, and extend are welcome.

## Start here

Use Xcode 27 or newer and the **BrilliantRecipez** scheme. The app targets iOS 26+. Recipe generation requires an available Apple Intelligence model; native image prompting requires iOS 27+ and image support. The sample and automated fixtures do not need a live model.

```sh
./scripts/verify.sh
./scripts/test-ui.sh
```

Run the UI suite when changing a covered flow. See [validation notes](docs/VALIDATION.md) for current checks and limits. If you evaluate a real model, record the device, OS, inputs, and outcome separately from fixture tests.

## Keep the foundation useful

- Keep platform model and Vision calls in the app, and shared validation in `RecipeCore`.
- Preserve on-device processing, manual ingredient entry, ingredient review, and a clearly labeled fixed sample.
- Handle unsupported hardware, unavailable models, refusals, malformed output, and cancellation without losing the ingredient draft.
- Keep copy direct: name the action, input, or result. Use **“Turn what you have into something you’ll love.”** as the home headline.
- Keep accessible labels, Dynamic Type, and readable contrast.
- Add meaningful tests for changed behavior, using synthetic inputs.
- Update compatibility, privacy, and setup documentation when implementation changes.

Do not commit signing identities, provisioning profiles, private photos, personal prompts, credentials, or account screenshots. System model weights are not part of this repository.

## Pull requests

Open an issue before a substantial redesign. For focused fixes, submit a pull request describing the problem, resulting behavior, and checks actually run. Include screenshots for interface changes and state what remains unverified. A fixture or simulator pass is not proof of successful generation on a physical device.

Contributions use the repository’s [MIT License](LICENSE). Include attribution and permissions for any added assets or code.
