//
//  BubbleWindowManager.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import AppKit
import SwiftUI
import Combine

// 自定义窗口类，允许无边框窗口成为 key window 并支持拖动
class BubbleWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    // 允许拖动背景
    override var isMovableByWindowBackground: Bool {
        get { return true }
        set { super.isMovableByWindowBackground = newValue }
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
        // let menuBarHeight: CGFloat = 22 // 预估高度，实际上 visibleFrame.maxY 已经扣除了菜单栏
        
        // 计算窗口尺寸 - 高度紧凑一点
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 300 // 减小高度，避免留白
        
        var x: CGFloat
        var y: CGFloat
        
        // 移除位置记忆功能，统一固定在屏幕右上角
        // 默认位置：距离顶部 50px，距离右侧 50px
        // 注意 macOS 坐标系原点在左下角
        // visibleFrame.maxY 是屏幕可用区域顶部（菜单栏下方）
        // 所以 y = visibleFrame.maxY - 50 (顶部间距) - windowHeight
        x = screenRect.maxX - windowWidth - 50
        y = screenRect.maxY - 50 - windowHeight
        
        // 创建自定义窗口
        let window = BubbleWindow(
            contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
            styleMask: [.borderless], // 无边框
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
        window.isMovable = true // 显式允许移动，配合 isMovableByWindowBackground
        
        // 创建气泡视图
        let bubble = BubbleView(
            timestamp: timestamp,
            isMilliseconds: isMilliseconds,
            detectedDate: detectedDate,
            settings: settings,
            monitor: monitor,
            onClose: { [weak self, weak monitor] in
                // 动画已在 BubbleView 内部播放完毕，这里只负责最终关闭窗口
                self?.bubbleWindow?.close()
                self?.bubbleWindow = nil
                // 清除粘贴板内容记录，允许再次显示相同内容
                monitor?.clearLastContent()
            },
            onClosingStart: { [weak self] in
                // 动画开始时，移除系统阴影，防止透明内容导致阴影残留
                self?.bubbleWindow?.hasShadow = false
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

