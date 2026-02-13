import Foundation
import UniformTypeIdentifiers

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct APIErrorResponse: Decodable {
    let error: String
}

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

struct PaginatedResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let pagination: Pagination?
}

extension PaginatedResponse where T: RangeReplaceableCollection {
    var items: T { data ?? T() }
}

struct Pagination: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

private struct EmptyDecodable: Decodable {}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

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

    var token: String? {
        didSet {
            if let token = token {
                UserDefaults.standard.set(token, forKey: "authToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        }
    }

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                if let date = APIClient.iso8601WithFractional.date(from: string) {
                    return date
                }
                if let date = APIClient.iso8601.date(from: string) {
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
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    var baseURL: URL {
        if let stored = UserDefaults.standard.string(forKey: "apiBaseURL"),
           let url = URL(string: stored) {
            return url
        }
        return URL(string: "http://localhost:8080/api/v1")!
    }

    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        query: [URLQueryItem] = []
    ) async throws -> T {
        return try await request(path, method: method, body: Optional<EmptyBody>.none, query: query)
    }

    func request<T: Decodable, Body: Encodable>(
        _ path: String,
        method: HTTPMethod,
        body: Body? = nil,
        query: [URLQueryItem] = []
    ) async throws -> T {
        let url = makeURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(message: "Invalid server response")
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError(message: errorResponse.error)
            }
            if let apiResponse = try? decoder.decode(APIResponse<EmptyDecodable>.self, from: data),
               let message = apiResponse.error {
                throw APIError(message: message)
            }
            throw APIError(message: "Request failed (\(httpResponse.statusCode))")
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError(message: errorResponse.error)
            }
            if let apiResponse = try? decoder.decode(APIResponse<EmptyDecodable>.self, from: data),
               let message = apiResponse.error {
                throw APIError(message: message)
            }
            throw error
        }
    }

    func uploadMultipart<T: Decodable>(
        _ path: String,
        fileURL: URL,
        fieldName: String = "file",
        query: [URLQueryItem] = []
    ) async throws -> T {
        let url = makeURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        let mimeType = Self.mimeType(for: fileURL)

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(message: "Invalid server response")
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError(message: errorResponse.error)
            }
            if let apiResponse = try? decoder.decode(APIResponse<EmptyDecodable>.self, from: data),
               let message = apiResponse.error {
                throw APIError(message: message)
            }
            throw APIError(message: "Upload failed (\(httpResponse.statusCode))")
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError(message: errorResponse.error)
            }
            if let apiResponse = try? decoder.decode(APIResponse<EmptyDecodable>.self, from: data),
               let message = apiResponse.error {
                throw APIError(message: message)
            }
            throw error
        }
    }

    private func makeURL(path: String, query: [URLQueryItem]) -> URL {
        let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var url = baseURL.appendingPathComponent(sanitizedPath)
        guard !query.isEmpty else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = query
        if let updated = components?.url {
            url = updated
        }
        return url
    }

    private static func mimeType(for fileURL: URL) -> String {
        let ext = fileURL.pathExtension
        if !ext.isEmpty,
           let type = UTType(filenameExtension: ext),
           let mime = type.preferredMIMEType {
            return mime
        }
        return "application/octet-stream"
    }
}

struct EmptyResponse: Decodable {}
struct EmptyBody: Encodable {}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
