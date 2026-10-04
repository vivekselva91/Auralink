import AVFoundation
import Vision
import AuraLinkCore

/// Front camera + Vision hand-pose detection at 30 fps, used only for the optional no-look pinch.
/// It runs on demand, never in the background. Frames are processed in memory and never stored or sent.
final class HandPoseCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onSample: ((HandSample) -> Void)?

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "auralink.handpose")
    private let request: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 1
        return r
    }()
    private var configured = false

    func start() {
        queue.async { [self] in
            if !configured { configure() }
            session.startRunning()
        }
    }

    func stop() { queue.async { [self] in session.stopRunning() } }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .vga640x480    // enough for hand joints; keeps power and latency low
        let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        guard let device, let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            session.commitConfiguration(); return
        }
        session.addInput(input)
        try? device.lockForConfiguration()
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
        device.unlockForConfiguration()

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true    // latency over completeness
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        configured = true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Orientation depends on how the phone is held; .up assumes the connection delivers upright frames.
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        guard (try? handler.perform([request])) != nil,
              let obs = request.results?.first,
              let thumb = try? obs.recognizedPoint(.thumbTip),
              let index = try? obs.recognizedPoint(.indexTip) else { return }

        let sample = HandSample(
            time: CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds,
            thumbTip: (Double(thumb.location.x), Double(thumb.location.y)),
            indexTip: (Double(index.location.x), Double(index.location.y)),
            confidence: Double(min(thumb.confidence, index.confidence)))
        DispatchQueue.main.async { self.onSample?(sample) }
    }
}
