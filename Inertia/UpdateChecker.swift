import Foundation

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    @Published var availableVersion: String?

    private var timer: Timer?
    private let releasesURL = URL(string: "https://api.github.com/repos/JayKayDude/Inertia/releases/latest")!
    static let releasesPageURL = URL(string: "https://github.com/JayKayDude/Inertia/releases/latest")!

    func startPeriodicChecks() {
        checkForUpdates()
        timer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
    }

    func checkForUpdates() {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else { return }

            let remote = tagName.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "^[vV]", with: "", options: .regularExpression)
            let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

            if Self.isNewer(remote: remote, local: local) {
                DispatchQueue.main.async {
                    self?.availableVersion = remote
                }
            } else {
                DispatchQueue.main.async {
                    self?.availableVersion = nil
                }
            }
        }.resume()
    }

    static func isNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        let count = max(r.count, l.count)
        for i in 0..<count {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}
