//
//  TimeConverter.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import Foundation

struct TimeConverter {
    /// 检测字符串是否为时间戳（10位秒或13位毫秒）
    static func detectTimestamp(_ text: String) -> (timestamp: TimeInterval, isMilliseconds: Bool)? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否为纯数字
        guard trimmed.allSatisfy({ $0.isNumber }) else { return nil }
        
        // 检查长度
        if trimmed.count == 10 {
            // 秒级时间戳
            guard let seconds = Double(trimmed) else { return nil }
            // 验证时间戳是否在合理范围内（1970-01-01 到 2100-01-01）
            let minTimestamp: TimeInterval = 0 // 1970-01-01
            let maxTimestamp: TimeInterval = 4102444800 // 2100-01-01
            guard seconds >= minTimestamp && seconds <= maxTimestamp else { return nil }
            return (seconds, false)
        } else if trimmed.count == 13 {
            // 毫秒级时间戳
            guard let milliseconds = Double(trimmed) else { return nil }
            let seconds = milliseconds / 1000.0
            // 验证时间戳是否在合理范围内（1970-01-01 到 2100-01-01）
            let minTimestamp: TimeInterval = 0 // 1970-01-01
            let maxTimestamp: TimeInterval = 4102444800 // 2100-01-01
            guard seconds >= minTimestamp && seconds <= maxTimestamp else { return nil }
            return (seconds, true)
        }
        
        return nil
    }
    
    /// 检测字符串是否为日期格式
    static func detectDateString(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 常见的日期格式
        let formatters: [DateFormatter] = [
            createFormatter("yyyy-MM-dd HH:mm:ss"),
            createFormatter("yyyy-MM-dd HH:mm"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("yyyy/MM/dd HH:mm:ss"),
            createFormatter("yyyy/MM/dd HH:mm"),
            createFormatter("yyyy/MM/dd"),
            createFormatter("MM/dd/yyyy HH:mm:ss"),
            createFormatter("MM/dd/yyyy HH:mm"),
            createFormatter("MM/dd/yyyy"),
            createFormatter("dd/MM/yyyy HH:mm:ss"),
            createFormatter("dd/MM/yyyy HH:mm"),
            createFormatter("dd/MM/yyyy"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ss"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ss'Z'"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
        ]
        
        for formatter in formatters {
            // 使用 isStrict 模式，确保完全匹配
            formatter.isLenient = false
            if let date = formatter.date(from: trimmed) {
                // 验证日期是否在合理范围内（1900-01-01 到 2100-01-01）
                let minDate = Date(timeIntervalSince1970: -2208988800) // 1900-01-01
                let maxDate = Date(timeIntervalSince1970: 4102444800) // 2100-01-01
                if date >= minDate && date <= maxDate {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    /// 将时间戳转换为日期字符串
    static func timestampToDateString(_ timestamp: TimeInterval, format: String, timeZone: TimeZone) -> String {
        // 验证时间戳是否有效
        guard timestamp.isFinite && !timestamp.isNaN else {
            return "Invalid date"
        }
        
        // 验证日期格式是否有效
        guard !format.isEmpty else {
            return "Invalid format"
        }
        
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // 尝试格式化，如果失败返回默认格式
        let result = formatter.string(from: date)
        // 验证结果是否有效（不应该为空或只包含格式字符）
        if result.isEmpty || result == format {
            // 如果格式化失败，使用默认格式
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
        
        return result
    }
    
    /// 将日期转换为时间戳字符串
    static func dateToTimestampString(_ date: Date, isMilliseconds: Bool) -> String {
        let timestamp = date.timeIntervalSince1970
        
        // 验证时间戳是否有效
        guard timestamp.isFinite && !timestamp.isNaN else {
            return "0"
        }
        
        if isMilliseconds {
            let ms = timestamp * 1000
            // 检查是否溢出
            guard ms.isFinite && !ms.isNaN else {
                return "0"
            }
            return String(format: "%.0f", ms)
        } else {
            return String(format: "%.0f", timestamp)
        }
    }
    
    /// 获取当前时间戳
    static func currentTimestamp(isMilliseconds: Bool) -> String {
        let timestamp = Date().timeIntervalSince1970
        if isMilliseconds {
            return String(format: "%.0f", timestamp * 1000)
        } else {
            return String(format: "%.0f", timestamp)
        }
    }
}

