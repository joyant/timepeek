import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
    case portuguese = "pt-BR"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .japanese: return "日本語"
        case .portuguese: return "Português"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .simplifiedChinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .portuguese: return "🇧🇷"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("appLanguage") private var storedLanguage: String?
    @Published var currentLanguage: AppLanguage
    
    // 内存中缓存的 Bundle，用于即时切换
    private var bundle: Bundle?
    
    private init() {
        // 如果没有存储的语言偏好，则检测系统语言
        if let stored = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: stored) {
            currentLanguage = language
        } else {
            // 检测系统首选语言
            let systemLang = Locale.preferredLanguages.first ?? "en"
            if systemLang.starts(with: "zh") {
                currentLanguage = .simplifiedChinese
            } else if systemLang.starts(with: "ja") {
                currentLanguage = .japanese
            } else if systemLang.starts(with: "pt") {
                currentLanguage = .portuguese
            } else {
                currentLanguage = .english
            }
        }
        
        updateBundle()
    }
    
    func setLanguage(_ language: AppLanguage) {
        storedLanguage = language.rawValue
        currentLanguage = language
        updateBundle()
        // 发送通知让视图刷新
        objectWillChange.send()
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = nil
        }
    }
    
    func localizedString(_ key: String) -> String {
        let targetBundle = bundle ?? Bundle.main
        return targetBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// 方便 SwiftUI 使用的扩展
extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(self)
    }
}
