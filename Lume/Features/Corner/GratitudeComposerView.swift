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
    @State private var showingCamera = false

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
                trailingEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil,
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

                    VStack(alignment: .leading, spacing: 10) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 190)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                Button {
                                    self.photoData = nil
                                    scheduleAutosave()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Circle())
                                }
                                .padding(6)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        HStack(spacing: 10) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label("Escolher foto", systemImage: "photo.on.rectangle")
                                    .font(LumeType.sans(14, weight: .bold))
                                    .foregroundStyle(LumeColor.brand)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.55)))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))

                            Button {
                                showingCamera = true
                            } label: {
                                Label("Tirar foto", systemImage: "camera")
                                    .font(LumeType.sans(14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(LumeColor.brand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
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
        .sheet(isPresented: $showingCamera) {
            CameraImagePicker { image in
                photoData = image.jpegData(compressionQuality: 0.86)
                scheduleAutosave()
            }
        }
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

private struct CameraImagePicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        controller.delegate = context.coordinator
        controller.allowsEditing = false
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImage: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImage = onImage
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
