# Prototype validation

Version 0.2.0. Checks recorded October 22, 2026 with Xcode 27.1 on macOS 27.0.1.

## Completed checks

| Check | Result |
| --- | --- |
| RecipeCore tests | 21 tests, 0 failures. |
| UI tests on iOS 26.5 and iOS 27.0 | Five scenarios passed on each runtime. Input validation and unavailable-model flows were rechecked on iOS 27 after the alert-state fix. |
| Generic iOS Simulator Release build | Passed with Xcode 27.1. |
| Generic iOS device Release build | Passed with signing disabled for compilation. |
| Visual review | Create screen in light and dark appearance, sample recipe detail, and unavailable-model Settings checked in the iOS 26.5 simulator. Release app installed and launched on iOS 27. |
| Live on-device text generation on the development Mac | The app’s actual `AppleRecipeService` compiled into a command-line harness, generated a two-serving recipe from chickpeas, spinach, and tomatoes, and passed recipe validation. The result was not a sample. |
| Native on-device image request on the development Mac | Model reported image support. An image request using the app’s non-food icon returned an empty ingredient list. |
| Vision fallback smoke test | Synthetic product-label image returned Tomatoes and Chickpeas; cancellation propagated. This does not evaluate real food recognition. |
| Privacy manifest syntax | Passed `plutil -lint`. |
| Documentation links | Local links resolve. |
| Release simulator bundle | Ad-hoc signature verified; packaged without extended filesystem metadata. |

The core tests cover input normalization and limits, preference bounds, explicit pantry staples, unknown and duplicate ingredients, incomplete responses, serving and time consistency, recipe serialization, compatibility with existing saved recipe records, and conservative filtering of Vision classifications and OCR labels.

The live model checks used Apple’s on-device model on the development Mac. Additional four-serving salad and pasta requests passed validation. A single-apple request with pantry basics disabled produced invalid ingredients and was correctly rejected. Very sparse lists may need editing or another attempt.

These checks establish real model calls in that environment. They do not establish iPhone performance, broad recipe quality, or recognition accuracy for real food photos.

## Not yet verified

- Physical-device camera capture and end-to-end generation on an iPhone.
- Recognition accuracy on real food photos, including the iOS 26 Vision fallback.
- Model output across multiple device types, system languages, regions, and OS model revisions.
- Every iPad layout and accessibility setting, or an App Store-signed build.
- The safety or correctness of generated cooking instructions. Structural validation does not prove natural-language steps are accurate.

The automated UI suite covers sample saving and removal across launches, editable normalized ingredients when the model is unavailable, local-model Settings without credential fields, invalid pending ingredients, and empty-input handling. It uses controlled unavailable-model state rather than live inference. Run `./scripts/verify.sh` and `./scripts/test-ui.sh` to reproduce the automated checks. The GitHub workflow uses the same scripts; consult its actual run result for CI status.
