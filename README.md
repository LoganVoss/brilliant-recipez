# Recipe Snap — archived

I had an idea, wanted to see if AI could do it, and wired it all together. Recipe Snap used Grok's vision API to identify ingredients from a photo, generate a recipe, and create an image of the finished dish.

I've since sunset the app and removed it from the App Store. I'm sharing the code because it was an important project for learning how to use AI, Xcode, Swift, and API wrappers. Maybe it'll come in handy for someone else building something similar.

This is the original Swift code, with a recreated Xcode project and the expired key removed. It's archived and no longer maintained.

To explore it:

- Open `RecipeSnap.xcodeproj` in Xcode 16 or later. The project targets iOS 17+.
- You'll need **your own Grok / xAI API key**. Set `XAI_API_KEY` in your local Run scheme's environment variables; never commit its value.
- Historical vision and image models may no longer be supported, which can prevent recipe generation. Live API functionality hasn't been retested.

See [archive notes](ARCHIVE_NOTES.md) for missing assets and setup limitations. MIT licensed.
