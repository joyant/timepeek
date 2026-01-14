//
//  CountdownCircle.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import SwiftUI

struct CountdownCircle: View {
    let duration: Double
    var isPaused: Bool = false  // 从外部控制暂停状态
    let onComplete: () -> Void
    
    @StateObject private var timer: CountdownTimer
    
    init(duration: Double, isPaused: Bool = false, onComplete: @escaping () -> Void) {
        self.duration = duration
        self.isPaused = isPaused
        self.onComplete = onComplete
        _timer = StateObject(wrappedValue: CountdownTimer(duration: duration, onComplete: onComplete))
    }
    
    var body: some View {
        ZStack {
            // 背景圆圈（浅灰色）
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
            
            // 进度圆圈（深一点的颜色）
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timer.progress)
        }
        .frame(width: 18, height: 18)
        .onAppear {
            timer.start()
        }
        .onDisappear {
            timer.stop()
        }
        .onChange(of: isPaused) { oldValue, newValue in
            if newValue {
                timer.pause()
            } else {
                timer.resume()
            }
        }
    }
}

