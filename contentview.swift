import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let captureSession = AVCaptureSession()
        
        // Request camera access
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            // Set up the capture device
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
            captureSession.addInput(input)
            
            // Set up the preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoOrientation = .landscapeRight // Set the video orientation
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                // Remove any existing sublayers
                uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                // Add the preview layer
                previewLayer.frame = uiView.bounds
                uiView.layer.addSublayer(previewLayer)
                
                // Start running the capture session
                captureSession.startRunning()
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            CameraView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
