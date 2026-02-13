import Foundation

final class RealtimeService {
    enum Event {
        case message(APIMessage)
        case conversation(Conversation)
        case task(APITask)
        case taskStatus(TaskStatusRealtimePayload)
    }

    var onEvent: ((Event) -> Void)?
    var onConnectionChange: ((Bool) -> Void)?

    private var task: URLSessionWebSocketTask?
    private var pingTask: _Concurrency.Task<Void, Never>?
    private var reconnectTask: _Concurrency.Task<Void, Never>?
    private var isConnected = false
    private var shouldReconnect = false
    private var reconnectAttempts = 0
    private var lastToken: String?
    private var lastBaseURL: URL?

    func connect(token: String, baseURL: URL) {
        disconnect()
        shouldReconnect = true
        lastToken = token
        lastBaseURL = baseURL
        guard let wsURL = makeWebSocketURL(from: baseURL) else { return }
        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.webSocketTask(with: request)
        self.task = task
        task.resume()
        isConnected = true
        reconnectAttempts = 0
        onConnectionChange?(true)
        listen()
        startPing()
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        pingTask?.cancel()
        pingTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        shouldReconnect = false
        lastToken = nil
        lastBaseURL = nil
        if isConnected {
            isConnected = false
            onConnectionChange?(false)
        }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessageData(Data(text.utf8))
                case .data(let data):
                    self.handleMessageData(data)
                @unknown default:
                    break
                }
                self.listen()
            case .failure:
                self.scheduleReconnect()
            }
        }
    }

    private func handleMessageData(_ data: Data) {
        guard let (type, payload) = parseWSMessage(data) else { return }
        switch type {
        case "message_received", "message_sent", "message_created":
            if let apiMessage: APIMessage = decodePayload(payload) {
                onEvent?(.message(apiMessage))
            }
        case "conversation_updated":
            if let conversation: Conversation = decodePayload(payload) {
                onEvent?(.conversation(conversation))
            }
        case "task_created", "task_updated":
            if let task: APITask = decodePayload(payload) {
                onEvent?(.task(task))
            }
        case "task_status_updated":
            if let statusPayload: TaskStatusRealtimePayload = decodePayload(payload) {
                onEvent?(.taskStatus(statusPayload))
            }
        default:
            break
        }
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil else { return }
        guard shouldReconnect, let token = lastToken, let baseURL = lastBaseURL else { return }
        isConnected = false
        onConnectionChange?(false)
        let delaySeconds = min(15, 2 * (1 << min(reconnectAttempts, 3)))
        reconnectAttempts += 1
        reconnectTask = _Concurrency.Task { [weak self] in
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
            guard let self else { return }
            self.reconnectTask = nil
            self.connect(token: token, baseURL: baseURL)
        }
    }

    private func startPing() {
        pingTask?.cancel()
        pingTask = _Concurrency.Task { [weak self] in
            while let self, !_Concurrency.Task.isCancelled {
                try? await _Concurrency.Task.sleep(nanoseconds: 20_000_000_000)
                self.task?.sendPing { _ in }
            }
        }
    }

    private func makeWebSocketURL(from baseURL: URL) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = (components.scheme == "https") ? "wss" : "ws"
        components.path = "/ws"
        components.query = nil
        return components.url
    }

    private func parseWSMessage(_ data: Data) -> (String, Data)? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = object["type"] as? String else {
            return nil
        }
        let payload = object["payload"] ?? NSNull()
        guard !(payload is NSNull) else { return nil }
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        return (type, payloadData)
    }

    private func decodePayload<T: Decodable>(_ data: Data) -> T? {
        let decoder = RealtimeService.decoder
        return try? decoder.decode(T.self, from: data)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                if let date = iso8601WithFractional.date(from: string) {
                    return date
                }
                if let date = iso8601.date(from: string) {
                    return date
                }
                if let timestamp = TimeInterval(string) {
                    return Date(timeIntervalSince1970: timestamp)
                }
            }
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return decoder
    }()

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

struct TaskStatusRealtimePayload: Decodable {
    let id: String
    let status: String
}
