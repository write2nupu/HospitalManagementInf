import SwiftUI

struct LoginView: View {
    @StateObject private var supabaseController = SupabaseController()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            if isLoading {
                ProgressView()
            } else {
                Button("Login") {
                    Task {
                        await login()
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            let admin = try await supabaseController.signInAdmin(email: email, password: password)
            print("Admin logged in successfully:", admin)
            // Navigate to AdminHomeView or handle successful login
        } catch {
            errorMessage = error.localizedDescription
            print("Login error:", error)
        }

        isLoading = false
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 