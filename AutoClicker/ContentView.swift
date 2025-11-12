//
//  ContentView.swift
//  AutoClicker
//
//  Created by wu xiao on 2025/11/12.
//

import SwiftUI

// 时间单位枚举
enum TimeUnit: String, CaseIterable {
    case milliseconds = "ms"
    case seconds = "s"
    case minutes = "min"

    var multiplier: Double {
        switch self {
        case .milliseconds: return 1
        case .seconds: return 1000
        case .minutes: return 60000
        }
    }

    var displayName: String {
        switch self {
        case .milliseconds: return "milliseconds".localized
        case .seconds: return "seconds".localized
        case .minutes: return "minutes".localized
        }
    }
}

struct ContentView: View {
    @StateObject private var clickerEngine = ClickerEngine()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    @State private var intervalValue: Double = 2  // 用户输入的值
    @State private var selectedTimeUnit: TimeUnit = .seconds  // 选择的时间单位
    @State private var clickCount: Int = 0
    @State private var selectedButton: MouseButton = .left
    @State private var selectedClickType: ClickType = .single
    @State private var selectedMode: ClickMode = .followMouse
    @State private var randomDelayPercent: Double = 0
    @State private var randomJitter: Double = 0

    @State private var targetX: String = "0"
    @State private var targetY: String = "0"

    // 随机区域相关
    @State private var areaX1: String = "0"  // 区域起点 X
    @State private var areaY1: String = "0"  // 区域起点 Y
    @State private var areaX2: String = "0"  // 区域终点 X
    @State private var areaY2: String = "0"  // 区域终点 Y

    // 延迟启动相关
    @State private var delayStartSeconds: Int = 0  // 延迟秒数 (0=立即启动)
    @State private var isCountingDown: Bool = false  // 是否正在倒计时
    @State private var countdownRemaining: Int = 0  // 剩余倒计时秒数
    @State private var countdownTimer: Timer?  // 倒计时 Timer

    // 坐标捕获状态
    @State private var isCapturingFixed: Bool = false  // 正在捕获固定位置
    @State private var isCapturingArea1: Bool = false  // 正在捕获区域起点
    @State private var isCapturingArea2: Bool = false  // 正在捕获区域终点
    @State private var captureCountdown: Int = 0  // 捕获倒计时
    @State private var captureTimer: Timer?  // 捕获倒计时 Timer

    // 设置界面
    @State private var showingSettings: Bool = false

    // 计算实际的毫秒值
    private var intervalMs: Double {
        intervalValue * selectedTimeUnit.multiplier
    }

    // 计算区域大小
    private var areaDimensions: (width: Double, height: Double) {
        let width = abs((Double(areaX2) ?? 0) - (Double(areaX1) ?? 0))
        let height = abs((Double(areaY2) ?? 0) - (Double(areaY1) ?? 0))
        return (width, height)
    }

    var body: some View {
        VStack(spacing: 20) {
            // 标题和设置按钮
            HStack {
                Spacer()

                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "cursorarrow.click.2")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        Text("AutoClicker")
                            .font(.title)
                    }

                    Text("TinyWuyou")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("settings".localized)
            }
            .padding(.top)
            .padding(.horizontal)

