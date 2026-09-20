import SwiftUI

struct AgendaDayView: View {
    @Binding var selectedDate: Date
    var allItems: [AgendaItem]
    @State private var calendarSync = CalendarSyncService.shared

    private var weekDates: [Date] {
        let start = LumeDateFormat.calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).map { start.adding(days: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(weekDates, id: \.self) { day in
                        dayCell(day)
                    }
                }

                LumeEyebrow(text: LumeDateFormat.shortWeekdayDayUppercased(selectedDate))
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(Array(allItems.enumerated()), id: \.element.id) { index, item in
                        AgendaEventCard(item: item)
                            .lumeRiseIn(delay: Double(index) * 0.06)
                    }

                    if allItems.isEmpty {
                        Text("Nada marcado por aqui.")
                            .font(LumeType.sans(14.5))
                            .foregroundStyle(LumeColor.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    }
                }

                if !calendarSync.isAuthorized {
                    connectRow
                }

                Color.clear.frame(height: 30)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = day.isSameDay(as: selectedDate)
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedDate = day }
        } label: {
            VStack(spacing: 4) {
                Text(LumeDateFormat.weekdayInitial(day))
                    .font(LumeType.sans(11))
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : LumeColor.textFaint)
                Text("\(LumeDateFormat.calendar.component(.day, from: day))")
                    .font(LumeType.sans(17, weight: isSelected ? .heavy : .bold))
                    .foregroundStyle(isSelected ? .white : LumeColor.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? LumeColor.brand : .white.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(isSelected ? 0 : 0.8), lineWidth: 1))
                .shadow(color: isSelected ? LumeColor.brand.opacity(0.3) : .clear, radius: 8, y: 4)
        }
    }

    private var connectRow: some View {
        Button {
            Task { await calendarSync.requestAccess() }
        } label: {
            HStack(spacing: 12) {
                Circle().fill(LumeColor.brandPillLight).frame(width: 34, height: 34)
                    .overlay(Image(systemName: "calendar.badge.plus").font(.system(size: 14)).foregroundStyle(LumeColor.brandDeep))
                Text("Conecte o Calendário do iPhone para ver tudo aqui.")
                    .font(LumeType.sans(13.5))
                    .foregroundStyle(LumeColor.textMuted)
                    .multilineTextAlignment(.leading)
                Spacer()
                Text("Conectar")
                    .font(LumeType.sans(13.5, weight: .heavy))
                    .foregroundStyle(LumeColor.brand)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(LumeColor.brand.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
    }
}

struct AgendaEventCard: View {
    var item: AgendaItem
    @State private var showingExpenseSheet = false

    var body: some View {
        HStack(spacing: 16) {
            Capsule().fill(item.category.accent).frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(LumeType.sans(16, weight: .heavy))
                        .foregroundStyle(LumeColor.ink)
                        .lineLimit(1)
                    if item.isExternal {
                        Image(systemName: "icloud")
                            .font(.system(size: 11))
                            .foregroundStyle(LumeColor.textFainter)
                    }
                }
                Text(item.location.map { "\(item.timeRangeLabel) · \($0)" } ?? item.timeRangeLabel)
                    .font(LumeType.sans(13.5))
                    .foregroundStyle(LumeColor.textMuted)
                    .lineLimit(1)

                if item.remindToLogExpense {
                    Button {
                        showingExpenseSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle().fill(LumeColor.brand).frame(width: 7, height: 7)
                            Text(item.loggedExpense ? "Gasto anotado" : "Lembrar de anotar o gasto")
                                .font(LumeType.sans(12.5, weight: .bold))
                                .foregroundStyle(LumeColor.brandDeep)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(LumeColor.brandPillLight))
                    }
                    .buttonStyle(.plain)
                    .disabled(item.loggedExpense)
                    .padding(.top, 6)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .lumeSoftGlass(cornerRadius: 24, shadow: false)
        .sheet(isPresented: $showingExpenseSheet) {
            NewExpenseView(eventToLink: item.sourceEvent)
        }
    }
}
