import Carbon
import Foundation
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let config = ScrollConfig.shared

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var mods = 0
        if flags.contains(.command) { mods |= cmdKey }
        if flags.contains(.shift) { mods |= shiftKey }
        if flags.contains(.option) { mods |= optionKey }
        if flags.contains(.control) { mods |= controlKey }
        return mods
    }

    static func modifierSymbols(from carbonMods: Int) -> String {
        var s = ""
        if carbonMods & controlKey != 0 { s += "⌃" }
        if carbonMods & optionKey != 0 { s += "⌥" }
        if carbonMods & shiftKey != 0 { s += "⇧" }
        if carbonMods & cmdKey != 0 { s += "⌘" }
        return s
    }

    static func keyName(for keyCode: Int) -> String {
        let names: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "Return", 48: "Tab", 51: "Delete", 53: "Escape",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 103: "F11", 105: "F13", 107: "F14", 109: "F10",
            111: "F12", 113: "F15", 118: "F4", 120: "F2", 122: "F1",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return names[keyCode] ?? "Key\(keyCode)"
    }

    static func displayString(keyCode: Int, modifiers: Int) -> String {
        return modifierSymbols(from: modifiers) + keyName(for: keyCode)
    }

    func register() {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x494E5254), id: 1)
        let modifiers = UInt32(config.globalHotkeyModifiers)
        let keyCode = UInt32(config.globalHotkeyKeyCode)

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    func updateHotkey() {
        if config.globalHotkeyEnabled {
            register()
        } else {
            unregister()
        }
    }
}

private func hotkeyCallback(
    _ handler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async {
        let config = ScrollConfig.shared
        config.enabled.toggle()
        if config.enabled {
            ScrollEngine.shared.start()
        } else {
            ScrollEngine.shared.stop()
        }
    }
    return noErr
}
