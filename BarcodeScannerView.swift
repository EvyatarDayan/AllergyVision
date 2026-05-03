//
//  BarcodeScannerView.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = BarcodeScannerViewModel()
    
    var body: some View {
        ZStack {
            // Camera Preview
            if !viewModel.permissionDenied {
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
            } else {
                // Permission denied view
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("To scan barcodes, please allow camera access in your device settings.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Settings")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 10)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)
                }
            }
            
            // Overlay with scanning area
            if !viewModel.permissionDenied {
                ZStack {
                    // Full screen dark overlay with cutout
                    ScannerOverlay()
                        .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 150)
                        
                        // Scanning instructions
                        Text("Position barcode within the frame")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                        
                        // Scanning area frame
                        ZStack {
                            // Frame border
                            Rectangle()
                                .stroke(viewModel.isScanning ? Color.green : Color.white, lineWidth: 3)
                                .frame(width: 280, height: 200)
                            
                            // Corner indicators
                            VStack {
                                HStack {
                                    ScannerCorner()
                                    Spacer()
                                    ScannerCorner()
                                        .rotation3DEffect(.degrees(90), axis: (x: 0, y: 0, z: 1))
                                }
                                Spacer()
                                HStack {
                                    ScannerCorner()
                                        .rotation3DEffect(.degrees(270), axis: (x: 0, y: 0, z: 1))
                                    Spacer()
                                    ScannerCorner()
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 0, z: 1))
                                }
                            }
                            .frame(width: 280, height: 200)
                            
                            // Scanning line animation
                            if viewModel.isScanning {
                                ScanningLine()
                            }
                        }
                        .frame(height: 200)
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            
            // Loading indicator
            if viewModel.isLoading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Fetching product details...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(item: $viewModel.scannedProduct) { product in
            ProductDetailsView(product: product)
        }
        .alert("No match", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Scanner Overlay with Cutout
struct ScannerOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Add the full screen rectangle
        path.addRect(rect)
        
        // Calculate the center position for the cutout
        let cutoutWidth: CGFloat = 280
        let cutoutHeight: CGFloat = 200
        let cutoutX = (rect.width - cutoutWidth) / 2
        let cutoutY = rect.midY - cutoutHeight / 2 - 20 // Slightly above center
        
        // Subtract the cutout rectangle (using even-odd fill rule)
        let cutoutRect = CGRect(x: cutoutX, y: cutoutY, width: cutoutWidth, height: cutoutHeight)
        path.addRect(cutoutRect)
        
        return path
    }
}

// MARK: - Scanner Corner
struct ScannerCorner: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 30, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 30))
        }
        .stroke(Color.green, lineWidth: 4)
        .frame(width: 30, height: 30)
    }
}

// MARK: - Scanning Line
struct ScanningLine: View {
    @State private var offset: CGFloat = -100
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .green, .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 280, height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    offset = 100
                }
            }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

#Preview {
    BarcodeScannerView()
}

