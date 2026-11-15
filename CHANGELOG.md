# Changelog

## [1.1] - 2026-11-15

Slimmed fork of upstream 1.0.

- Dropped SwiftUI for plain AppKit: lower memory, builds with command line tools only.
- Removed sounds, pin animations, shake-tuning sliders (fixed at sensible values), unused opacity setting.
- Shake detection no longer looks up windows on every click, only when a drag starts.
- Setup window no longer polls with a timer.
- Removed demo images, release automation, issue templates. Working tree is ~1 MB instead of ~6 MB.
- Bundle ID is now com.abhinxx.FloatPin.
