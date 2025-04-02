//
//  SearchBars.swift
//  HospitalManagement
//
//  Created by Shivani Verma on 02/04/25.
//

import SwiftUICore
import SwiftUI



// MARK: - SearchBar with Microphone
struct SearchBars: View {
    @Binding var text: String
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var showPermissionAlert = false

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            // Search Text Field
            TextField("Search invoices...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // Clear Button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            // Microphone Button
            Button(action: {
                handleMicrophoneButtonTap()
            }) {
                Image(systemName: getMicrophoneIcon())
                    .foregroundColor(getMicrophoneColor())
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("Please enable microphone access in Settings to use voice search.")
        }
        .onAppear {
            speechRecognizer.requestAuthorization()
        }
    }

    // MARK: - Microphone Button Tap Handler
    private func handleMicrophoneButtonTap() {
        switch speechRecognizer.microphonePermissionStatus {
        case .notDetermined:
            speechRecognizer.requestAuthorization()
        case .authorized:
            if speechRecognizer.isRecording {
                // Stop Recording and Set Recognized Text
                speechRecognizer.stopRecording()
                text = speechRecognizer.recognizedText
            } else {
                // Start Recording
                speechRecognizer.startRecording()
                text = "" // Clear current text while recording
            }
        case .denied, .restricted, .error:
            showPermissionAlert = true
        }
    }

    // MARK: - Dynamic Microphone Icon
    private func getMicrophoneIcon() -> String {
        switch speechRecognizer.microphonePermissionStatus {
        case .authorized:
            return speechRecognizer.isRecording ? "mic.fill" : "mic"
        case .denied, .restricted, .error:
            return "mic.slash.fill"
        case .notDetermined:
            return "mic"
        }
    }

    // MARK: - Dynamic Microphone Color
    private func getMicrophoneColor() -> Color {
        switch speechRecognizer.microphonePermissionStatus {
        case .authorized:
            return speechRecognizer.isRecording ? .red : .secondary
        case .denied, .restricted, .error:
            return .red
        case .notDetermined:
            return .secondary
        }
    }
}
