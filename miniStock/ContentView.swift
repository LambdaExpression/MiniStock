//
//  ContentView.swift
//  miniStock
//
//  Created by meizu on 2025/6/11.
//
import SwiftUI

struct ContentView: View {
    @ObservedObject var stockModel: StockModel
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 网格布局配置
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("多股票监控")
                .font(.headline)
                .padding(.leading,14)
            
            // 股票信息显示区域 - 限制为3行，超出部分可滚动
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(stockModel.stockInfos) { stock in
                        StockCardView(stock: stock)
                            .padding(.bottom, 8)
                    }
                    
                    // 如果没有股票数据，显示提示
                    if stockModel.stockInfos.isEmpty {
                        Text("未找到股票数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                            .gridCellColumns(3)
                    }
                }
                .padding(.horizontal)
            }
            .frame(minHeight:150, maxHeight: 400) // 限制最大高度，确保最多显示3行
            
            Divider()
            
            // 设置区域
            VStack(alignment: .leading, spacing: 16) {
                Text("设置")
                    .font(.headline)
                
                // 股票代码输入
                HStack {
                    Text("股票代码:")
                        .frame(width: 80, alignment: .leading)
                    TextField("sh600000,sh600001", text: $stockModel.stockCodes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: stockModel.stockCodes) { newValue in
                            stockModel.stockCodes = newValue.replacingOccurrences(of: "，", with: ",")
                        }
                }
                
                // 更新间隔输入
                HStack {
                    Text("更新间隔(秒):")
                        .frame(width: 80, alignment: .leading)
                    TextField("5", text: $stockModel.updateIntervalText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: stockModel.updateIntervalText) { newValue in
                            // 过滤非数字字符
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                stockModel.updateIntervalText = filtered
                            }
                            
                            // 限制最大长度为3位
                            if stockModel.updateIntervalText.count > 3 {
                                stockModel.updateIntervalText = String(stockModel.updateIntervalText.prefix(3))
                            }
                            
                            // 确保值不小于1
                            if let value = Int(stockModel.updateIntervalText), value < 1 {
                                stockModel.updateIntervalText = "1"
                            }
                            
                            // 如果为空，设置为默认值1
                            if stockModel.updateIntervalText.isEmpty {
                                stockModel.updateIntervalText = "1"
                            }
                        }
                }
                
                // 任务栏显示选项（下拉框）
                HStack {
                    Picker("任务栏显示", selection: $stockModel.menuBarDisplayOption) {
                        ForEach(MenuBarDisplayOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                // 控制按钮
                HStack {
                    Button(action: {
                        if validateInput() {
                            stockModel.updateStockList()
                            stockModel.startUpdating()
                        }
                    }) {
                        Label("开始监控", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(stockModel.isUpdating)
                    
                    Button(action: stockModel.stopUpdating) {
                        Label("停止监控", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!stockModel.isUpdating)
                    
                    Button(action: stockModel.stopApp) {
                        Label("退出应用", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    Text(stockModel.isUpdating ? "监控中" : "已停止")
                        .font(.caption)
                        .foregroundColor(stockModel.isUpdating ? Color.green : Color.gray)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 2)
        }
        .padding(.vertical, 16)
        .frame(width: 400, height: 480)
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("输入错误"), message: Text(errorMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    // 验证输入
    private func validateInput() -> Bool {
        // 验证股票代码
        let codes = stockModel.stockCodes.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if codes.isEmpty {
            errorMessage = "请输入至少一个股票代码"
            showErrorAlert = true
            return false
        }
        
        // 验证更新间隔
        if let interval = Int(stockModel.updateIntervalText), interval < 1 {
            errorMessage = "更新间隔不能小于1秒"
            showErrorAlert = true
            return false
        }
        
        return true
    }
}

// 股票卡片视图组件
struct StockCardView: View {
    let stock: StockInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stock.currentPrice)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stock.priceColor)
                
                Spacer()
                
                Text(stock.changePercent)
                    .font(.system(size: 12))
                    .foregroundColor(stock.changeColor)
            }
            
            Text(stock.name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
