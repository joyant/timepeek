//
//  BubbleWindowManager.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import AppKit
import SwiftUI
import Combine

// 自定义窗口类，允许无边框窗口成为 key window
class BubbleWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

class BubbleWindowManager: ObservableObject {
    static let shared = BubbleWindowManager()
    
    private var bubbleWindow: NSWindow?
    private var bubbleTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let settings = AppSettings.shared
    
    private init() {
    }
    
    func showBubble(timestamp: TimeInterval, isMilliseconds: Bool, detectedDate: Date?, monitor: PasteboardMonitor) {
        // 确保在主线程执行
        if Thread.isMainThread {
            displayBubble(timestamp: timestamp, isMilliseconds: isMilliseconds, detectedDate: detectedDate, monitor: monitor)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.displayBubble(timestamp: timestamp, isMilliseconds: isMilliseconds, detectedDate: detectedDate, monitor: monitor)
            }
        }
    }
    
    private func displayBubble(timestamp: TimeInterval, isMilliseconds: Bool, detectedDate: Date?, monitor: PasteboardMonitor) {
        // 关闭之前的窗口
        bubbleWindow?.close()
        bubbleTimer?.invalidate()
        
        // 获取屏幕尺寸和菜单栏位置
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let menuBarHeight: CGFloat = 22
        
        // 计算窗口位置（右上角，菜单栏下方）
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 400
        let x = screenRect.maxX - windowWidth - 20
        let y = screenRect.maxY - menuBarHeight - windowHeight - 10
        
        // 创建自定义窗口
        let window = BubbleWindow(
            contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false  // 防止窗口被过早释放
        
        // 创建气泡视图
        let bubble = BubbleView(
            timestamp: timestamp,
            isMilliseconds: isMilliseconds,
            detectedDate: detectedDate,
            settings: settings,
            monitor: monitor,
            onClose: { [weak self, weak monitor] in
                self?.bubbleWindow?.close()
                self?.bubbleWindow = nil
                // 清除粘贴板内容记录，允许再次显示相同内容
                monitor?.clearLastContent()
            }
        )
        
        let hostingView = NSHostingView(rootView: bubble)
        hostingView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        window.contentView = hostingView
        
        // 只显示窗口，不尝试成为 key window（避免警告）
        window.orderFront(nil)
        
        // 激活应用（确保窗口可以显示）
        NSApp.activate(ignoringOtherApps: true)
        
        bubbleWindow = window
        
        // 注意：自动隐藏现在由 BubbleView 中的 CountdownCircle 管理
        // 不再需要在这里设置 Timer
    }
    
    func hideBubble() {
        bubbleWindow?.close()
        bubbleWindow = nil
        bubbleTimer?.invalidate()
    }
}

