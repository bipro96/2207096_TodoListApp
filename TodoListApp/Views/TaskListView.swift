import SwiftUI

struct TaskListView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Done"
        var id: String { rawValue }
    }

    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var taskVM: TaskViewModel

    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var editorMode: TaskEditorView.Mode?
    @State private var showSignOutConfirm = false

    private var filteredTasks: [TodoTask] {
        taskVM.tasks.filter { task in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .active: matchesFilter = !task.isCompleted
            case .completed: matchesFilter = task.isCompleted
            }
            guard matchesFilter else { return false }
            guard !searchText.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(searchText)
                || task.details.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var completedCount: Int {
        taskVM.tasks.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Text("\(completedCount) of \(taskVM.tasks.count) completed")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                content
            }
            .navigationTitle("My Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let email = auth.user?.email {
                            Text(email)
                        }
                        Button("Sign Out", role: .destructive) {
                            showSignOutConfirm = true
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorMode = .add
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $editorMode) { mode in
                TaskEditorView(mode: mode)
            }
            .confirmationDialog("Sign out of your account?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK", role: .cancel) { taskVM.errorMessage = nil }
            } message: {
                Text(taskVM.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if taskVM.isLoading {
            Spacer()
            ProgressView("Loading tasks...")
            Spacer()
        } else if filteredTasks.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: taskVM.tasks.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text(taskVM.tasks.isEmpty ? "No tasks yet" : "No matching tasks")
                    .font(.headline)
                Text(taskVM.tasks.isEmpty ? "Tap + to add your first task." : "Try a different search or filter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else {
            List {
                ForEach(filteredTasks) { task in
                    TaskRowView(task: task) {
                        taskVM.toggleCompleted(task)
                    }
                    .onTapGesture { editorMode = .edit(task) }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            taskVM.delete(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editorMode = .edit(task)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { taskVM.errorMessage != nil },
            set: { if !$0 { taskVM.errorMessage = nil } }
        )
    }
}
