import LocalAuthentication
import SwiftUI

/// Gates the app behind Face ID when the "Abrir com Face ID" setting is on.
/// `@MainActor` because it drives UI state directly; `unlock`'s completion
/// hops back with an explicit `Task { @MainActor in }` since LAContext calls
/// its handler on an arbitrary background queue.
@Observable
@MainActor
final class AppLockController {
    var isLocked: Bool = false

    func unlock(completion: @escaping (Bool) -> Void = { _ in }) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometry/passcode configured on this device — don't lock her out.
            isLocked = false
            completion(true)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Abrir o Lume") { success, _ in
            Task { @MainActor in
                if success { self.isLocked = false }
                completion(success)
            }
        }
    }
}

/// The dark screen shown over the app while it's locked.
struct LockGateView: View {
    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [LumeColor.lockGradientTop, LumeColor.lockGradientBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image("LumeMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Lume está trancado")
                    .font(LumeType.serif(22))
                    .foregroundStyle(LumeColor.lockTextPrimary)

                Button(action: onUnlock) {
                    Text("Desbloquear")
                        .font(LumeType.sans(16, weight: .bold))
                        .foregroundStyle(LumeColor.lockGradientBottom)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(Capsule().fill(LumeColor.lockTextPrimary))
            }
        }
    }
}
