# Privacy notes

This document describes version 0.2.0 of this open-source prototype. A fork must reassess its own behavior before distribution.

## On-device processing

The app uses Apple’s on-device Foundation Models and Vision APIs. Ingredients, preferences, and selected photos are processed locally. It does not send them to a server or select a cloud model. No API key, app account, analytics SDK, advertising SDK, or project-operated backend is included.

Apple manages the system models and their initial downloads and updates. Those OS operations may require a connection. That is separate from the app’s recipe generation and photo analysis, which run on the device once the required models are available. See Apple’s [Foundation Models documentation](https://developer.apple.com/documentation/foundationmodels/) and [Apple Intelligence requirements](https://support.apple.com/en-us/121115).

## Local data

| Data | Handling |
| --- | --- |
| Selected or captured photo | Resized and re-encoded for local recognition. Not written to the saved recipe file. |
| Ingredient list and cooking preferences | Held in app state while creating a recipe and used in the local generation prompt. |
| Saved recipes | Stored in `Application Support/BrilliantRecipez/recipes.json` inside the app container. |
| Sample recipe | Bundled content; opening it does not run a model. |

The system photo picker provides the selected image, not unrestricted access to the photo library. Camera permission is requested for capture. The app has no recipe sync service. Local storage may still appear in operating-system backups; device access, OS diagnostics, backups, and a fork’s changes are separate considerations.

## Sharing, links, and deletion

Sharing sends recipe text to the iOS share sheet. The destination you choose handles that text under its own policies. Opening the source-code link launches a website in the system browser.

Remove a recipe in the **Saved** tab to delete it from the app’s collection. Existing exports and OS backups are not removed by that action. The app does not keep server copies of recipes or photos.

## Apple privacy manifest

`PrivacyInfo.xcprivacy` declares no tracking, no tracking domains, and no collected data types for this implementation. This reflects the app’s local generation and photo processing. Apple distinguishes local handling from off-device collection in its [App Privacy Details guidance](https://developer.apple.com/app-store/app-privacy-details/).

The manifest retains the own-app `UserDefaults` required reason, `CA92.1`, for local migration and test-state access. A manifest does not submit or certify an App Store privacy label. Reassess it and the App Store Connect privacy answers when changing storage, networking, model providers, or dependencies.
