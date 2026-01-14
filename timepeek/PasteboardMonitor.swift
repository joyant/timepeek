//
//  PasteboardMonitor.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import AppKit
import Combine

struct TimestampInfo: Equatable {
    let timestamp: TimeInterval
    let isMilliseconds: Bool
    
    static func == (lhs: TimestampInfo, rhs: TimestampInfo) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.isMilliseconds == rhs.isMilliseconds
    }
}

class PasteboardMonitor: ObservableObject {
    @Published var lastPasteboardContent: String = ""
    @Published var detectedTimestamp: TimestampInfo? = nil
    @Published var detectedDate: Date? = nil
    
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var isMonitoring: Bool = false
    private var isInternalCopy: Bool = false  // 标记是否是内部复制操作
    private let bubbleManager = BubbleWindowManager.shared
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPasteboard() {
        // 如果正在执行内部复制操作，跳过检测
        guard !isInternalCopy else { return }
        
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        guard let string = pasteboard.string(forType: .string) else { return }
        
        // 如果内容相同，跳过检测（避免重复显示）
        // 注意：当气泡关闭时会调用 clearLastContent() 清除这个记录
        guard string != lastPasteboardContent else { return }
        
        lastPasteboardContent = string
        
        // 检测时间戳
        if let timestampInfo = TimeConverter.detectTimestamp(string) {
            let info = TimestampInfo(timestamp: timestampInfo.timestamp, isMilliseconds: timestampInfo.isMilliseconds)
            detectedTimestamp = info
            detectedDate = nil
            // 立即显示气泡
            bubbleManager.showBubble(
                timestamp: info.timestamp,
                isMilliseconds: info.isMilliseconds,
                detectedDate: nil,
                monitor: self
            )
            return
        }
        
        // 检测日期字符串
        if let date = TimeConverter.detectDateString(string) {
            detectedDate = date
            detectedTimestamp = nil
            // 立即显示气泡
            bubbleManager.showBubble(
                timestamp: date.timeIntervalSince1970,
                isMilliseconds: false,
                detectedDate: date,
                monitor: self
            )
            return
        }
        
        // 清空检测结果
        detectedTimestamp = nil
        detectedDate = nil
    }
    
    func clearLastContent() {
        // 清除最后的内容记录，允许再次检测相同内容
        lastPasteboardContent = ""
    }
    
    func copyToPasteboard(_ text: String) {
        // 验证文本是否有效
        guard !text.isEmpty && text != "Invalid date" && text != "Invalid format" else { return }
        
        // 确保在主线程执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.copyToPasteboard(text)
            }
            return
        }
        
        // 标记这是内部复制操作，避免触发监听
        isInternalCopy = true
        
        // 使用 autoreleasepool 确保对象生命周期正确
        autoreleasepool {
            // 创建新的字符串副本，避免引用问题
            let textCopy = String(text)
            
            // 安全地操作粘贴板
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            let success = pasteboard.setString(textCopy, forType: .string)
            
            if success {
                // 更新状态，这样下次检测时会跳过（因为内容相同）
                self.lastChangeCount = pasteboard.changeCount
                self.lastPasteboardContent = textCopy
            }
        }
        
        // 延迟重置标志，确保检测循环已经跳过这次变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isInternalCopy = false
        }
    }
}

