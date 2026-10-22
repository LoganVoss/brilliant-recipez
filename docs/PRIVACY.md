# Privacy notes

These notes describe this open-source prototype, not every app someone might build from it. Review changes to networking, storage, and dependencies before distributing a fork.

## What stays on the device

- **Your API key:** saved in the iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and read when making a live request. It is not part of the repository or compiled app configuration.
- **App settings:** model identifiers are stored locally in `UserDefaults`. Ingredient input and cooking preferences are held in the app while you work.
- **Saved recipes:** stored as `BrilliantRecipez/recipes.json` in the app’s Application Support directory. This project does not operate a recipe-sync server.
- **Offline demo:** uses bundled sample content and does not call xAI.

Local storage is not a promise that data can never appear in an operating-system backup. Device access, backups, debugging tools, and changes made by a fork are separate considerations.

## What is sent to xAI

A live recipe request sends your ingredient list, selected pantry staples, and cooking preferences to `https://api.x.ai`. A live photo-recognition request sends the selected photo and the recognition prompt. Requests authenticate with your own key over HTTPS.

Images are resized to a maximum dimension of 1,600 pixels and re-encoded as JPEG. The prepared image does not carry the original photo file's metadata. Anything visible in the image—including faces, addresses, labels, or documents—is still visible to the provider. Crop or remove content you do not want to send before selecting the image.

Selecting a photo gives the app access to that selection. The app does not upload your entire photo library. Camera access is requested for capture. Review the ingredients returned by image recognition before generating a recipe.

## Provider handling and retention

When checked on October 22, 2026, xAI's API security documentation stated that API inputs and outputs are retained for 30 days by default for abuse auditing, and are not used for training without explicit permission. Zero Data Retention is a separate provider team setting. A client storage flag, where supported, is not equivalent to that setting.

Provider policies can change. Review the current [API data and security FAQ](https://docs.x.ai/developers/faq/security) and [Data Processing Addendum](https://x.ai/legal/data-processing-addendum) for the terms applicable to your account. The [general privacy policy](https://x.ai/legal/privacy-policy) is not a substitute for API-specific terms.

## Apple privacy manifest

`PrivacyInfo.xcprivacy` describes the live API path as collection, even though this project has no backend. Apple counts off-device data retained beyond real-time request handling; the default provider retention therefore matters. The manifest does not describe the offline demo as the app’s only behavior. See [Apple’s app privacy guidance](https://developer.apple.com/app-store/app-privacy-details/).

| Manifest data type | Why it is included |
| --- | --- |
| `NSPrivacyCollectedDataTypePhotosorVideos` | A selected, prepared photo is sent for ingredient recognition. |
| `NSPrivacyCollectedDataTypeOtherUserContent` | Ingredients, staples, and cooking preferences are sent for recipe generation. |
| `NSPrivacyCollectedDataTypeUserID` | A conservative declaration of the provider-account association created by authenticating with the user’s own API key. This does not claim that xAI retains the raw secret in request logs. |

All three use `NSPrivacyCollectedDataTypeLinked = true`, `NSPrivacyCollectedDataTypeTracking = false`, and purpose `NSPrivacyCollectedDataTypePurposeAppFunctionality`. The linked flag reflects that the provider can associate authenticated requests with an account; removing photo metadata does not anonymize that connection. This is the project’s assessment of its data flow, not a provider or Apple certification. Apple defines account-level identifiers within [collected data types](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype) and documents the fields in [TN3184](https://developer.apple.com/documentation/technotes/tn3184-adding-data-collection-details-to-your-privacy-manifest).

The app does not perform advertising measurement or share data with a data broker. `NSPrivacyTracking` remains false and `NSPrivacyTrackingDomains` is empty. An API domain is not a tracking domain simply because it receives requests. Authentication and feature delivery use Apple’s [App Functionality purpose](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes).

The manifest also declares the app’s own `UserDefaults` access with required-reason code `CA92.1`. A fork must reassess these declarations and its App Store Connect privacy answers against the final implementation, provider agreement, and retention settings before distribution. This source manifest does not submit or certify an App Store privacy label.

## Sharing and deletion

The app's share action gives recipe text to the iOS share sheet. The destination you choose handles that text under its own policies. Share only recipes you intend to disclose.

Manage saved recipes in the app and remove your API key in Settings when it is no longer needed. Deleting the local key does not revoke it at xAI; revoke or rotate it in the [xAI Console](https://console.x.ai/). Local deletion also does not erase provider records created by earlier requests.

## What the project does not include

The prototype includes no advertising SDK, analytics SDK, subscription SDK, or project-operated backend. It does not include a developer API key. Live usage is charged through the account associated with the key you supply.

For a production fork, publish a privacy policy that matches the final app and complete the platform's required privacy disclosures. Recheck these notes whenever you add a server, telemetry, cloud sync, a new SDK, or another AI provider.
