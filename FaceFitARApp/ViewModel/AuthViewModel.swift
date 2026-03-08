//
//  AuthViewModel.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import Foundation
import FirebaseAuth
import Combine

enum AuthState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUser: User?
    @Published var authState: AuthState = .idle
    
    // Form Fields
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""
    
    // MARK: - Private
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let databaseService = DatabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Validation
    var isEmailValid: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    var isPasswordValid: Bool {
        password.count >= 8
    }
    
    var doPasswordsMatch: Bool {
        password == confirmPassword
    }
    
    var canLogin: Bool {
        isEmailValid && isPasswordValid
    }
    
    var canSignup: Bool {
        isEmailValid && isPasswordValid && doPasswordsMatch && !displayName.isEmpty
    }
    
    var emailValidationMessage: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Enter a valid email address"
    }
    
    var passwordValidationMessage: String? {
        guard !password.isEmpty else { return nil }
        return isPasswordValid ? nil : "Password must be at least 8 characters"
    }
    
    var confirmPasswordMessage: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return doPasswordsMatch ? nil : "Passwords do not match"
    }
    
    // MARK: - Init
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self.currentUser = User(from: firebaseUser)
                    self.isAuthenticated = true
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Login
    func login() async {
        guard canLogin else { return }
        authState = .loading
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = User(from: result.user)
            authState = .success
            clearForm()
        } catch {
            authState = .error(mapAuthError(error))
        }
    }
    
    // MARK: - Sign Up
    func signUp() async {
        guard canSignup else { return }
        authState = .loading
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            var user = User(from: result.user)
            user.displayName = displayName
            
            // Save user to Firestore
            try await databaseService.saveUser(user)
            
            currentUser = user
            authState = .success
            clearForm()
        } catch {
            authState = .error(mapAuthError(error))
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            authState = .error("Failed to sign out")
        }
    }
    
    // MARK: - Password Reset
    func sendPasswordReset() async {
        guard isEmailValid else { return }
        authState = .loading
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            authState = .success
        } catch {
            authState = .error(mapAuthError(error))
        }
    }
    
    // MARK: - Helpers
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }
    
    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case 17004: return "Invalid email or password"
        case 17007: return "This email is already registered"
        case 17008: return "Invalid email format"
        case 17009: return "Wrong password"
        case 17011: return "No account found with this email"
        case 17026: return "Password is too weak"
        default: return error.localizedDescription
        }
    }
}

