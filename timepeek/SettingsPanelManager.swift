import AppKit
import SwiftUI

final class SettingsPanelManager: NSObject {
    static let shared = SettingsPanelManager()
    
    private var panel: NSPanel?
    private var clickOutsideMonitor: Any?
    private let yOffset: CGFloat = 6
    private let contentSize = NSSize(width: 480, height: 360)
    private var ignoreOutsideClicksUntil: TimeInterval = 0
    
    private override init() {
        super.init()
    }
    
    func toggle(anchorFrame: NSRect?) {
        if let panel, panel.isVisible {
            close()
            return
        }
        
        show(anchorFrame: anchorFrame)
    }
    
    func close() {
        panel?.orderOut(nil)
        removeClickOutsideMonitor()
    }
    
    private func show(anchorFrame: NSRect?) {
        if panel == nil {
            let settingsView = SettingsView(settings: AppSettings.shared)
            let hostingView = NSHostingView(rootView: settingsView)
            hostingView.frame = NSRect(origin: .zero, size: contentSize)
            hostingView.autoresizingMask = [.width, .height]
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            
            let effectView = NSVisualEffectView(frame: hostingView.bounds)
            effectView.autoresizingMask = [.width, .height]
            effectView.material = .popover
            effectView.blendingMode = .withinWindow
            effectView.state = .active
            effectView.wantsLayer = true
            // effectView.layer?.cornerRadius = 20
            // effectView.layer?.cornerCurve = .continuous
            // effectView.layer?.masksToBounds = true
            effectView.addSubview(hostingView)
            
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: contentSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isReleasedWhenClosed = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.level = .popUpMenu
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hidesOnDeactivate = false
            panel.isMovable = false
            panel.isMovableByWindowBackground = false
            panel.contentView = effectView
            
            self.panel = panel
            
            // 监听应用失活事件
            NotificationCenter.default.addObserver(self, selector: #selector(handleAppResignActive), name: NSApplication.didResignActiveNotification, object: nil)
        }
        
        guard let panel else { return }
        
        let (x, y) = calculatePanelPosition(anchorFrame: anchorFrame, size: contentSize)
        panel.setFrame(NSRect(x: x, y: y, width: contentSize.width, height: contentSize.height), display: false)
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        
        ignoreOutsideClicksUntil = CACurrentMediaTime() + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.setupClickOutsideMonitor()
        }
    }
    
    private func calculatePanelPosition(anchorFrame: NSRect?, size: NSSize) -> (x: CGFloat, y: CGFloat) {
        let screen: NSScreen?
        if let anchorFrame {
            screen = NSScreen.screens.first { $0.frame.intersects(anchorFrame) }
        } else {
            let mouseLocation = NSEvent.mouseLocation
            screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        }
        
        guard let screen else { return (0, 0) }
        let visible = screen.visibleFrame
        
        var x: CGFloat
        var y: CGFloat
        
        if let anchorFrame {
            x = anchorFrame.midX - size.width / 2
            x = min(max(x, visible.minX), visible.maxX - size.width)
            
            y = anchorFrame.minY - size.height + yOffset
            if y < visible.minY {
                y = min(anchorFrame.maxY - yOffset, visible.maxY - size.height)
            }
        } else {
            x = visible.maxX - size.width
            y = visible.maxY - size.height
        }
        
        return (x, y)
    }
    
    @objc private func handleAppResignActive() {
        if let panel, panel.isVisible {
            close()
        }
    }
    
    private func setupClickOutsideMonitor() {
        removeClickOutsideMonitor()
        
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            if CACurrentMediaTime() < self.ignoreOutsideClicksUntil {
                return
            }
            let location = NSEvent.mouseLocation
            if !panel.frame.contains(location) {
                self.close()
            }
        }
    }
    
    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
}
