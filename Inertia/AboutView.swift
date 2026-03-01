import SwiftUI

struct AboutView: View {
    @ObservedObject private var updateChecker = UpdateChecker.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            VStack(spacing: 4) {
                Text("Inertia")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let version = updateChecker.availableVersion {
                    Link("v\(version) available — download", destination: UpdateChecker.releasesPageURL)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            VStack(spacing: 4) {
                Text("JayKayDude")
                    .font(.headline)
                Text("Young Developer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("GitHub Profile", destination: URL(string: "https://github.com/JayKayDude")!)
                    .font(.caption)
            }

            Divider()

            Button("Support Inertia — Coming Soon") {}
                .buttonStyle(.bordered)
                .disabled(true)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Credits")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                creditEntry(
                    name: "Mac Mouse Fix",
                    description: "Physics formulas reference — by Noah Nuebling",
                    url: "https://github.com/noah-nuebling/mac-mouse-fix"
                )

                creditEntry(
                    name: "App Icon",
                    description: "Created by Freepik — Flaticon",
                    url: "https://www.flaticon.com/free-icons/inertia"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Link("Inertia on GitHub", destination: URL(string: "https://github.com/JayKayDude/Inertia")!)
                .font(.caption)
        }
        .padding(24)
        .frame(width: 300)
    }

    private func creditEntry(name: String, description: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Link(name, destination: URL(string: url)!)
                .font(.subheadline)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
