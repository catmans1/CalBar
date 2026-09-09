import Cocoa
import Combine
import SwiftUI

final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: AppSettings.Keys.enableGlobalHotkey)
            updateMonitoring()
        }
    }

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {
        isEnabled = UserDefaults.standard.object(forKey: AppSettings.Keys.enableGlobalHotkey) as? Bool ?? true
        updateMonitoring()
    }

    func updateMonitoring() {
        stopMonitoring()
        guard isEnabled else { return }

        // Monitor Option + C globally
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Option key (flags contains .option) + 'c' (keyCode 8)
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.option) && event.keyCode == 8 {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                // Post notification or simulate menu bar activation
                NotificationCenter.default.post(name: .toggleCalBarPopover, object: nil)
            }
            return true
        }
        return false
    }

    deinit {
        stopMonitoring()
    }
}

extension Notification.Name {
    static let toggleCalBarPopover = Notification.Name("toggleCalBarPopover")
}
