import SwiftUI

struct SmokeParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var speed: CGPoint
    var rotation: Double
    var rotationSpeed: Double
    let creationTime: TimeInterval
}

struct SmokeEffectView: View {
    @Binding var isActive: Bool
    let onCompletion: () -> Void
    
    @State private var particles: [SmokeParticle] = []
    @State private var startTime: TimeInterval = 0
    
    // 配置参数
    let particleCount = 200
    let duration: TimeInterval = 1.0 // 缩短动画时间，减少等待感
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                // 绘制所有粒子
                for particle in particles {
                    let timeAlive = now - particle.creationTime
                    if timeAlive > 0 && timeAlive < duration {
                        // 计算当前状态
                        let progress = timeAlive / duration
                        let easeOutProgress = 1 - pow(1 - progress, 3) // Cubic ease-out
                        
                        // 粒子向上飘散并扩散 - 速度稍微加快以适配更短的时间
                        // xOffset
                        let xOffset = particle.speed.x * CGFloat(easeOutProgress * 100) + sin(CGFloat(timeAlive) * 5 + particle.id.uuidString.hashValue.cgFloat) * 12
                        // yOffset: 向上漂移
                        let yOffset = particle.speed.y * CGFloat(easeOutProgress * 100) - CGFloat(pow(timeAlive, 1.2) * 80)
                        
                        let currentPos = CGPoint(
                            x: particle.position.x + xOffset,
                            y: particle.position.y + yOffset
                        )
                        
                        // 变化曲线优化 - 让消失更平滑但更干脆
                        let currentScale = particle.scale * (1.0 - CGFloat(progress) * 0.6)
                        let currentOpacity = particle.opacity * (1.0 - pow(progress, 0.5)) // 稍微加速透明度衰减
                        let currentRotation = particle.rotation + particle.rotationSpeed * timeAlive
                        
                        var drawingContext = context
                        drawingContext.opacity = currentOpacity
                        drawingContext.translateBy(x: currentPos.x, y: currentPos.y)
                        drawingContext.rotate(by: .degrees(currentRotation))
                        drawingContext.scaleBy(x: currentScale, y: currentScale)
                        
                        // 绘制烟雾/时间碎片粒子
                        let rect = CGRect(x: -2, y: -2, width: 4, height: 4)
                        let path = Path(ellipseIn: rect)
                        drawingContext.fill(path, with: .color(.white.opacity(0.6)))
                    }
                }
            }
        }
        .onChange(of: isActive) {
            if isActive {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        let now = Date().timeIntervalSinceReferenceDate
        startTime = now
        
        // 生成粒子
        var newParticles: [SmokeParticle] = []
        let center = CGPoint(x: 160, y: 120)
        
        for _ in 0..<particleCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let r = CGFloat.random(in: 0...1)
            let distance = (1 - r * r) * 120
            
            let randomPos = CGPoint(
                x: center.x + cos(angle) * distance * 1.2,
                y: center.y + sin(angle) * distance * 0.8
            )
            
            let particle = SmokeParticle(
                position: randomPos,
                scale: CGFloat.random(in: 0.2...1.2),
                opacity: Double.random(in: 0.2...0.6),
                speed: CGPoint(
                    x: CGFloat.random(in: -1.5...1.5), // 横向速度范围扩大 3 倍
                    y: CGFloat.random(in: -2.5...1.0)  // 纵向速度范围扩大
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10),
                creationTime: now + Double.random(in: 0...0.3)
            )
            newParticles.append(particle)
        }
        
        particles = newParticles
        
        // 动画结束后回调
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onCompletion()
        }
    }
}

extension Int {
    var cgFloat: CGFloat { CGFloat(self) }
}
