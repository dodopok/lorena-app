import SwiftUI

struct AgendaMonthView: View {
    @Binding var selectedDate: Date
    var itemsProvider: (Date, Date) -> [AgendaItem]

    private var monthInterval: DateInterval {
        LumeDateFormat.calendar.dateInterval(of: .month, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 0)
    }

    private var gridStart: Date {
        let firstOfMonth = monthInterval.start
        let weekday = LumeDateFormat.calendar.component(.weekday, from: firstOfMonth)
        let daysFromMonday = (weekday - LumeDateFormat.calendar.firstWeekday + 7) % 7
        return firstOfMonth.adding(days: -daysFromMonday)
    }

    private var gridDates: [Date] { (0..<42).map { gridStart.adding(days: $0) } }
    private var monthItems: [AgendaItem] { itemsProvider(gridStart, gridStart.adding(days: 42)) }
    private func items(on day: Date) -> [AgendaItem] { monthItems.filter { $0.start.isSameDay(as: day) } }
    private var selectedDayItems: [AgendaItem] { items(on: selectedDate) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weekdayHeader

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                    ForEach(gridDates, id: \.self) { day in
                        dayCell(day)
                    }
                }
                .padding(14)
                .lumeSoftGlass(cornerRadius: 28, shadow: false)

                legend

                LumeEyebrow(text: LumeDateFormat.shortWeekdayDayUppercased(selectedDate))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    ForEach(selectedDayItems) { item in
                        AgendaEventCard(item: item)
                    }
                    if selectedDayItems.isEmpty {
                        Text("Nada marcado neste dia.")
                            .font(LumeType.sans(14))
                            .foregroundStyle(LumeColor.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }

                Color.clear.frame(height: 20)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(0..<7, id: \.self) { index in
                Text(LumeDateFormat.weekdayInitial(gridDates[index]))
                    .font(LumeType.mono(10))
                    .foregroundStyle(LumeColor.textFainter)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = LumeDateFormat.calendar.isDate(day, equalTo: selectedDate, toGranularity: .month)
        let isSelected = day.isSameDay(as: selectedDate)
        let dayItems = items(on: day)

        return Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedDate = day }
        } label: {
            VStack(spacing: 4) {
                Text("\(LumeDateFormat.calendar.component(.day, from: day))")
                    .font(LumeType.sans(14, weight: isSelected ? .heavy : .regular))
                    .foregroundStyle(isSelected ? .white : (inMonth ? LumeColor.ink : LumeColor.textFainter.opacity(0.6)))
                HStack(spacing: 2) {
                    ForEach(dayItems.prefix(3)) { item in
                        Circle().fill(isSelected ? .white : item.category.accent).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? LumeColor.brand : Color.clear)
                .shadow(color: isSelected ? LumeColor.brand.opacity(0.3) : .clear, radius: 6, y: 3)
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(AgendaCategory.allCases) { category in
                HStack(spacing: 6) {
                    Circle().fill(category.accent).frame(width: 9, height: 9)
                    Text(category.label).font(LumeType.sans(11.5)).foregroundStyle(LumeColor.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
