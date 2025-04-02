import SwiftUI

struct OTPVerificationView: View {
    let email: String
    let onVerificationComplete: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var supabaseController = SupabaseController()
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var timeRemaining = 60
    @State private var canResendOTP = false
    @FocusState private var isOTPFieldFocused: Bool
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.mint)
                        .padding()
                        .background(Circle().fill(Color.mint.opacity(0.2)))
                    
                    Text("OTP Verification")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("We've sent a verification code to")
                        .foregroundColor(.gray)
                    
                    Text(email)
                        .fontWeight(.medium)
                }
                .padding(.top)
                
                // OTP Input Field
                VStack(spacing: 15) {
                    HStack(spacing: 12) {
                        ForEach(0..<6) { index in
                            OTPDigitBox(
                                digit: index < otpCode.count ? String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)]) : "",
                                isSelected: otpCode.count == index && isOTPFieldFocused
                            )
                        }
                    }
                    .overlay(
                        TextField("", text: $otpCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($isOTPFieldFocused)
                            .opacity(0.001)
                            .onChange(of: otpCode) { oldValue, newValue in
                                // Limit to 6 digits and numbers only
                                otpCode = String(newValue.filter { $0.isNumber }.prefix(6))
                            }
                    )
                }
                .padding(.vertical)
                
                // Timer and Resend Button
                HStack {
                    if timeRemaining > 0 && !canResendOTP {
                        Text("Resend code in \(timeRemaining)s")
                            .foregroundColor(.gray)
                    } else {
                        Button("Resend Code") {
                            resendOTP()
                        }
                        .foregroundColor(.mint)
                    }
                }
                .font(.subheadline)
                
                // Verify Button
                Button(action: verifyOTP) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(otpCode.count == 6 ? Color.mint : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(otpCode.count != 6 || isLoading)
                
                // Cancel Button
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                isOTPFieldFocused = true
            }
            .onReceive(timer) { _ in
                if timeRemaining > 0 && !canResendOTP {
                    timeRemaining -= 1
                    if timeRemaining == 0 {
                        canResendOTP = true
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func verifyOTP() {
        guard otpCode.count == 6 else { return }
        isLoading = true
        
        Task {
            do {
                try await supabaseController.verifyOTP(email: email, token: otpCode)
                await MainActor.run {
                    isLoading = false
                    onVerificationComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func resendOTP() {
        isLoading = true
        
        Task {
            do {
                try await supabaseController.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    timeRemaining = 60
                    canResendOTP = false
                    otpCode = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - OTP Digit Box
struct OTPDigitBox: View {
    let digit: String
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.mint : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 45, height: 55)
            
            if digit.isEmpty {
                if isSelected {
                    Rectangle()
                        .fill(Color.mint)
                        .frame(width: 2, height: 25)
                        .opacity(0.5)
                }
            } else {
                Text(digit)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    OTPVerificationView(
        email: "test@example.com",
        onVerificationComplete: {},
        onCancel: {}
    )
} 