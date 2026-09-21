import SwiftUI
import SwiftData

struct WaterGoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()

            VStack(spacing: 28) {
                WaterFillRing(
                    progress: 0.46,
                    diameter: 220,
                    valueText: LumeCurrency.integer(profile?.waterGoalML ?? 2000),
                    unitText: "ML / DIA"
                )

                HStack(spacing: 20) {
                    LumeGlassIconButton(systemImage: "minus", size: 54, iconSize: 20) { adjust(-100) }
                    Text("passo 100 ml").font(LumeType.mono(12)).foregroundStyle(LumeColor.textFaint)
                    LumeSolidIconButton(systemImage: "plus", size: 54, iconSize: 20) { adjust(100) }
                }

                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 28)
        }
        .navigationTitle("Meta de água")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func adjust(_ delta: Int) {
        guard let profile else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            profile.waterGoalML = min(5000, max(500, profile.waterGoalML + delta))
        }
        try? modelContext.save()
    }
}
