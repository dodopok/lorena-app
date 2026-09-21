import SwiftUI

struct AgendaWeekView: View {
    @Binding var selectedDate: Date
    var itemsProvider: (Date, Date) -> [AgendaItem]
    var onSelect: (AgendaItem) -> Void

    private let startHour = 7
    private let endHour = 21

    private var weekStart: Date {
        LumeDateFormat.calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
    }
    private var weekDates: [Date] { (0..<7).map { weekStart.adding(days: $0) } }
    private var allItems: [AgendaItem] { itemsProvider(weekStart, weekStart.adding(days: 7)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 3) {
                    Color.clear.frame(width: 26)
                    ForEach(weekDates, id: \.self) { day in
                        dayHeader(day)
                    }
                }

                GeometryReader { geo in
                    let hourHeight = geo.size.height / CGFloat(endHour - startHour)
                    HStack(alignment: .top, spacing: 3) {
                        hourLabels(hourHeight: hourHeight)
                        ForEach(weekDates, id: \.self) { day in
                            ZStack(alignment: .top) {
                                gridLines(hourHeight: hourHeight)
                                ForEach(items(on: day)) { item in
                                    eventBlock(item, hourHeight: hourHeight)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 320)
                .padding(12)
                .lumeSoftGlass(cornerRadius: 26, shadow: false)

                legend
                Color.clear.frame(height: 20)
            }
        }
    }

    private func items(on day: Date) -> [AgendaItem] {
        allItems.filter { $0.start.isSameDay(as: day) }
    }

    private func dayHeader(_ day: Date) -> some View {
        let isSelected = day.isSameDay(as: selectedDate)
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedDate = day }
        } label: {
            VStack(spacing: 2) {
                Text(LumeDateFormat.weekdayInitial(day))
                    .font(LumeType.mono(10.5))
                Text("\(LumeDateFormat.calendar.component(.day, from: day))")
                    .font(LumeType.sans(13, weight: .bold))
            }
            .foregroundStyle(isSelected ? LumeColor.brand : LumeColor.ink)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func hourLabels(hourHeight: CGFloat) -> some View {
        Canvas { context, size in
            var hour = startHour
            while hour <= endHour {
                let y = CGFloat(hour - startHour) * hourHeight
                context.draw(
                    Text(String(format: "%02d", hour)).font(LumeType.mono(9)).foregroundColor(LumeColor.textFainter),
                    at: CGPoint(x: size.width, y: y),
                    anchor: .topTrailing
                )
                hour += 2
            }
        }
        .frame(width: 26, height: hourHeight * CGFloat(endHour - startHour))
    }

    private func gridLines(hourHeight: CGFloat) -> some View {
        Canvas { context, size in
            var hour = startHour
            while hour <= endHour {
                let y = CGFloat(hour - startHour) * hourHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(LumeColor.brandPlumStart.opacity(0.07)), lineWidth: 1)
                hour += 2
            }
        }
        .frame(height: hourHeight * CGFloat(endHour - startHour))
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.001)))
    }

    private func eventBlock(_ item: AgendaItem, hourHeight: CGFloat) -> some View {
        Button {
            onSelect(item)
        } label: {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(item.category.chipBackground)
                .overlay(alignment: .leading) {
                    Rectangle().fill(item.category.accent).frame(width: 3)
                }
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .frame(height: blockHeight(item, hourHeight: hourHeight))
                .frame(maxWidth: .infinity)
                .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .offset(y: yOffset(for: item.start, hourHeight: hourHeight))
    }

    private func yOffset(for date: Date, hourHeight: CGFloat) -> CGFloat {
        let comps = LumeDateFormat.calendar.dateComponents([.hour, .minute], from: date)
        let hour = Double(comps.hour ?? startHour)
        let minute = Double(comps.minute ?? 0)
        let fractional = (hour - Double(startHour)) + minute / 60
        return CGFloat(max(0, fractional)) * hourHeight
    }

    private func blockHeight(_ item: AgendaItem, hourHeight: CGFloat) -> CGFloat {
        guard let end = item.end else { return hourHeight * 0.6 }
        let startY = yOffset(for: item.start, hourHeight: hourHeight)
        let endY = yOffset(for: end, hourHeight: hourHeight)
        return max(hourHeight * 0.32, endY - startY)
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
    }
}
