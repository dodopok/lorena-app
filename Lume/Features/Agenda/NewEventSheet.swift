import SwiftUI
import SwiftData
import EventKit

/// Not one of the mockup's explicitly drawn screens, but the Agenda's "+"
/// needs a destination — built in the same visual language as the rest.
struct NewEventSheet: View {
    var initialDate: Date
    var eventToEdit: CalendarEvent?
    var externalEventToEdit: EKEvent?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var title = ""
    @State private var location = ""
    @State private var category: AgendaCategory = .pessoal
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndTime = true
    @State private var remindToLogExpense = false
    @State private var saveError: String?

    init(
        initialDate: Date,
        eventToEdit: CalendarEvent? = nil,
        externalEventToEdit: EKEvent? = nil
    ) {
        self.initialDate = initialDate
        self.eventToEdit = eventToEdit
        self.externalEventToEdit = externalEventToEdit
        let defaultStart = LumeDateFormat.calendar.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate) ?? initialDate
        let start = eventToEdit?.startDate ?? externalEventToEdit?.startDate ?? defaultStart
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: eventToEdit?.endDate ?? externalEventToEdit?.endDate ?? start.addingTimeInterval(3600))
        _title = State(initialValue: eventToEdit?.title ?? externalEventToEdit?.title ?? "")
        _location = State(initialValue: eventToEdit?.location ?? externalEventToEdit?.location ?? "")
        _category = State(initialValue: eventToEdit?.category ?? .pessoal)
        _hasEndTime = State(initialValue: eventToEdit?.endDate != nil || externalEventToEdit != nil)
        _remindToLogExpense = State(initialValue: eventToEdit?.remindToLogExpense ?? false)
    }

    private var isEditingExternal: Bool { externalEventToEdit != nil }
    private var isEditing: Bool { eventToEdit != nil || externalEventToEdit != nil }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: isEditing ? "Editar compromisso" : "Novo compromisso",
                trailingTitle: "Salvar",
                trailingEnabled: !title.trimmingCharacters(in: .whitespaces).isEmpty,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 16) {
                    field(label: "Título") {
                        TextField("Com quem, ou o quê?", text: $title)
                            .font(LumeType.sans(17, weight: .semibold))
                    }

                    field(label: "Local") {
                        TextField("Opcional", text: $location)
                            .font(LumeType.sans(16))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Início", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        if isEditingExternal {
                            DatePicker("Término", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                        } else {
                            Toggle("Definir horário de término", isOn: $hasEndTime.animation())
                            if hasEndTime {
                                DatePicker("Término", selection: $endDate, in: startDate..., displayedComponents: [.hourAndMinute])
                            }
                        }
                    }
                    .font(LumeType.sans(15, weight: .semibold))
                    .tint(LumeColor.brand)
                    .padding(18)
                    .lumeSoftGlass(cornerRadius: 22, opacity: 0.6, shadow: false)

                    if !isEditingExternal {
                        VStack(alignment: .leading, spacing: 10) {
                            LumeEyebrow(text: "Categoria")
                            LumeWrapChips(items: AgendaCategory.allCases, selection: $category) { $0.label }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Toggle(isOn: $remindToLogExpense) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lembrar de anotar o gasto")
                                    .font(LumeType.sans(15, weight: .semibold))
                                Text("Um empurrãozinho depois do compromisso.")
                                    .font(LumeType.sans(12.5))
                                    .foregroundStyle(LumeColor.textFaint)
                            }
                        }
                        .tint(LumeColor.brand)
                        .padding(18)
                        .lumeSoftGlass(cornerRadius: 22, opacity: 0.6, shadow: false)
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
        .alert("Não foi possível salvar no Calendário", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Tente novamente.")
        }
    }

    private func field(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(LumeType.sans(12.5))
                .foregroundStyle(LumeColor.textFaint)
            content()
                .foregroundStyle(LumeColor.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumeSoftGlass(cornerRadius: 20, opacity: 0.65, shadow: false)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let cleanLocation = location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location.trimmingCharacters(in: .whitespaces)

        if let externalEventToEdit {
            do {
                try CalendarSyncService.shared.update(
                    event: externalEventToEdit,
                    title: trimmed,
                    location: cleanLocation,
                    startDate: startDate,
                    endDate: max(endDate, startDate)
                )
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
            return
        }

        let cleanEndDate = hasEndTime ? max(endDate, startDate) : nil
        let event: CalendarEvent

        if let eventToEdit {
            eventToEdit.title = trimmed
            eventToEdit.location = cleanLocation
            eventToEdit.startDate = startDate
            eventToEdit.endDate = cleanEndDate
            eventToEdit.category = category
            eventToEdit.remindToLogExpense = remindToLogExpense
            event = eventToEdit
        } else {
            event = CalendarEvent(
                title: trimmed,
                location: cleanLocation,
                startDate: startDate,
                endDate: cleanEndDate,
                category: category,
                remindToLogExpense: remindToLogExpense
            )
            modelContext.insert(event)
        }

        try? modelContext.save()
        let remindersEnabled = profiles.first?.postEventExpenseReminderEnabled ?? true
        if remindToLogExpense && remindersEnabled {
            NotificationScheduler.shared.scheduleExpenseReminder(for: event)
        } else {
            NotificationScheduler.shared.cancelExpenseReminder(for: event)
        }
        dismiss()
    }
}
