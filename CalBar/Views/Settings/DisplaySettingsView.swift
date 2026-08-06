import SwiftUI

struct DisplaySettingsView: View {
    @AppStorage(AppSettings.Keys.use24HourTime)          private var use24Hour: Bool = true
    @AppStorage(AppSettings.Keys.maxEventsToShow)        private var maxEvents: Int = 5
    @AppStorage(AppSettings.Keys.showDynamicMenuBarIcon) private var dynamicIcon: Bool = true
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        Form {
            Section(lm.str("display.eventList")) {
                Picker(lm.str("display.timeFormat"), selection: $use24Hour) {
                    Text(lm.str("display.24h")).tag(true)
                    Text(lm.str("display.12h")).tag(false)
                }

                LabeledContent(lm.strFormat("display.maxEvents", maxEvents)) {
                    Slider(
                        value: Binding(
                            get: { Double(maxEvents) },
                            set: { maxEvents = Int($0) }
                        ),
                        in: 3...10, step: 1
                    )
                    .frame(width: 140)
                }
            }

            Section {
                Toggle(lm.str("display.dynamicIcon"), isOn: $dynamicIcon)
            } header: {
                Text("Menu Bar")
            } footer: {
                Text(lm.str("display.dynamicIconFooter"))
            }

            Section {
                Picker(lm.str("display.language"), selection: Binding(
                    get: { lm.language },
                    set: { lm.language = $0 }
                )) {
                    Text(lm.str("display.languageSystem")).tag("system")
                    Text("English").tag("en")
                    Text("Tiếng Việt").tag("vi")
                    Text("日本語").tag("ja")
                }
                .pickerStyle(.menu)
            } header: {
                Text(lm.str("display.language"))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(lm.str("tab.display"))
    }
}
