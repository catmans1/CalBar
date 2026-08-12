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
                eventList
            }

            // Footer always visible regardless of auth state
            FooterView(
                onOffsetChange: { viewModel.rescheduleNotifications(offsetMinutes: $0) },
                onSync: { Task { await viewModel.sync() } },
                onSignOut: { viewModel.signOut() }
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

    // MARK: - Event List

    @ViewBuilder
    private var eventList: some View {
        if viewModel.isLoading && viewModel.events.isEmpty {
            HStack { Spacer(); ProgressView(); Spacer() }
                .padding(.vertical, 40)
        } else if let error = viewModel.errorMessage {
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        } else if viewModel.todayEvents.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text(lm.str("events.empty"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        } else {
            let nextID = viewModel.nextMeeting?.id
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        Text(lm.str("today"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 2)

                        ForEach(viewModel.todayEvents) { event in
                            EventRowView(
                                event: event,
                                onJoin: { viewModel.openMeeting(event) },
                                isPast: event.end <= Date(),
                                isNext: event.id == nextID
                            )
                            .id(event.id)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .onAppear { scrollToNext(proxy: proxy, id: nextID) }
                .onChange(of: viewModel.events) { _, _ in scrollToNext(proxy: proxy, id: viewModel.nextMeeting?.id) }
            }
        }
    }

    private func scrollToNext(proxy: ScrollViewProxy, id: String?) {
        guard let id else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { proxy.scrollTo(id, anchor: .top) }
        }
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
