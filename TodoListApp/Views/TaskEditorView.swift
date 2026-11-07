import SwiftUI

struct TaskEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(TodoTask)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let task): return task.id
            }
        }
    }

    let mode: Mode

    @EnvironmentObject private var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var isCompleted: Bool

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _title = State(initialValue: "")
            _details = State(initialValue: "")
            _isCompleted = State(initialValue: false)
        case .edit(let task):
            _title = State(initialValue: task.title)
            _details = State(initialValue: task.details)
            _isCompleted = State(initialValue: task.isCompleted)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Finish lab report", text: $title)
                }

                Section("Description") {
                    TextField("Add details (optional)", text: $details, axis: .vertical)
                        .lineLimit(4...10)
                }

                if isEditing {
                    Section {
                        Toggle("Completed", isOn: $isCompleted)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private func save() {
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .add:
            taskVM.add(title: trimmedTitle, details: cleanDetails)
        case .edit(var task):
            task.title = trimmedTitle
            task.details = cleanDetails
            task.isCompleted = isCompleted
            taskVM.update(task)
        }
        dismiss()
    }
}
