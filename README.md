# fntoggle

A minimal macOS menu bar app that toggles the Fn key mode between standard function keys (F1–F12) and media/special keys.

## What it does

macOS lets you choose whether the top row of keys acts as standard function keys or as media/special keys (brightness, volume, etc.). fntoggle puts that toggle one click away in the menu bar — no need to open System Settings.

| Icon | Mode |
|------|------|
| `F•` | Standard function keys (F1–F12) |
| `♪`  | Media / special keys |

- **Left-click** the menu bar icon to toggle the mode instantly.
- **Right-click** for a context menu with About and Quit.

The setting is applied immediately via IOKit and persisted to `~/Library/Preferences/com.apple.keyboard.plist` so it survives reboots.

## Requirements

- macOS 26 (Tahoe) or later
- Apple Silicon or Intel Mac

## Building

Open `fntoggle.xcodeproj` in Xcode, set your Development Team in the project settings, and build (`⌘B`).

The app does not require any entitlements or sandbox permissions beyond what is granted by default.

## How it works

fntoggle calls the private `IOHIDSetParameter` / `IOHIDGetParameter` IOKit functions on the `IOHIDSystem` service to read and write the `HIDFKeyMode` parameter (`1` = standard fn keys, `0` = media keys). This is the same mechanism the system uses internally when you change the setting in System Settings → Keyboard.

## License

MIT
