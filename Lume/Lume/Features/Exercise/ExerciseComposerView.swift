import SwiftUI
import SwiftData

/// Screen 18 — recent types as one-tap chips, duration as a big number with presets.
struct ExerciseComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var type: ExerciseType = .caminhada
    @State private var duration: Int = 40
    @State private var intensity: ExerciseIntensity = .leve
    @State private var when: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: "Exercício",
                trailingTitle: "Salvar",
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LumeEyebrow(text: "O que você fez")
                    HStack(spacing: 8) {
                        ForEach(ExerciseType.allCases) { option in
                            LumeChip(title: option.rawValue, isSelected: type == option) { type = option }
                        }
                    }

                    LumeEyebrow(text: "Por quanto tempo")
                        .padding(.top, 6)

                    VStack(spacing: 18) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text("\(duration)")
                                .font(LumeType.serif(58))
                                .foregroundStyle(LumeColor.ink)
                                .contentTransition(.numericText())
                                .animation(.default, value: duration)
                            Text("min").font(LumeType.sans(17)).foregroundStyle(LumeColor.textFaint)
                        }
                        .frame(maxWidth: .infinity)

                        HStack(spacing: 8) {
                            ForEach([15, 30, 40, 60], id: \.self) { preset in
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) { duration = preset }
                                } label: {
                                    Text("\(preset)")
                                        .font(LumeType.sans(13.5, weight: duration == preset ? .heavy : .bold))
                                        .foregroundStyle(duration == preset ? .white : LumeColor.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(duration == preset ? LumeColor.greenDeep : .white.opacity(0.7))
                                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(duration == preset ? 0 : 0.95), lineWidth: 1))
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .lumeSoftGlass(cornerRadius: 26, shadow: false)

                    HStack(spacing: 10) {
                        Menu {
                            Picker("Intensidade", selection: $intensity) {
                                ForEach(ExerciseIntensity.allCases) { Text($0.label).tag($0) }
                            }
                        } label: {
                            labeledCard(label: "Intensidade", value: "\(intensity.label) ▾")
                        }

                        labeledCard(label: "Quando", value: whenLabel)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }

            Button(action: save) {
                Text("Salvar exercício")
                    .font(LumeType.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.plain)
            .background(LumeColor.greenDeep, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func labeledCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(LumeType.sans(12.5)).foregroundStyle(LumeColor.textFaint)
            Text(value).font(LumeType.sans(15.5, weight: .bold)).foregroundStyle(LumeColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
    }

    private var whenLabel: String {
        when.isToday ? "Hoje, \(LumeDateFormat.time(when))" : "\(LumeDateFormat.dayMonthAbbrev(when)), \(LumeDateFormat.time(when))"
    }

    private func save() {
        let entry = ExerciseEntry(type: type.rawValue, durationMinutes: duration, intensity: intensity, date: when)
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
