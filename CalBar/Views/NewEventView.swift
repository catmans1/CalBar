import SwiftUI

struct NewEventView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager
    @FocusState private var titleFocused: Bool

    // Required fields
    @State private var title = ""
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Self.nextSlot())
    @State private var startTime: Date = Self.nextSlot()
    @State private var durationMinutes = 30
    @State private var isAllDay = false

    // Optional fields
    @State private var location = ""
    @State private var notes = ""
    @State private var addGoogleMeet = false

    private var durations: [(label: String, minutes: Int)] {
        [
            (lm.str("duration.15m"), 15),
            (lm.str("duration.30m"), 30),
            (lm.str("duration.45m"), 45),
            (lm.str("duration.1h"), 60),
            (lm.str("duration.1_5h"), 90),
            (lm.str("duration.2h"), 120)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3).padding(.vertical, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    requiredSection
                    optionalSection
                    if let error = viewModel.createEventError {
                        errorBanner(error)
                            .padding(.top, 8)
                    }
                    Spacer(minLength: 8)
                }
            }

            createButton
                .padding(.top, 10)
        }
        .padding(14)
        .frame(width: 340, height: 420)
        .background(.ultraThinMaterial)
        .onAppear {
            viewModel.createEventError = nil
            titleFocused = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: dismiss) {
                Text(lm.str("newEvent.cancel"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(lm.str("newEvent.title"))
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Text(lm.str("newEvent.cancel")).font(.system(size: 12)).hidden()
        }
    }

    // MARK: - Required Section

    private var requiredSection: some View {
        VStack(spacing: 11) {
            // Title
            TextField(lm.str("newEvent.titlePlaceholder"), text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.primary.opacity(0.06))
                )
                .focused($titleFocused)
                .onSubmit { if canCreate { create() } }

            // All-day toggle
            formRow(icon: "sun.max", label: lm.str("newEvent.allDay")) {
                Toggle("", isOn: $isAllDay.animation(.easeInOut(duration: 0.18)))
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Date
            formRow(icon: "calendar", label: lm.str("newEvent.date")) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Start time — hidden when all-day
            if !isAllDay {
                formRow(icon: "clock", label: lm.str("newEvent.start")) {
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Duration
                formRow(icon: "timer", label: lm.str("newEvent.duration")) {
                    Picker("", selection: $durationMinutes) {
                        ForEach(durations, id: \.minutes) { d in
                            Text(d.label).tag(d.minutes)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // End time preview
                HStack {
                    Spacer()
                    Text(lm.strFormatStr("newEvent.endsAt", endTimeString))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, -4)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Optional Section

    private var optionalSection: some View {
        VStack(spacing: 11) {
            // Section divider
            HStack(spacing: 8) {
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 0.5)
                Text(lm.str("newEvent.optional"))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 0.5)
            }
            .padding(.bottom, 2)

            // Location
            formRow(icon: "mappin.circle", label: lm.str("newEvent.location")) {
                TextField(lm.str("newEvent.locationPlaceholder"), text: $location)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }

            Divider().opacity(0.2)

            // Notes — multiline
            formRow(icon: "text.alignleft", label: lm.str("newEvent.notes"), alignment: .top) {
                TextField(lm.str("newEvent.notesPlaceholder"), text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .lineLimit(3)
            }

            Divider().opacity(0.2)

            // Google Meet
            formRow(icon: "video", label: lm.str("newEvent.googleMeet")) {
                Toggle("", isOn: $addGoogleMeet)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if addGoogleMeet {
                Text(lm.str("newEvent.meetNote"))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 86)
                    .padding(.top, -6)
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).lineLimit(2)
        }
        .font(.system(size: 11))
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.08)))
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button(action: create) {
            HStack(spacing: 6) {
                if viewModel.isCreatingEvent {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "calendar.badge.plus")
                }
                Text(viewModel.isCreatingEvent ? lm.str("newEvent.creating") : lm.str("newEvent.create"))
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canCreate)
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func formRow<Content: View>(
        icon: String, label: String,
        alignment: VerticalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: alignment, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)
            content()
        }
    }

    // MARK: - Computed Properties

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.isCreatingEvent
    }

    private var combinedStart: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: startTime)
        return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0,
                        second: 0, of: selectedDate) ?? selectedDate
    }

    private var combinedEnd: Date {
        combinedStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    private var endTimeString: String {
        let f = AppSettings.use24HourTime ? DateFormatters.time24 : DateFormatters.time12
        return f.string(from: combinedEnd)
    }

    // MARK: - Actions

    private func create() {
        let cal = Calendar.current
        let start: Date
        let end: Date

        if isAllDay {
            start = cal.startOfDay(for: selectedDate)
            end   = cal.date(byAdding: .day, value: 1, to: start) ?? start
        } else {
            start = combinedStart
            end   = combinedEnd
        }

        var request = NewEventRequest(summary: title.trimmingCharacters(in: .whitespaces),
                                      start: start, end: end)
        request.location      = location
        request.notes         = notes
        request.isAllDay      = isAllDay
        request.addGoogleMeet = addGoogleMeet

        Task { await viewModel.createNewEvent(request) }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewModel.showNewEvent = false
        }
    }

    private static func nextSlot() -> Date {
        let now = Date()
        let cal = Calendar.current
        let mins = cal.component(.minute, from: now)
        let add  = mins % 30 == 0 ? 30 : (30 - mins % 30)
        return cal.date(byAdding: .minute, value: add, to: now) ?? now
    }
}
