import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                    Text("CalBar")
                        .font(.largeTitle).bold()
                    Text(lm.str("about.subtitle"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section(lm.str("about.info")) {
                LabeledContent(lm.str("about.version"), value: "1.0.0")
                LabeledContent(lm.str("about.requirements"), value: lm.str("about.macosReq"))
                LabeledContent("Framework", value: "SwiftUI · AuthenticationServices · CryptoKit")
            }

            Section(lm.str("about.integration")) {
                LabeledContent("API", value: "Google Calendar REST v3")
                LabeledContent("Auth", value: "OAuth 2.0 + PKCE")
                LabeledContent(lm.str("about.tokenStorage"), value: lm.str("about.keychain"))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(lm.str("tab.about"))
    }
}
