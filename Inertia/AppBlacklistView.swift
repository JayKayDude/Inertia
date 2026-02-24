import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AppBlacklistView: View {
    @EnvironmentObject var config: ScrollConfig
    @State private var runningApps: [NSRunningApplication] = []
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Blacklist")
                .font(.headline)
            Text("Smooth scrolling is disabled in these apps.")
                .font(.caption)
                .foregroundStyle(.secondary)

            let ids = config.blacklistedBundleIDs.sorted()

            List(ids, id: \.self, selection: $selection) { bundleID in
                HStack(spacing: 8) {
                    appIcon(for: bundleID)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(appName(for: bundleID))
                        .lineLimit(1)
                }
            }
            .listStyle(.bordered)
            .frame(height: 128)

            HStack(spacing: 0) {
                Button {
                    showAddMenu()
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .frame(width: 28, height: 22)

                Divider()
                    .frame(height: 16)

                Button {
                    if let sel = selection {
                        var set = config.blacklistedBundleIDs
                        set.remove(sel)
                        config.blacklistedBundleIDs = set
                        selection = nil
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .frame(width: 28, height: 22)
                .disabled(selection == nil)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(nsColor: .separatorColor)))
        }
        .onAppear { refreshRunningApps() }
    }

    private func showAddMenu() {
        let menu = NSMenu()

        let runningItem = NSMenuItem(title: "Running Apps", action: nil, keyEquivalent: "")
        let runningSubmenu = NSMenu()
        let blacklisted = config.blacklistedBundleIDs
        let available = runningApps.filter { app in
            guard let id = app.bundleIdentifier else { return false }
            return !blacklisted.contains(id) && app.activationPolicy == .regular
        }
        if available.isEmpty {
            let emptyItem = NSMenuItem(title: "No apps available", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            runningSubmenu.addItem(emptyItem)
        } else {
            for app in available {
                let item = NSMenuItem(title: app.localizedName ?? app.bundleIdentifier ?? "Unknown", action: #selector(AddMenuTarget.menuAction(_:)), keyEquivalent: "")
                item.representedObject = app.bundleIdentifier
                item.target = AddMenuTarget.shared
                runningSubmenu.addItem(item)
            }
        }
        runningItem.submenu = runningSubmenu
        menu.addItem(runningItem)

        let browseItem = NSMenuItem(title: "Browse...", action: #selector(AddMenuTarget.browseAction(_:)), keyEquivalent: "")
        browseItem.target = AddMenuTarget.shared
        menu.addItem(browseItem)

        AddMenuTarget.shared.onAdd = { [self] bundleID in addApp(bundleID: bundleID) }
        AddMenuTarget.shared.onBrowse = { [self] in browseForApp() }

        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    private func addApp(bundleID: String?) {
        guard let bundleID else { return }
        var set = config.blacklistedBundleIDs
        set.insert(bundleID)
        config.blacklistedBundleIDs = set
    }

    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an app to blacklist"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let id = Bundle(url: url)?.bundleIdentifier {
            addApp(bundleID: id)
        }
    }

    private func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func appIcon(for bundleID: String) -> Image {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            return Image(nsImage: icon)
        }
        return Image(systemName: "app")
    }

    private func appName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default.displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }
}

private class AddMenuTarget: NSObject {
    static let shared = AddMenuTarget()
    var onAdd: ((String?) -> Void)?
    var onBrowse: (() -> Void)?

    @objc func menuAction(_ sender: NSMenuItem) {
        onAdd?(sender.representedObject as? String)
    }

    @objc func browseAction(_ sender: NSMenuItem) {
        onBrowse?()
    }
}
