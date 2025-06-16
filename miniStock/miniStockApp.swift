//
//  miniStockApp.swift
//  miniStock
//
//  Created by meizu on 2025/6/11.
//
import SwiftUI

@main
struct miniStockApp: App {
    @StateObject private var stockModel = StockModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra(content: {
            ContentView(stockModel: stockModel)
        }, label: {
            // 任务栏显示
            if !stockModel.stockInfos.isEmpty {
                let stock = stockModel.stockInfos.first!
                
                switch stockModel.menuBarDisplayOption {
                case .price:
                    Text(stock.currentPrice)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(stock.priceColor)
                case .changePercent:
                    Text(stock.changePercent)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(stock.changeColor)
                case .both:
                    Text("\(stock.currentPrice) \(stock.changePercent)")
                        .font(.system(size: 12, weight: .medium))
                case .woodfish:
                    // 木鱼动画在任务栏显示
                    ImageSequenceView()
                }
            } else {
                Text("多股票监控")
                    .font(.system(size: 12, weight: .medium))
            }
        })
        .menuBarExtraStyle(.window)
    }
}
