import Foundation
import SwiftUI

@MainActor
final class LumeRoute: ObservableObject {
    static let pendingShareKey = "lume.pendingShareURL"
    @Published var pendingSharedURL: URL?

    func receive(_ url: URL) {
        if url.scheme?.lowercased() == "lume" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let raw = components?.queryItems?.first(where: { $0.name == "url" })?.value,
               let sharedURL = URL(string: raw) {
                pendingSharedURL = sharedURL
            }
        } else if ["http", "https"].contains(url.scheme?.lowercased()) {
            pendingSharedURL = url
        }
    }

    func consumeStoredShare() {
        let defaults = UserDefaults(suiteName: LumeModelContainer.appGroupID)
        guard let rawURL = defaults?.string(forKey: Self.pendingShareKey),
              let url = URL(string: rawURL) else { return }
        defaults?.removeObject(forKey: Self.pendingShareKey)
        pendingSharedURL = url
    }
}
