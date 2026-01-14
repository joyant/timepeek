//
//  PasteboardMonitorManager.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import Foundation
import Combine

class PasteboardMonitorManager {
    static let shared = PasteboardMonitorManager()
    
    let monitor = PasteboardMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 监听设置变化
        AppSettings.shared.$isMonitoringEnabled
            .sink { [weak self] enabled in
                if enabled {
                    self?.monitor.startMonitoring()
                } else {
                    self?.monitor.stopMonitoring()
                }
            }
            .store(in: &cancellables)
        
        // 应用启动时如果启用监听，则开始监控
        if AppSettings.shared.isMonitoringEnabled {
            monitor.startMonitoring()
        }
    }
}

