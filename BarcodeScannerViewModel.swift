//
//  BarcodeScannerViewModel.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import Foundation
import AVFoundation
import SwiftUI

class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isLoading = false
    @Published var scannedProduct: Product?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var permissionDenied = false
    @Published var dataConfidence: DataConfidence = .low
    
    let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "com.allergens.camera")
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCamera()
                } else {
                    DispatchQueue.main.async {
                        self?.permissionDenied = true
                        self?.showError(message: "Camera access is required to scan barcodes. Please enable it in Settings.")
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionDenied = true
                self.showError(message: "Camera access denied. Please enable camera access in Settings > Allergens.")
            }
        @unknown default:
            break
        }
    }
    
    func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                DispatchQueue.main.async {
                    self.showError(message: "Unable to access camera")
                }
                return
            }
            
            self.session.addInput(videoInput)
            
            // Add metadata output for barcode scanning
            let metadataOutput = AVCaptureMetadataOutput()
            
            if self.session.canAddOutput(metadataOutput) {
                self.session.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
                    .ean8,
                    .ean13,
                    .upce,
                    .code128,
                    .code39,
                    .qr
                ]
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startScanning() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isSessionRunning else { return }
            self.session.startRunning()
            self.isSessionRunning = true
            
            DispatchQueue.main.async {
                self.isScanning = true
            }
        }
    }
    
    func stopScanning() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.isSessionRunning else { return }
            self.session.stopRunning()
            self.isSessionRunning = false
            
            DispatchQueue.main.async {
                self.isScanning = false
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        // Prevent multiple scans
        guard !isLoading else { return }
        
        isLoading = true
        stopScanning()
        
        // Fetch enhanced product data from multiple sources
        Task {
            do {
                let enhancedData = await EnhancedProductService.shared.getEnhancedProductData(barcode: barcode)
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if let enhancedData = enhancedData {
                        // Update confidence level
                        self.dataConfidence = enhancedData.confidence
                        
                        // Create enhanced product
                        let enhancedProduct = EnhancedProductService.shared.createEnhancedProduct(for: enhancedData)
                        
                        // Save to history
                        ScanHistoryManager.shared.saveProduct(enhancedProduct)
                        
                        // Add 0.5 second delay before showing product view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.scannedProduct = enhancedProduct
                        }
                    } else {
                        self.showError(message: "Looks like this product isn't in the database yet")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError(message: "Failed to fetch product data")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let barcode = readableObject.stringValue else {
            return
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        handleScannedBarcode(barcode)
    }
}

