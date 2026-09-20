import SwiftUI
import AuthenticationServices

/// Screen 01 — the animated welcome + auth choice. If Sign in with Apple
/// doesn't hand back a given name (it only ever does on the very first
/// authorization), or she picks "Usar só neste iPhone", we ask for a first
/// name inline before moving on — Hoje greets her by name, so we need one
/// from somewhere before onboarding can finish.
struct WelcomeStepView: View {
    @Bindable var draft: OnboardingDraft
    var onFinishedAuth: () -> Void

    @State private var showNameEntry = false
    @FocusState private var nameFieldFocused: Bool

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.roseOrb, size: 300, opacity: 0.62, blur: 52, alignment: .topLeading, offset: CGSize(width: -70, height: -40), duration: 13),
        OrbSpec(color: LumeColor.amberOrb, size: 260, opacity: 0.55, blur: 56, alignment: .topTrailing, offset: CGSize(width: 80, height: 230), duration: 17, reversed: true),
        OrbSpec(color: LumeColor.lavenderOrb, size: 320, opacity: 0.42, blur: 60, alignment: .bottomLeading, offset: CGSize(width: -40, height: 90), duration: 21),
    ]

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()
            LumeOrbBackground(orbs: orbs)

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                VStack(spacing: 24) {
                    LumeLogoMark()

                    Text("LUME")
                        .font(LumeType.serif(38))
                        .tracking(6)
                        .foregroundStyle(LumeColor.brand)
                        .lumeRiseIn(delay: 0.1)

                    VStack(spacing: 14) {
                        Text("Um lugar calmo\npara o seu dia.")
                            .font(LumeType.serif(36))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(LumeColor.ink)
                        Text("Água, banheiro, mesada e gratidão. Anotações de dois segundos, sem cobrança.")
                            .font(LumeType.sans(16))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(LumeColor.textTertiary)
                            .frame(maxWidth: 290)
                    }
                    .lumeRiseIn(delay: 0.18)
                }

                Spacer(minLength: 20)

                Group {
                    if showNameEntry {
                        nameEntryPanel.transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        authButtons.transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }

    private var authButtons: some View {
        VStack(spacing: 10) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                handleAppleResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            LumeGlassButton(title: "Usar só neste iPhone") {
                draft.authMethod = .local
                withAnimation(.easeOut(duration: 0.3)) { showNameEntry = true }
            }

            Text("Seus dados ficam no aparelho até você escolher sincronizar.")
                .font(LumeType.sans(12.5))
                .foregroundStyle(LumeColor.textFaint)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .lumeRiseIn(delay: 0.32)
    }

    private var nameEntryPanel: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                LumeEyebrow(text: "Como podemos te chamar?")
                TextField("Seu primeiro nome", text: $draft.name)
                    .font(LumeType.serif(24))
                    .foregroundStyle(LumeColor.ink)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($nameFieldFocused)
                    .onSubmit(proceedIfPossible)
            }
            .padding(18)
            .lumeSoftGlass(cornerRadius: 20)

            LumePrimaryButton(
                title: "Continuar",
                isEnabled: !draft.name.trimmingCharacters(in: .whitespaces).isEmpty,
                action: proceedIfPossible
            )
        }
        .onAppear { nameFieldFocused = true }
    }

    private func proceedIfPossible() {
        guard !draft.name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        onFinishedAuth()
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        draft.authMethod = .apple
        if let given = credential.fullName?.givenName, !given.isEmpty {
            draft.name = given
            onFinishedAuth()
        } else {
            withAnimation(.easeOut(duration: 0.3)) { showNameEntry = true }
        }
    }
}
