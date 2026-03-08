//
//  CameraPreviewView.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel
    
    func makeUIView(context: Context) -> CameraUIView {
        let view = CameraUIView()
        view.setupPreview(session: viewModel.captureSession)
        view.filterOverlayView.updateFilter(viewModel.selectedFilter)
        
        // Observe face changes
        context.coordinator.setupObserver(viewModel: viewModel, overlayView: view.filterOverlayView)
        
        return view
    }
    
    func updateUIView(_ uiView: CameraUIView, context: Context) {
        uiView.filterOverlayView.updateFilter(viewModel.selectedFilter)
        
        // Update preview layer frame
        DispatchQueue.main.async {
            uiView.previewLayer?.frame = uiView.bounds
            uiView.filterOverlayView.frame = uiView.bounds
            viewModel.previewLayerSize = uiView.bounds.size
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        private var observation: NSKeyValueObservation?
        
        func setupObserver(viewModel: CameraViewModel, overlayView: FilterOverlayView) {
            // Observe face detection results and update overlay
            Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { [weak viewModel, weak overlayView] _ in
                guard let vm = viewModel, let overlay = overlayView else { return }
                DispatchQueue.main.async {
                    overlay.renderFaces(
                        vm.detectedFaces,
                        filter: vm.selectedFilter,
                        opacity: vm.filterOpacity
                    )
                }
            }
        }
    }
}

// MARK: - CameraUIView
class CameraUIView: UIView {
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    let filterOverlayView = FilterOverlayView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        filterOverlayView.frame = bounds
    }
    
    func setupPreview(session: AVCaptureSession) {
        backgroundColor = .black
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.addSublayer(preview)
        previewLayer = preview
        
        // Add filter overlay on top
        filterOverlayView.frame = bounds
        filterOverlayView.backgroundColor = .clear
        addSubview(filterOverlayView)
    }
}


//#Preview {
//    CameraPreviewView()
//}
