//
//  LocalizationManager.swift
//  AutoClicker
//
//  本地化管理器
//

import SwiftUI

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            updateLocale()
        }
    }

    private var bundle: Bundle = Bundle.main

    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "zh-Hans"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .simplifiedChinese
        updateLocale()
    }

    private func updateLocale() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }

    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

// 便捷的本地化扩展
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(self)
    }
}
