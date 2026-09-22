import SwiftUI
import SwiftData
import EventKit

struct AgendaDayView: View {
    @Binding var selectedDate: Date
    var allItems: [AgendaItem]
    var onSelect: (AgendaItem) -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyTodo.createdAt, order: .forward) private var allTodos: [DailyTodo]
    @State private var calendarSync = CalendarSyncService.shared
    @State private var showingNewTodo = false
    @State private var todoToEdit: DailyTodo?
    @State private var todoToDelete: DailyTodo?
    @State private var showingTodoDeleteConfirmation = false

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

                todoChecklist

                LumeEyebrow(text: LumeDateFormat.shortWeekdayDayUppercased(selectedDate))
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(Array(allItems.enumerated()), id: \.element.id) { index, item in
                        AgendaEventCard(item: item, onSelect: onSelect)
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
        .sheet(isPresented: $showingNewTodo) {
            DailyTodoSheet(date: selectedDate)
        }
        .sheet(item: $todoToEdit) { todo in
            DailyTodoSheet(date: todo.date, todoToEdit: todo)
        }
        .confirmationDialog("Remover esta tarefa?", isPresented: $showingTodoDeleteConfirmation, titleVisibility: .visible) {
            Button("Remover", role: .destructive) {
                deletePendingTodo()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var dayTodos: [DailyTodo] {
        allTodos.filter { $0.date.isSameDay(as: selectedDate) }
    }

    private var todoChecklist: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                LumeEyebrow(text: "TAREFAS DO DIA")
                Spacer()
                Button {
                    showingNewTodo = true
                } label: {
                    Label("Adicionar", systemImage: "plus")
                        .font(LumeType.sans(13, weight: .bold))
                        .foregroundStyle(LumeColor.brand)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(LumeColor.brandPillLight))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if dayTodos.isEmpty {
                Button {
                    showingNewTodo = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checklist")
                            .foregroundStyle(LumeColor.lavenderText)
                        Text("Adicione uma tarefa para este dia")
                            .font(LumeType.sans(13.5))
                            .foregroundStyle(LumeColor.textMuted)
                        Spacer()
                    }
                    .padding(16)
                    .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .lumeSoftGlass(cornerRadius: 20, opacity: 0.48, shadow: false)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(dayTodos.enumerated()), id: \.element.persistentModelID) { index, todo in
                        if index > 0 {
                            Divider()
                                .overlay(LumeColor.brandPlumStart.opacity(0.08))
                                .padding(.leading, 58)
                        }
                        DailyTodoRow(
                            todo: todo,
                            onEdit: { todoToEdit = todo },
                            onDelete: {
                                todoToDelete = todo
                                showingTodoDeleteConfirmation = true
                            }
                        )
                    }
                }
                .lumeSoftGlass(cornerRadius: 20, opacity: 0.48, shadow: false)
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
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private func deletePendingTodo() {
        guard let todoToDelete else { return }
        modelContext.delete(todoToDelete)
        try? modelContext.save()
        self.todoToDelete = nil
    }
}

private struct DailyTodoRow: View {
    var todo: DailyTodo
    var onEdit: () -> Void
    var onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            todo.isCompleted.toggle()
            try? modelContext.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(todo.isCompleted ? LumeColor.greenDeep : LumeColor.textFainter)
                Text(todo.title)
                    .font(LumeType.sans(15.5, weight: .semibold))
                    .foregroundStyle(todo.isCompleted ? LumeColor.textFainter : LumeColor.ink)
                    .strikethrough(todo.isCompleted, color: LumeColor.textFainter)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Editar") { onEdit() }
            Button("Remover", role: .destructive) { onDelete() }
        }
    }
}

private struct DailyTodoSheet: View {
    let date: Date
    var todoToEdit: DailyTodo?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""

    init(date: Date, todoToEdit: DailyTodo? = nil) {
        self.date = date
        self.todoToEdit = todoToEdit
        _title = State(initialValue: todoToEdit?.title ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: todoToEdit == nil ? "Nova tarefa" : "Editar tarefa",
                trailingTitle: "Salvar",
                trailingEnabled: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 8) {
                Text(LumeDateFormat.shortWeekdayDayUppercased(date))
                    .font(LumeType.sans(12.5, weight: .bold))
                    .foregroundStyle(LumeColor.textFaint)
                TextField("O que precisa ser feito?", text: $title)
                    .font(LumeType.sans(17, weight: .semibold))
                    .foregroundStyle(LumeColor.ink)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.72)))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
            }
            .padding(24)

            Spacer()
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let todoToEdit {
            todoToEdit.title = trimmed
            todoToEdit.date = date.startOfDay
        } else {
            modelContext.insert(DailyTodo(title: trimmed, date: date))
        }
        try? modelContext.save()
        dismiss()
    }
}

