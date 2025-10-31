//
//  LoginView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var auth: Authentication
    @Environment(\.dismiss) var dismiss
    @Binding var authSheetState: AuthState
    @Binding var selectedRole: UserRole
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    enum Field { case email, password }
    private var accentColor: Color { selectedRole == .patient ? .blue : .red }
    private var accentGradient: LinearGradient { LinearGradient(colors: [accentColor, accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                  
                    Picker("Login As", selection: $selectedRole) {
                        Text("Patient").tag(UserRole.patient)
                        Text("Caregiver").tag(UserRole.admin)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .animation(.easeInOut, value: selectedRole)

                    VStack(spacing: 4) {
                        Text(selectedRole == .patient ? "Welcome Back" : "Caregiver")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        
                        Text("Log in to continue.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)
                    .animation(.easeInOut, value: selectedRole)

                     VStack(spacing: 16) {
                        FloatingTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, accentColor: accentColor).keyboardType(.emailAddress).focused($focusedField, equals: .email).submitLabel(.next).onSubmit { focusedField = .password }
                        FloatingTextField(icon: "lock.fill", placeholder: "Password", text: $password, accentColor: accentColor, isSecure: !showPassword, showPasswordToggle: $showPassword).focused($focusedField, equals: .password).submitLabel(.go).onSubmit { performLogin() }
                     }.padding(.top, 10)

                    Button(action: { /* FP */ }) { Text("Forgot Password?").font(.footnote).fontWeight(.semibold).foregroundColor(accentColor) }.frame(maxWidth: .infinity, alignment: .trailing)

                    if let errorMessage { ErrorTextView(message: errorMessage) }

                    Button(action: performLogin) { HStack(spacing: 12) { if isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) } else { Text("Log In").font(.headline.weight(.semibold)) } }.frame(maxWidth: .infinity) }.controlSize(.large).buttonStyle(.glassProminent).tint(accentGradient).disabled(isLoading).animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)

                     VStack(spacing: 10) {
                          Text("OR").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                          SignInWithAppleButton(
                              onRequest: { $0.requestedScopes = [.email] },
                              onCompletion: handleSignInWithApple
                          )
                          .signInWithAppleButtonStyle(selectedRole == .patient ? .black : .whiteOutline)
                          .frame(height: 50)
                          .clipShape(Capsule())
                          .shadow(color: .black.opacity(0.1), radius: 5)
                      }
                      .padding(.top, 5)

                    if selectedRole == .patient {
                        Button(action: {
                            authSheetState = .signUp
                        }) {
                            Text("Don't have an account? **Sign Up**")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(30)
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) { Button { dismiss() } label: { Label("Close", systemImage: "xmar").symbolRenderingMode(.hierarchical).foregroundStyle(.primary).font(.callout) } }
            }
        }
    }

    // MARK: - Functions
    
    func performLogin() {
        focusedField = nil; errorMessage = nil; guard email.isValidEmail else { withAnimation(.snappy){ errorMessage = "Invalid email." }; return }; guard !password.isEmpty else { withAnimation(.snappy){ errorMessage = "Password required." }; return }; isLoading = true; Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let loginSuccess = (password == "password123")
            await MainActor.run {
                isLoading = false
                if loginSuccess {
                    authenticateUser(role: selectedRole)
                } else {
                    errorMessage = "Invalid credentials."
                }
            }
        }
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        if case .success = result {
            isLoading = true
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    isLoading = false
                    authenticateUser(role: selectedRole)
                }
            }
        } else if case .failure(let error) = result {
            errorMessage = "Apple Sign In failed."
            print("Apple Sign In error: \(error.localizedDescription)")
        }
    }
    
    func authenticateUser(role: UserRole) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            auth.userRole = role
            auth.isAuthenticating = true
        }
    }
}

#Preview {
    LoginView(authSheetState: .constant(.login), selectedRole: .constant(.patient))
        .environmentObject(Authentication())
}
