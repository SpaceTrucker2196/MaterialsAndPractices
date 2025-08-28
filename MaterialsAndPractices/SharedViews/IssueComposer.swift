//
//  IssueComposer.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 8/28/25.
//

import SwiftUI

struct IssueComposerView: View {
    // Persist the token locally (keychain is recommended in production)
    @AppStorage("github.pat") private var token: String = ""

    // Basic issue fields
    @State private var owner: String = ""
    @State private var repo: String = ""
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    @State private var labelsCSV: String = ""  // comma‑separated
    @State private var assigneesCSV: String = "" // comma‑separated

    // UI state
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var createdIssueURL: URL? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("GitHub Auth")) {
                    SecureField("Fine‑grained PAT (Issues: Read & Write)", text: $token)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("Repository")) {
                    TextField("Owner (e.g., apple)", text: $owner)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Repo (e.g., swift)", text: $repo)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Issue")) {
                    TextField("Title", text: $titleText)
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.body.monospaced())
                        .accessibilityLabel("Issue body (Markdown supported)")
                }

                Section(header: Text("Optional Metadata")) {
                    TextField("Labels (comma‑separated)", text: $labelsCSV)
                        .textInputAutocapitalization(.never)
                    TextField("Assignees (comma‑separated)", text: $assigneesCSV)
                        .textInputAutocapitalization(.never)
                }

                if let url = createdIssueURL {
                    Section(header: Text("Created")) {
                        Link(destination: url) {
                            Label(url.absoluteString, systemImage: "link")
                                .lineLimit(1)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New GitHub Issue")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(isSubmitDisabled)
                }
            }
        }
    }

    private var isSubmitDisabled: Bool {
        isSubmitting || token.isEmpty || owner.isEmpty || repo.isEmpty || titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        errorMessage = nil
        createdIssueURL = nil
        isSubmitting = true

        Task {
            do {
                let client = GitHubClient(token: token)
                let labels = labelsCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let assignees = assigneesCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

                let response = try await client.createIssue(owner: owner, repo: repo, title: titleText, body: bodyText, labels: labels, assignees: assignees)
                await MainActor.run {
                    createdIssueURL = response.html_url
                    isSubmitting = false
                    // Reset minimal fields for quick entry; keep repo/owner for batch filing
                    titleText = ""
                    bodyText = ""
                    labelsCSV = ""
                    assigneesCSV = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - GitHub API Client

struct CreatedIssueResponse: Decodable {
    let html_url: URL
    let number: Int
    let title: String
}

struct GitHubErrorResponse: Decodable, Error { let message: String }

final class GitHubClient {
    private let token: String
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    init(token: String) { self.token = token }

    /// Create an issue via REST v3: POST /repos/{owner}/{repo}/issues
    func createIssue(owner: String, repo: String, title: String, body: String?, labels: [String], assignees: [String]) async throws -> CreatedIssueResponse {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues")!)
        request.httpMethod = "POST"
        request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        struct Payload: Encodable { let title: String; let body: String?; let labels: [String]; let assignees: [String] }
        let payload = Payload(title: title, body: body, labels: labels, assignees: assignees)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

        switch http.statusCode {
        case 200, 201:
            return try decoder.decode(CreatedIssueResponse.self, from: data)
        default:
            // Try to surface a helpful GitHub message
            if let apiErr = try? decoder.decode(GitHubErrorResponse.self, from: data) {
                throw NSError(domain: "GitHub", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "GitHub: \(apiErr.message)"])
            }
            throw NSError(domain: "GitHub", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
    }
}

// MARK: - Preview

#Preview {
    IssueComposerView()
}
