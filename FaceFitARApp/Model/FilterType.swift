//
//  FilterType.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import Foundation
import UIKit
import Vision

// MARK: - Filter Type
enum FilterType: String, CaseIterable, Codable {
    case roseCrown = "rose_crown"
    case animalEars = "animal_ears"
    case glasses = "glasses"
    case mask = "mask"
    case decorative = "decorative"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .roseCrown: return "Rose Crown"
        case .animalEars: return "Animal Ears"
        case .glasses: return "Glasses"
        case .mask: return "Mask"
        case .decorative: return "Sparkle"
        case .none: return "None"
        }
    }
    
    var iconName: String {
        switch self {
        case .roseCrown: return "🌹"
        case .animalEars: return "🐱"
        case .glasses: return "🕶️"
        case .mask: return "🎭"
        case .decorative: return "✨"
        case .none: return "⊘"
        }
    }
}

// MARK: - Face Filter Model
struct FaceFilter: Identifiable, Codable {
    let id: String
    let name: String
    let type: FilterType
    let overlayImageName: String      // Asset catalog name
    let thumbnailImageName: String
    var anchorPoint: FilterAnchorPoint
    var scaleFactor: CGFloat
    var verticalOffset: CGFloat       // Offset relative to face height
    var isPremium: Bool
    
    static let allFilters: [FaceFilter] = [
        FaceFilter(
            id: "none",
            name: "None",
            type: .none,
            overlayImageName: "",
            thumbnailImageName: "filter_none",
            anchorPoint: .forehead,
            scaleFactor: 1.0,
            verticalOffset: 0,
            isPremium: false
        ),
        FaceFilter(
            id: "rose_crown_1",
            name: "Rose Crown",
            type: .roseCrown,
            overlayImageName: "filter_rose_crown",
            thumbnailImageName: "thumb_rose_crown",
            anchorPoint: .forehead,
            scaleFactor: 1.2,
            verticalOffset: -0.15,
            isPremium: false
        ),
        FaceFilter(
            id: "cat_ears_1",
            name: "Cat Ears",
            type: .animalEars,
            overlayImageName: "filter_cat_ears",
            thumbnailImageName: "thumb_cat_ears",
            anchorPoint: .forehead,
            scaleFactor: 1.1,
            verticalOffset: -0.2,
            isPremium: false
        ),
        FaceFilter(
            id: "bunny_ears_1",
            name: "Bunny Ears",
            type: .animalEars,
            overlayImageName: "filter_bunny_ears",
            thumbnailImageName: "thumb_bunny_ears",
            anchorPoint: .forehead,
            scaleFactor: 1.0,
            verticalOffset: -0.35,
            isPremium: false
        ),
        FaceFilter(
            id: "sunglasses_1",
            name: "Sunglasses",
            type: .glasses,
            overlayImageName: "filter_sunglasses",
            thumbnailImageName: "thumb_sunglasses",
            anchorPoint: .eyes,
            scaleFactor: 0.95,
            verticalOffset: 0,
            isPremium: false
        ),
        FaceFilter(
            id: "retro_glasses_1",
            name: "Retro Glasses",
            type: .glasses,
            overlayImageName: "filter_retro_glasses",
            thumbnailImageName: "thumb_retro_glasses",
            anchorPoint: .eyes,
            scaleFactor: 0.9,
            verticalOffset: 0,
            isPremium: true
        ),
        FaceFilter(
            id: "venetian_mask_1",
            name: "Venetian",
            type: .mask,
            overlayImageName: "filter_venetian",
            thumbnailImageName: "thumb_venetian",
            anchorPoint: .nose,
            scaleFactor: 1.1,
            verticalOffset: -0.05,
            isPremium: true
        ),
        FaceFilter(
            id: "sparkle_1",
            name: "Sparkle",
            type: .decorative,
            overlayImageName: "filter_sparkle",
            thumbnailImageName: "thumb_sparkle",
            anchorPoint: .face,
            scaleFactor: 1.3,
            verticalOffset: 0,
            isPremium: false
        )
    ]
}

// MARK: - Filter Anchor Point
enum FilterAnchorPoint: String, Codable {
    case forehead   // Anchored to top of face / forehead
    case eyes       // Anchored to eye region
    case nose       // Anchored to nose
    case mouth      // Anchored to mouth
    case face       // Covers full face
}

