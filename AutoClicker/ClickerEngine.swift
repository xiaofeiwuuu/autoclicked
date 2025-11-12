//
//  ClickerEngine.swift
//  AutoClicker
//
//  核心点击引擎 - 实现人性化的自动点击
//

import Foundation
import CoreGraphics
import Combine
import AppKit

@MainActor
class ClickerEngine: ObservableObject {

    // MARK: - Published Properties

    @Published var isRunning: Bool = false
    @Published var clickedCount: Int = 0
    @Published var configuration: ClickConfiguration

    // MARK: - Private Properties

    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.autoclicker.timer", qos: .userInteractive)

    // MARK: - Initialization

    init(configuration: ClickConfiguration = ClickConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// 开始自动点击
    func start() {
        guard !isRunning else { return }
        guard configuration.isValid() else { return }

        isRunning = true
        clickedCount = 0

        scheduleNextClick()
    }

    /// 停止自动点击
    func stop() {
        guard isRunning else { return }

        isRunning = false
        timer?.cancel()
        timer = nil
    }

    /// 更新配置
    func updateConfiguration(_ newConfig: ClickConfiguration) {
        let wasRunning = isRunning
        if wasRunning {
            stop()
        }
        configuration = newConfig
        if wasRunning {
            start()
        }
    }

    // MARK: - Private Methods

    /// 安排下一次点击
    private func scheduleNextClick() {
        guard isRunning else { return }

        // 检查是否达到点击次数限制
        if configuration.clickCount > 0 && clickedCount >= configuration.clickCount {
            Task { @MainActor in
                stop()
            }
            return
        }

        // 计算带随机波动的延迟时间
        let interval = configuration.getRandomizedInterval()

        // 使用 DispatchSourceTimer 实现高精度定时
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now() + interval)
        timer?.setEventHandler { [weak self] in
            self?.performClick()
        }
        timer?.resume()
    }

    /// 执行点击操作
    private func performClick() {
        guard isRunning else { return }

        // 获取带随机抖动的点击位置
        let position = configuration.getRandomizedPosition()

        // 转换坐标系统（macOS 使用左下角为原点，需要转换）
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let flippedY = screenHeight - position.y

        let clickPosition = CGPoint(x: position.x, y: flippedY)

        // 执行点击
        performMouseClick(at: clickPosition)

        // 更新计数
        Task { @MainActor in
            clickedCount += 1
        }

        // 安排下一次点击
        scheduleNextClick()
    }

    /// 执行鼠标点击事件
    private func performMouseClick(at position: CGPoint) {
        let button = configuration.mouseButton
        let clickCount = configuration.clickType.clickCount

        // 获取对应的事件类型
        let (mouseDown, mouseUp) = getMouseEventTypes(for: button)

        // 获取系统双击间隔
        let systemDoubleClickInterval = NSEvent.doubleClickInterval

        // 创建鼠标按下事件
        guard let downEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: mouseDown,
            mouseCursorPosition: position,
            mouseButton: button.cgMouseButton
        ) else {
            return
        }

        downEvent.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))

        // 创建鼠标抬起事件
        guard let upEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: mouseUp,
            mouseCursorPosition: position,
            mouseButton: button.cgMouseButton
        ) else {
            return
        }

        upEvent.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))

        // 发送事件
        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)

        // 对于双击和三击，需要重复发送事件
        if clickCount > 1 {
            // 使用系统双击间隔的一半作为点击间隔（更可靠）
            let clickInterval = systemDoubleClickInterval / Double(clickCount)

            for _ in 1..<clickCount {
                Thread.sleep(forTimeInterval: clickInterval)
                downEvent.post(tap: .cghidEventTap)
                upEvent.post(tap: .cghidEventTap)
            }
        }
    }

    /// 获取鼠标事件类型
    private func getMouseEventTypes(for button: MouseButton) -> (CGEventType, CGEventType) {
        switch button {
        case .left:
            return (.leftMouseDown, .leftMouseUp)
        case .right:
            return (.rightMouseDown, .rightMouseUp)
        }
    }

    // MARK: - Deinit

    deinit {
        timer?.cancel()
        timer = nil
    }
}
