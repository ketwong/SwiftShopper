import SwiftUI
import AVFoundation
import Vision
import CoreML
import PlaygroundSupport

func loadObjectDetectionModel() -> VNCoreMLModel? {
    guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodel") else {
        print("Failed to locate model file in playground's Resources folder")
        return nil
    }
    do {
        let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        return model
    } catch {
        print("Failed to load model from file: \(error.localizedDescription)")
        return nil
    }
}

// Define the CameraView as a UIViewRepresentable
// Define the CameraView as a UIViewRepresentable
struct CameraView: UIViewRepresentable {
    let model: VNCoreMLModel?
    
    func makeUIView(context: Context) -> UIView {
        return UIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let model = model else { return }
        
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
                
                // Use the object detection model to detect objects in the camera feed
                let request = VNCoreMLRequest(model: model) { request, error in
                    guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }
                    let newObservations = observations.filter { observation in
                        // Only show observations with a confidence of 30% or higher
                        return observation.confidence > 0.3
                    }
                    if let firstObservation = newObservations.first {
                        // Update the state variables for the detected object name and percentage
                        name = firstObservation.labels.first?.identifier ?? ""
                        percentage = Double(firstObservation.confidence * 100)
                    } else {
                        // If no objects are detected, set the state variables to empty
                        name = ""
                        percentage = 0.0
                    }
                }
                request.imageCropAndScaleOption = .centerCrop
                let handler = VNImageRequestHandler(cvPixelBuffer: CMSampleBufferGetImageBuffer(CMSampleBufferCreateCopy(nil, context.sampleBuffer)!)!, orientation: .right, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}


struct ContentView: View {
    @State var name: String = ""
    @State var percentage: Double = 0.0
    @State var model: VNCoreMLModel?
    
    var body: some View {
        ZStack {
            CameraView(model: model, name: $name, percentage: $percentage)

                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .foregroundColor(.white)
                .frame(height: UIScreen.main.bounds
                    .height / 2) // Set the height to half the screen
                .opacity(0.7)
                .blur(radius: 20)
                .offset(y: UIScreen.main.bounds.height / 4) // Center the rectangle on the bottom half of the screen
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
            .offset(y: UIScreen.main.bounds.height / 4 + 50) // Center the text on the bottom half of the screen
        }
        .onAppear {
            model = loadObjectDetectionModel()
        }
    }
}

