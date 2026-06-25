import AppKit

// MARK: - Recorder view

final class HotkeyRecorderView: NSView {
    var keyCode: UInt16 = 0
    var modifiers: NSEvent.ModifierFlags = []
    private(set) var isRecording = false

    var hasHotkey: Bool { keyCode != 0 }

    var displayString: String {
        if isRecording { return "● Presiona un atajo…" }
        if !hasHotkey  { return "Clic para grabar…" }
        return modifiers.symbolString + keyDisplayString(keyCode)
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])

        if event.keyCode == 53 {                                     // Esc → cancelar
            isRecording = false; needsDisplay = true; return
        }
        if (event.keyCode == 51 || event.keyCode == 117) && mods.isEmpty { // Delete → limpiar
            keyCode = 0; modifiers = []; isRecording = false; needsDisplay = true; return
        }
        guard !mods.isEmpty else { return }                          // requiere al menos un modificador

        keyCode = event.keyCode
        modifiers = mods
        isRecording = false
        needsDisplay = true
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { isRecording = false; needsDisplay = true }
        return super.resignFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 1.5, dy: 1.5)
        let path = NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6)

        if isRecording {
            NSColor.selectedControlColor.withAlphaComponent(0.2).setFill()
            NSColor.controlAccentColor.setStroke()
            path.lineWidth = 2
        } else {
            NSColor.controlBackgroundColor.setFill()
            NSColor.separatorColor.setStroke()
            path.lineWidth = 1
        }
        path.fill(); path.stroke()

        let text = displayString
        let fg: NSColor = hasHotkey && !isRecording ? .labelColor : .secondaryLabelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: fg
        ]
        let sz = (text as NSString).size(withAttributes: attrs)
        let pt = CGPoint(x: (bounds.width - sz.width) / 2,
                         y: (bounds.height - sz.height) / 2)
        (text as NSString).draw(at: pt, withAttributes: attrs)
    }
}

// MARK: - Window controller

final class HotkeyWindowController: NSWindowController {
    private var recorder: HotkeyRecorderView!
    var onSave: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var onClear: (() -> Void)?

    convenience init(currentKeyCode: UInt16, currentModifiers: NSEvent.ModifierFlags) {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 140),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Atajo de teclado"
        win.isReleasedWhenClosed = false
        self.init(window: win)

        let lbl = NSTextField(labelWithString: "Atajo:")
        lbl.frame = NSRect(x: 20, y: 96, width: 70, height: 20)
        lbl.alignment = .right

        let rec = HotkeyRecorderView(frame: NSRect(x: 100, y: 90, width: 220, height: 30))
        rec.keyCode = currentKeyCode
        rec.modifiers = currentModifiers
        recorder = rec

        let hint = NSTextField(labelWithString: "Esc cancela · Delete limpia · requiere ⌘ ⌃ ⌥ o ⇧")
        hint.frame = NSRect(x: 20, y: 64, width: 300, height: 16)
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .tertiaryLabelColor

        let clearBtn = NSButton(title: "Limpiar", target: self, action: #selector(didClear))
        clearBtn.frame = NSRect(x: 20, y: 20, width: 90, height: 28)
        clearBtn.bezelStyle = .rounded

        let saveBtn = NSButton(title: "Guardar", target: self, action: #selector(didSave))
        saveBtn.frame = NSRect(x: 230, y: 20, width: 90, height: 28)
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"

        let content = win.contentView!
        [lbl, rec, hint, clearBtn, saveBtn].forEach { content.addSubview($0) }
    }

    @objc private func didClear() { onClear?(); window?.close() }

    @objc private func didSave() {
        if recorder.hasHotkey {
            onSave?(recorder.keyCode, recorder.modifiers)
        } else {
            onClear?()
        }
        window?.close()
    }
}
