//
//  timepeekApp.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import SwiftUI
import AppKit

@main
struct timepeekApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        _ = PasteboardMonitorManager.shared
        
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "TimePeek")
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // 配置 Popover 管理器
            SettingsPopoverManager.shared.configure(with: button)
        }
        statusItem = item
    }
    
    @objc private func handleStatusItemClick(_ sender: Any?) {
        SettingsPopoverManager.shared.toggle()
    }
}
