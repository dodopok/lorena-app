import SwiftUI
import SwiftData
import UIKit

struct GratitudeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GratitudeEntry.date, order: .reverse) private var entries: [GratitudeEntry]
    @State private var showingComposer = false
    @State private var entryToEdit: GratitudeEntry?
    @State private var entryToDelete: GratitudeEntry?
    @State private var showingDeleteConfirmation = false

    private var todayEntry: GratitudeEntry? { entries.first(where: \.date.isToday) }
    private var pastEntries: [GratitudeEntry] { entries.filter { !$0.date.isToday } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        LumeEyebrow(text: "Hoje")
                        Spacer()
                        if let todayEntry {
                            gratitudeMenu(for: todayEntry)
                        }
                    }

                    Button { showingComposer = true } label: {
                        VStack(alignment: .leading, spacing: 14) {
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

                            Text(todayEntry == nil ? "Escrever" : "Editar")
                                .font(LumeType.sans(15, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LumeColor.brand))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lumeSoftGlass(cornerRadius: 28)
                .lumeRiseIn()

                if !pastEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Últimos dias")
                        VStack(spacing: 10) {
                            ForEach(Array(pastEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                                HStack(spacing: 12) {
                                    Button { entryToEdit = entry } label: {
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

                                            Rectangle()
                                                .fill(LumeColor.brandPlumStart.opacity(0.1))
                                                .frame(width: 1)

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(entry.text.isEmpty ? "Uma lembrança boa" : entry.text)
                                                    .font(LumeType.sans(14.5))
                                                    .foregroundStyle(LumeColor.inkSoft)
                                                    .lineLimit(3)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                if entry.photoData != nil {
                                                    Label("Com foto", systemImage: "photo")
                                                        .font(LumeType.sans(11.5, weight: .semibold))
                                                        .foregroundStyle(LumeColor.brand)
                                                }
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    gratitudeMenu(for: entry)
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
        .sheet(item: $entryToEdit) { entry in
            GratitudeComposerView(existing: entry)
        }
        .confirmationDialog(
            "Apagar esta gratidão?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Apagar", role: .destructive) { deletePendingEntry() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esse registro e a foto dele serão removidos.")
        }
    }

    @ViewBuilder
    private func gratitudeMenu(for entry: GratitudeEntry) -> some View {
        Menu {
            Button("Editar", systemImage: "pencil") {
                entryToEdit = entry
            }
            Button("Apagar", systemImage: "trash", role: .destructive) {
                entryToDelete = entry
                showingDeleteConfirmation = true
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(LumeColor.brand)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ações da gratidão")
    }

    private func deletePendingEntry() {
        guard let entryToDelete else { return }
        modelContext.delete(entryToDelete)
        try? modelContext.save()
        self.entryToDelete = nil
    }
}
