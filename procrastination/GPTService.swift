//
//  GPTService.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/13.
//

import Foundation

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

final class GPTService {
    private let apiKey = "YOUR_OPENAI_API_KEY" // ← 換成你的 key
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func sendMessage(_ text: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini", // 或 "gpt-4-turbo"
            "messages": [
                ["role": "system", "content": "You are a helpful and empathetic mood journaling assistant."],
                ["role": "user", "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(GPTResponse.self, from: data)
        return decoded.choices.first?.message.content ?? "No response."
    }
}
