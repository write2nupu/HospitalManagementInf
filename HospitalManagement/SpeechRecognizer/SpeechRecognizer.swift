import Foundation
import AVFoundation
import Speech
import SwiftUI

@MainActor
class SpeechRecognizer: NSObject, ObservableObject, @unchecked Sendable {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: AlertMessage?
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .notDetermined
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    enum MicrophonePermissionStatus: Equatable {
        case notDetermined
        case authorized
        case denied
        case restricted
        case error(String)
        
        static func == (lhs: MicrophonePermissionStatus, rhs: MicrophonePermissionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notDetermined, .notDetermined),
                 (.authorized, .authorized),
                 (.denied, .denied),
                 (.restricted, .restricted):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    override init() {
        if let locale = Locale.current.language.languageCode?.identifier {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        } else {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
        super.init()
        checkMicrophonePermission()
    }
    
    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermissionStatus = .authorized
        case .denied:
            microphonePermissionStatus = .denied
        case .undetermined:
            microphonePermissionStatus = .notDetermined
        @unknown default:
            microphonePermissionStatus = .error("Unknown permission status")
        }
    }
    
    public func requestAuthorization() {
        // First request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                if granted {
                    self?.microphonePermissionStatus = .authorized
                    // Then request speech recognition permission
                    SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                        Task { @MainActor [weak self] in
                            switch authStatus {
                            case .authorized:
                                self?.microphonePermissionStatus = .authorized
                            case .denied:
                                self?.microphonePermissionStatus = .denied
                                self?.errorMessage = AlertMessage(message: "Speech recognition authorization was denied. Please enable it in Settings.")
                            case .restricted:
                                self?.microphonePermissionStatus = .restricted
                                self?.errorMessage = AlertMessage(message: "Speech recognition is restricted on this device.")
                            case .notDetermined:
                                self?.microphonePermissionStatus = .notDetermined
                            @unknown default:
                                self?.microphonePermissionStatus = .error("Unknown authorization status")
                                self?.errorMessage = AlertMessage(message: "An unknown error occurred during authorization.")
                            }
                        }
                    }
                } else {
                    self?.microphonePermissionStatus = .denied
                    self?.errorMessage = AlertMessage(message: "Microphone access was denied. Please enable it in Settings.")
                }
            }
        }
    }
    
    func startRecording() {
        errorMessage = nil
        recognizedText = ""
        
        guard microphonePermissionStatus == .authorized else {
            errorMessage = AlertMessage(message: "Microphone access is required for voice search. Please enable it in Settings.")
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = AlertMessage(message: "Speech recognition is not available at the moment.")
            return
        }
        
        // Setup audio engine and recognition request
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = request else {
            errorMessage = AlertMessage(message: "Failed to create recognition request.")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = AlertMessage(message: "Audio session error: \(error.localizedDescription)")
            return
        }
        
        guard let inputNode = audioEngine?.inputNode else {
            errorMessage = AlertMessage(message: "Audio engine has no input node.")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                if let error = error {
                    self?.errorMessage = AlertMessage(message: "Recognition error: \(error.localizedDescription)")
                    self?.stopRecording()
                    return
                }
                
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        do {
            try audioEngine?.start()
            isRecording = true
        } catch {
            errorMessage = AlertMessage(message: "Audio engine couldn't start: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        
        // Deactivate audio session when done
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }
    
    func reset() {
        stopRecording()
        recognizedText = ""
        errorMessage = nil
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}
