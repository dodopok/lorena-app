import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Screen 16 — free text + an optional photo, autosaved as she types so
/// there's never a "did I save that?" moment.
struct GratitudeComposerView: View {
    var existing: GratitudeEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var text: String
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var workingEntry: GratitudeEntry?
    @State private var saveTask: Task<Void, Never>?
    @State private var didSaveOnce: Bool

    init(existing: GratitudeEntry?) {
        self.existing = existing
        _text = State(initialValue: existing?.text ?? "")
        _photoData = State(initialValue: existing?.photoData)
        _workingEntry = State(initialValue: existing)
        _didSaveOnce = State(initialValue: existing != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Fechar",
                title: "Gratidão de hoje",
                trailingTitle: "Salvar",
                trailingEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onLeading: { persist(); dismiss() },
                onTrailing: { persist(); dismiss() }
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextEditor(text: $text)
                        .font(LumeType.serif(22))
                        .foregroundStyle(LumeColor.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150)
                        .padding(16)
                        .lumeSoftGlass(cornerRadius: 26, shadow: false)
                        .onChange(of: text) { _, _ in scheduleAutosave() }

                    HStack(spacing: 10) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                Button {
                                    self.photoData = nil
                                    scheduleAutosave()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .padding(6)
                            }
                        }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.system(size: 20))
                                Text("Foto").font(LumeType.sans(11.5, weight: .bold))
                            }
                            .foregroundStyle(LumeColor.brand)
                            .frame(width: 96, height: 96)
                        }
                        .buttonStyle(.plain)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.5)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(LumeColor.brand.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        )

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Circle().fill(LumeColor.greenDeep).frame(width: 7, height: 7)
                        Text(didSaveOnce ? "Rascunho salvo automaticamente" : "Comece a escrever…")
                            .font(LumeType.sans(13))
                            .foregroundStyle(LumeColor.textFaint)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    photoData = data
                    scheduleAutosave()
                }
            }
        }
    }

    private func scheduleAutosave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            persist()
        }
    }

    private func persist() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || photoData != nil else { return }

        if let entry = workingEntry {
            entry.text = text
            entry.photoData = photoData
        } else {
            let entry = GratitudeEntry(text: text, photoData: photoData)
            modelContext.insert(entry)
            workingEntry = entry
        }
        try? modelContext.save()
        didSaveOnce = true
    }
}
