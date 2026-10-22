import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: model.availability.isAvailable ? "checkmark.circle" : "info.circle")
                            .font(.title2.weight(.light)).foregroundStyle(Theme.brass).accessibilityHidden(true)
                        Text(model.availability.title).font(.system(.title3, design: .serif))
                            .accessibilityIdentifier("modelAvailabilityTitle")
                        Text(model.availability.message).font(.subheadline).foregroundStyle(.secondary)
                            .accessibilityIdentifier("modelAvailabilityMessage")
                    }.padding(.vertical, 8)
                    Button("Check again") { model.refreshAvailability() }.accessibilityIdentifier("refreshAvailability")
                } header: { Text("On-device intelligence") } footer: {
                    if !model.availability.isAvailable {
                        Text("Check Apple Intelligence & Siri in your device’s Settings. An eligible device and downloaded models are required.")
                    }
                }
                Section {
                    LabeledContent("Recipe generation", value: "Apple Intelligence")
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Photo recognition").font(.subheadline.weight(.medium))
                        Text(model.supportsImageInput ? "On-device image model" : "On-device label and image suggestions")
                            .font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("nativePhotoStatus")
                    }.padding(.vertical, 3)
                } footer: {
                    Text("Review photo suggestions before creating a recipe. Type any ingredients the photo missed.")
                }
                Section {
                    Label("Photos and ingredients stay on this device", systemImage: "iphone")
                    Label("No accounts or generation fees", systemImage: "checkmark.circle")
                    Label("Saved recipes are available offline", systemImage: "bookmark")
                } header: { Text("Privacy") }
                Section {
                    Link(destination: URL(string: "https://github.com/LoganVoss/brilliant-recipez")!) {
                        HStack { Text("View source on GitHub"); Spacer(); Image(systemName: "arrow.up.right").font(.caption) }
                    }
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0")
                } footer: { Text("Brilliant! Recipez · Open source under the MIT license.") }
            }
            .scrollContentBackground(.hidden).background(Theme.cream).navigationTitle("Settings")
            .onAppear { model.refreshAvailability() }
        }
    }
}
