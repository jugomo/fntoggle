import AppKit
import IOKit
import os

// IOHIDSetParameter / IOHIDGetParameter are in IOKit but not exposed in the Swift overlay.
@_silgen_name("IOHIDSetParameter")
func IOHIDSetParameter(_ handle: io_connect_t, _ key: CFString, _ bytes: UnsafeRawPointer, _ count: IOByteCount) -> kern_return_t

@_silgen_name("IOHIDGetParameter")
func IOHIDGetParameter(_ handle: io_connect_t, _ key: CFString, _ maxSize: IOByteCount, _ bytes: UnsafeMutableRawPointer, _ actualSize: UnsafeMutablePointer<IOByteCount>) -> kern_return_t

class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "com.jugomo.fntoggle", category: "fn")
    private var statusItem: NSStatusItem!
    private var fnActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(handleClick)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        fnActive = hidFKeyMode() == 1
        log.info("launched fnActive=\(self.fnActive) HIDFKeyMode=\(self.hidFKeyMode())")
        updateIcon()
    }

    private func updateIcon() {
        statusItem.button?.title = fnActive ? "F•" : "♪"
    }

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggle()
        }
    }

    private func toggle() {
        let next = !fnActive
        fnActive = next
        updateIcon()
        DispatchQueue.global(qos: .userInitiated).async {
            self.setHIDFKeyMode(next ? 1 : 0)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About fntoggle", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    // Read current HIDFKeyMode (1 = standard fn keys, 0 = media keys).
    private func hidFKeyMode() -> Int32 {
        guard let conn = openHIDSystem() else { return -1 }
        defer { IOServiceClose(conn) }
        var value: Int32 = -1
        var size = IOByteCount(MemoryLayout<Int32>.size)
        _ = IOHIDGetParameter(conn, "HIDFKeyMode" as CFString, size, &value, &size)
        return value
    }

    // Apply HIDFKeyMode (1 = standard fn keys, 0 = media keys).
    private func setHIDFKeyMode(_ mode: Int32) {
        guard let conn = openHIDSystem() else {
            log.error("failed to open IOHIDSystem")
            return
        }
        defer { IOServiceClose(conn) }
        var value = mode
        let kr = IOHIDSetParameter(conn, "HIDFKeyMode" as CFString, &value, IOByteCount(MemoryLayout<Int32>.size))
        log.info("IOHIDSetParameter(HIDFKeyMode=\(mode)): \(kr == KERN_SUCCESS ? "OK" : String(format: "0x%08x", UInt32(bitPattern: kr)))")
        persistPref(mode == 1)
    }

    private func openHIDSystem() -> io_connect_t? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }
        var connect: io_connect_t = 0
        // kIOHIDParamConnectType = 1
        guard IOServiceOpen(service, mach_task_self_, 1, &connect) == KERN_SUCCESS else { return nil }
        return connect
    }

    private func persistPref(_ enabled: Bool) {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.apple.keyboard.plist")
        var prefs: [String: Any] = [:]
        if let data = try? Data(contentsOf: url),
           let p = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            prefs = p
        }
        prefs["fnState"] = enabled ? 0 : 1  // fnState=0 → standard fn keys, fnState=1 → media keys
        if let data = try? PropertyListSerialization.data(fromPropertyList: prefs, format: .binary, options: 0) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
