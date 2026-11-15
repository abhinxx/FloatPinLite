import AppKit
import ServiceManagement

// Plain AppKit on purpose: no SwiftUI runtime in memory, and it builds with
// just the command line tools (SwiftUI's @State macros need full Xcode).

private func text(_ s: String, small: Bool = false, bold: Bool = false) -> NSTextField {
    let t = NSTextField(wrappingLabelWithString: s)
    t.preferredMaxLayoutWidth = 380
    if small { t.font = .systemFont(ofSize: 11); t.textColor = .secondaryLabelColor }
    if bold { t.font = .boldSystemFont(ofSize: 13) }
    return t
}

private func makeWindow(_ title: String, _ rows: [NSView]) -> NSWindow {
    let s = NSStackView(views: rows)
    s.orientation = .vertical
    s.alignment = .leading
    s.spacing = 12
    s.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
    w.title = title
    w.contentView = s
    w.setContentSize(s.fittingSize)
    w.isReleasedWhenClosed = false
    w.center()
    return w
}

// MARK: - Permissions

/// Shows the two permissions with live status. Re-checks whenever the app
/// becomes active again (i.e. when you come back from System Settings).
final class PermissionsWindow: NSObject {
    let window: NSWindow
    private let axStatus = text("")
    private let srStatus = text("")
    private let axButton = NSButton(title: "Grant…", target: nil, action: nil)
    private let srButton = NSButton(title: "Grant…", target: nil, action: nil)
    private var observer: Any?

    override init() {
        let done = NSButton(title: "Done", target: nil, action: nil)
        done.keyEquivalent = "\r"
        let relaunch = NSButton(title: "Relaunch", target: nil, action: nil)
        window = makeWindow("FloatPin Lite Setup", [
            text("Shake a window to keep it on top. FloatPin Lite needs two permissions for that.", bold: true),
            text("Accessibility: moves the real window under its pin and brings it forward on click.", small: true),
            NSStackView(views: [axStatus, axButton]),
            text("Screen Recording: shows a live copy of the pinned window. Frames stay in memory; nothing is saved or sent.", small: true),
            NSStackView(views: [srStatus, srButton]),
            text("Granted but still unchecked? macOS sometimes needs the app restarted.", small: true),
            NSStackView(views: [relaunch, done]),
        ])
        super.init()
        axButton.target = self; axButton.action = #selector(grantAX)
        srButton.target = self; srButton.action = #selector(grantSR)
        relaunch.target = self; relaunch.action = #selector(relaunchApp)
        done.target = self; done.action = #selector(close)
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    func refresh() {
        let ax = Permissions.accessibility, sr = Permissions.screenRecording
        axStatus.stringValue = ax ? "Accessibility: granted" : "Accessibility: not granted"
        srStatus.stringValue = sr ? "Screen Recording: granted" : "Screen Recording: not granted"
        axButton.isHidden = ax
        srButton.isHidden = sr
    }

    @objc private func grantAX() { Permissions.requestAccessibility() }
    @objc private func grantSR() { Permissions.requestScreenRecording() }
    @objc private func relaunchApp() { Permissions.relaunch() }
    @objc private func close() { window.close() }
}

// MARK: - Settings

final class SettingsWindow: NSObject {
    let window: NSWindow
    private let fps = NSPopUpButton(frame: .zero, pullsDown: false)
    private let login = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)

    override init() {
        fps.addItems(withTitles: ["15 fps", "30 fps", "60 fps"])
        let rate = Prefs.frameRate
        fps.selectItem(at: rate <= 15 ? 0 : rate <= 30 ? 1 : 2)
        let fpsRow = NSStackView(views: [NSTextField(labelWithString: "Frame rate"), fps])

        window = makeWindow("FloatPin Lite Settings", [
            DefaultsCheck("Shake a window to pin it", key: K.shakeEnabled),
            DefaultsCheck("Pin the front window with ⌃⌥P", key: K.hotkeyEnabled),
            DefaultsCheck("Click-through (clicks pass to what's behind a pin)", key: K.clickThrough),
            DefaultsCheck("Show colored border on pins", key: K.showBorder),
            fpsRow,
            login,
            text("Shake a pinned window again, or click its pin badge, to unpin.", small: true),
        ])
        super.init()
        fps.target = self; fps.action = #selector(fpsChanged)
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        login.target = self; login.action = #selector(loginChanged)
    }

    @objc private func fpsChanged() {
        Prefs.d.set([15, 30, 60][fps.indexOfSelectedItem], forKey: K.frameRate)
    }

    @objc private func loginChanged() {
        let on = login.state == .on
        do { if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } } catch {}
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}

/// A checkbox that reads and writes one UserDefaults bool.
private final class DefaultsCheck: NSButton {
    private let key: String

    init(_ title: String, key: String) {
        self.key = key
        super.init(frame: .zero)
        setButtonType(.switch)
        self.title = title
        state = Prefs.d.bool(forKey: key) ? .on : .off
        target = self
        action = #selector(toggled)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    @objc private func toggled() { Prefs.d.set(state == .on, forKey: key) }
}
