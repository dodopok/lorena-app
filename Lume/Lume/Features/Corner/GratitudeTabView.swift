import SwiftUI
import SwiftData
import UIKit

struct GratitudeTabView: View {
    @Query(sort: \GratitudeEntry.date, order: .reverse) private var entries: [GratitudeEntry]
    @State private var showingComposer = false

    private var todayEntry: GratitudeEntry? { entries.first(where: \.date.isToday) }
    private var pastEntries: [GratitudeEntry] { entries.filter { !$0.date.isToday } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Button { showingComposer = true } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        LumeEyebrow(text: "Hoje")
                        if let data = todayEntry?.photoData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(.black.opacity(0.35), in: Circle())
                                        .padding(10)
                                }
                        }
                        if let todayEntry, !todayEntry.text.isEmpty {
                            Text(todayEntry.text)
                                .font(LumeType.serif(20))
                                .foregroundStyle(LumeColor.ink)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Quer guardar algo bom de hoje?")
                                .font(LumeType.serif(23))
                                .foregroundStyle(LumeColor.ink)
                        }
                        HStack(spacing: 10) {
                            Text(todayEntry == nil ? "Escrever" : "Editar")
                                .font(LumeType.sans(15, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LumeColor.brand))
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .lumeSoftGlass(cornerRadius: 28)
                .lumeRiseIn()

                if !pastEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Últimos dias")
                        VStack(spacing: 10) {
                            ForEach(Array(pastEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                                HStack(spacing: 14) {
                                    VStack(spacing: 1) {
                                        Text("\(LumeDateFormat.calendar.component(.day, from: entry.date))")
                                            .font(LumeType.serif(22))
                                            .foregroundStyle(LumeColor.ink)
                                        Text(LumeDateFormat.dayMonthAbbrev(entry.date).split(separator: " ").last.map(String.init) ?? "")
                                            .font(LumeType.sans(10.5))
                                            .foregroundStyle(LumeColor.textFaint)
                                    }
                                    .frame(width: 40)

                                    Rectangle().fill(LumeColor.brandPlumStart.opacity(0.1)).frame(width: 1)

                                    Text(entry.text)
                                        .font(LumeType.sans(14.5))
                                        .foregroundStyle(LumeColor.inkSoft)
                                        .lineLimit(3)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(16)
                                .lumeSoftGlass(cornerRadius: 22, shadow: false)
                                .lumeRiseIn(delay: Double(index) * 0.05)
                            }
                        }
                    }
                }

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showingComposer) {
            GratitudeComposerView(existing: todayEntry)
        }
    }
}
