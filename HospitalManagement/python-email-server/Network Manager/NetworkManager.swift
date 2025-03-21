import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case serverError(Int)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:5001"
    
    private init() {}
    
    func sendTemporaryPassword(email: String, tempPassword: String, role: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/send-email") else {
            throw NetworkError.invalidURL
        }
        
        let payload: [String: String] = [
            "email": email,
            "tempPassword": tempPassword,
            "role": role
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["message"] ?? "Email sent successfully"
    }
} 
