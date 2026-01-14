//
//  CountdownTimer.swift
//  timepeek
//
//  Created by xyz on 2026/1/12.
//

import Foundation
import Combine

class CountdownTimer: ObservableObject {
    @Published var progress: Double = 1.0
    @Published var isPaused: Bool = false
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedProgress: Double = 1.0
    private let duration: Double
    private let onComplete: () -> Void
    
    init(duration: Double, onComplete: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
    }
    
    func start() {
        progress = 1.0
        pausedProgress = 1.0
        startTime = Date()
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            
            guard let start = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            let remaining = max(0, self.duration - elapsed)
            let newProgress = remaining / self.duration
            
            DispatchQueue.main.async {
                self.progress = newProgress
                self.pausedProgress = newProgress
                
                if newProgress <= 0 {
                    self.stop()
                    self.onComplete()
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func pause() {
        isPaused = true
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            pausedProgress = max(0, (duration - elapsed) / duration)
        }
    }
    
    func resume() {
        if isPaused {
            isPaused = false
            let remaining = pausedProgress * duration
            startTime = Date().addingTimeInterval(-(duration - remaining))
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

