import Foundation
import UIKit

/// Lightweight wrapper around Jira Cloud’s REST v3 API.
/// - Creates a Bug issue.
/// - Immediately uploads the annotated screenshot as an attachment.
struct JiraClient {
  let domain: String            // e.g. "acme.atlassian.net"
  let email: String             // bot or user email
  let apiToken: String          // read from Keychain / Secrets at call-site
  let projectKey: String        // e.g. "IOS"
  let issueTypeId: String = "10004"   // default = “Bug”

  // MARK: – Public API -------------------------------------------------------

  /// Returns the created issue key (e.g. "IOS-123") or throws.
  @discardableResult
  func send(image: UIImage, note: String) async throws -> String {
    let key = try await createIssue(
      summary: note.isEmpty ? "Shake feedback" : note,
      description: makeDescription(note: note))
    try await attach(image: image, to: key)
    return key
  }

  // MARK: – Private helpers ---------------------------------------------------

  /// Human-friendly issue body with device/build metadata.
  private func makeDescription(note: String) -> String {
    """
    \(note)

    ----
    • iOS \(UIDevice.current.systemVersion)
    • \(UIDevice.current.model)
    • Build \(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))
    • Locale \(Locale.current.identifier)
    """
  }

  private func createIssue(summary: String, description: String) async throws -> String {
    let url = URL(string: "https://\(domain)/rest/api/3/issue")!
    var req = URLRequest(url: url); req.httpMethod = "POST"
    auth(&req)
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")

    req.httpBody = """
    {
      "fields": {
        "project":   { "key": "\(projectKey)" },
        "issuetype": { "id": "\(issueTypeId)" },
        "summary":      "\(summary)",
        "description":  "\(description)"
      }
    }
    """.data(using: .utf8)!

    let (data, _) = try await URLSession.shared.data(for: req)
    guard let key = try? JSONDecoder().decode(IssueKey.self, from: data).key else {
      throw JiraError.badResponse
    }
    return key
  }

  private func attach(image: UIImage, to key: String) async throws {
    let url = URL(string: "https://\(domain)/rest/api/3/issue/\(key)/attachments")!
    var req = URLRequest(url: url); req.httpMethod = "POST"
    auth(&req)
    req.setValue("no-check", forHTTPHeaderField: "X-Atlassian-Token")    // Jira requirement

    // Multipart form-data body
    let boundary = UUID().uuidString
    req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.append("--\(boundary)\r\n")
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"feedback.jpg\"\r\n")
    body.append("Content-Type: image/jpeg\r\n\r\n")
    body.append(image.jpegData(compressionQuality: 0.6)!)
    body.append("\r\n--\(boundary)--\r\n")

    _ = try await URLSession.shared.upload(for: req, from: body)
  }

  private func auth(_ req: inout URLRequest) {
    let cred = "\(email):\(apiToken)".data(using: .utf8)!.base64EncodedString()
    req.setValue("Basic \(cred)", forHTTPHeaderField: "Authorization")
  }
}

// MARK: – Support types -------------------------------------------------------

private struct IssueKey: Decodable { let key: String }

enum JiraError: Error { case badResponse }

// MARK: – Bundle convenience --------------------------------------------------

private extension Bundle {
  var shortVersion: String { infoDictionary?["CFBundleShortVersionString"] as? String ?? "x.x" }
  var buildNumber:   String { infoDictionary?["CFBundleVersion"]            as? String ?? "0"   }
}