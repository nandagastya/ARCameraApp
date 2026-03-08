//
//  ProfileView.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0D1A").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Profile Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#FF6B9D"), Color(hex: "#C084FC")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)
                                
                                Text(String(authViewModel.currentUser?.displayName.prefix(1).uppercased() ?? "U"))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 8)
                        
                        // Stats Row
                        HStack(spacing: 1) {
                            StatCell(value: "\(authViewModel.currentUser?.filterUsageCount ?? 0)", label: "Filters Used")
                            Divider().background(.white.opacity(0.1)).frame(width: 1, height: 40)
                            StatCell(value: "\(authViewModel.currentUser?.favoriteFilterIDs.count ?? 0)", label: "Favorites")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 20)
                        
                        // Settings
                        VStack(spacing: 0) {
                            ProfileRow(icon: "bell", title: "Notifications", color: .orange)
                            Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                            ProfileRow(icon: "lock.shield", title: "Privacy", color: .blue)
                            Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                            ProfileRow(icon: "questionmark.circle", title: "Help & Support", color: .green)
                            Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                            ProfileRow(icon: "star.fill", title: "Rate the App", color: .yellow)
                        }
                        .background(.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 20)
                        
                        // Sign Out
                        Button(action: {
                            authViewModel.signOut()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#FF6B9D"))
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Capture Preview View
struct CapturePreviewView: View {
    let image: UIImage
    let onSave: () -> Void
    let onDiscard: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Action Bar
                HStack(spacing: 32) {
                    Button(action: onDiscard) {
                        VStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 24))
                            Text("Discard")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Button(action: onSave) {
                        VStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 26))
                            Text("Save")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FF6B9D"), Color(hex: "#C084FC")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button(action: {
                        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?
                            .rootViewController?.present(av, animated: true)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                            Text("Share")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(.black.opacity(0.8))
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0D0D1A"), Color(hex: "#1A0A2E")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("✨")
                    .font(.system(size: 80))
                Text("FaceFit AR")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B9D"), Color(hex: "#C084FC")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}


#Preview {
    ProfileView()
}
