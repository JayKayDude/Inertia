import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Credits")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
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

            Spacer()

            Link("Inertia on GitHub", destination: URL(string: "https://github.com/JayKayDude/Inertia")!)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(24)
        .frame(width: 320, height: 220)
    }

    private func creditEntry(name: String, description: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Link(name, destination: URL(string: url)!)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
