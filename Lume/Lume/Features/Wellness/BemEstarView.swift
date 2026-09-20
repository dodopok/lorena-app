import SwiftUI
import SwiftData

struct BemEstarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \WaterEntry.date, order: .reverse) private var waterEntries: [WaterEntry]
    @Query(sort: \BathroomEntry.date, order: .reverse) private var bathroomEntries: [BathroomEntry]
    @Query(sort: \ExerciseEntry.date, order: .reverse) private var exerciseEntries: [ExerciseEntry]

    @State private var showingWaterHistory = false
    @State private var showingExercise = false

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.greenOrb, size: 320, opacity: 0.55, blur: 60, alignment: .topLeading, offset: CGSize(width: -70, height: -60), duration: 16),
        OrbSpec(color: LumeColor.roseOrb, size: 260, opacity: 0.45, blur: 54, alignment: .bottomTrailing, offset: CGSize(width: -70, height: -140), duration: 20, reversed: true),
    ]

    private var profile: UserProfile? { profiles.first }
    private var goal: Int { profile?.waterGoalML ?? 2000 }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeColor.canvas.ignoresSafeArea()
                LumeOrbBackground(orbs: orbs)

                ScrollView {
                    VStack(spacing: 12) {
                        Text("Bem-estar")
                            .font(LumeType.serif(32))
                            .foregroundStyle(LumeColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lumeRiseIn()

                        waterCard.lumeRiseIn(delay: 0.06)
                        bathroomCard.lumeRiseIn(delay: 0.12)
                        exerciseCard.lumeRiseIn(delay: 0.18)

                        Color.clear.frame(height: 110)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingWaterHistory) { WaterHistorySheet(entries: waterEntries) }
            .sheet(isPresented: $showingExercise) { ExerciseComposerView() }
        }
    }

    private var waterCard: some View {
        HStack(spacing: 20) {
            WaterFillRing(progress: goal > 0 ? Double(todayWaterML) / Double(goal) : 0, diameter: 104, valueText: LumeCurrency.integer(todayWaterML), unitText: "/ \(LumeCurrency.integer(goal))")

            VStack(alignment: .leading, spacing: 3) {
                Text("Água")
                    .font(LumeType.sans(17, weight: .heavy))
                    .foregroundStyle(LumeColor.ink)
                Text("\(todayWaterCount) copos hoje · média de \(averageLitersLabel)")
                    .font(LumeType.sans(13.5))
                    .foregroundStyle(LumeColor.textMuted)

                HStack(spacing: 8) {
                    Button {
                        logWater(300)
                    } label: {
                        Text("+300").font(LumeType.sans(14, weight: .heavy)).foregroundStyle(LumeColor.greenText)
                            .frame(maxWidth: .infinity).frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.85), lineWidth: 1)))

                    Button("Histórico") { showingWaterHistory = true }
                        .font(LumeType.sans(14, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LumeColor.greenDeep))
                        .buttonStyle(.plain)
                }
                .padding(.top, 10)
            }
        }
        .padding(22)
        .lumeSoftGlass(cornerRadius: 28)
    }

    private var bathroomCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Banheiro").font(LumeType.sans(17, weight: .heavy)).foregroundStyle(LumeColor.ink)
                Spacer()
                Text("média \(averageBathroomLabel) por dia").font(LumeType.sans(13.5)).foregroundStyle(LumeColor.textMuted)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(lastSevenDays, id: \.self) { day in
                    let count = bathroomEntries.filter { $0.date.isSameDay(as: day) }.count
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(day.isToday ? LumeColor.greenDeep : (count > 0 ? LumeColor.greenChipBgMid : LumeColor.greenChipBgFaint))
                            .frame(height: barHeight(for: count))
                        Text(LumeDateFormat.weekdayInitial(day))
                            .font(LumeType.sans(11, weight: day.isToday ? .heavy : .regular))
                            .foregroundStyle(day.isToday ? LumeColor.greenTextDeep : LumeColor.textFaint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 96)
            .padding(.top, 18)

            Button {
                modelContext.insert(BathroomEntry())
                try? modelContext.save()
            } label: {
                Text("Registrar mais uma")
                    .font(LumeType.sans(15, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LumeColor.greenDeep))
            .padding(.top, 16)
        }
        .padding(22)
        .lumeSoftGlass(cornerRadius: 28)
    }

    private var exerciseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Exercício").font(LumeType.sans(17, weight: .heavy)).foregroundStyle(LumeColor.ink)
                Spacer()
                Button("Novo") { showingExercise = true }
                    .font(LumeType.sans(13.5, weight: .bold))
                    .foregroundStyle(LumeColor.brand)
            }

            if let last = exerciseEntries.first {
                HStack(spacing: 14) {
                    Circle().fill(LumeColor.lavenderChipBgFaint).frame(width: 42, height: 42)
                        .overlay(Image(systemName: ExerciseType(rawValue: last.type)?.symbolName ?? "figure.mixed.cardio").font(.system(size: 16)).foregroundStyle(LumeColor.lavenderText))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(last.type).font(LumeType.sans(15.5, weight: .bold)).foregroundStyle(LumeColor.ink)
                        Text("\(weekdayLabel(last.date)) · \(last.durationMinutes) min · \(last.intensity.label.lowercased())")
                            .font(LumeType.sans(13)).foregroundStyle(LumeColor.textFaint)
                    }
                    Spacer()
                }
            } else {
                Text("Nada registrado ainda.")
                    .font(LumeType.sans(14)).foregroundStyle(LumeColor.textMuted)
            }
        }
        .padding(22)
        .lumeSoftGlass(cornerRadius: 28)
    }

    private var todayWaterML: Int { waterEntries.filter(\.date.isToday).reduce(0) { $0 + $1.amountML } }
    private var todayWaterCount: Int { waterEntries.filter(\.date.isToday).count }

    private var averageLitersLabel: String {
        let days = 7
        let start = Date.now.adding(days: -days)
        let recent = waterEntries.filter { $0.date >= start }
        let total = recent.reduce(0) { $0 + $1.amountML }
        let avg = Double(total) / Double(days) / 1000
        return String(format: "%.1f l", avg).replacingOccurrences(of: ".", with: ",")
    }

    private var averageBathroomLabel: String {
        let days = 7
        let start = Date.now.adding(days: -days)
        let recent = bathroomEntries.filter { $0.date >= start }
        let avg = Double(recent.count) / Double(days)
        return String(format: "%.1f", avg).replacingOccurrences(of: ".", with: ",")
    }

    private var lastSevenDays: [Date] {
        (0..<7).map { Date.now.startOfDay.adding(days: -(6 - $0)) }
    }

    private func barHeight(for count: Int) -> CGFloat {
        let maxCount = 6.0
        return max(10, CGFloat(min(Double(count), maxCount) / maxCount) * 96)
    }

    private func weekdayLabel(_ date: Date) -> String {
        if date.isToday { return "hoje" }
        if date.isYesterday { return "ontem" }
        let formatter = DateFormatter()
        formatter.locale = LumeDateFormat.ptBR
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func logWater(_ amount: Int) {
        modelContext.insert(WaterEntry(amountML: amount))
        try? modelContext.save()
        LiveActivityController.shared.logWater(totalML: todayWaterML + amount, goalML: goal)
    }
}
