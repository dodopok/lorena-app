import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

struct WaterLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaterActivityAttributes.self) { context in
            LockScreenWaterView(state: context.state)
                .activityBackgroundTint(LumeColor.lockGradientBottom)
                .activitySystemActionForegroundColor(LumeColor.lockTextPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ringGlyph(progress: context.state.progress, diameter: 44)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: LogWaterIntent(amountML: 300)) {
                        Text("+300").font(.system(size: 13, weight: .heavy))
                    }
                    .tint(LumeColor.brand)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(context.state.currentML) de \(context.state.goalML) ml")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Água de hoje")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            } compactLeading: {
                lumeGlyph(size: 18)
            } compactTrailing: {
                Text("\(Int((context.state.progress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LumeColor.brand)
            } minimal: {
                lumeGlyph(size: 16)
            }
            .widgetURL(URL(string: "lume://hoje"))
            .keylineTint(LumeColor.brand)
        }
    }

    private func ringGlyph(progress: Double, diameter: CGFloat) -> some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.25), lineWidth: diameter * 0.13)
            Circle()
                .trim(from: 0, to: min(1, max(0.02, progress)))
                .stroke(LumeColor.roseBadge, style: StrokeStyle(lineWidth: diameter * 0.13, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
    }

    private func lumeGlyph(size: CGFloat) -> some View {
        Image("LumeMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

/// The lock-screen card — a compact version of the Hoje water card.
struct LockScreenWaterView: View {
    var state: WaterActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: min(1, max(0.02, state.progress)))
                    .stroke(LumeColor.roseBadge, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LumeColor.lockTextPrimary)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(state.currentML) de \(state.goalML) ml")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LumeColor.lockTextPrimary)
                Text(remainingCopy)
                    .font(.system(size: 13))
                    .foregroundStyle(LumeColor.lockTextSecondary)
            }

            Spacer(minLength: 8)

            Button(intent: LogWaterIntent(amountML: 300)) {
                Text("+300").font(.system(size: 13.5, weight: .heavy))
            }
            .buttonStyle(.borderedProminent)
            .tint(LumeColor.lockTextPrimary)
            .foregroundStyle(LumeColor.lockGradientBottom)
        }
        .padding(16)
    }

    private var remainingCopy: String {
        let remainingML = state.goalML - state.currentML
        guard remainingML > 0 else { return "Meta batida hoje." }
        let cups = max(1, Int((Double(remainingML) / 250).rounded(.up)))
        return "Faltam \(cups) copo\(cups == 1 ? "" : "s") até a meta."
    }
}
