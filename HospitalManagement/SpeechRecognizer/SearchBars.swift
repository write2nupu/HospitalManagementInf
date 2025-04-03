import SwiftUI

struct SearchBars: View {
    @Binding var text: String
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var showPermissionAlert = false

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search invoices...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {
                handleMicrophoneButtonTap()
            }) {
                Image(systemName: getMicrophoneIcon())
                    .foregroundColor(getMicrophoneColor())
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        }
    }

    private func handleMicrophoneButtonTap() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
            text = speechRecognizer.recognizedText.trimmingCharacters(in: .whitespaces)
        } else {
            speechRecognizer.startRecording()
            text = ""
        }
    }

    private func getMicrophoneIcon() -> String {
        return speechRecognizer.isRecording ? "mic.fill" : "mic"
    }

    private func getMicrophoneColor() -> Color {
        return speechRecognizer.isRecording ? .red : .secondary
    }
}
