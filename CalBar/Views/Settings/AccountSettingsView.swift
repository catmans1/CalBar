import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager
    @AppStorage(AppSettings.Keys.oauthClientID) private var clientID: String = ""
    @State private var testStatus: TestStatus = .idle

    var body: some View {
        Form {
            Section(lm.str("account.google")) {
                if viewModel.auth.isAuthenticated {
                    accountRow
                    Button(lm.str("sign.out")) { viewModel.signOut() }
                        .foregroundStyle(.red)
                } else {
                    Button(lm.str("signin.button")) {
                        Task { await viewModel.signIn(contextProvider: WindowContextProvider.shared) }
                    }
                    .disabled(viewModel.isLoading)
                }
            }

            Section {
                LabeledContent("Client ID") {
                    TextField("xxxxxx.apps.googleusercontent.com", text: $clientID)
                        .font(.system(size: 11, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: clientID) { _, _ in testStatus = .idle }
                }

                HStack(spacing: 10) {
                    Button(lm.str("account.testConn")) {
                        Task { await testConnection() }
                    }
                    .disabled(testStatus == .loading || !viewModel.auth.isAuthenticated)

                    testStatusView
                }
            } header: {
                Text(lm.str("account.oauthConfig"))
            } footer: {
                Text(lm.str("account.oauthFooter"))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(lm.str("tab.account"))
    }

    // MARK: - Subviews

    private var accountRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.blue)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(viewModel.auth.userEmail?.prefix(1) ?? "?").uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.auth.userEmail?.components(separatedBy: "@").first ?? "")
                    .fontWeight(.medium)
                Text(viewModel.auth.userEmail ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(lm.str("account.connected"))
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private var testStatusView: some View {
        switch testStatus {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView().scaleEffect(0.7)
        case .success:
            Label(lm.str("success"), systemImage: "checkmark.circle.fill")
                .font(.caption).foregroundStyle(.green)
        case .failure(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .font(.caption).foregroundStyle(.red)
                .lineLimit(1)
        }
    }

    // MARK: - Actions

    private func testConnection() async {
        testStatus = .loading
        do {
            let token = try await AuthManager.shared.validAccessToken()
            var req = URLRequest(url: URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary")!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: req)
            testStatus = (response as? HTTPURLResponse)?.statusCode == 200 ? .success : .failure(lm.str("error.http"))
        } catch {
            testStatus = .failure(error.localizedDescription)
        }
    }
}

// MARK: - TestStatus

enum TestStatus: Equatable {
    case idle, loading, success, failure(String)
}
