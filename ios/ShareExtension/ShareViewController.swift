import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private static let appGroup = "group.com.dodopok.lume"
  private static let pendingURLKey = "pending_shared_url"
  private static let pendingAtKey = "pending_shared_url_at"

  private var didHandleInput = false

  override func loadView() {
    let root = UIView()
    root.backgroundColor = .systemBackground

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    let spinner = UIActivityIndicatorView(style: .medium)
    spinner.startAnimating()
    let label = UILabel()
    label.text = "Abrindo no Lume…"
    label.textColor = .label
    label.font = .preferredFont(forTextStyle: .body)

    stack.addArrangedSubview(spinner)
    stack.addArrangedSubview(label)
    root.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: root.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: root.centerYAnchor),
    ])
    view = root
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    handleInput()
  }

  private func handleInput() {
    guard !didHandleInput else { return }
    didHandleInput = true

    let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    let attachments = items.flatMap { $0.attachments ?? [] }
    let urlType = UTType.url.identifier
    let textType = UTType.text.identifier
    guard let provider = attachments.first(where: {
      $0.hasItemConformingToTypeIdentifier(urlType)
    }) ?? attachments.first(where: {
      $0.hasItemConformingToTypeIdentifier(textType)
    }) else {
      finish()
      return
    }

    let type = provider.hasItemConformingToTypeIdentifier(urlType) ? urlType : textType
    provider.loadItem(forTypeIdentifier: type, options: nil) { [weak self] item, _ in
      DispatchQueue.main.async {
        guard let self else { return }
        guard let raw = Self.stringValue(from: item), let url = Self.validatedURL(raw) else {
          self.finish()
          return
        }

        let defaults = UserDefaults(suiteName: Self.appGroup)
        defaults?.set(url.absoluteString, forKey: Self.pendingURLKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: Self.pendingAtKey)

        guard let callback = URL(string: "lume://share"), let context = self.extensionContext else {
          self.finish()
          return
        }
        context.open(callback) { [weak self] _ in
          self?.finish()
        }
      }
    }
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: nil)
  }

  private static func stringValue(from item: NSSecureCoding?) -> String? {
    if let url = item as? URL { return url.absoluteString }
    if let url = item as? NSURL { return url.absoluteString }
    if let text = item as? String { return text }
    if let text = item as? NSString { return text as String }
    return nil
  }

  private static func validatedURL(_ raw: String) -> URL? {
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 4096, let url = URL(string: value) else {
      return nil
    }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let scheme = components.scheme?.lowercased(),
          (scheme == "http" || scheme == "https"),
          let host = components.host,
          !host.isEmpty,
          components.user == nil,
          components.password == nil else {
      return nil
    }
    return url
  }
}
