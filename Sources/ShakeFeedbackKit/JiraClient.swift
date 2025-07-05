import UIKit
import Foundation

actor JiraClient {
    private let jiraDomain: String
    private let email: String
    private let apiToken: String
    private let projectKey: String
    private var issueTypeId: String
    
    // Cache for project metadata to avoid repeated API calls
    private var projectId: String? = nil
    private var validIssueTypes: [String: String] = [:] // name -> id mapping
    
    init(jiraDomain: String, email: String, apiToken: String, projectKey: String, issueTypeId: String) {
        self.jiraDomain = jiraDomain
        self.email = email
        self.apiToken = apiToken
        self.projectKey = projectKey
        self.issueTypeId = issueTypeId
    }
    
    func send(image: UIImage, note: String) async throws -> String {
        // Ensure we have valid project data before creating an issue
        try await fetchProjectMetadata()
        
        // Use the most appropriate issue type if available
        if let bugId = validIssueTypes["Bug"] ?? validIssueTypes["bug"] {
            self.issueTypeId = bugId
            print("ShakeFeedbackKit: Using Bug issue type with ID: \(bugId)")
        } else if let taskId = validIssueTypes["Task"] ?? validIssueTypes["task"] {
            self.issueTypeId = taskId
            print("ShakeFeedbackKit: Using Task issue type with ID: \(taskId)")
        } else if let storyId = validIssueTypes["Story"] ?? validIssueTypes["story"] {
            self.issueTypeId = storyId
            print("ShakeFeedbackKit: Using Story issue type with ID: \(storyId)")
        } else if !validIssueTypes.isEmpty {
            // Use the first available issue type if no preferred ones are found
            let firstType = validIssueTypes.first!
            self.issueTypeId = firstType.value
            print("ShakeFeedbackKit: Using \(firstType.key) issue type with ID: \(firstType.value)")
        } else {
            print("ShakeFeedbackKit: No valid issue types found, using provided ID: \(issueTypeId)")
        }
        
        let issueKey = try await createIssue(note: note)
        try await attach(image: image, to: issueKey)
        return issueKey
    }
    
    private func createIssue(note: String) async throws -> String {
        // Print debug information
        print("ShakeFeedbackKit: Creating Jira issue with domain: \(jiraDomain)")
        print("ShakeFeedbackKit: Project key: \(projectKey), Issue Type ID: \(issueTypeId)")
        
        // Format the URL properly
        let urlString = "https://\(jiraDomain)/rest/api/3/issue"
        guard let url = URL(string: urlString) else {
            print("ShakeFeedbackKit: Invalid URL: \(urlString)")
            throw JiraError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(basicAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let deviceMetadata = await buildDeviceMetadata()
        
        // Format the date in a readable format
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateStr = dateFormatter.string(from: Date())
        
        // Get unique report ID
        let reportId = UUID().uuidString.prefix(8)
        
        // Format description as markdown instead of ADF
        let reportIdString = String(reportId)
        
        // Extract OS version for summary
        let osVersion = (deviceMetadata["System"] ?? "Unknown").components(separatedBy: " ").last ?? "Unknown"
        
        // Extract app details needed for the template
        let appName = deviceMetadata["App Name"] ?? "Unknown"
        let appVersion = deviceMetadata["App Version"] ?? "Unknown"
        let buildNumber = deviceMetadata["Build"] ?? "Unknown"
        
        // Extract additional device details needed for the template
        let deviceModel = deviceMetadata["Device Model"] ?? "Unknown"
        let batteryStatus = await getBatteryStatus()
        let freeMemory = await getSystemFreeMemory()
        let freeDisk = await getFreeDiskSpace()
        let localeName = Locale.current.identifier
        let timeZone = TimeZone.current.identifier.replacingOccurrences(of: "_", with: "/")
        let uptimeMinutes = Int(ProcessInfo.processInfo.systemUptime / 60)
        
        // Format date in UTC
        let utcDateFormatter = DateFormatter()
        utcDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        utcDateFormatter.dateFormat = "dd MMM yyyy HH:mm"
        let utcDateStr = utcDateFormatter.string(from: Date()) + " UTC"
        
        // Create ADF structure for the description that matches the user's new template
        var contentArray: [[String: Any]] = []
        
        // Header line with date
        contentArray.append([
            "type": "paragraph",
            "content": [
                ["type": "text", "text": "Feedback submitted via shake feedback   |   \(utcDateStr)"]
            ]
        ])
        
        // Separator (blank line)
        contentArray.append([
            "type": "paragraph",
            "content": [["type": "text", "text": ""]]
        ])
        
        // User note section
        contentArray.append([
            "type": "paragraph",
            "content": [
                ["type": "text", "text": "User note", "marks": [["type": "strong"]]]
            ]
        ])
        
        // User note content
        contentArray.append([
            "type": "paragraph",
            "content": [[
                "type": "text", 
                "text": note.isEmpty ? "No comment provided." : note
            ]]
        ])
        
        // Separator (blank line)
        contentArray.append([
            "type": "paragraph",
            "content": [["type": "text", "text": ""]]
        ])
        
        // Device snapshot heading
        contentArray.append([
            "type": "paragraph",
            "content": [
                ["type": "text", "text": "Device snapshot", "marks": [["type": "strong"]]]
            ]
        ])
        
        // Device info as separate paragraphs with formatting preserved
        contentArray.append(["type": "paragraph", "content": [["type": "text", "text": "Model | \(deviceModel)"]]])
        contentArray.append(["type": "paragraph", "content": [["type": "text", "text": "iOS  | \(osVersion)"]]])
        contentArray.append(["type": "paragraph", "content": [["type": "text", "text": "Battery | \(batteryStatus)"]]])
        contentArray.append(["type": "paragraph", "content": [["type": "text", "text": "Disk free | \(freeDisk)"]]])
        contentArray.append(["type": "paragraph", "content": [["type": "text", "text": "Locale | \(localeName) · TZ \(timeZone)"]]])
        
        // Separator (blank line)
        contentArray.append([
            "type": "paragraph",
            "content": [["type": "text", "text": ""]]
        ])
        
        // No text about attachments - they will appear naturally in Jira
        
        // Create the complete ADF document structure
        let description: [String: Any] = [
            "type": "doc",
            "version": 1,
            "content": contentArray
        ]
        
        // Create summary based on new template: "Shake feedback – [user note] (iOS [version] · build [build])"
        
        // Extract user note for summary
        let shortUserNote = note.isEmpty ? "feedback" : 
                         (note.count <= 40 ? note : 
                         String(note.prefix(37).appending("...")))
        
        // Format summary according to new template - without "Shake feedback"
        let summary = "\(shortUserNote) (iOS \(osVersion) · build \(buildNumber))"
        
        // Jira Cloud API requires the description field to be in Atlassian Document Format (ADF)
        let payload: [String: Any] = [
            "fields": [
                "project": ["key": projectKey],
                "summary": summary,
                "description": description,  // Using ADF structure
                "issuetype": ["id": issueTypeId],
                // Add labels for easier filtering
                "labels": ["shake-feedback", "mobile-app", "ios"]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            // Print the entire request for debugging
            print("ShakeFeedbackKit: Sending request to Jira API...")
            print("ShakeFeedbackKit: URL: \(url.absoluteString)")
            
            // Print the request payload for debugging
            if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                print("ShakeFeedbackKit: Request payload: \(jsonString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ShakeFeedbackKit: Invalid HTTP response")
                throw JiraError.invalidResponse
            }
            
            print("ShakeFeedbackKit: Response status code: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                // Print the raw response for complete debugging
                let responseText = String(data: data, encoding: .utf8) ?? "<unable to decode response>"
                print("ShakeFeedbackKit: Complete Jira error response: \(responseText)")
                
                // Try to extract structured error details if available
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Handle multiple error message formats from Jira API
                    if let errorMessages = errorJson["errorMessages"] as? [String], !errorMessages.isEmpty {
                        print("ShakeFeedbackKit: Jira API errors: \(errorMessages.joined(separator: ", "))")
                    } else if let errors = errorJson["errors"] as? [String: String], !errors.isEmpty {
                        let errorList = errors.map { key, value in "\(key): \(value)" }.joined(separator: ", ")
                        print("ShakeFeedbackKit: Jira API field errors: \(errorList)")
                    } else if let message = errorJson["message"] as? String {
                        print("ShakeFeedbackKit: Jira API message: \(message)")
                    } else {
                        print("ShakeFeedbackKit: Jira returned error status \(httpResponse.statusCode) with unrecognized error format")
                    }
                    
                    // Print the full JSON structure for debugging
                    print("ShakeFeedbackKit: Full error JSON structure: \(errorJson)")
                }
                
                throw JiraError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let key = json?["key"] as? String else { 
                print("ShakeFeedbackKit: Invalid response format - missing key")
                throw JiraError.invalidResponse 
            }
            return key
        } catch JiraError.httpError(let statusCode) {
            print("ShakeFeedbackKit: HTTP error with status code \(statusCode)")
            throw JiraError.createIssueFailed
        } catch {
            print("ShakeFeedbackKit: Error creating issue - \(error)")
            throw JiraError.createIssueFailed
        }
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
        let authString = "\(email):\(apiToken)"
        let encodedString = Data(authString.utf8).base64EncodedString()
        let header = "Basic \(encodedString)"
        print("ShakeFeedbackKit: Auth header created for email: \(email) (token hidden)")
        return header
    }
    
    private func buildDeviceMetadata() async -> [String: String] {
        await MainActor.run {
            let device = UIDevice.current
            let bundle = Bundle.main
            let processInfo = ProcessInfo.processInfo
            
            var metadata: [String: String] = [:]
            metadata["Device Model"] = device.model
            metadata["System"] = "\(device.systemName) \(device.systemVersion)"
            metadata["App Version"] = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            metadata["Build"] = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            metadata["App Name"] = bundle.infoDictionary?["CFBundleName"] as? String ?? "Unknown"
            metadata["Device Name"] = device.name
            metadata["Memory"] = "\(Int(processInfo.physicalMemory / 1024 / 1024)) MB"
            metadata["Processor Count"] = "\(processInfo.processorCount)"
            
            return metadata
        }
    }
    
    private func getNetworkStatus() async -> String {
        // Simplified network status - in a real app, you would implement full network monitoring
        return "Unknown" // Would normally return WiFi/Cellular/None
    }
    
    private func getBatteryStatus() async -> String {
        return await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel
            let state = UIDevice.current.batteryState
            
            let levelString = level < 0 ? "Unknown" : "\(Int(level * 100)) %"
            
            var stateString = "unknown"
            switch state {
            case .charging: stateString = "charging"
            case .full: stateString = "full"
            case .unplugged: stateString = "unplugged"
            case .unknown: stateString = "unknown"
            @unknown default: stateString = "unknown"
            }
            
            return "\(levelString) – \(stateString)"
        }
    }
    
    private func getFreeDiskSpace() async -> String {
        let fileManager = FileManager.default
        if let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path,
           let attrs = try? fileManager.attributesOfFileSystem(forPath: path),
           let freeSpace = attrs[.systemFreeSize] as? NSNumber {
            let bytes = freeSpace.int64Value
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }
        return "Unknown"
    }
    
    private func getTotalDiskSpace() async -> String {
        let fileManager = FileManager.default
        if let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path,
           let attrs = try? fileManager.attributesOfFileSystem(forPath: path),
           let totalSpace = attrs[.systemSize] as? NSNumber {
            let bytes = totalSpace.int64Value
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }
        return "Unknown"
    }
    
    private func getDeviceOrientation() async -> String {
        return await MainActor.run {
            switch UIDevice.current.orientation {
            case .portrait: return "Portrait"
            case .portraitUpsideDown: return "Portrait Upside Down"
            case .landscapeLeft: return "Landscape Left"
            case .landscapeRight: return "Landscape Right"
            case .faceUp: return "Face Up"
            case .faceDown: return "Face Down"
            case .unknown: return "Unknown"
            @unknown default: return "Unknown"
            }
        }
    }
    
    private func getSystemFreeMemory() async -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .file
        
        // This is an approximation as getting true free memory is complex on iOS
        let freeMemoryBytes = Int64(ProcessInfo.processInfo.physicalMemory) / 8  // Rough approximation
        return formatter.string(fromByteCount: freeMemoryBytes)
    }
    
    private func fetchProjectMetadata() async throws {
        // Skip fetching if we already have issue type data
        if !validIssueTypes.isEmpty {
            return
        }
        
        print("ShakeFeedbackKit: Fetching project metadata from Jira...")
        
        // 1. First get the project ID from project key
        let projectURL = URL(string: "https://\(jiraDomain)/rest/api/3/project/\(projectKey)")!
        var request = URLRequest(url: projectURL)
        request.setValue(basicAuthHeader(), forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200, httpResponse.statusCode < 300 else {
                print("ShakeFeedbackKit: Failed to get project data. Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("ShakeFeedbackKit: Error response: \(errorText)")
                }
                throw JiraError.projectMetadataFailed
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = json["id"] as? String else {
                print("ShakeFeedbackKit: Could not extract project ID from response")
                throw JiraError.invalidResponse
            }
            
            self.projectId = id
            print("ShakeFeedbackKit: Found project ID: \(id)")
            
            // 2. Now fetch issue types for this project
            let metaURL = URL(string: "https://\(jiraDomain)/rest/api/3/issue/createmeta?projectIds=\(id)&expand=projects.issuetypes")!
            var metaRequest = URLRequest(url: metaURL)
            metaRequest.setValue(basicAuthHeader(), forHTTPHeaderField: "Authorization")
            
            let (metaData, metaResponse) = try await URLSession.shared.data(for: metaRequest)
            guard let metaHttpResponse = metaResponse as? HTTPURLResponse, metaHttpResponse.statusCode >= 200, metaHttpResponse.statusCode < 300 else {
                print("ShakeFeedbackKit: Failed to get project metadata. Status: \((metaResponse as? HTTPURLResponse)?.statusCode ?? 0)")
                if let errorText = String(data: metaData, encoding: .utf8) {
                    print("ShakeFeedbackKit: Error response: \(errorText)")
                }
                throw JiraError.projectMetadataFailed
            }
            
            // Parse issue types
            guard let metaJson = try JSONSerialization.jsonObject(with: metaData) as? [String: Any],
                  let projects = metaJson["projects"] as? [[String: Any]],
                  projects.count > 0 else {
                print("ShakeFeedbackKit: No projects found in metadata response")
                throw JiraError.invalidResponse
            }
            
            guard let issueTypes = projects[0]["issuetypes"] as? [[String: Any]] else {
                print("ShakeFeedbackKit: No issue types found for project")
                throw JiraError.noValidIssueTypes
            }
            
            // Map issue type names to IDs
            for issueType in issueTypes {
                if let name = issueType["name"] as? String,
                   let id = issueType["id"] as? String {
                    validIssueTypes[name] = id
                }
            }
            
            if validIssueTypes.isEmpty {
                print("ShakeFeedbackKit: No valid issue types found")
                throw JiraError.noValidIssueTypes
            }
            
            print("ShakeFeedbackKit: Found \(validIssueTypes.count) issue types: \(validIssueTypes.keys.joined(separator: ", "))")
            
        } catch let error as JiraError {
            throw error
        } catch {
            print("ShakeFeedbackKit: Error fetching project metadata: \(error)")
            throw JiraError.projectMetadataFailed
        }
    }
}

enum JiraError: Error {
    case createIssueFailed
    case attachmentFailed
    case imageConversionFailed
    case invalidResponse
    case invalidURL
    case httpError(statusCode: Int)
    case projectMetadataFailed
    case noValidIssueTypes
}
