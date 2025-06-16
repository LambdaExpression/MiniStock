//
//  ImageSequenceView.swift
//  miniStock
//
//  Created by meizu on 2025/6/12.
//
import SwiftUI
import Combine



struct ImageSequenceView: View {
    // 图片名称数组（包含resource文件夹路径）
    let imageNames: [String] = ["0","1", "2", "3", "4", "5", "6", "7", "8", "9","10","11", "12", "13", "14", "15", "16", "17", "18", "19","20","21", "22", "23", "24", "25", "26", "27", "28", "29","30","31", "32"]
    
    // 当前显示的图片索引
    @State private var currentIndex = 0
    
    // 动画计时器
    @State private var cancellable: AnyCancellable?
    
    // 每张图片显示的时间（秒）
    private let frameDuration: TimeInterval = 0.25
    
    var body: some View {
        VStack {
            // 显示当前图片
            Image(imageNames[currentIndex])
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: 20,
                    height: 20
                )
                .transition(.opacity) // 添加淡入淡出效果
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // 开始动画
    private func startAnimation() {
        // 创建计时器并存储cancellable
        cancellable = Timer.publish(every: frameDuration, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // 直接使用self，因为Timer已经在主线程上
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentIndex = (currentIndex + 1) % imageNames.count
                }
            }
    }
    
    // 停止动画
    private func stopAnimation() {
        cancellable?.cancel()
        cancellable = nil
    }
}
