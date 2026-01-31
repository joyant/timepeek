//
//  SettingsView.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import SwiftUI

struct FocusAwareTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.focusRingType = .default
        textField.bezelStyle = .roundedBezel
        // 防止自动获取焦点
        textField.refusesFirstResponder = true
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        // 实时更新 placeholder，以支持动态语言切换
        if nsView.placeholderString != placeholder {
            nsView.placeholderString = placeholder
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue
        }
    }
}

struct SettingsView: View {
    // 移除 @ObservedObject，直接使用 @AppStorage 或在内部使用 @ObservedObject 监听单例
    // 为了确保视图刷新，我们直接观察单例对象
    @ObservedObject var settings = AppSettings.shared
    
    // 直接绑定 UserDefaults，绕过 AppSettings 中间层，确保状态同步
    @AppStorage("isMonitoringEnabled") private var isMonitoringEnabled: Bool = true
    
    @StateObject private var localization = LocalizationManager.shared
    @State private var currentTimestamp: String = ""
    @State private var timestampTimer: Timer?
    @State private var showMilliseconds: Bool = false
    @State private var timezoneSearchText: String = ""
    @State private var showTimezoneMenu: Bool = false
    
    let timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
    
    // 预设的日期格式选项
    let dateFormatOptions: [(label: String, format: String)] = [
        ("2024-01-15 14:30:00", "yyyy-MM-dd HH:mm:ss"),
        ("2024-01-15 14:30", "yyyy-MM-dd HH:mm"),
        ("2024-01-15", "yyyy-MM-dd"),
        ("01/15/2024 14:30:00", "MM/dd/yyyy HH:mm:ss"),
        ("01/15/2024 14:30", "MM/dd/yyyy HH:mm"),
        ("01/15/2024", "MM/dd/yyyy"),
        ("15/01/2024 14:30:00", "dd/MM/yyyy HH:mm:ss"),
        ("15/01/2024 14:30", "dd/MM/yyyy HH:mm"),
        ("15/01/2024", "dd/MM/yyyy"),
        ("Jan 15, 2024 14:30:00", "MMM dd, yyyy HH:mm:ss"),
        ("Jan 15, 2024 14:30", "MMM dd, yyyy HH:mm"),
        ("Jan 15, 2024", "MMM dd, yyyy"),
    ]
    
    var filteredTimezones: [String] {
        if timezoneSearchText.isEmpty {
            return []
        }
        return timezones.filter { $0.localizedCaseInsensitiveContains(timezoneSearchText) }.prefix(20).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 语言设置
            VStack(alignment: .leading, spacing: 6) {
                Text("Language".localized)
                    .font(.headline)
                HStack {
                    Text("Language".localized + ":")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $localization.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName.localized)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .onChange(of: localization.currentLanguage) { _, newValue in
                        localization.setLanguage(newValue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Real-time Preview".localized)
                    .font(.headline)
                Button(action: {
                    // 使用 PasteboardMonitorManager 执行复制，以避免触发自身监听
                    PasteboardMonitorManager.shared.monitor.copyToPasteboard(currentTimestamp)
                }) {
                    HStack {
                        Text("Current Timestamp:".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currentTimestamp)
                            .font(.system(.body, design: .monospaced))
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                Toggle("Show Milliseconds".localized, isOn: $showMilliseconds)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Preferences".localized)
                    .font(.headline)
                HStack {
                    Text("Date Format:".localized)
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $settings.dateFormat) {
                        ForEach(dateFormatOptions, id: \.format) { option in
                            Text(option.label).tag(option.format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Bubble Settings".localized)
                    .font(.headline)
                HStack {
                    Text("Auto-Hide:".localized)
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: Binding(
                        get: {
                            if let delay = settings.autoHideDelay {
                                return delay
                            }
                            return -1
                        },
                        set: { newValue in
                            if newValue == -1 {
                                settings.autoHideDelay = nil
                            } else {
                                settings.autoHideDelay = newValue
                            }
                        }
                    )) {
                        Text("10 seconds".localized).tag(10.0)
                        Text("20 seconds".localized).tag(20.0)
                        Text("30 seconds".localized).tag(30.0)
                        Text("40 seconds".localized).tag(40.0)
                        Text("50 seconds".localized).tag(50.0)
                        Text("60 seconds".localized).tag(60.0)
                        Text("Never Auto-Hide".localized).tag(-1.0)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Timezone Management".localized)
                    .font(.headline)
                HStack {
                    Text("Favorite Timezone:".localized)
                        .frame(width: 100, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                                FocusAwareTextField(placeholder: "Search or type timezone...".localized, text: $timezoneSearchText)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        if let matched = timezones.first(where: { $0.localizedCaseInsensitiveContains(timezoneSearchText) }) {
                                            settings.favoriteTimezone = matched
                                            timezoneSearchText = ""
                                        }
                                    }
                                
                                if !timezoneSearchText.isEmpty {
                                Button("Clear".localized) {
                                    timezoneSearchText = ""
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button("None".localized) {
                                settings.favoriteTimezone = nil
                                timezoneSearchText = ""
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if let currentTZ = settings.favoriteTimezone {
                            HStack {
                                Text("\("Current:".localized) \(currentTZ)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Remove".localized) {
                                    settings.favoriteTimezone = nil
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        if !timezoneSearchText.isEmpty && !filteredTimezones.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Suggestions:".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(filteredTimezones.prefix(5), id: \.self) { tz in
                                    Button(tz) {
                                        settings.favoriteTimezone = tz
                                        timezoneSearchText = ""
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Behavior Control".localized)
                    .font(.headline)
                HStack {
                    Text("Smart Detect (Monitor Clipboard)".localized)
                    Spacer()
                    Toggle("", isOn: $isMonitoringEnabled) // 绑定 @AppStorage 属性
                        .toggleStyle(.switch)
                        .tint(.blue) // 强制蓝色，解决视觉灰色问题
                        .onChange(of: isMonitoringEnabled) { _, newValue in
                            // 同步给 AppSettings.shared 以触发业务逻辑
                            settings.isMonitoringEnabled = newValue
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            Divider()
            
            // 底部退出按钮
            HStack {
                Spacer()
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text("Quit TimePeek".localized)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true) // 让高度根据内容自适应
        .background(Color.clear)
        .onAppear {
            updateTimestamp()
            timestampTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTimestamp()
            }
        }
        .onDisappear {
            timestampTimer?.invalidate()
        }
    }
    
    private func updateTimestamp() {
        currentTimestamp = TimeConverter.currentTimestamp(isMilliseconds: showMilliseconds)
    }
}
