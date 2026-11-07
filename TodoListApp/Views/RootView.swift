import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var taskVM: TaskViewModel

    var body: some View {
        Group {
            if auth.user != nil {
                TaskListView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: auth.user?.uid)
        .onAppear {
            if let uid = auth.user?.uid {
                taskVM.start(userId: uid)
            }
        }
        .onChange(of: auth.user?.uid) { newValue in
            if let uid = newValue {
                taskVM.start(userId: uid)
            } else {
                taskVM.stop()
            }
        }
    }
}
