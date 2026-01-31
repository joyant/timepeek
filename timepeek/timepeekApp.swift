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
            // 使用自定义绘制的图标
            button.image = createMenuBarIcon()
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // 配置 Popover 管理器
            SettingsPopoverManager.shared.configure(with: button)
        }
        statusItem = item
    }
    
    // 创建一个自定义的菜单栏图标：实心圆角矩形 + 时钟镂空
    // 这种实心风格（Dark Background）在 Light Mode 下是深色的，在 Dark Mode 下是白色的，符合 macOS 规范
    private func createMenuBarIcon() -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current?.cgContext
            
            // 1. 绘制背景：圆角矩形
            NSColor.black.setFill() // Template 模式下，黑色 = 前景色（随系统变色）
            let bgRect = NSRect(x: 2, y: 2, width: 18, height: 18)
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 4.5, yRadius: 4.5)
            bgPath.fill()
            
            // 2. 绘制镂空内容：时钟
            // 使用 .destinationOut 混合模式，将后续绘制的内容变成透明（即镂空）
            ctx?.setBlendMode(.destinationOut)
            NSColor.black.set() // 颜色不重要，只要有 Alpha 即可
            
            // 表盘圆圈
            let clockRect = NSRect(x: 5, y: 5, width: 12, height: 12)
            let clockPath = NSBezierPath(ovalIn: clockRect)
            clockPath.lineWidth = 1.2
            clockPath.stroke()
            
            // 指针
            let center = NSPoint(x: 11, y: 11)
            let handPath = NSBezierPath()
            handPath.move(to: center)
            handPath.line(to: NSPoint(x: 11, y: 15)) // 垂直向上
            handPath.move(to: center)
            handPath.line(to: NSPoint(x: 14, y: 11)) // 水平向右
            handPath.lineWidth = 1.2
            handPath.lineCapStyle = .round
            handPath.stroke()
            
            return true
        }
        image.isTemplate = true // 设置为模版图像，自动适应系统浅色/深色模式
        return image
    }
    
    @objc private func handleStatusItemClick(_ sender: Any?) {
        SettingsPopoverManager.shared.toggle()
    }
}
