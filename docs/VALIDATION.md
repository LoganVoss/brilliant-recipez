# Prototype validation

Checked October 22, 2026 with Xcode 27.1. App version: 0.1.0.

| Check | Result |
| --- | --- |
| RecipeCore fixture and mocked-network tests | 19 tests, 0 failures |
| iPhone 17 Pro / iOS 26.5 UI tests | 5 tests, 0 failures |
| Generic iOS Simulator Debug build | Passed, arm64 and x86_64 |
| Generic iOS Simulator Release build | Passed, ad-hoc signed |
| Generic iOS device Release build | Passed, signing disabled for compile verification |
| Packaged Release simulator app | Signature verified; installed and launched on iPhone 17e / iOS 26.5 |
| Visual review | Home, recipe detail, recipe box, and dark home checked in Simulator |
| Repository credential scan | No credential-shaped values found; original notes excluded |

The five UI scenarios cover offline sample bookmarks across launches and removal; manual ingredient normalization, deduplication, missing-key feedback and draft preservation; rejection of an invalid pending ingredient before generation; model settings persistence; and Keychain save, relaunch, and removal using a harmless placeholder in an isolated test namespace. No UI test makes a paid API request.

Core tests cover request construction, JSON parsing, strict ingredient-list validation, malformed/truncated responses, provider HTTP errors, network failures, cancellation, and the offline recipe.

## Not verified

- Live xAI requests, billing, model access, and actual model output. Supply your own valid key to test these.
- Physical-device camera capture or an App Store-signed build.
- Every iPad size, accessibility setting, or older supported iOS release. The deployment target is iOS 17; the recorded local UI run used iOS 26.5.
- The safety or correctness of generated cooking instructions. Structured ingredient checks do not prove natural-language steps are accurate.

The GitHub workflow independently tests the core, compiles the simulator app, and runs the UI suite on its pinned Xcode/iOS simulator configuration. See the workflow run for its current result. Reproduce local checks with `./scripts/verify.sh` and `./scripts/test-ui.sh`.
