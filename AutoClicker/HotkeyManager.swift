//
//  HotkeyManager.swift
//  AutoClicker
//
//  全局快捷键管理器
//

import AppKit
import Carbon

/// 全局快捷键管理器
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    private var eventHandler: EventHandlerRef?
    private var hotkeys: [String: EventHotKeyRef] = [:]

    // 回调闭包
    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onCapture: (() -> Void)?

    private init() {}

    /// 注册所有快捷键
    func registerHotkeys() {
        // Cmd+Shift+S: 启动 (S = Start)
        registerHotkey(
            id: "start",
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(cmdKey | shiftKey)
        )

        // Cmd+Shift+X: 停止 (X = Stop)
        registerHotkey(
            id: "stop",
            keyCode: UInt32(kVK_ANSI_X),
            modifiers: UInt32(cmdKey | shiftKey)
        )

        // Cmd+Shift+P: 捕获位置 (P = Position)
        registerHotkey(
            id: "capture",
            keyCode: UInt32(kVK_ANSI_P),
            modifiers: UInt32(cmdKey | shiftKey)
        )
    }

    /// 注册单个快捷键
    private func registerHotkey(id: String, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?

        // 使用简单的数字 ID 避免 hashValue 为负数的问题
        let numericID: UInt32 = {
            switch id {
            case "start": return 1
            case "stop": return 2
            case "capture": return 3
            default: return 0
            }
        }()

        let hotKeyID = EventHotKeyID(signature: OSType(fourCharCodeToOSType("ACLK")), id: numericID)

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let hotKeyRef = hotKeyRef {
            hotkeys[id] = hotKeyRef
        }

        // 安装事件处理器
        if eventHandler == nil {
            installEventHandler()
        }
    }

    /// 将四字符代码转换为 OSType
    private func fourCharCodeToOSType(_ code: String) -> OSType {
        var result: OSType = 0
        for char in code.utf8 {
            result = (result << 8) | OSType(char)
        }
        return result
    }

    /// 安装事件处理器
    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let callback: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr {
                // 在主线程执行回调
                DispatchQueue.main.async {
                    HotkeyManager.shared.handleHotkey(id: hotKeyID.id)
                }
            }

            return noErr
        }

        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    /// 处理快捷键事件
    private func handleHotkey(id: UInt32) {
        switch id {
        case 1:  // start
            onStart?()
        case 2:  // stop
            onStop?()
        case 3:  // capture
            onCapture?()
        default:
            break
        }
    }

    /// 注销所有快捷键
    func unregisterHotkeys() {
        for (_, hotKeyRef) in hotkeys {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotkeys.removeAll()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregisterHotkeys()
    }
}
