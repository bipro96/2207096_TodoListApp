import SwiftUI

struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case login = "Login"
        case signUp = "Sign Up"
        var id: String { rawValue }
    }

    @EnvironmentObject private var auth: AuthViewModel

    @State private var mode: Mode = .login
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showReset = false
    @State private var resetEmail = ""

    private var isSignUp: Bool { mode == .signUp }

    private var isValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 6
        if isSignUp {
            return emailOK && passwordOK && password == confirmPassword
        }
        return emailOK && passwordOK
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { _ in auth.clearMessages() }

                VStack(spacing: 14) {
                    if isSignUp {
                        field("Full name", systemImage: "person") {
                            TextField("Full name", text: $name)
                                .textContentType(.name)
                        }
                    }
                    field("Email", systemImage: "envelope") {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    field("Password", systemImage: "lock") {
                        SecureField("Password (min 6 characters)", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    if isSignUp {
                        field("Confirm password", systemImage: "lock.rotation") {
                            SecureField("Confirm password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        }
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords do not match.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                if let info = auth.infoMessage {
                    Text(info)
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        if isSignUp {
                            await auth.signUp(name: name, email: email.trimmed, password: password)
                        } else {
                            await auth.signIn(email: email.trimmed, password: password)
                        }
                    }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Create Account" : "Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid || auth.isLoading)

                if !isSignUp {
                    Button("Forgot password?") {
                        resetEmail = email
                        showReset = true
                    }
                    .font(.footnote)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Reset password", isPresented: $showReset) {
            TextField("Email", text: $resetEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            Button("Send link") {
                Task { await auth.resetPassword(email: resetEmail.trimmed) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We will email you a link to reset your password.")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.tint)
                .padding(.top, 40)
            Text("Todo List")
                .font(.largeTitle.bold())
            Text(isSignUp ? "Create an account to sync your tasks" : "Welcome back! Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func field<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            content()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
