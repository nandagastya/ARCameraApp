//
//  MainCameraView.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//


import SwiftUI
import AVFoundation

struct MainCameraView: View {
    
    @StateObject private var viewModel = CameraViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showProfile = false
    @State private var shutterPressed = false
    @State private var showSaveConfirmation = false
    
    var body: some View {
        ZStack {
            // Full-screen black background
            Color.black.ignoresSafeArea()
            
            // Camera Preview
            CameraPreviewView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Vignette overlay for depth
            VignetteOverlay()
                .ignoresSafeArea()
            
            // UI Controls Layer
            VStack(spacing: 0) {
                TopControlBar(
                    viewModel: viewModel,
                    showProfile: $showProfile
                )
                
                Spacer()
                
                // Filter Selector + Capture Controls
                BottomControlArea(
                    viewModel: viewModel,
                    shutterPressed: $shutterPressed,
                    onCapture: capturePhoto
                )
            }
            
            // Save Confirmation Toast
            if showSaveConfirmation {
                SaveConfirmationToast()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $viewModel.showCapturePreview) {
            if let image = viewModel.capturedImage {
                CapturePreviewView(
                    image: image,
                    onSave: { savePhoto(image) },
                    onDiscard: { viewModel.showCapturePreview = false }
                )
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(authViewModel)
        }
        .onAppear { viewModel.startSession() }
        .onDisappear { viewModel.stopSession() }
    }
    
    private func capturePhoto() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            shutterPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation { shutterPressed = false }
        }
        viewModel.capturePhoto(with: nil)
    }
    
    private func savePhoto(_ image: UIImage) {
        viewModel.savePhotoToLibrary(image)
        viewModel.showCapturePreview = false
        withAnimation(.spring()) {
            showSaveConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showSaveConfirmation = false }
        }
    }
}

// MARK: - Top Control Bar
struct TopControlBar: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var showProfile: Bool
    
    var body: some View {
        HStack {
            // Profile Button
            Button(action: { showProfile = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            
            Spacer()
            
            // FPS Debug (optional)
            #if DEBUG
            Text("\(viewModel.fpsCount) FPS")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            #endif
            
            Spacer()
            
            HStack(spacing: 20) {
                // Flash Button
                Button(action: { viewModel.toggleFlash() }) {
                    Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                        .font(.system(size: 22))
                        .foregroundStyle(viewModel.isFlashOn ? .yellow : .white)
                        .shadow(radius: 4)
                }
                
                // Camera Flip
                Button(action: { viewModel.toggleCamera() }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
}

// MARK: - Bottom Control Area
struct BottomControlArea: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var shutterPressed: Bool
    let onCapture: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Filter carousel
            FilterCarousel(
                filters: viewModel.availableFilters,
                selectedFilter: viewModel.selectedFilter,
                onSelect: { viewModel.selectFilter($0) }
            )
            
            // Capture row
            HStack(alignment: .center, spacing: 44) {
                // Gallery
                Button(action: {}) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                        )
                }
                
                // Shutter Button
                ShutterButton(isPressed: shutterPressed, onTap: onCapture)
                
                // Effects toggle
                Button(action: {}) {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                        )
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Shutter Button
struct ShutterButton: View {
    let isPressed: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 76, height: 76)
                
                Circle()
                    .fill(.white)
                    .frame(width: isPressed ? 58 : 64, height: isPressed ? 58 : 64)
                    .scaleEffect(isPressed ? 0.88 : 1.0)
            }
        }
        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: isPressed)
    }
}

// MARK: - Filter Carousel
struct FilterCarousel: View {
    let filters: [FaceFilter]
    let selectedFilter: FaceFilter
    let onSelect: (FaceFilter) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters) { filter in
                    FilterThumbnailCell(
                        filter: filter,
                        isSelected: filter.id == selectedFilter.id,
                        onTap: { onSelect(filter) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Filter Thumbnail Cell
struct FilterThumbnailCell: View {
    let filter: FaceFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? .white : .white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(filter.type.iconName)
                        .font(.system(size: 26))
                    
                    if filter.isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.yellow)
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color(hex: "#FF6B9D") : .clear, lineWidth: 2)
                )
                
                Text(filter.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Vignette Overlay
struct VignetteOverlay: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.4)],
            center: .center,
            startRadius: UIScreen.main.bounds.width * 0.35,
            endRadius: UIScreen.main.bounds.width * 0.85
        )
    }
}

// MARK: - Save Confirmation Toast
struct SaveConfirmationToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Saved to Photos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 8)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

#Preview {
    MainCameraView()
}
