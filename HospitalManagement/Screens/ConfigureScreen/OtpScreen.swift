//
//  OtpScreen.swift
//  HospitalManagement
//
//  Created by Mariyo on 24/03/25.
//

import SwiftUI

struct OTPVerificationView: View {
    var user: users   // Authenticated User Data
    
    @State private var otp: [String] = Array(repeating: "", count: 6)  // Updated to 6 digits
    @FocusState private var focusedIndex: Int?
    @State private var isOTPValid = false
    @State private var errorMessage: String?
    @State private var resendTimer = 30
    
//    @State private var isResendEnabled = false
    
    var body: some View {
        NavigationStack {
            Spacer()
            VStack(spacing: 30) {
                Text("Enter OTP")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We have sent a 6-digit OTP to your registered mobile/email.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        TextField("", text: $otp[index])
                            .keyboardType(.numberPad)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .multilineTextAlignment(.center)
                            .font(.title)
                            .focused($focusedIndex, equals: index)
                            .onChange(of: otp[index]) { newValue in
                                handleOTPInputChange(index: index, value: newValue)
                            }
                    }
                }
                
//                if isResendEnabled {
//                    Button("Resend OTP") {
//                        resendOTP()
//                    }
//                    .font(.headline)
//                    .foregroundColor(.black)
//                } else {
//                    Text("Resend OTP in \(resendTimer)s")
//                        .foregroundColor(.gray)
//                        .onAppear {
//                            startResendTimer()
//                        }
//                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                NavigationLink(destination: getDashboardView(), isActive: $isOTPValid) {
                    Button(action: validateOTP) {
                        Text("Verify OTP")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isOTPComplete() ? AppConfig.buttonColor : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isOTPComplete())
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding()
            .background(AppConfig.backgroundColor)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func handleOTPInputChange(index: Int, value: String) {
        let filteredValue = value.filter { "0123456789".contains($0) } // Allow only numbers
        
        if filteredValue.count > 1 {
            otp[index] = String(filteredValue.last!)  // Keep only last digit
        } else {
            otp[index] = filteredValue
        }
        
        // Auto-move focus
        if !filteredValue.isEmpty && index < 5 {
            focusedIndex = index + 1
        } else if filteredValue.isEmpty && index > 0 {
            focusedIndex = index - 1
        }
    }
    
    private func isOTPComplete() -> Bool {
        return otp.allSatisfy { !$0.isEmpty }
    }


    
    private func validateOTP() {
        let enteredOTP = otp.joined()
        
        if enteredOTP == "123456" {  // Updated to 6-digit OTP
            isOTPValid = true
        } else {
            errorMessage = "Invalid OTP. Please try again."
        }
    }
    
    private func startResendTimer() {
        resendTimer = 30
//        isResendEnabled = false
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            resendTimer -= 1
            if resendTimer <= 0 {
                timer.invalidate()
//                isResendEnabled = true
            }
        }
    }
    
//    private func resendOTP() {
//        errorMessage = nil
//        otp = Array(repeating: "", count: 6)  // Fixed OTP reset issue
//        focusedIndex = 0
//        startResendTimer()
//    }
    
    @ViewBuilder
    private func getDashboardView() -> some View {
        switch user.role.lowercased() {
        case "admin":
            AdminHomeView()
        case "superadmin":
            ContentView()
        case "doctor":
            mainBoard()
//        case "patient":
//            PatientDashboardView()
        default:
            Text("Role not recognized").foregroundColor(.red)
        }
    }
}