struct AgendaEventCard: View {
    var item: AgendaItem
    var onSelect: (AgendaItem) -> Void
    @State private var showingExpenseSheet = false

    var body: some View {
        HStack(spacing: 16) {
            Capsule().fill(item.category.accent).frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Button {
                    onSelect(item)
                } label: {
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

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

struct AgendaEventDetailSheet: View {
    let item: AgendaItem
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editTarget: EditTarget?

    private enum EditTarget: Identifiable {
        case lume(CalendarEvent)
        case external(EKEvent)

        var id: String {
            switch self {
            case .lume(let event): "lume-\(event.id.uuidString)"
            case .external(let event): "ek-\(event.eventIdentifier ?? UUID().uuidString)"
            }
        }
    }

    private var displayedItem: AgendaItem {
        if let event = item.sourceEvent { return AgendaItem(event: event) }
        if let event = item.externalEvent { return AgendaItem(external: event) }
        return item
    }

    private var canEdit: Bool {
        !displayedItem.isExternal || displayedItem.isExternalEditable
    }

    private func beginEditing() {
        if let event = displayedItem.sourceEvent {
            editTarget = .lume(event)
        } else if let event = displayedItem.externalEvent, displayedItem.isExternalEditable {
            editTarget = .external(event)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Fechar",
                title: "Detalhes",
                trailingTitle: canEdit ? "Editar" : " ",
                trailingEnabled: canEdit,
                onLeading: { dismiss() },
                onTrailing: beginEditing
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(displayedItem.category.accent)
                                .frame(width: 12, height: 12)
                            Text(displayedItem.category.label)
                                .font(LumeType.sans(13.5, weight: .bold))
                                .foregroundStyle(LumeColor.textMuted)
                            Spacer()
                            if displayedItem.isExternal {
                                Image(systemName: "icloud")
                                    .foregroundStyle(LumeColor.textFainter)
                            }
                        }

                        Text(displayedItem.title)
                            .font(LumeType.serif(30))
                            .foregroundStyle(LumeColor.ink)

                        detailRow(systemImage: "calendar", text: LumeDateFormat.shortWeekdayDayUppercased(displayedItem.start))
                        detailRow(systemImage: "clock", text: displayedItem.timeRangeLabel)

                        if let location = displayedItem.location, !location.isEmpty {
                            detailRow(systemImage: "mappin.and.ellipse", text: location)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lumeSoftGlass(cornerRadius: 26, opacity: 0.62, shadow: false)

                    if displayedItem.remindToLogExpense {
                        HStack(spacing: 10) {
                            Image(systemName: displayedItem.loggedExpense ? "checkmark.circle.fill" : "bell.fill")
                                .foregroundStyle(LumeColor.brand)
                            Text(displayedItem.loggedExpense ? "Gasto anotado" : "Lembrete de gasto ativado")
                                .font(LumeType.sans(14, weight: .semibold))
                                .foregroundStyle(LumeColor.brandDeep)
                            Spacer()
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LumeColor.brandPillLight))
                    }

                    if !displayedItem.isExternal {
                        LumeGlassButton(
                            title: "Apagar compromisso",
                            textColor: LumeColor.errorText
                        ) {
                            onDelete()
                        }
                    } else if displayedItem.isExternalEditable {
                        Text("As alterações serão salvas no calendário de origem do iPhone.")
                            .font(LumeType.sans(13.5))
                            .foregroundStyle(LumeColor.textFaint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                    } else {
                        Text("Este calendário permite visualizar o compromisso, mas não alterar.")
                            .font(LumeType.sans(13.5))
                            .foregroundStyle(LumeColor.textFaint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(item: $editTarget) { target in
            switch target {
            case .lume(let event):
                NewEventSheet(initialDate: event.startDate, eventToEdit: event)
            case .external(let event):
                NewEventSheet(initialDate: event.startDate, externalEventToEdit: event)
            }
        }
    }

    private func detailRow(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(LumeType.sans(15, weight: .semibold))
            .foregroundStyle(LumeColor.textSecondary)
    }
}
