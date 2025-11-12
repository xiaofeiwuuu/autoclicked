//
//  AccessibilityManager.swift
//  AutoClicker
//
//  辅助功能权限管理
//

import Cocoa
import ApplicationServices

@MainActor
class AccessibilityManager: ObservableObject {

    @Published var hasPermission: Bool = false

    static let shared = AccessibilityManager()

    private var monitoringTimer: Timer?

    private init() {
        checkPermission()
    }

    /// 检查是否已授予辅助功能权限
    func checkPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        hasPermission = trusted
    }

    /// 请求辅助功能权限（会弹出系统对话框）
    func requestPermission() {
        // 使用 prompt: true 会让系统自动弹出对话框
        // 用户可以选择是否跳转到系统设置
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        hasPermission = AXIsProcessTrustedWithOptions(options)
    }

    /// 开始监听权限变化
    func startMonitoring() {
        // 防止重复创建 Timer
        monitoringTimer?.invalidate()

        // 每 2 秒检查一次权限状态
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
            }
        }
    }

    /// 停止监听权限变化
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    deinit {
        monitoringTimer?.invalidate()
    }
}
