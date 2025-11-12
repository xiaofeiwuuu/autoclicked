//
//  ClickConfiguration.swift
//  AutoClicker
//
//  点击配置数据模型
//

import Foundation
import CoreGraphics
import AppKit

/// 鼠标按键类型
enum MouseButton: String, CaseIterable, Codable {
    case left
    case right

    var cgMouseButton: CGMouseButton {
        switch self {
        case .left: return .left
        case .right: return .right
        }
    }

    var localizedName: String {
        switch self {
        case .left: return "left_button".localized
        case .right: return "right_button".localized
        }
    }
}

/// 点击类型
enum ClickType: String, CaseIterable, Codable {
    case single
    case double
    case triple

    var clickCount: Int {
        switch self {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }

    var localizedName: String {
        switch self {
        case .single: return "single_click".localized
        case .double: return "double_click".localized
        case .triple: return "triple_click".localized
        }
    }
}

/// 点击模式
enum ClickMode: String, CaseIterable, Codable {
    case fixed
    case followMouse
    case randomArea

    var localizedName: String {
        switch self {
        case .fixed: return "fixed_position".localized
        case .followMouse: return "follow_mouse".localized
        case .randomArea: return "random_area".localized
        }
    }
}

/// 点击配置
struct ClickConfiguration: Codable {
    /// 点击间隔（毫秒）
    var intervalMs: Double = 100

    /// 点击次数（0 表示无限）
    var clickCount: Int = 0

    /// 鼠标按键
    var mouseButton: MouseButton = .left

    /// 点击类型
    var clickType: ClickType = .single

    /// 点击模式
    var clickMode: ClickMode = .fixed

    /// 固定点击位置（当 mode 为 fixed 时使用）
    var targetPosition: CGPoint = .zero

    /// 随机区域设置（当 mode 为 randomArea 时使用）
    var randomAreaTopLeft: CGPoint = .zero      // 区域左上角
    var randomAreaBottomRight: CGPoint = .zero  // 区域右下角

    // MARK: - 人性化设置

    /// 随机延迟波动百分比 (0-100)
    /// 例如: 20% 表示实际延迟在 ±20% 范围内波动
    var randomDelayPercent: Double = 0

    /// 随机坐标抖动范围（像素）
    /// 例如: 3 表示点击位置在 ±3 像素范围内随机偏移
    var randomPositionJitter: Double = 0

    // MARK: - 计算属性

    /// 获取带随机波动的实际间隔时间（秒）
    func getRandomizedInterval() -> TimeInterval {
        let baseInterval = intervalMs / 1000.0
        let variance = baseInterval * (randomDelayPercent / 100.0)
        let randomOffset = Double.random(in: -variance...variance)
        return max(0.001, baseInterval + randomOffset) // 最小 1ms
    }

    /// 获取带随机抖动的实际点击位置
    func getRandomizedPosition() -> CGPoint {
        switch clickMode {
        case .followMouse:
            // 跟随鼠标模式，获取当前鼠标位置
            return NSEvent.mouseLocation

        case .fixed:
            // 固定位置 + 抖动
            let jitterX = Double.random(in: -randomPositionJitter...randomPositionJitter)
            let jitterY = Double.random(in: -randomPositionJitter...randomPositionJitter)

            return CGPoint(
                x: targetPosition.x + jitterX,
                y: targetPosition.y + jitterY
            )

        case .randomArea:
            // 随机区域内任意位置
            let minX = min(randomAreaTopLeft.x, randomAreaBottomRight.x)
            let maxX = max(randomAreaTopLeft.x, randomAreaBottomRight.x)
            let minY = min(randomAreaTopLeft.y, randomAreaBottomRight.y)
            let maxY = max(randomAreaTopLeft.y, randomAreaBottomRight.y)

            let randomX = Double.random(in: minX...maxX)
            let randomY = Double.random(in: minY...maxY)

            return CGPoint(x: randomX, y: randomY)
        }
    }

    // MARK: - 验证

    /// 验证配置是否有效
    func isValid() -> Bool {
        return intervalMs > 0 && clickCount >= 0
    }
}
