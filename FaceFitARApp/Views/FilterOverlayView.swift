//
//  FilterOverlayView.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import UIKit
import QuartzCore

class FilterOverlayView: UIView {
    
    // MARK: - Properties
    private var filterLayers: [CALayer] = []
    private var currentFilter: FaceFilter = FaceFilter.allFilters[0]
    
    // Particle layers for decorative effects
    private var particleLayer: CAEmitterLayer?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        layer.masksToBounds = false
    }
    
    // MARK: - Update Filter Display
    func updateFilter(_ filter: FaceFilter) {
        currentFilter = filter
        
        // Remove particle effects when switching away from decorative
        if filter.type != .decorative {
            particleLayer?.removeFromSuperlayer()
            particleLayer = nil
        }
    }
    
    // MARK: - Render Faces
    /// Called every frame with fresh face landmark data
    func renderFaces(_ faces: [FaceLandmarkData], filter: FaceFilter, opacity: CGFloat = 1.0) {
        
        // Animate layer updates without flicker
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Remove excess layers
        while filterLayers.count > faces.count {
            filterLayers.removeLast().removeFromSuperlayer()
        }
        
        // Add missing layers
        while filterLayers.count < faces.count {
            let newLayer = makeFilterLayer(for: filter)
            layer.addSublayer(newLayer)
            filterLayers.append(newLayer)
        }
        
        // Update each face layer
        for (index, face) in faces.enumerated() {
            let filterLayer = filterLayers[index]
            
            if filter.type == .none {
                filterLayer.isHidden = true
                continue
            }
            
            filterLayer.isHidden = false
            filterLayer.opacity = Float(opacity)
            
            // Compute transform
            let (position, size, rotation) = computeTransform(for: face, filter: filter)
            
            filterLayer.position = position
            filterLayer.bounds = CGRect(origin: .zero, size: size)
            
            // Apply rotation matching face angle
            let rotationRadians = rotation * .pi / 180
            filterLayer.transform = CATransform3DMakeRotation(rotationRadians, 0, 0, 1)
            
            // Apply yaw scaling (perspective effect when turning head)
            let yawScale = max(0.3, cos(face.yawAngle * .pi / 180))
            var transform = filterLayer.transform
            transform = CATransform3DScale(transform, CGFloat(yawScale), 1.0, 1.0)
            filterLayer.transform = transform
        }
        
        CATransaction.commit()
        
        // Update decorative particle effect
        if filter.type == .decorative && !faces.isEmpty {
            updateParticleEffect(for: faces[0])
        }
    }
    
    // MARK: - Make Filter Layer
    private func makeFilterLayer(for filter: FaceFilter) -> CALayer {
        let filterLayer = CALayer()
        
        if let image = UIImage(named: filter.overlayImageName) {
            filterLayer.contents = image.cgImage
            filterLayer.contentsGravity = .resizeAspect
        } else {
            // Fallback: Draw emoji placeholder
            filterLayer.contents = renderEmojiAsImage(filter.type.iconName, size: CGSize(width: 120, height: 120))?.cgImage
        }
        
        filterLayer.shadowColor = UIColor.black.cgColor
        filterLayer.shadowOpacity = 0.3
        filterLayer.shadowOffset = CGSize(width: 0, height: 2)
        filterLayer.shadowRadius = 4
        
        return filterLayer
    }
    
    // MARK: - Compute Transform
    private func computeTransform(
        for face: FaceLandmarkData,
        filter: FaceFilter
    ) -> (position: CGPoint, size: CGSize, rotation: CGFloat) {
        
        let faceWidth = face.faceWidth
        let faceHeight = face.faceHeight
        
        // Scale filter overlay proportional to face size
        let overlayWidth = faceWidth * filter.scaleFactor
        
        // Aspect ratio: use original image ratio or default to some ratios per type
        let aspectRatio: CGFloat
        switch filter.type {
        case .roseCrown: aspectRatio = 2.0  // Wide crown
        case .animalEars: aspectRatio = 1.5
        case .glasses: aspectRatio = 2.5   // Wide glasses
        case .mask: aspectRatio = 1.0
        case .decorative: aspectRatio = 1.5
        case .none: aspectRatio = 1.0
        }
        
        let overlayHeight = overlayWidth / aspectRatio
        let size = CGSize(width: overlayWidth, height: overlayHeight)
        
        var position: CGPoint
        
        switch filter.anchorPoint {
        case .forehead:
            // Anchor above the eyes
            let foreheadY = face.faceRect.minY + faceHeight * 0.2 + faceHeight * filter.verticalOffset
            position = CGPoint(x: face.faceCenter.x, y: foreheadY)
            
        case .eyes:
            // Center on eye midpoint
            if let eyeMid = face.eyesMidpoint {
                position = CGPoint(x: eyeMid.x, y: eyeMid.y + faceHeight * filter.verticalOffset)
            } else {
                position = CGPoint(x: face.faceCenter.x, y: face.faceRect.minY + faceHeight * 0.38)
            }
            
        case .nose:
            position = face.nose ?? face.faceCenter
            
        case .mouth:
            position = face.mouth ?? CGPoint(x: face.faceCenter.x, y: face.faceRect.maxY - faceHeight * 0.15)
            
        case .face:
            position = face.faceCenter
        }
        
        return (position, size, face.faceAngle)
    }
    
    // MARK: - Particle Effect (Decorative Filter)
    private func updateParticleEffect(for face: FaceLandmarkData) {
        if particleLayer == nil {
            let emitter = CAEmitterLayer()
            emitter.emitterShape = .rectangle
            emitter.renderMode = .additive
            
            let cell = CAEmitterCell()
            cell.birthRate = 12
            cell.lifetime = 2.0
            cell.lifetimeRange = 0.5
            cell.velocity = 60
            cell.velocityRange = 30
            cell.emissionRange = .pi * 2
            cell.scale = 0.06
            cell.scaleRange = 0.04
            cell.spin = 2
            cell.spinRange = 4
            cell.alphaSpeed = -0.4
            
            // Use star shape or sparkle image
            if let sparkle = renderEmojiAsImage("✨", size: CGSize(width: 30, height: 30)) {
                cell.contents = sparkle.cgImage
            }
            
            emitter.emitterCells = [cell]
            layer.addSublayer(emitter)
            particleLayer = emitter
        }
        
        particleLayer?.emitterPosition = face.faceCenter
        particleLayer?.emitterSize = CGSize(width: face.faceWidth, height: face.faceHeight)
    }
    
    // MARK: - Helpers
    private func renderEmojiAsImage(_ emoji: String, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        let fontSize = min(size.width, size.height) * 0.8
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let text = emoji as NSString
        let textSize = text.size(withAttributes: attributes)
        
        let origin = CGPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        )
        text.draw(at: origin, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Snapshot (for photo capture)
    func snapshotForCapture() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

#Preview {
    FilterOverlayView()
}
