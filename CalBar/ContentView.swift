import SwiftUI
import AppKit
import AuthenticationServices

struct ContentView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider().opacity(0.3).padding(.bottom, 10)

            if !viewModel.auth.isAuthenticated {
                SignInView()
            } else {
                mainContent
                    .frame(maxHeight: .infinity)
            }

            FooterView(
                onOffsetChange: { viewModel.rescheduleNotifications(offsetMinutes: $0) },
                onSync: { Task { await viewModel.sync() } },
                onSignOut: { viewModel.signOut() },
                onImport: { viewModel.importICSFile() }
            )
        }
        .padding(14)
        .frame(width: 340, height: 420)
        .background(.ultraThinMaterial)
        .environmentObject(viewModel)
        .onAppear {
            if viewModel.auth.isAuthenticated && viewModel.events.isEmpty {
                Task { await viewModel.sync() }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            if viewModel.importState != .idle {
                ImportBanner(state: viewModel.importState)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            innerContent
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.importState != .idle)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var innerContent: some View {
        if viewModel.isLoading && viewModel.events.isEmpty {
            HStack { Spacer(); ProgressView(); Spacer() }
                .frame(maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 20)
        } else if viewModel.todayEvents.isEmpty {
            FreeView()
        } else {
            focusView
        }
    }

    // MARK: - Focus View

    @ViewBuilder
    private var focusView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if let next = viewModel.nextMeeting {
                    NextMeetingCardView(event: next) {
                        viewModel.openMeeting(next)
                    }
                }

                let later = viewModel.todayEvents.filter { $0.id != viewModel.nextMeeting?.id }
                if !later.isEmpty {
                    LaterTodayView(events: later) { event in
                        viewModel.openMeeting(event)
                    }
                }
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Import Banner

private struct ImportBanner: View {
    let state: ImportState

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 11))
                .lineLimit(2)
            Spacer()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(color.opacity(0.1))
        )
    }

    private var icon: String {
        switch state {
        case .idle:               return "circle"
        case .importing:          return "arrow.down.circle"
        case .success:            return "checkmark.circle.fill"
        case .failure:            return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch state {
        case .idle, .importing:   return .blue
        case .success:            return .green
        case .failure:            return .red
        }
    }

    private var label: String {
        switch state {
        case .idle:
            return ""
        case .importing(let current, let total):
            return "Importing \(current)/\(total)…"
        case .success(let count):
            return "\(count) event\(count == 1 ? "" : "s") imported"
        case .failure(let msg):
            return msg
        }
    }
}

// MARK: - Later Today

private struct LaterTodayView: View {
    let events: [CalendarEvent]
    let onJoin: (CalendarEvent) -> Void
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lm.str("later.today"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(events) { event in
                EventRowView(
                    event: event,
                    onJoin: { onJoin(event) },
                    isPast: false,
                    isNext: false
                )
            }
        }
    }
}

// MARK: - Free View

private struct FreeView: View {
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green.opacity(0.75))
            Text(lm.str("events.free"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            Text(lm.str("events.noMore"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - Header

struct HeaderView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        HStack {
            Text(lm.str("app.title"))
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            if viewModel.auth.isAuthenticated, let email = viewModel.auth.userEmail {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(email.prefix(1)).uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        )
                    Text(email.components(separatedBy: "@").first ?? email)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Sign In

struct SignInView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(lm.str("signin.description"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            Button(lm.str("signin.button")) {
                Task { await viewModel.signIn(contextProvider: WindowContextProvider.shared) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            if viewModel.isLoading { ProgressView() }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Window Context Provider

final class WindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WindowContextProvider()
    private override init() { super.init() }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
    }
}

#Preview {
    ContentView()
        .environmentObject(CalendarViewModel())
        .environmentObject(LocalizationManager.shared)
}
