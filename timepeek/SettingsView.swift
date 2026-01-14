//
//  SettingsView.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
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
        ScrollView(.vertical) {
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
                        .onChange(of: localization.currentLanguage) { newValue in
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
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(currentTimestamp, forType: .string)
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
                                TextField("Search or type timezone...".localized, text: $timezoneSearchText)
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
                    Toggle("Smart Detect (Monitor Clipboard)".localized, isOn: $settings.isMonitoringEnabled)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
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
