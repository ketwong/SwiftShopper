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
            previewLayer.connection?.videoOrientation = .landscapeRight // Set the video orientation to landscape right
            
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
    @State var name: String = ""
    @State var percentage: Double = 0.0
    
    var body: some View {
        ZStack {
            CameraView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            Rectangle()
                .foregroundColor(.white)
                .frame(height: UIScreen.main.bounds.height / 3) // Set the height to half the screen
                .opacity(0.7)
                .blur(radius: 0)
                .offset(y: UIScreen.main.bounds.height / 2.5) // Center the rectangle on the bottom half of the screen
                .alignmentGuide(.bottom) { d in d[.bottom] }
            
            VStack {
                Text("Object: \(name)")
                    .foregroundColor(.black)
                    .font(.title2)
                Text("Accuracy: \(percentage)%")
                    .foregroundColor(.black)
                    .font(.title3)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .offset(y: UIScreen.main.bounds.height / 3.5 + 50) // Center the text on the bottom half of the screen
        }
    }
}
