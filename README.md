# FloatPin

Shake a window to keep it on top. Menu bar app for macOS 14+, about 170 KB, no dependencies, no network.

Fork of [Tron16/FloatPin](https://github.com/Tron16/FloatPin) (MIT), trimmed down.

## Use

- Drag a window by its title bar and shake it: it floats above everything until you shake it again.
- ⌃⌥P pins or unpins the front window. The menu bar lists all windows too.
- Click a pin to jump into the real window. Drag or resize a pin and the real window follows.

## How it works

macOS can't float another app's window, so FloatPin streams the window (ScreenCaptureKit) into its own floating panel and keeps the real window glued underneath it (Accessibility). Only one of the two is visible at a time.

## Privacy

No network code, no analytics, nothing written to disk except its own settings. Needs two permissions:

- **Screen Recording** to show the live copy. Frames stay in memory.
- **Accessibility** to move and raise the real window.

## Build and install

Needs only the Xcode command line tools (`xcode-select --install`). Full Xcode is not required.

```bash
./build.sh install   # build, copy to /Applications, launch
./build.sh           # build only, into ./build
```

Builds are ad-hoc signed, so macOS forgets permissions after each rebuild. Reset with
`tccutil reset Accessibility com.abhinxx.FloatPin && tccutil reset ScreenCapture com.abhinxx.FloatPin`,
or sign with your own certificate: `SIGN_IDENTITY="Apple Development: ..." ./build.sh install`.

## Code

| File | Role |
|---|---|
| `Shake.swift` | Global mouse monitor, shake detection |
| `PinnedWindow.swift` | Floating panel, glue to the real window, `PinManager` |
| `WindowList.swift` | Window lookup (CoreGraphics), move/raise (Accessibility) |
| `Permissions.swift` | Permission checks and prompts |
| `Views.swift` | Setup and settings windows (AppKit) |
| `HotKey.swift` | ⌃⌥P shortcut |
| `AppDelegate.swift` | Menu bar menu and wiring |

MIT licensed.
