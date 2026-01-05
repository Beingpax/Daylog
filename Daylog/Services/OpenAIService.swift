//
//  OpenAIService.swift
//  Daylog
//

import Foundation

struct OpenAIService {
    private let apiKey = "" // Add your OpenAI API key here
    private let model = "gpt-5.2"

    struct ParsedLogEntry: Codable {
        let hour: Int
        let category: String
        let notes: String
        let mood: String
        let extraDetails: String

        enum CodingKeys: String, CodingKey {
            case hour
            case category
            case notes
            case mood
            case extraDetails = "extra_details"
        }
    }

    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let response_format: ResponseFormat?
    }

    struct ResponseFormat: Codable {
        let type: String
    }

    struct ChatResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: MessageContent

            struct MessageContent: Codable {
                let content: String
            }
        }
    }

    func testConnection() async throws -> Bool {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = ChatRequest(
            model: model,
            messages: [ChatMessage(role: "user", content: "Say 'ok'")],
            temperature: 0,
            response_format: nil
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    struct RecentLog {
        let hour: Int
        let category: String
        let notes: String
    }

    func parseLogInput(
        input: String,
        categories: [(name: String, group: String)],
        currentDate: Date,
        lastLoggedHour: Int?,
        currentHour: Int,
        recentLogs: [RecentLog]
    ) async throws -> [ParsedLogEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let dateString = dateFormatter.string(from: currentDate)

        let categoryList = categories.map { "\($0.name) (\($0.group))" }.joined(separator: ", ")

        let startHour: Int
        if let lastHour = lastLoggedHour {
            startHour = (lastHour + 1) % 24
        } else {
            startHour = 6 // Default start at 6 AM if no logs
        }

        // Format recent logs for context
        let recentLogsContext: String
        if recentLogs.isEmpty {
            recentLogsContext = "No recent activity logged."
        } else {
            let logStrings = recentLogs.map { log in
                "\(log.hour):00 - \(log.category): \(log.notes)"
            }
            recentLogsContext = "Recent activity (last 5 hours):\n" + logStrings.joined(separator: "\n")
        }

        let systemPrompt = """
        You are a time-logging assistant. Parse the user's natural language input into structured hour-by-hour log entries.

        ## Context
        Today's date: \(dateString)
        Current time: \(currentHour):00
        Hours to log: \(startHour):00 to \(currentHour):00

        \(recentLogsContext)

        ## Available Categories (ONLY use these exact names):
        \(categoryList)

        ## Available Moods (ONLY use these exact values):
        focused, energetic, calm, tired, stressed, happy

        ## Rules
        1. Each entry represents ONE hour block (hour 9 = 9:00-10:00)
        2. ONLY create entries for hours between \(startHour):00 and \(currentHour):00
        3. Map activities to the EXACT category name from the list above
        4. If user mentions a time range (e.g., "9 to 12"), create separate entries for hours 9, 10, 11
        5. Infer mood based on activity description
        6. Keep notes concise (under 50 chars)
        7. If user says "worked all morning", expand to hours \(startHour)-12
        8. If user doesn't specify times, distribute activities logically across available hours

        ## Output Format
        Respond with a JSON object containing an "entries" array:
        {"entries": [{"hour": 9, "category": "Deep Work", "notes": "Worked on project", "mood": "focused", "extra_details": ""}]}
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = ChatRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: input)
            ],
            temperature: 0.3,
            response_format: ResponseFormat(type: "json_object")
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorBody = String(data: data, encoding: .utf8) {
                throw OpenAIError.apiError(errorBody)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }

        // Parse the response JSON
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidJSON
        }

        // Try parsing as wrapped object first (expected format)
        struct WrappedResponse: Codable {
            let entries: [ParsedLogEntry]?
            let logs: [ParsedLogEntry]?
            let data: [ParsedLogEntry]?
        }

        if let wrapped = try? JSONDecoder().decode(WrappedResponse.self, from: jsonData) {
            if let entries = wrapped.entries ?? wrapped.logs ?? wrapped.data {
                return entries
            }
        }

        // Fallback: try parsing as array directly
        if let entries = try? JSONDecoder().decode([ParsedLogEntry].self, from: jsonData) {
            return entries
        }

        throw OpenAIError.invalidJSON
    }
}

enum OpenAIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noContent:
            return "No content in response."
        case .invalidJSON:
            return "Failed to parse response."
        }
    }
}
