//
//  AppSettings.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var dateFormat: String {
        didSet {
            UserDefaults.standard.set(dateFormat, forKey: "dateFormat")
        }
    }
    
    @Published var isMonitoringEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMonitoringEnabled, forKey: "isMonitoringEnabled")
        }
    }
    
    @Published var autoHideDelay: Double? {
        didSet {
            if let delay = autoHideDelay {
                UserDefaults.standard.set(delay, forKey: "autoHideDelay")
            } else {
                UserDefaults.standard.removeObject(forKey: "autoHideDelay")
            }
        }
    }
    
    @Published var favoriteTimezone: String? {
        didSet {
            if let tz = favoriteTimezone {
                UserDefaults.standard.set(tz, forKey: "favoriteTimezone")
            } else {
                UserDefaults.standard.removeObject(forKey: "favoriteTimezone")
            }
        }
    }
    
    static let shared = AppSettings()
    
    private init() {
        self.dateFormat = UserDefaults.standard.string(forKey: "dateFormat") ?? "yyyy-MM-dd HH:mm:ss"
        self.isMonitoringEnabled = UserDefaults.standard.object(forKey: "isMonitoringEnabled") as? Bool ?? true
        if let delay = UserDefaults.standard.object(forKey: "autoHideDelay") as? Double {
            self.autoHideDelay = delay
        } else {
            self.autoHideDelay = 30.0 // 默认30秒
        }
        self.favoriteTimezone = UserDefaults.standard.string(forKey: "favoriteTimezone")
    }
    
    func getFavoriteTimeZone() -> TimeZone? {
        guard let tzIdentifier = favoriteTimezone else { return nil }
        return TimeZone(identifier: tzIdentifier)
    }
}

