//
//  AuthView.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var showPasswordReset = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#0D0D1A"),
                    Color(hex: "#1A0A2E"),
                    Color(hex: "#0D0D1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "#FF6B9D").opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.4, y: -60)
                
                Circle()
                    .fill(Color(hex: "#9B59B6").opacity(0.15))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: -60, y: geo.size.height * 0.6)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 60))
                        
                        Text("FaceFit AR")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#FF6B9D"), Color(hex: "#C084FC")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Real-Time Face Filters")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 72)
                    .padding(.bottom, 48)
                    
                    // Auth Card
                    VStack(spacing: 20) {
                        // Tab selector
                        AuthTabSelector(isSignUp: $isSignUp)
                        
                        if isSignUp {
                            SignUpForm()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            LoginForm(showPasswordReset: $showPasswordReset)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(24)
                    .background(.white.opacity(0.05))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSignUp)
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Tab Selector
struct AuthTabSelector: View {
    @Binding var isSignUp: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            authTabButton(title: "Log In", isSignUpTab: false)
            authTabButton(title: "Sign Up", isSignUpTab: true)
        }
        .padding(4)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    @ViewBuilder
    private func authTabButton(title: String, isSignUpTab: Bool) -> some View {
        let isSelected = isSignUp == isSignUpTab
        Button(action: { isSignUp = isSignUpTab }) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(tabBackground(isSelected: isSelected))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private func tabBackground(isSelected: Bool) -> some View {
        if isSelected {
            LinearGradient(
                colors: [Color(hex: "#FF6B9D"), Color(hex: "#C084FC")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.9)
        } else {
            Color.clear
        }
    }
}

// MARK: - Login Form
struct LoginForm: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showPasswordReset: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            AuthTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $authViewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                validation: authViewModel.emailValidationMessage
            )
            
            AuthTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: $authViewModel.password,
                icon: "lock",
                isSecure: true,
                validation: authViewModel.passwordValidationMessage
            )
            
            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot password?") { showPasswordReset = true }
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#C084FC"))
            }
            
            // Error message
            if case .error(let msg) = authViewModel.authState {
                ErrorBanner(message: msg)
            }
            
            // Login Button
            AuthActionButton(
                title: "Log In",
                isLoading: {
                    if case .loading = authViewModel.authState { return true }
                    return false
                }(),
                isEnabled: authViewModel.canLogin
            ) {
                Task { await authViewModel.login() }
            }
        }
    }
}

// MARK: - Sign Up Form
struct SignUpForm: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            AuthTextField(
                title: "Display Name",
                placeholder: "Your name",
                text: $authViewModel.displayName,
                icon: "person"
            )
            
            AuthTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $authViewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                validation: authViewModel.emailValidationMessage
            )
            
            AuthTextField(
                title: "Password",
                placeholder: "Min. 8 characters",
                text: $authViewModel.password,
                icon: "lock",
                isSecure: true,
                validation: authViewModel.passwordValidationMessage
            )
            
            AuthTextField(
                title: "Confirm Password",
                placeholder: "Repeat your password",
                text: $authViewModel.confirmPassword,
                icon: "lock.shield",
                isSecure: true,
                validation: authViewModel.confirmPasswordMessage
            )
            
            // Error message
            if case .error(let msg) = authViewModel.authState {
                ErrorBanner(message: msg)
            }
            
            AuthActionButton(
                title: "Create Account",
                isLoading: {
                    if case .loading = authViewModel.authState { return true }
                    return false
                }(),
                isEnabled: authViewModel.canSignup
            ) {
                Task { await authViewModel.signUp() }
            }
            
            Text("By signing up, you agree to our Terms of Service and Privacy Policy.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Auth TextField
struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var validation: String? = nil
    
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.8)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 20)
                
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                        .foregroundStyle(.white)
                        .tint(Color(hex: "#FF6B9D"))
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundStyle(.white)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .tint(Color(hex: "#FF6B9D"))
                }
                
                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(validation != nil ? Color.red.opacity(0.6) : .white.opacity(0.1), lineWidth: 1)
            )
            
            if let msg = validation {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.8))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validation)
    }
}

// MARK: - Auth Action Button
struct AuthActionButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isEnabled
                    ? LinearGradient(
                        colors: [Color(hex: "#FF6B9D"), Color(hex: "#C084FC")],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                    : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0D1A").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Enter your email and we'll send you a link to reset your password.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    AuthTextField(
                        title: "Email",
                        placeholder: "you@example.com",
                        text: $authViewModel.email,
                        icon: "envelope",
                        keyboardType: .emailAddress
                    )
                    
                    if case .success = authViewModel.authState {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Reset email sent! Check your inbox.")
                                .font(.system(size: 14)).foregroundStyle(.green)
                        }
                    }
                    
                    AuthActionButton(
                        title: "Send Reset Link",
                        isLoading: {
                            if case .loading = authViewModel.authState { return true }
                            return false
                        }(),
                        isEnabled: authViewModel.isEmailValid
                    ) {
                        Task { await authViewModel.sendPasswordReset() }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#FF6B9D"))
                }
            }
        }
    }
}

#Preview {
    AuthView()
}
