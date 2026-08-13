import SwiftUI

struct NewEventView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @FocusState private var titleFocused: Bool

    @State private var title = ""
    @State private var startDate: Date = Self.nextSlot()
    @State private var durationMinutes = 30

    private let durations: [(label: String, minutes: Int)] = [
        ("15 min", 15), ("30 min", 30), ("45 min", 45),
        ("1 hour", 60), ("1.5 hours", 90), ("2 hours", 120)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3).padding(.vertical, 10)
            form
            Spacer()
            createButton
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
                Text("Cancel")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("New Event")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Balance spacer
            Text("Cancel")
                .font(.system(size: 12))
                .hidden()
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 14) {
            // Title
            TextField("Event title", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.primary.opacity(0.06))
                )
                .focused($titleFocused)
                .onSubmit { if canCreate { create() } }

            // When
            row(icon: "calendar", label: "When") {
                DatePicker("", selection: $startDate)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            // Duration
            row(icon: "clock", label: "Duration") {
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
                Text("Ends \(endTimeString)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            // Error banner
            if let error = viewModel.createEventError {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                        .lineLimit(2)
                }
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.08))
                )
            }
        }
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
                Text(viewModel.isCreatingEvent ? "Creating…" : "Create Event")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canCreate)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func row<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            content()
        }
    }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.isCreatingEvent
    }

    private var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    private var endTimeString: String {
        let f = DateFormatter()
        f.dateFormat = AppSettings.use24HourTime ? "HH:mm" : "h:mm a"
        return f.string(from: endDate)
    }

    private func create() {
        Task {
            await viewModel.createNewEvent(
                title: title.trimmingCharacters(in: .whitespaces),
                start: startDate,
                end: endDate
            )
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewModel.showNewEvent = false
        }
    }

    // Round to the next 30-minute slot
    private static func nextSlot() -> Date {
        let now = Date()
        let cal = Calendar.current
        let mins = cal.component(.minute, from: now)
        let addMins = mins % 30 == 0 ? 30 : (30 - mins % 30)
        return cal.date(byAdding: .minute, value: addMins, to: now) ?? now
    }
}
