import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    var timer: Timer?
    
    // Path to save the recording
    var audioFilename: URL?
    
    override init() {
        super.init()
    }
    
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { allowed in
                DispatchQueue.main.async {
                    completion(allowed)
                }
            }
        default:
            completion(false)
        }
    }
    
    func startRecording() {
        // Ensure documents directory exists
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let audioURL = docsDirect.appendingPathComponent("voice_message_\(Date().timeIntervalSince1970).m4a")
        audioFilename = audioURL
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.recordingTime += 0.1
            }
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    func cancelRecording() {
        stopRecording()
        if let url = audioFilename {
            try? FileManager.default.removeItem(at: url)
        }
        audioFilename = nil
    }
}
