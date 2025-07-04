import UIKit
import Foundation

actor JiraClient {
    private let jiraDomain: String
    private let email: String
    private let apiToken: String
    private let projectKey: String
    private let issueTypeId: String
    
    init(jiraDomain: String, email: String, apiToken: String, projectKey: String, issueTypeId: String) {
        self.jiraDomain = jiraDomain
        self.email = email
        self.apiToken = apiToken
        self.projectKey = projectKey
        self.issueTypeId = issueTypeId
    }
    
    func send(image: UIImage, note: String) async throws -> String {
        let issueKey = try await createIssue(note: note)
        try await attach(image: image, to: issueKey)
        return issueKey
    }
    
    private func createIssue(note: String) async throws -> String {
        let url = URL(string: "https://\(jiraDomain)/rest/api/3/issue")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(basicAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let deviceInfo = await buildDeviceMetadata()
        let payload: [String: Any] = [
            "fields": [
                "project": ["key": projectKey],
                "summary": "Shake feedback: \(note.prefix(50))",
                "description": [
                    "type": "doc", "version": 1,
                    "content": [["type": "paragraph", "content": [["type": "text", "text": "\(note)\n\n---\nDevice Information:\n\(deviceInfo)"]]]]
                ],
                "issuetype": ["id": issueTypeId]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw JiraError.createIssueFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let key = json?["key"] as? String else { throw JiraError.invalidResponse }
        return key
    }
    
    private func attach(image: UIImage, to issueKey: String) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw JiraError.imageConversionFailed
        }
        
        let url = URL(string: "https://\(jiraDomain)/rest/api/3/issue/\(issueKey)/attachments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(basicAuthHeader(), forHTTPHeaderField: "Authorization")
        request.setValue("nocheck", forHTTPHeaderField: "X-Atlassian-Token")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: body)
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw JiraError.attachmentFailed
        }
    }
    
    private func basicAuthHeader() -> String {
        "Basic \(Data("\(email):\(apiToken)".utf8).base64EncodedString())"
    }
    
    private func buildDeviceMetadata() async -> String {
        await MainActor.run {
            let device = UIDevice.current
            let bundle = Bundle.main
            return "Model: \(device.model)\nSystem: \(device.systemName) \(device.systemVersion)\nApp Version: \(bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\nBuild: \(bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")"
        }
    }
}

enum JiraError: Error {
    case createIssueFailed
    case attachmentFailed
    case imageConversionFailed
    case invalidResponse
}
