# 🎭 FaceFit AR
Real-Time Face Filter iOS Application

Turn your face into a live AR playground.
FaceFit AR detects facial landmarks in real time and attaches animated filters that move, rotate, and scale with your face.

Built using Swift, AVFoundation, Vision Framework, Firebase, and Core Data.

## ✨ What This App Does

📷 Opens the camera and detects faces in real time
🎭 Applies animated filters that follow facial movement
📐 Adjusts position, scale, and rotation automatically
📸 Captures photos with filters applied
👤 Stores user data and filter usage stats

https://drive.google.com/file/d/1EcU0owIMUKDoa-bR4DpeqAvN6LNjk_0p/view?usp=sharing

<img width="379" height="782" alt="Screenshot 2026-03-05 at 9 02 39 PM" src="https://github.com/user-attachments/assets/129da7d4-0a54-4ff7-a411-5f4d27cc4f78" />
<img width="368" height="777" alt="Screenshot 2026-03-05 at 9 02 03 PM" src="https://github.com/user-attachments/assets/56982aed-7b2c-425a-ac05-1ec373b98f7c" />
<img width="381" height="786" alt="Screenshot 2026-03-05 at 9 01 45 PM" src="https://github.com/user-attachments/assets/d55d72ec-ec05-4f5c-9ff5-52ac7250f3f2" />
<img width="363" height="770" alt="Screenshot 2026-03-05 at 9 02 52 PM" src="https://github.com/user-attachments/assets/22096c34-a60d-442f-8b6b-9942ebc7e2ec" />

##  📂 Project Structure

FaceFitAR
│
├── App
│   ├── FaceFitARApp.swift
│   └── RootView.swift
│
├── Models
│   ├── User.swift
│   └── FaceFilter.swift
│
├── ViewModels
│   ├── AuthViewModel.swift
│   └── CameraViewModel.swift
│
├── Views
│   ├── Auth
│   │   └── AuthView.swift
│   │
│   ├── Camera
│   │   ├── MainCameraView.swift
│   │   ├── CameraPreviewView.swift
│   │   └── FilterOverlayView.swift
│   │
│   └── Profile
│       └── ProfileView.swift
│
└── Services
    └── DatabaseService.swift


##Folder Roles

### 📦 App
Application entry point and root navigation logic.

### 🧠 ViewModels
Where the brain of the app lives. Handles authentication, camera lifecycle, and filter state.

### 🗂 Models
Data structures representing users, filters, and landmark data.

### 🖥 Views
SwiftUI screens for camera, authentication, and profile.

### ☁️ Services
Handles data storage and retrieval using Firebase and CoreData.

### 🧠 Architecture

The app uses MVVM (Model View ViewModel) for clean separation of responsibilities.

View
  ↓ observes
ViewModel
  ↓ communicates
Services
  ↓ interacts with
Database / System APIs

### Why MVVM?

✔ Clean separation of UI and logic
✔ Easier testing
✔ Scalable architecture for larger apps

Camera Capture (AVFoundation)
        │
        ▼
Frame Buffer
        │
        ▼
Vision Framework
Face Landmark Detection
        │
        ▼
FaceLandmarkData
        │
        ▼
FilterOverlayView
        │
        ▼
CALayer Transform Rendering

## 🎭 Filter System

Each filter defines three simple rules:

Anchor Point
Where it attaches to the face (eyes, nose, forehead, etc).

Scale Factor
How large it should appear relative to face size.

Vertical Offset
Fine-tuning for perfect alignment.

This allows filters to stay locked to the face even while moving or rotating.

## ⚡ Rendering Strategy

Filters are drawn using Core Animation CALayer instead of SwiftUI overlays.

### Why?

SwiftUI view updates are tied to the main run loop and can drop frames.

### Using CALayer gives:

🚀 Faster updates
🎯 Accurate positioning
🎥 Smooth 30fps rendering

## 🧵 Threading Model
Camera Queue
AVCaptureSession frame capture

Detection Queue
Vision face landmark detection

Main Thread
SwiftUI UI updates + CALayer rendering

Separating these tasks keeps the UI smooth even during heavy camera processing.

## 🚀 Performance Goals
Metric	Target
Frame rate	30 FPS
Detection latency	< 33 ms
Memory usage	< 150 MB
Camera startup	< 1.2 seconds

## 🛠 Technologies
Swift
SwiftUI
AVFoundation
Vision Framework
Core Animation
Firebase Authentication
Firebase Firestore
CoreData

## 🎯 Why This Project Matters

FaceFit AR demonstrates how to build a real-time computer vision application on iOS while maintaining smooth UI performance.

It combines:

📷 Camera processing
🧠 Computer vision
🎭 AR-style filter rendering
☁️ Cloud backend integration
📱 Modern SwiftUI architecture

## 👨‍💻 Author

Agastya Nand
iOS Developer
