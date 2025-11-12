//
//  ThemeManager.swift
//  AutoClicker
//
//  主题管理器
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "theme_system".localized
        case .light: return "theme_light".localized
        case .dark: return "theme_dark".localized
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "app_theme") ?? "system"
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
    }
}
