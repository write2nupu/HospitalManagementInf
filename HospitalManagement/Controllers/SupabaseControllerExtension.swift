import Supabase

extension SupabaseController {
    func sendOTP(email: String) async throws {
        // Send OTP to email using signInWithOTP
        try await client.auth.signInWithOTP(
            email: email
        )
    }
    
    func verifyOTP(email: String, token: String) async throws {
        // Verify the OTP token
        try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
    }
} 