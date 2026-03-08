//
//  CameraViewModel.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import Foundation
import AVFoundation
import Vision
import UIKit
import SwiftUI
import Combine
import CoreImage

@MainActor
class CameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Published State
    @Published var selectedFilter: FaceFilter = FaceFilter.allFilters[0]
    @Published var availableFilters: [FaceFilter] = FaceFilter.allFilters
    @Published var detectedFaces: [FaceLandmarkData] = []
    @Published var isCapturing: Bool = false
    @Published var capturedImage: UIImage?
    @Published var showCapturePreview: Bool = false
    @Published var cameraPermissionGranted: Bool = false
    @Published var isFrontCamera: Bool = true
    @Published var isFlashOn: Bool = false
    @Published var filterOpacity: Double = 1.0
    
    // Performance Metrics (debug)
    @Published var fpsCount: Int = 0
    @Published var detectionLatency: Double = 0
    
    // MARK: - Camera Session
    let captureSession = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Vision
    private var faceDetectionRequest: VNDetectFaceLandmarksRequest?
    private var sequenceHandler = VNSequenceRequestHandler()
    // Nonisolated copies for use in delegate callback
    nonisolated(unsafe) private var _faceDetectionRequest: VNDetectFaceLandmarksRequest?
    nonisolated(unsafe) private var _sequenceHandler = VNSequenceRequestHandler()
    
    // MARK: - Rendering
    private(set) var filterOverlayLayer: CALayer?
    var previewLayerSize: CGSize = .zero
    
    // MARK: - Threading
    private let cameraQueue = DispatchQueue(
        label: "com.facefitar.camera",
        qos: .userInteractive
    )
    private let detectionQueue = DispatchQueue(
        label: "com.facefitar.detection",
        qos: .userInteractive
    )
    
    // MARK: - Performance
    private var frameCount: Int = 0
    private var fpsTimer: Timer?
    private var lastDetectionTime: CFAbsoluteTime = 0
    
    // MARK: - Services
    private let databaseService = DatabaseService.shared
    
    // MARK: - Init
    override init() {
        super.init()
        setupFaceDetection()
        checkCameraPermission()
        startFPSCounter()
    }
    
    deinit {
        fpsTimer?.invalidate()
        captureSession.stopRunning()  // Call directly on the session, bypassing @MainActor
    }
    
    // MARK: - Permission
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted { self?.setupCaptureSession() }
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }
    
    // MARK: - Session Setup
    func setupCaptureSession() {
        cameraQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1280x720  // Balance quality/performance
            
            // Camera Input
            let position: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.videoInput = input
            }
            
            // Video Output for face detection
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.alwaysDiscardsLateVideoFrames = true  // Performance optimization
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: self.detectionQueue)
            
            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
            }
            
            // Photo Output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            // Mirror front camera
            if let connection = videoOutput.connection(with: .video), self.isFrontCamera {
                connection.isVideoMirrored = true
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    // MARK: - Face Detection Setup
    private func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self, error == nil else { return }
            
            let faces = (request.results as? [VNFaceObservation]) ?? []
            let landmarkData = faces.map {
                FaceLandmarkData(from: $0, in: self.previewLayerSize)
            }
            
            DispatchQueue.main.async {
                self.detectedFaces = landmarkData
                self.detectionLatency = CFAbsoluteTimeGetCurrent() - self.lastDetectionTime
            }
        }
        
        // Configure for performance
        faceDetectionRequest?.preferBackgroundProcessing = true
        faceDetectionRequest?.usesCPUOnly = false  // Prefer Neural Engine / GPU
    
        _faceDetectionRequest = faceDetectionRequest
    }
    
    // MARK: - Camera Toggle
    func toggleCamera() {
        isFrontCamera.toggle()
        
        cameraQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            if let currentInput = self.videoInput {
                self.captureSession.removeInput(currentInput)
            }
            
            let position: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.videoInput = newInput
            }
            
            if let connection = self.videoOutput?.connection(with: .video) {
                connection.isVideoMirrored = self.isFrontCamera
            }
            
            self.captureSession.commitConfiguration()
        }
        
        // Clear faces on camera switch
        detectedFaces = []
    }
    
    // MARK: - Flash Toggle
    func toggleFlash() {
        guard let device = videoInput?.device, device.hasTorch else { return }
        
        try? device.lockForConfiguration()
        if isFlashOn {
            device.torchMode = .off
        } else {
            try? device.setTorchModeOn(level: 1.0)
        }
        device.unlockForConfiguration()
        isFlashOn.toggle()
    }
    
    // MARK: - Filter Selection
    func selectFilter(_ filter: FaceFilter) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedFilter = filter
        }
        
        // Log filter usage
        Task {
            if let userID = AuthViewModel().currentUser?.id {
                let record = FilterUsageRecord(
                    userID: userID,
                    filterID: filter.id,
                    filterName: filter.name
                )
                try? await databaseService.logFilterUsage(record)
            }
        }
    }
    
    // MARK: - Photo Capture
    func capturePhoto(with filterLayer: CALayer?) {
        guard !isCapturing else { return }
        isCapturing = true
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        if isFlashOn {
            settings.flashMode = .on
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Save Photo
    func savePhotoToLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    // MARK: - Session Control
    func startSession() {
        cameraQueue.async { [weak self] in
            if self?.captureSession.isRunning == false {
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        cameraQueue.async { [weak self] in
            if self?.captureSession.isRunning == true {
                self?.captureSession.stopRunning()
            }
        }
    }
    
    // MARK: - FPS Counter
    private func startFPSCounter() {
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.fpsCount = self.frameCount
                self.frameCount = 0
            }
        }
    }
    
    // MARK: - Compute Filter Transform
    /// Compute position, size, and rotation for filter overlay given face landmarks
    func filterTransform(for face: FaceLandmarkData, filter: FaceFilter) -> (position: CGPoint, size: CGSize, rotation: CGFloat) {
        let faceWidth = face.faceWidth
        let faceHeight = face.faceHeight
        
        let overlayWidth = faceWidth * filter.scaleFactor
        let overlayHeight = overlayWidth  // Assume square overlay; adjust per filter
        
        var position: CGPoint
        
        switch filter.anchorPoint {
        case .forehead:
            position = CGPoint(
                x: face.faceCenter.x,
                y: face.faceRect.minY + faceHeight * filter.verticalOffset
            )
        case .eyes:
            position = face.eyesMidpoint ?? CGPoint(
                x: face.faceCenter.x,
                y: face.faceRect.minY + faceHeight * 0.35
            )
        case .nose:
            position = face.nose ?? face.faceCenter
        case .mouth:
            position = face.mouth ?? CGPoint(
                x: face.faceCenter.x,
                y: face.faceRect.maxY - faceHeight * 0.15
            )
        case .face:
            position = face.faceCenter
        }
        
        return (
            position: position,
            size: CGSize(width: overlayWidth, height: overlayHeight),
            rotation: face.faceAngle
        )
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        Task { @MainActor in
            frameCount += 1
            lastDetectionTime = CFAbsoluteTimeGetCurrent()
        }

        guard let request = _faceDetectionRequest else { return }

        let orientation: CGImagePropertyOrientation = .leftMirrored

        try? _sequenceHandler.perform(
            [request],
            on: pixelBuffer,
            orientation: orientation
        )
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in self.isCapturing = false }
            return
        }
        
        Task { @MainActor in
            self.capturedImage = image
            self.showCapturePreview = true
            self.isCapturing = false
        }
    }
}

