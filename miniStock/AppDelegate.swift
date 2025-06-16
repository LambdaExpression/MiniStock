//
//  AppDelegate.swift
//  miniStock
//
//  Created by meizu on 2025/6/11.
//import Cocoa
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 配置应用设置
        NSApp.setActivationPolicy(.accessory)
        
        // 设置应用窗口样式，避免振动效果问题
        if let window = NSApp.windows.first {
            window.styleMask.remove(.fullSizeContentView)
            window.isOpaque = true
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 保存应用状态
    }
}

