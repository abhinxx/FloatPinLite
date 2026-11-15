import Foundation

/// UserDefaults keys. SettingsView uses the same keys through @AppStorage.
enum K {
    static let shakeEnabled = "shakeEnabled"
    static let clickThrough = "clickThrough"
    static let frameRate = "frameRate"
    static let showBorder = "showBorder"
    static let hotkeyEnabled = "hotkeyEnabled"
}

enum Prefs {
    static var d: UserDefaults { .standard }

    static func register() {
        d.register(defaults: [
            K.shakeEnabled: true,
            K.clickThrough: false,
            K.frameRate: 30,
            K.showBorder: false,
            K.hotkeyEnabled: true,
        ])
    }

    static var shakeEnabled: Bool { d.bool(forKey: K.shakeEnabled) }
    static var clickThrough: Bool { d.bool(forKey: K.clickThrough) }
    static var frameRate: Int { max(1, d.integer(forKey: K.frameRate)) }
    static var showBorder: Bool { d.bool(forKey: K.showBorder) }
    static var hotkeyEnabled: Bool { d.bool(forKey: K.hotkeyEnabled) }
}
