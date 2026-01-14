//
//  BubbleView.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import SwiftUI

// 可复制的行组件，支持hover效果和整行点击
struct CopyableRow: View {
    let text: String
    let onCopy: () -> Void
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: onCopy) {
            HStack {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovering ? Color.gray.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct BubbleView: View {
    let timestamp: TimeInterval
    let isMilliseconds: Bool
    let detectedDate: Date?
    @ObservedObject var settings: AppSettings
    @ObservedObject var monitor: PasteboardMonitor  // 使用全局单例，不会被释放
    var onClose: (() -> Void)?
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text("TimePeek".localized)
                    .font(.headline)
                Spacer()
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
                
                Divider()
                
                if let date = detectedDate {
                    // 显示日期对应的时间戳
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timestamp:".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(TimeConverter.dateToTimestampString(date, isMilliseconds: false))
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button("Copy".localized) {
                                let timestampStr = TimeConverter.dateToTimestampString(date, isMilliseconds: false)
                                if !timestampStr.isEmpty {
                                    monitor.copyToPasteboard(timestampStr)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        HStack {
                            Text(TimeConverter.dateToTimestampString(date, isMilliseconds: true) + " (ms)".localized)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button("Copy".localized) {
                                let timestampStr = TimeConverter.dateToTimestampString(date, isMilliseconds: true)
                                if !timestampStr.isEmpty {
                                    monitor.copyToPasteboard(timestampStr)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    // 显示时间戳对应的日期
                    VStack(alignment: .leading, spacing: 8) {
                        // UTC 时间
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UTC".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            CopyableRow(
                                text: TimeConverter.timestampToDateString(
                                    timestamp,
                                    format: settings.dateFormat,
                                    timeZone: TimeZone(identifier: "UTC") ?? TimeZone.current
                                ),
                                onCopy: {
                                    guard let utcTimeZone = TimeZone(identifier: "UTC") else { return }
                                    let formatted = TimeConverter.timestampToDateString(
                                        timestamp,
                                        format: settings.dateFormat,
                                        timeZone: utcTimeZone
                                    )
                                    if !formatted.isEmpty && formatted != "Invalid date" {
                                        monitor.copyToPasteboard(formatted)
                                    }
                                }
                            )
                        }
                        
                        Divider()
                        
                        // 本地时间
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\("Local (".localized)\(TimeZone.current.identifier))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            CopyableRow(
                                text: TimeConverter.timestampToDateString(
                                    timestamp,
                                    format: settings.dateFormat,
                                    timeZone: TimeZone.current
                                ),
                                onCopy: {
                                    let formatted = TimeConverter.timestampToDateString(
                                        timestamp,
                                        format: settings.dateFormat,
                                        timeZone: TimeZone.current
                                    )
                                    if !formatted.isEmpty && formatted != "Invalid date" {
                                        monitor.copyToPasteboard(formatted)
                                    }
                                }
                            )
                        }
                        
                        // 常用时区
                        if let favoriteTZ = settings.getFavoriteTimeZone() {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(favoriteTZ.identifier)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(TimeConverter.timestampToDateString(
                                    timestamp,
                                    format: settings.dateFormat,
                                    timeZone: favoriteTZ
                                ))
                                .font(.system(.body, design: .monospaced))
                            }
                        }
                        
                        // 时间戳信息
                        Divider()
                        HStack(alignment: .center) {
                            Text("Timestamp: \(String(format: "%.0f", isMilliseconds ? timestamp * 1000 : timestamp))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if isMilliseconds {
                                Text("(ms)".localized)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Spacer()

                            // 倒计时圆圈（与Timestamp对齐）
                            if let delay = settings.autoHideDelay {
                                CountdownCircle(duration: delay, isPaused: isHovering) {
                                    // 倒计时完成，关闭气泡并清除粘贴板内容记录
                                    monitor.clearLastContent()
                                    onClose?()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .frame(width: 320)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

