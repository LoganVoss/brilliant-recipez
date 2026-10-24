# Archive notes

The 14 Swift files in `RecipeSnap/` were extracted from the supplied [Recipe Snap Markdown](archive/Recipe%20Snap.redacted.md). That document is retained as a historical reference with its expired credential replaced by `YOUR_XAI_API_KEY`. Its opening editing request is part of the old document, not a change applied to this archive.

## Packaging changes

- Removed Markdown escape characters and trailing formatting whitespace from the Swift files.
- Replaced the embedded API key with a read of the local `XAI_API_KEY` environment variable. The existing missing-key error handles an unset variable.
- Recreated an Xcode project, shared scheme, and camera permission configuration because the original project was lost.

The original UI, prompts, networking, strict ingredient checks, image generation, bookmark storage, trial counter, and StoreKit logic are preserved. There is no Apple Intelligence replacement or new recipe engine.

## What is missing or historical

- `Image("RecipeSnap")` and the `SuperJellyfish` font are referenced in the code, but their asset files were not supplied. Without them, the logo is absent and text falls back to a system font.
- `grok-2-vision-1212` and `grok-2-image-1212` are the original model IDs. They have not been replaced or tested against the live service. Check [xAI's current models](https://docs.x.ai/developers/models) and [API setup](https://docs.x.ai/developers/quickstart) before attempting to use the app.
- StoreKit product ID `10`, the five-use trial, loading UI, and the original policy links remain as historical app code. A source checkout does not include the original App Store Connect setup or a working subscription product.
- The app sends ingredient photos to xAI and downloads generated recipe images. It does not process photos locally. The original diagnostic logging and prototype limitations remain.

Earlier reconstruction commits and releases are retained in Git history. They are separate from this original-source archive.

## Verification

On October 23, 2026, the recreated project compiled with Xcode 27.1 for both iOS Simulator (Debug) and iOS devices (unsigned Release). The app launched on an iOS 26.5 simulator. No Swift compatibility edits were needed. Live Grok requests, physical camera capture, and StoreKit purchases were not tested.