// MARK: - Facial Landmark Data
struct FaceLandmarkData {
    var faceRect: CGRect
    var faceAngle: CGFloat          // Roll angle in degrees
    var yawAngle: CGFloat           // Yaw (left/right turn)
    var pitchAngle: CGFloat         // Pitch (up/down tilt)
    
    // Key landmark points (normalized 0-1 coordinates)
    var leftEye: CGPoint?
    var rightEye: CGPoint?
    var nose: CGPoint?
    var mouth: CGPoint?
    var leftEyebrow: CGPoint?
    var rightEyebrow: CGPoint?
    var faceContour: [CGPoint]
    
    // Computed properties
    var eyesMidpoint: CGPoint? {
        guard let l = leftEye, let r = rightEye else { return nil }
        return CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
    }
    
    var faceWidth: CGFloat { faceRect.width }
    var faceHeight: CGFloat { faceRect.height }
    var faceCenter: CGPoint { CGPoint(x: faceRect.midX, y: faceRect.midY) }
    
    init(from observation: VNFaceObservation, in viewSize: CGSize) {
        // Convert from Vision coordinates (origin bottom-left, normalized)
        // to UIKit coordinates (origin top-left)
        let w = viewSize.width
        let h = viewSize.height
        
        let visionRect = observation.boundingBox
        self.faceRect = CGRect(
            x: visionRect.origin.x * w,
            y: (1 - visionRect.origin.y - visionRect.height) * h,
            width: visionRect.width * w,
            height: visionRect.height * h
        )
        
        self.faceAngle = CGFloat(observation.roll?.floatValue ?? 0) * (180 / .pi)
        self.yawAngle = CGFloat(observation.yaw?.floatValue ?? 0) * (180 / .pi)
        self.pitchAngle = CGFloat(observation.pitch?.floatValue ?? 0) * (180 / .pi)
        self.faceContour = []
        
        // Extract landmarks
        if let landmarks = observation.landmarks {
            if let leftEyeRegion = landmarks.leftEye {
                let pts = leftEyeRegion.normalizedPoints
                if !pts.isEmpty {
                    let avg = pts.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                    leftEye = CGPoint(
                        x: (visionRect.origin.x + avg.x / CGFloat(pts.count) * visionRect.width) * w,
                        y: (1 - visionRect.origin.y - avg.y / CGFloat(pts.count) * visionRect.height) * h
                    )
                }
            }
            
            if let rightEyeRegion = landmarks.rightEye {
                let pts = rightEyeRegion.normalizedPoints
                if !pts.isEmpty {
                    let avg = pts.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                    rightEye = CGPoint(
                        x: (visionRect.origin.x + avg.x / CGFloat(pts.count) * visionRect.width) * w,
                        y: (1 - visionRect.origin.y - avg.y / CGFloat(pts.count) * visionRect.height) * h
                    )
                }
            }
            
            if let noseRegion = landmarks.nose {
                let pts = noseRegion.normalizedPoints
                if !pts.isEmpty {
                    let avg = pts.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                    nose = CGPoint(
                        x: (visionRect.origin.x + avg.x / CGFloat(pts.count) * visionRect.width) * w,
                        y: (1 - visionRect.origin.y - avg.y / CGFloat(pts.count) * visionRect.height) * h
                    )
                }
            }
            
            if let outerLips = landmarks.outerLips {
                let pts = outerLips.normalizedPoints
                if !pts.isEmpty {
                    let avg = pts.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                    mouth = CGPoint(
                        x: (visionRect.origin.x + avg.x / CGFloat(pts.count) * visionRect.width) * w,
                        y: (1 - visionRect.origin.y - avg.y / CGFloat(pts.count) * visionRect.height) * h
                    )
                }
            }
            
            if let contour = landmarks.faceContour {
                faceContour = contour.normalizedPoints.map { pt in
                    CGPoint(
                        x: (visionRect.origin.x + pt.x * visionRect.width) * w,
                        y: (1 - visionRect.origin.y - pt.y * visionRect.height) * h
                    )
                }
            }
        }
    }
}

