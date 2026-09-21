import UIKit
import UniformTypeIdentifiers

final class LumeShareViewController: UIViewController {
    private let appGroupID = "group.com.dodopok.lume"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadSharedLink()
    }

    private func loadSharedLink() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            finish()
            return
        }

        let type: UTType = provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            ? .url
            : .plainText

        provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { [weak self] value, _ in
            let sharedString: String?
            if let url = value as? URL {
                sharedString = url.absoluteString
            } else if let url = value as? NSURL {
                sharedString = url.absoluteURL?.absoluteString
            } else if let string = value as? String {
                sharedString = string
            } else if let string = value as? NSString {
                sharedString = string as String
            } else if let data = value as? Data {
                sharedString = String(data: data, encoding: .utf8)
            } else {
                sharedString = nil
            }

            DispatchQueue.main.async {
                guard let self, let sharedString else {
                    self?.finish()
                    return
                }
                self.openInLume(sharedString)
            }
        }
    }

    private func openInLume(_ sharedString: String) {
        guard let sharedURL = URL(string: sharedString),
              ["http", "https"].contains(sharedURL.scheme?.lowercased()) else {
            finish()
            return
        }

        var components = URLComponents()
        components.scheme = "lume"
        components.host = "share"
        components.queryItems = [URLQueryItem(name: "url", value: sharedURL.absoluteString)]

        guard let lumeURL = components.url else {
            finish()
            return
        }

        // Keep a copy in the shared container. Opening the containing app from
        // a share extension is asynchronous and can be skipped by iOS while
        // the extension is being dismissed; Lume consumes this value on launch
        // or when it becomes active again.
        UserDefaults(suiteName: appGroupID)?.set(sharedURL.absoluteString, forKey: "lume.pendingShareURL")

        extensionContext?.open(lumeURL) { [weak self] _ in
            self?.finish()
        }
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
