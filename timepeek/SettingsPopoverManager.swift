import AppKit
import SwiftUI

class SettingsPopoverManager: NSObject, NSPopoverDelegate {
    static let shared = SettingsPopoverManager()
    
    // 将 popover 声明为 lazy var 或在 toggle 中确保每次都检查
    // 这里保持强引用，避免被意外释放
    private var popover: NSPopover?
    private var statusItemButton: NSStatusBarButton?
    private var eventMonitor: Any? // 添加事件监听器
    
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
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: 480, height: 360)
        
        // 创建 SwiftUI 视图
        let settingsView = SettingsView()
        
        // 使用 NSHostingController 承载
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        popover.contentViewController = hostingController
        popover.delegate = self
        
        self.popover = popover
    }
    
    private func show(relativeTo button: NSStatusBarButton) {
        // 强制激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        let adjustedRect = NSRect(x: button.bounds.minX, y: button.bounds.maxY + 10, width: button.bounds.width, height: 0)
        popover?.show(relativeTo: adjustedRect, of: button, preferredEdge: .minY)
        
        // 添加全局点击监听，辅助关闭 (双重保障)
        if eventMonitor == nil {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let strongSelf = self, let popover = strongSelf.popover, popover.isShown {
                    strongSelf.close()
                }
            }
        }
    }
    
    func close() {
        popover?.close() // 直接使用 close() 而不是 performClose()，更强制
        
        // 移除监听器
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        // Popover 关闭后的清理工作（如果需要）
    }
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true // 允许拖拽分离变成独立窗口（可选，通常设为 true 更有趣，设为 false 则固定）
    }
}
