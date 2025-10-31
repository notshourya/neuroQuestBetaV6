//
//  SignUpView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI
import AuthenticationServices
import Contacts
import ContactsUI

struct SignUpView: View {
    @EnvironmentObject var auth: Authentication
    @Environment(\.dismiss) var dismiss
    @Binding var authSheetState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showCaregiverInvite = false
    @State private var caregiverName: String? = nil
    @State private var isShowingContactPicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    enum Field { case fullName, email, password, confirmPassword }

    private let accentColor: Color = .blue

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    Text("Create Your Account")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    VStack(spacing: 16) {
                         FloatingTextField(icon: "person.fill", placeholder: "Full Name", text: $fullName, accentColor: accentColor).focused($focusedField, equals: .fullName).submitLabel(.next).onSubmit { focusedField = .email }
                        FloatingTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, accentColor: accentColor).keyboardType(.emailAddress).focused($focusedField, equals: .email).submitLabel(.next).onSubmit { focusedField = .password }
                        FloatingTextField(icon: "lock.fill", placeholder: "Password", text: $password, accentColor: accentColor, isSecure: !showPassword, showPasswordToggle: $showPassword).focused($focusedField, equals: .password).submitLabel(.next).onSubmit { focusedField = .confirmPassword }
                        FloatingTextField(icon: "lock.shield.fill", placeholder: "Confirm Password", text: $confirmPassword, accentColor: accentColor, isSecure: !showConfirmPassword, showPasswordToggle: $showConfirmPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit(performSignUp)
                    }
                    DisclosureGroup(isExpanded: $showCaregiverInvite) {
                         VStack(alignment: .leading, spacing: 10) {
                             HStack {
                                 if let name = caregiverName {
                                     VStack(alignment: .leading) { Text(name).font(.headline) }
                                     .padding(.vertical, 8)
                                     .transition(.opacity.combined(with: .move(edge: .leading)))
                                 } else {
                                     Text("No caregiver selected.")
                                         .font(.subheadline)
                                         .foregroundStyle(.secondary)
                                         .padding(.vertical, 8)
                                 }
                                 Spacer()
                                 Button { requestContactsAccess() } label: {
                                     Label(caregiverName == nil ? "Choose Contact" : "Change",
                                           systemImage: "person.crop.circle.badge.plus")
                                         .font(.caption.bold())
                                 }
                                 .buttonStyle(.bordered)
                                 .tint(accentColor)
                             }
                         }
                        .padding(.top, 5)
                        .animation(.default, value: caregiverName)
                    } label: {
                        Label("Add a Caregiver", systemImage: "person.crop.circle.badge.plus")
                            .font(.headline)
                            .foregroundStyle(accentColor)
                    }
                    .accentColor(accentColor)
                    .padding(.vertical, 10).padding(.horizontal)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    if let errorMessage { ErrorTextView(message: errorMessage) }
                    Button(action: performSignUp) {
                         HStack(spacing: 12) {
                            if isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                            else { Text("Create Account").font(.headline.weight(.semibold)) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.glassProminent)
                    .tint(accentColor.gradient)
                    .disabled(isLoading)
                     VStack(spacing: 10) {
                         Text("OR").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                         SignInWithAppleButton(
                             onRequest: { $0.requestedScopes = [.fullName, .email] },
                             onCompletion: handleSignInWithApple
                         )
                         .signInWithAppleButtonStyle(.black)
                         .frame(height: 50)
                         .clipShape(Capsule())
                         .shadow(color: .black.opacity(0.1), radius: 5)
                     }
                     .padding(.top, 5)
                    Button(action: {
                        authSheetState = .login
                    }) {
                        Text("Already have an account? **Log In**")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 5)
                }
                .padding(30)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button { dismiss() } label: { Label("Close", systemImage: "xmar").symbolRenderingMode(.hierarchical).foregroundStyle(.secondary).font(.callout) } }
            }
            .sheet(isPresented: $isShowingContactPicker) {
                 ContactPicker(didSelectContact: { contact in
                     self.caregiverName = CNContactFormatter.string(from: contact, style: .fullName)
                     self.focusedField = nil
                 })
             }
        }
    }

    // MARK: - Functions
    
    func requestContactsAccess() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.caregiverName = "Preview Contact"
            return
        }
        #endif
        let store = CNContactStore(); switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: self.isShowingContactPicker = true
        case .denied, .restricted: errorMessage = "Please enable Contacts access in Settings."
        case .notDetermined: store.requestAccess(for: .contacts) { granted, _ in DispatchQueue.main.async { if granted { self.isShowingContactPicker = true } else { errorMessage = "Contacts access was denied." } } }
        @unknown default: fatalError() }
    }
    
    func performSignUp() {
        focusedField = nil; errorMessage = nil; guard !fullName.isEmpty else { withAnimation(.snappy){ errorMessage = "Full Name required." }; return }; guard email.isValidEmail else { withAnimation(.snappy){ errorMessage = "Invalid Email." }; return }; guard password.count >= 6 else { withAnimation(.snappy){ errorMessage = "Password needs 6+ chars." }; return }; guard password == confirmPassword else { withAnimation(.snappy){ errorMessage = "Passwords don't match." }; return }
        
        isLoading = true; Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if showCaregiverInvite, let name = caregiverName {
                print("TODO: Save caregiver reference: \(name)")
            }
            await MainActor.run {
                isLoading = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    authSheetState = .onboardingHealth
                }
            }
        }
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        if case .success(let authResult) = result {
            if let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential {
                print("Apple Sign Up: UserID=\(appleIDCredential.user), Name=\(appleIDCredential.fullName?.givenName ?? "N/A"), Email=\(appleIDCredential.email ?? "N/A")")
            }
            isLoading = true
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    isLoading = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        authSheetState = .onboardingHealth
                    }
                }
            }
        } else if case .failure(let error) = result {
            errorMessage = "Apple Sign In failed."
            print("Apple Sign In error: \(error.localizedDescription)")
        }
    }
}


#Preview {
    SignUpView(authSheetState: .constant(.signUp))
        .environmentObject(Authentication())
}
