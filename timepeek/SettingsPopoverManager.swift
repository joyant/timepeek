import AppKit
import SwiftUI

class SettingsPopoverManager: NSObject, NSPopoverDelegate {
    static let shared = SettingsPopoverManager()
    
    private var popover: NSPopover?
    private var statusItemButton: NSStatusBarButton?
    
    private override init() {
        super.init()
    }
    
    func configure(with button: NSStatusBarButton) {
        self.statusItemButton = button
    }
    
    func toggle() {
        guard let button = statusItemButton else { return }
        
        if popover == nil {
            setupPopover()
        }
        
        guard let popover = popover else { return }
        
        if popover.isShown {
            close()
        } else {
            show(relativeTo: button)
        }
    }
    
    private func setupPopover() {
        let popover = NSPopover()
        popover.behavior = .transient // 点击外部自动关闭
        popover.animates = true
        popover.contentSize = NSSize(width: 480, height: 360) // 初始尺寸，会被 SettingsView 撑开或限制
        
        // 创建 SwiftUI 视图
        let settingsView = SettingsView(settings: AppSettings.shared)
        
        // 使用 NSHostingController 承载
        let hostingController = NSHostingController(rootView: settingsView)
        // 确保视图背景透明，利用 Popover 的材质
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        popover.contentViewController = hostingController
        popover.delegate = self
        
        self.popover = popover
    }
    
    private func show(relativeTo button: NSStatusBarButton) {
        // 强制激活应用，确保 Popover 能获取焦点
        NSApp.activate(ignoringOtherApps: true)
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    func close() {
        popover?.performClose(nil)
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        // Popover 关闭后的清理工作（如果需要）
    }
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true // 允许拖拽分离变成独立窗口（可选，通常设为 true 更有趣，设为 false 则固定）
    }
}
