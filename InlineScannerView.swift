//
//  InlineScannerView.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI
import AVFoundation

struct InlineScannerView: View {
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @State private var selectedProduct: Product?
    @Binding var isScanning: Bool
    
    let scannerWidth: CGFloat = 320
    let scannerHeight: CGFloat = 240
    
    var body: some View {
        ZStack {
            if !viewModel.permissionDenied {
                // Camera Preview
                CameraPreview(session: viewModel.session)
                    .frame(width: scannerWidth, height: scannerHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                
                // Professional scanning overlay
                ZStack {
                    // Dark overlay with cutout
                    InlineScannerOverlay()
                        .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
                    
                    // Modern scanning frame
                    ProfessionalScanningFrame(isScanning: viewModel.isScanning)
                    
                    // Scanning line animation
                    if viewModel.isScanning {
                        ProfessionalScanningLine()
                    }
                    
                }
                .frame(width: scannerWidth, height: scannerHeight)
                
                // Loading overlay
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: scannerWidth, height: scannerHeight)
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                        
                        Text("Fetching details...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            } else {
                // Permission denied view
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Camera Access Required")
                        .font(.headline)
                    
                    Text("Enable camera access in Settings to scan barcodes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Settings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .frame(width: scannerWidth, height: scannerHeight)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .frame(width: scannerWidth, height: scannerHeight)
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(item: $viewModel.scannedProduct, onDismiss: {
            // Stop scanning when product view is dismissed
            isScanning = false
        }) { product in
            ProductDetailsView(product: product)
        }
        .alert("No match", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                // Stop scanning after error
                isScanning = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Inline Scanner Overlay
struct InlineScannerOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        
        // Inner scanning area (smaller than the larger camera view)
        let inset: CGFloat = 40
        let innerRect = rect.insetBy(dx: inset, dy: inset)
        path.addRoundedRect(in: innerRect, cornerSize: CGSize(width: 16, height: 16))
        
        return path
    }
}

// MARK: - Professional Scanning Frame
struct ProfessionalScanningFrame: View {
    let isScanning: Bool
    
    var body: some View {
        ZStack {
            // Main frame border
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: isScanning ? [.green, .mint] : [.white, .gray.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            // Corner brackets
            VStack {
                HStack {
                    CornerBracket()
                    Spacer()
                    CornerBracket()
                        .rotation3DEffect(.degrees(90), axis: (x: 0, y: 0, z: 1))
                }
                Spacer()
                HStack {
                    CornerBracket()
                        .rotation3DEffect(.degrees(270), axis: (x: 0, y: 0, z: 1))
                    Spacer()
                    CornerBracket()
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 0, z: 1))
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Corner Bracket
struct CornerBracket: View {
    var body: some View {
        Path { path in
            // Modern L-shaped bracket
            path.move(to: CGPoint(x: 20, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 20))
            
            // Inner accent line
            path.move(to: CGPoint(x: 16, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 16))
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [.green, .mint]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 3
        )
        .frame(width: 20, height: 20)
    }
}

// MARK: - Professional Scanning Line
struct ProfessionalScanningLine: View {
    @State private var offset: CGFloat = -80
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .green.opacity(0.8),
                        .mint.opacity(0.9),
                        .green.opacity(0.8),
                        .clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 3)
            .blur(radius: 1)
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    offset = 80
                }
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                }
            }
    }
}


#Preview {
    InlineScannerView(isScanning: .constant(true))
}

