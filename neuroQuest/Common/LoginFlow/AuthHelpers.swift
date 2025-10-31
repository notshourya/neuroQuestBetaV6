//
//  AuthHelpers.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI
import AuthenticationServices
import Contacts
import ContactsUI

// MARK: - Auth State Enum 
enum AuthState {
    case welcome, login, signUp
    case onboardingHealth
    case onboardingWatch
}

// MARK: - Error Enum
enum AuthError: Error {
    case invalidCredentials
    case unknown
}

// MARK: - App Icon View 
struct AppIconView: View {
    let iconName: String
    let size: CGFloat
    let gradient: Gradient
    var body: some View {
        ZStack {
//            Circle()
//                .glassEffect(in: .circle)
//                .overlay(
//                    Circle()
//                        .stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
//                )
//                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5, height: size * 0.5)
                .foregroundStyle(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .frame(width: size, height: size)
    }
}
// MARK: - Floating Text Field
struct FloatingTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var accentColor: Color
    var isSecure: Bool = false
    var showPasswordToggle: Binding<Bool>? = nil
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(isFocused ? 0.15 : 0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isFocused ? accentColor : accentColor.opacity(0.7))
            }
            .animation(.easeOut(duration: 0.2), value: isFocused)
            .allowsHitTesting(false) // Don't intercept taps
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .font(.system(size: 17))
            .foregroundColor(.primary)
            
            if let showPasswordToggle = showPasswordToggle {
                Button(action: {
                    showPasswordToggle.wrappedValue.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: showPasswordToggle.wrappedValue ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Spacer().frame(width: 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassEffect(in: .capsule)
        .overlay(
            Capsule()
                .strokeBorder(isFocused ? accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.2), value: isFocused)
        )
        .shadow(
            color: isFocused ? accentColor.opacity(0.15) : .black.opacity(0.03),
            radius: isFocused ? 8 : 4,
            y: isFocused ? 4 : 2
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}

struct CustomBottomSheet<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> SheetContent
    
    @State private var offsetY: CGFloat = 10000

    func body(content base: Content) -> some View {
        ZStack {
            base

            if isPresented {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
            }

            if isPresented {
                sheetBody
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isPresented)
    }

    private var sheetBody: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            VStack {
                Capsule()
                    .frame(width: 40, height: 6)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                self.content()
                    .padding(.bottom, 20)
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(in: .rect(cornerRadius: 40))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: -2)
            )
            .cornerRadius(40)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .offset(y: offsetY)
            .onAppear {
                offsetY = height
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    offsetY = 0
                }
            }
            .onDisappear {
                offsetY = height
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

extension View {
    func customBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(CustomBottomSheet(isPresented: isPresented, content: content))
    }
}


// MARK: - Error Message View
struct ErrorTextView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 16)).foregroundColor(.orange)
            Text(message).font(.footnote).foregroundColor(.primary)
            Spacer()
        }
        .padding(14)
        .glassEffect(in: .capsule)
      
        .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
        .transition(.scale.combined(with: .opacity))
        .animation(.snappy(duration: 0.25), value: message)
    }
}

// MARK: - Success Overlay View
struct SuccessOverlayView: View {
    let message: String
    let accentColor: Color = .blue
    @State private var animateCheckmark = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.2)).frame(width: 100, height: 100)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(accentColor)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                        .opacity(animateCheckmark ? 1.0 : 0)
                }
                Text("Success!").font(.title2.bold())
                Text(message)
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .padding(40)
            .glassEffect(in: .rect(cornerRadius: 30))
            .shadow(color: .black.opacity(0.2), radius: 20)
            .scaleEffect(1.0)
            .opacity(1.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3)) {
                    animateCheckmark = true
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateCheckmark)
    }
}


// MARK: - Contact Picker Wrapper
struct ContactPicker: UIViewControllerRepresentable {
    var didSelectContact: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        picker.displayedPropertyKeys = [CNContactEmailAddressesKey]
        return picker
    }
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}


    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        init(_ parent: ContactPicker) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            DispatchQueue.main.async {
                self.parent.didSelectContact(contact)
            }
        }
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }
}


// MARK: - String Extension
extension String {
     var isValidEmail: Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return self.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Press Events Modifier
struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in onPress() })
                    .onEnded({ _ in onRelease() })
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
