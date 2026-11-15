import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let shakeMonitor = ShakeMonitor()
    private let hotKey = HotKey()
    private var hotKeyOn: Bool?
    private var permissions: PermissionsWindow?
    private var settings: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.register()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()

        let pins = PinManager.shared
        pins.onChange = { [weak self] in self?.updateIcon() }
        pins.onNeedsPermission = { [weak self] in self?.showOnboarding() }

        // Feedback the moment a shake is recognized; the pin happens when you let go.
        shakeMonitor.onArmed = {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
        shakeMonitor.onShake = { window in PinManager.shared.toggle(window) }
        shakeMonitor.start()

        hotKey.action = { [weak self] in self?.pinFrontWindow() }
        syncHotKey()

        // Settings changes apply live to existing pins.
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            PinManager.shared.applyPrefs()
            self?.syncHotKey()
        }

        if !Permissions.allGranted { showOnboarding() }
    }

    // MARK: Menu bar

    private func updateIcon() {
        let name = PinManager.shared.pins.isEmpty ? "pin" : "pin.fill"
        statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "FloatPin Lite")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let pins = PinManager.shared.pins

        if pins.isEmpty {
            let hint = NSMenuItem(title: Prefs.shakeEnabled ? "Shake a window to pin it" : "No pinned windows",
                                  action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
        } else {
            let header = NSMenuItem(title: "Pinned (click to unpin)", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            for p in pins {
                let item = NSMenuItem(title: p.title, action: #selector(unpinItem(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = p
                item.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
                menu.addItem(item)
            }
            menu.addItem(makeItem("Unpin All", #selector(unpinAll)))
        }

        menu.addItem(.separator())

        let pinMenu = NSMenu()
        let windows = WindowList.onScreen()
        if windows.isEmpty {
            let none = NSMenuItem(title: "No windows found", action: nil, keyEquivalent: "")
            none.isEnabled = false
            pinMenu.addItem(none)
        }
        for w in windows {
            let item = NSMenuItem(title: w.displayName, action: #selector(pinItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = w
            if let app = NSRunningApplication(processIdentifier: w.pid), let icon = app.icon {
                icon.size = NSSize(width: 16, height: 16)
                item.image = icon
            }
            pinMenu.addItem(item)
        }
        let pinParent = NSMenuItem(title: "Pin a Window", action: nil, keyEquivalent: "")
        pinParent.submenu = pinMenu
        menu.addItem(pinParent)

        let front = makeItem("Pin Front Window", #selector(pinFrontWindow), key: "p")
        front.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(front)

        menu.addItem(.separator())
        menu.addItem(makeItem("Permissions…", #selector(showOnboarding)))
        menu.addItem(makeItem("Settings…", #selector(showSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem("Quit FloatPin Lite", #selector(quit), key: "q"))
    }

    private func makeItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: Actions

    @objc private func unpinItem(_ sender: NSMenuItem) {
        (sender.representedObject as? PinnedWindow)?.unpin()
    }

    @objc private func unpinAll() { PinManager.shared.unpinAll() }

    @objc private func pinItem(_ sender: NSMenuItem) {
        if let w = sender.representedObject as? WinInfo { PinManager.shared.toggle(w) }
    }

    @objc private func pinFrontWindow() {
        guard let w = WindowList.frontmostWindow() else { NSSound.beep(); return }
        PinManager.shared.toggle(w)
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func syncHotKey() {
        let on = Prefs.hotkeyEnabled
        guard on != hotKeyOn else { return }
        hotKeyOn = on
        if on { hotKey.register() } else { hotKey.unregister() }
    }

    // MARK: Windows

    @objc func showOnboarding() {
        let w = permissions ?? PermissionsWindow()
        permissions = w
        w.refresh()
        NSApp.activate()
        w.window.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        let w = settings ?? SettingsWindow()
        settings = w
        NSApp.activate()
        w.window.makeKeyAndOrderFront(nil)
    }
}
