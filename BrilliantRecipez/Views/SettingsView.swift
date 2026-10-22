import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var key = ""
    @State private var textModel = ""
    @State private var visionModel = ""
    @State private var status: String?
    @State private var confirmRemove = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image("BrandMark").resizable().frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 17))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Brilliant! Recipez").font(.system(.title3, design: .serif).bold())
                            Text("A little intelligence. A lot of possibility.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
                Section {
                    Label(model.hasKey ? "Key saved securely on this device" : "Your own Grok key is required", systemImage: model.hasKey ? "checkmark.shield" : "key")
                        .font(.subheadline)
                    SecureField(model.hasKey ? "Paste a replacement key" : "Paste your xAI API key", text: $key)
                        .textContentType(.password).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("apiKeyInput")
                    Link("Get a key from xAI", destination: URL(string: "https://console.x.ai/")!)
                } header: { Text("Power your kitchen") } footer: {
                    Text("Your key is kept in iOS Keychain, never in the project or recipe collection. xAI may charge for API usage. A Grok chat subscription does not necessarily include API credits.")
                }
                Section {
                    LabeledContent("Recipe model") { TextField("grok-4.7", text: $textModel).multilineTextAlignment(.trailing).accessibilityIdentifier("recipeModelInput") }
                    LabeledContent("Vision model") { TextField("grok-4.7", text: $visionModel).multilineTextAlignment(.trailing).accessibilityIdentifier("visionModelInput") }
                    Link("Check available models", destination: URL(string: "https://docs.x.ai/developers/models")!)
                } header: { Text("Models that work for you") } footer: {
                    Text("Model IDs and APIs change. Specific VISION or image APIs may no longer be supported, which can affect recognition, performance, or generation. Choose models available to your account. Manual ingredients bypass vision but still need a working recipe model.")
                }.textInputAutocapitalization(.never).autocorrectionDisabled()
                Section {
                    Button("Save configuration") {
                        do {
                            try model.saveSettings(key: key.isEmpty ? nil : key, text: textModel, vision: visionModel)
                            key = ""
                            status = "Configuration saved. Your key has not been tested with a live request."
                        } catch { model.errorMessage = error.localizedDescription }
                    }.accessibilityIdentifier("saveConfiguration")
                    if let status { Text(status).font(.footnote).foregroundStyle(.secondary) }
                    if model.hasKey { Button("Remove API key", role: .destructive) { confirmRemove = true } }
                }
                Section {
                    Label("Saved recipes stay on your device", systemImage: "internaldrive")
                    Label("Selected photos go to xAI only when you tap Identify", systemImage: "photo")
                    Label("No ad SDKs, analytics, or subscriptions", systemImage: "hand.raised")
                    Link("xAI API privacy & retention", destination: URL(string: "https://docs.x.ai/developers/faq/security")!)
                    Link("Open-source project", destination: URL(string: "https://github.com/LoganVoss/brilliant-recipez")!)
                } header: { Text("Made for curious builders") } footer: {
                    Text("Open-source prototype · MIT license. AI output is a starting point; check ingredient identification, allergens, and cooking safety. Photos are resized and re-encoded before upload. Requests are subject to xAI’s retention policy.")
                }
            }.scrollContentBackground(.hidden).background(Theme.cream).navigationTitle("Settings")
                .onAppear { textModel = model.textModel; visionModel = model.visionModel }
                .confirmationDialog("Remove the API key from this device?", isPresented: $confirmRemove, titleVisibility: .visible) {
                    Button("Remove key", role: .destructive) { model.removeKey(); key = ""; status = nil }
                }
        }
    }
}
