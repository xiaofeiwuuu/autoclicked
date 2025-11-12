//
//  SettingsView.swift
//  AutoClicker
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("settings".localized)
                .font(.title2)
                .fontWeight(.bold)

            Form {
                // 语言设置
                Section {
                    Picker("language".localized, selection: $localizationManager.currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }

                // 主题设置
                Section {
                    Picker("theme".localized, selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 280, height: 180)

            // 关闭按钮
            Button("OK") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 320, height: 280)
    }
}
