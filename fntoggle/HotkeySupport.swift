import AppKit
import Carbon.HIToolbox

// MARK: - Persistence

struct HotkeyConfig {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags

    static func load() -> HotkeyConfig? {
        let d = UserDefaults.standard
        guard d.object(forKey: "hotkeyKeyCode") != nil else { return nil }
        let kc = UInt16(d.integer(forKey: "hotkeyKeyCode"))
        guard kc != 0 else { return nil }
        let mods = NSEvent.ModifierFlags(rawValue: UInt(d.integer(forKey: "hotkeyModifiers")))
        return HotkeyConfig(keyCode: kc, modifiers: mods)
    }

    func save() {
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "hotkeyModifiers")
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: "hotkeyKeyCode")
        UserDefaults.standard.removeObject(forKey: "hotkeyModifiers")
    }
}

// MARK: - Modifier helpers

extension NSEvent.ModifierFlags {
    var symbolString: String {
        var s = ""
        if contains(.control) { s += "⌃" }
        if contains(.option)  { s += "⌥" }
        if contains(.shift)   { s += "⇧" }
        if contains(.command) { s += "⌘" }
        return s
    }

    var carbonFlags: UInt32 {
        var c: UInt32 = 0
        if contains(.command) { c |= UInt32(cmdKey) }
        if contains(.shift)   { c |= UInt32(shiftKey) }
        if contains(.option)  { c |= UInt32(optionKey) }
        if contains(.control) { c |= UInt32(controlKey) }
        return c
    }
}

// MARK: - Key code → display string

func keyDisplayString(_ keyCode: UInt16) -> String {
    let specials: [UInt16: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        76: "↩", 96: "F5", 97: "F6", 98: "F7", 99: "F3",
        100: "F8", 101: "F9", 103: "F11", 109: "F10",
        111: "F12", 118: "F4", 120: "F2", 122: "F1",
        123: "←", 124: "→", 125: "↓", 126: "↑"
    ]
    if let s = specials[keyCode] { return s }
    let alphanum: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 50: "`"
    ]
    return alphanum[keyCode] ?? "#\(keyCode)"
}

