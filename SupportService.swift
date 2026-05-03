//
//  SupportService.swift
//  AllergyVision
//
//  Created to send support messages from the app without opening Mail.
//

import Foundation

struct SupportMessage: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let appVersion: String
    let deviceModel: String
    let systemVersion: String
    let sentAt: String
}

enum SupportSendError: Error {
    case notConfigured
    case network
    case badResponse
}

final class SupportService {
    // Configure this to your serverless function or backend endpoint
    // Expected to accept POST application/json and forward to abashelariprod@gmail.com
    static var endpointURL: String = ""
    static var apiKey: String? = nil // Optional header: Authorization: Bearer <apiKey>

    static func send(_ message: SupportMessage, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: endpointURL), !endpointURL.isEmpty else {
            completion(.failure(SupportSendError.notConfigured))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONEncoder().encode(message)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let _ = error {
                completion(.failure(SupportSendError.network))
                return
            }
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                completion(.failure(SupportSendError.badResponse))
                return
            }
            completion(.success(()))
        }.resume()
    }
}