            // 主控制区域
            Form {
                // 点击设置
                Section {
                    // 点击间隔
                    HStack {
                        Text("click_interval".localized)
                        Spacer()
                        // 数值输入
                        TextField("", value: $intervalValue, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)

                        // 单位下拉选择器
                        Picker("", selection: $selectedTimeUnit) {
                            ForEach(TimeUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .frame(width: 80)
                    }

                    // 点击次数
                    HStack {
                        Text("click_count".localized)
                        Spacer()
                        TextField("", value: $clickCount, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                        Text("unlimited".localized)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    // 鼠标按键
                    Picker("mouse_button".localized, selection: $selectedButton) {
                        ForEach(MouseButton.allCases, id: \.self) { button in
                            Text(button.localizedName).tag(button)
                        }
                    }

                    // 点击类型
                    Picker("click_type".localized, selection: $selectedClickType) {
                        ForEach(ClickType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }

                    // 点击模式
                    Picker("click_mode".localized, selection: $selectedMode) {
                        ForEach(ClickMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }

                    // 延迟启动
                    HStack {
                        Text("delay_start".localized)
                        Spacer()
                        TextField("", value: $delayStartSeconds, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("seconds".localized)
                        Text("immediately".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 人性化设置
                Section {
                    HStack {
                        Text("delay_variation".localized)
                        Slider(value: $randomDelayPercent, in: 0...100, step: 1)
                        Text("\(Int(randomDelayPercent))%")
                            .frame(width: 40)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("position_jitter".localized)
                        Slider(value: $randomJitter, in: 0...10, step: 0.5)
                        Text("\(String(format: "%.1f", randomJitter)) px")
                            .frame(width: 50)
                            .foregroundColor(.secondary)
                    }
                }

                // 坐标设置（仅固定模式）
                if selectedMode == .fixed {
                    Section {
                        HStack {
                            Text("coordinates".localized)
                            Spacer()
                            Text("X:")
                            TextField("", text: $targetX)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: targetX) { oldValue, newValue in
                                    targetX = newValue.filter { $0.isNumber || $0 == "-" || $0 == "." }
                                }
                            Text("Y:")
                            TextField("", text: $targetY)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: targetY) { oldValue, newValue in
                                    targetY = newValue.filter { $0.isNumber || $0 == "-" || $0 == "." }
                                }
                        }

                        Button(isCapturingFixed ? "\("capturing".localized) \(captureCountdown)s" : "capture_position".localized) {
                            startCaptureFixed()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCapturingFixed)
                    }
                }

                // 随机区域设置（仅随机区域模式）
                if selectedMode == .randomArea {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("start_point".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("X1:")
                                TextField("", text: $areaX1)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: areaX1) { oldValue, newValue in
                                        areaX1 = newValue.filter { $0.isNumber || $0 == "-" || $0 == "." }
                                    }
                                Text("Y1:")
                                TextField("", text: $areaY1)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: areaY1) { oldValue, newValue in
                                        areaY1 = newValue.filter { $0.isNumber || $0 == "-" || $0 == "." }
                                    }

                                Button(isCapturingArea1 ? "\(captureCountdown)" : "📍") {
                                    startCaptureArea1()
                                }
                                .disabled(isCapturingArea1)
                            }

                            Text("end_point".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("X2:")
                                TextField("", text: $areaX2)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: areaX2) { oldValue, newValue in
                                        areaX2 = newValue.filter { $0.isNumber || $0 == "-" || $0 == "." }
                                    }
                                Text("Y2:")
                                TextField("", text: $areaY2)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: areaY2) { oldValue, newValue in
                                        areaY2 = newValue.filter { $0.isNumber || $0 == "-" || $0 == "." }
                                    }

                                Button(isCapturingArea2 ? "\(captureCountdown)" : "📍") {
                                    startCaptureArea2()
                                }
                                .disabled(isCapturingArea2)
                            }

                            // 区域大小显示
                            if areaDimensions.width > 0 && areaDimensions.height > 0 {
                                Text("\(Int(areaDimensions.width)) × \(Int(areaDimensions.height)) px")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // 状态显示
            HStack {
                Circle()
                    .fill(clickerEngine.isRunning ? Color.green : (isCountingDown ? Color.orange : Color.gray))
                    .frame(width: 12, height: 12)

                if isCountingDown {
                    Text("\("countdown".localized) \(countdownRemaining) \("seconds".localized)")
                        .font(.headline)
                        .foregroundColor(.orange)
                } else {
                    Text(clickerEngine.isRunning ? "running".localized : "stopped".localized)
                        .font(.headline)
                }

                Spacer()

                Text("\("clicked_count".localized) \(clickerEngine.clickedCount) \("times".localized)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // 控制按钮
            HStack(spacing: 20) {
                Button(action: startClicking) {
                    Label(isCountingDown ? "\("capturing".localized)..." : "start".localized, systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(clickerEngine.isRunning || isCountingDown)

                Button(action: stopClicking) {
                    Label("stop".localized, systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!clickerEngine.isRunning && !isCountingDown)
            }
            .padding(.horizontal)

            // 快捷键提示
            VStack(spacing: 4) {
                Text("global_hotkeys".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("⌘⇧S")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                        Text("hotkey_start".localized)
                            .font(.caption2)
                    }

                    HStack(spacing: 4) {
                        Text("⌘⇧X")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                        Text("hotkey_stop".localized)
                            .font(.caption2)
                    }

                    HStack(spacing: 4) {
                        Text("⌘⇧P")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                        Text("hotkey_capture".localized)
                            .font(.caption2)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 420, height: 550)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            accessibilityManager.startMonitoring()
            setupHotkeys()
        }
    }

    // MARK: - Actions

    private func startClicking() {
        // 先检查权限
        if !accessibilityManager.hasPermission {
            accessibilityManager.requestPermission()
            return
        }

        // 如果设置了延迟启动
        if delayStartSeconds > 0 {
            startCountdown()
        } else {
            // 立即启动
            actuallyStartClicking()
        }
    }

    private func stopClicking() {
        // 取消倒计时
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountingDown = false
        countdownRemaining = 0

        // 停止点击
        clickerEngine.stop()
    }

    /// 开始倒计时
    private func startCountdown() {
        // 先清理可能存在的旧 Timer
        countdownTimer?.invalidate()

        isCountingDown = true
        countdownRemaining = delayStartSeconds

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            if self.countdownRemaining > 1 {
                self.countdownRemaining -= 1
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.isCountingDown = false
                self.actuallyStartClicking()
            }
        }
    }

    /// 实际开始点击
    private func actuallyStartClicking() {
        var config = ClickConfiguration()
        config.intervalMs = intervalMs
        config.clickCount = clickCount
        config.mouseButton = selectedButton
        config.clickType = selectedClickType
        config.clickMode = selectedMode
        config.randomDelayPercent = randomDelayPercent
        config.randomPositionJitter = randomJitter

        if selectedMode == .fixed {
            config.targetPosition = CGPoint(
                x: Double(targetX) ?? 0,
                y: Double(targetY) ?? 0
            )
        } else if selectedMode == .randomArea {
            config.randomAreaTopLeft = CGPoint(
                x: Double(areaX1) ?? 0,
                y: Double(areaY1) ?? 0
            )
            config.randomAreaBottomRight = CGPoint(
                x: Double(areaX2) ?? 0,
                y: Double(areaY2) ?? 0
            )
        }

        clickerEngine.updateConfiguration(config)
        clickerEngine.start()
    }

    // MARK: - 坐标捕获函数

    /// 开始捕获固定位置
    private func startCaptureFixed() {
        isCapturingFixed = true
        captureCountdown = 3
        startCountdownCapture { location in
            self.targetX = String(format: "%.0f", location.x)
            self.targetY = String(format: "%.0f", location.y)
            self.isCapturingFixed = false
        }
    }

    /// 开始捕获区域起点
    private func startCaptureArea1() {
        isCapturingArea1 = true
        captureCountdown = 3
        startCountdownCapture { location in
            self.areaX1 = String(format: "%.0f", location.x)
            self.areaY1 = String(format: "%.0f", location.y)
            self.isCapturingArea1 = false
        }
    }

    /// 开始捕获区域终点
    private func startCaptureArea2() {
        isCapturingArea2 = true
        captureCountdown = 3
        startCountdownCapture { location in
            self.areaX2 = String(format: "%.0f", location.x)
            self.areaY2 = String(format: "%.0f", location.y)
            self.isCapturingArea2 = false
        }
    }

    /// 倒计时捕获通用函数
    private func startCountdownCapture(completion: @escaping (CGPoint) -> Void) {
        // 先清理可能存在的旧 Timer
        captureTimer?.invalidate()

        captureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            if self.captureCountdown > 1 {
                self.captureCountdown -= 1
            } else {
                timer.invalidate()
                self.captureTimer = nil
                // 捕获当前鼠标位置
                let location = NSEvent.mouseLocation
                completion(location)
            }
        }
    }

    /// 立即捕获固定位置 (用于快捷键)
    private func captureFixedImmediately() {
        let location = NSEvent.mouseLocation
        targetX = String(format: "%.0f", location.x)
        targetY = String(format: "%.0f", location.y)
    }

    /// 立即捕获区域起点 (用于快捷键)
    private func captureArea1Immediately() {
        let location = NSEvent.mouseLocation
        areaX1 = String(format: "%.0f", location.x)
        areaY1 = String(format: "%.0f", location.y)
    }

    /// 立即捕获区域终点 (用于快捷键)
    private func captureArea2Immediately() {
        let location = NSEvent.mouseLocation
        areaX2 = String(format: "%.0f", location.x)
        areaY2 = String(format: "%.0f", location.y)
    }

    // MARK: - 快捷键设置

    /// 设置全局快捷键
    private func setupHotkeys() {
        // 注册快捷键
        hotkeyManager.registerHotkeys()

        // 设置回调
        hotkeyManager.onStart = { [self] in
            if !clickerEngine.isRunning && !isCountingDown {
                startClicking()
            }
        }

        hotkeyManager.onStop = { [self] in
            stopClicking()
        }

        hotkeyManager.onCapture = { [self] in
            // 快捷键立即捕获,无倒计时
            if selectedMode == .fixed {
                captureFixedImmediately()
            } else if selectedMode == .randomArea {
                // 优先捕获起点,如果起点已设置则捕获终点
                if areaX1 == "0" && areaY1 == "0" {
                    captureArea1Immediately()
                } else {
                    captureArea2Immediately()
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
