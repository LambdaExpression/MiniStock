import SwiftUI
import Combine
import Foundation

// 股票信息结构体
struct StockInfo: Identifiable, Codable {
    var id: UUID?
    let code: String
    var name: String
    var currentPrice: String = "--"
    var changePercent: String = "--"
    var priceColor: Color = .primary
    var changeColor: Color = .primary
    
    init(code: String) {
        self.id = UUID()
        self.code = code
        self.name = ""
    }
    
    enum CodingKeys: CodingKey {
        case id, code, name, currentPrice, changePercent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        currentPrice = try container.decode(String.self, forKey: .currentPrice)
        changePercent = try container.decode(String.self, forKey: .changePercent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(code, forKey: .code)
        try container.encode(name, forKey: .name)
        try container.encode(currentPrice, forKey: .currentPrice)
        try container.encode(changePercent, forKey: .changePercent)
    }
}

// 任务栏显示选项
enum MenuBarDisplayOption: String, CaseIterable, Identifiable {
    case price = "价格"
    case changePercent = "涨跌幅"
    case both = "价格+涨跌幅"
    case woodfish = "敲木鱼"
    
    var id: String { self.rawValue }
}

// 添加 GBK 编码支持
extension String.Encoding {
    static let gbk: String.Encoding = {
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        return String.Encoding(rawValue: encoding)
    }()
}

class StockModel: ObservableObject {
    @Published var stockInfos: [StockInfo] = []
    @Published var stockCodes: String = "sh600000,sh600001"
    @Published var updateIntervalText: String = "5" // 字符串类型用于输入框
    @Published var isUpdating: Bool = false
    @Published var menuBarDisplayOption: MenuBarDisplayOption = .price
    @Published var woodfishInterval: Double = 1.0 // 木鱼敲打间隔（秒）
    @Published var woodfishAnimationIndex: Int = 0 // 木鱼动画索引
    
    private var timer: AnyCancellable?
    private var woodfishTimer: AnyCancellable?
    private let defaults = UserDefaults.standard
    
    
    // 木鱼动画帧
    private let woodfishFrames = ["🎵", "🎶", "🎵", "🎶", "🎼"]
    
    init() {
        // 从UserDefaults加载设置
        if let savedCodes = defaults.string(forKey: "stockCodes") {
            stockCodes = savedCodes
        }
        
        if let savedInterval = defaults.string(forKey: "updateInterval") {
            updateIntervalText = savedInterval
        } else {
            updateIntervalText = "5" // 默认值5秒
        }
        
        if let savedOption = defaults.string(forKey: "menuBarDisplayOption"),
           let option = MenuBarDisplayOption(rawValue: savedOption) {
            menuBarDisplayOption = option
        }
        
        // 初始化木鱼设置
        woodfishInterval = defaults.double(forKey: "woodfishInterval")
        if woodfishInterval <= 0 {
            woodfishInterval = 1.0 // 默认值1秒
        }
        
        // 初始化股票信息
        updateStockList()
        
    }
    
    // 更新股票列表
    func updateStockList() {
        // 清除现有股票信息
        stockInfos.removeAll()
        
        // 解析股票代码
        let codes = stockCodes.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // 创建股票信息对象
        for code in codes {
            stockInfos.append(StockInfo(code: code))
        }
        
        // 保存设置
        saveSettings()
        
        // 如果选择了敲木鱼，开始动画
        if menuBarDisplayOption == .woodfish {
            startWoodfishAnimation()
        }
    }
    
    // 开始更新股票数据
    func startUpdating() {
        guard !stockInfos.isEmpty else { return }
        
        // 验证更新间隔
        let interval = Int(updateIntervalText) ?? 5
        if interval < 1 {
            updateIntervalText = "1" // 确保最小值为1
        }
        
        if menuBarDisplayOption == .woodfish {
            startWoodfishAnimation()
        }
        
        isUpdating = true
        fetchStockData()
        
        timer = Timer.publish(every: TimeInterval(interval), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchStockData()
            }
    }
    
    // 停止更新
    func stopUpdating() {
        isUpdating = false
        timer?.cancel()
        stopWoodfishAnimation()
    }
    
    func stopApp(){
        NSApplication.shared.terminate(nil)
    }
    
    // 开始木鱼动画
    func startWoodfishAnimation() {
        stopWoodfishAnimation()
        
        woodfishTimer = Timer.publish(every: woodfishInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateWoodfishAnimation()
            }
    }
    
    // 停止木鱼动画
    func stopWoodfishAnimation() {
        woodfishTimer?.cancel()
    }
    
    // 更新木鱼动画
    private func updateWoodfishAnimation() {
        woodfishAnimationIndex = (woodfishAnimationIndex + 1) % woodfishFrames.count
    }
    
    // 获取当前木鱼动画帧
    func currentWoodfishFrame() -> String {
        return woodfishFrames[woodfishAnimationIndex]
    }
    
    // 获取股票数据
    private func fetchStockData() {
        guard !stockInfos.isEmpty else { return }
        
        let codes = stockInfos.map(\.code).joined(separator: ",")
        guard let url = URL(string: "https://qt.gtimg.cn/q=\(codes)") else {
            print("无效的URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("请求错误: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("未收到数据")
                return
            }
            
            // 尝试多种编码解析
            let encodings: [String.Encoding] = [.gbk, .utf8, .ascii, .isoLatin1]
            var decodedString: String?
            
            for encoding in encodings {
                if let string = String(data: data, encoding: encoding) {
                    decodedString = string
//                    print("使用 \(encoding) 编码成功解析")
                    break
                }
            }
            
            guard let responseString = decodedString else {
                print("无法解析响应数据")
                return
            }
            
            // 解析多股票数据
            self.parseStockData(responseString)
        }.resume()
    }
    
    // 解析股票数据
    private func parseStockData(_ response: String) {
        // 使用正则表达式提取股票数据
        let pattern = "v_([a-z0-9]+)=\"([^\"]+)\""
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: response, options: [], range: NSRange(response.startIndex..., in: response))
        
        var parsedStockData: [String: (name: String, price: String, percent: String, color: Color)] = [:]
        
        matches?.forEach { match in
            if let codeRange = Range(match.range(at: 1), in: response),
               let dataRange = Range(match.range(at: 2), in: response) {
                
                let code = String(response[codeRange])
                let data = String(response[dataRange])
                let fields = data.split(separator: "~")
                
                // 确保有足够的字段
                if fields.count >= 32 {
                    let name = String(fields[1])
                    let price = String(fields[3])
                    let close = String(fields[4]) // 前收盘价
                    
                    // 计算涨跌幅
                    if let current = Double(price), let prevClose = Double(close) {
                        let change = current - prevClose
                        let percent = (change / prevClose) * 100
                        
                        // 修复：显式指定Color命名空间
                        let color = percent > 0 ? Color.red: (percent < 0 ? Color.green : Color.primary)
                        
                        parsedStockData[code] = (name, price, String(format: "%.2f%%", percent), color)
//                        print("成功解析股票: \(name) (\(code)) - 价格: \(price), 涨跌幅: \(percent)%")
                    }
                }
            }
        }
        
        // 如果没有匹配到数据，尝试备用方法
        if parsedStockData.isEmpty {
            print("使用备用方法解析数据")
            let stockDataStrings = response.components(separatedBy: ";").filter { $0.contains("v_") && $0.contains("=\"") }
            
            for stockData in stockDataStrings {
                if let parts = stockData.components(separatedBy: "=").last?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
                   let code = stockData.components(separatedBy: "_").last?.components(separatedBy: "=").first {
                    
                    let fields = parts.split(separator: "~")
                    
                    if fields.count >= 32 {
                        let name = String(fields[1])
                        let price = String(fields[3])
                        let close = String(fields[4]) // 前收盘价
                        
                        if let current = Double(price), let prevClose = Double(close) {
                            let change = current - prevClose
                            let percent = (change / prevClose) * 100
                            
                            // 修复：显式指定Color命名空间
                            let color = percent > 0 ? Color.red : (percent < 0 ? Color.green : Color.primary)
                            
                            parsedStockData[code] = (name, price, String(format: "%.2f%%", percent), color)
//                            print("成功解析股票: \(name) (\(code)) - 价格: \(price), 涨跌幅: \(percent)%")
                        }
                    }
                }
            }
        }
        
        // 更新股票数据（在主线程）
        DispatchQueue.main.async {
            var updatedStocks: [StockInfo] = []
            
            // 处理每只股票
            for stock in self.stockInfos {
                // 尝试匹配完整代码
                if let data = parsedStockData[stock.code] {
                    var updatedStock = stock
                    updatedStock.name = data.name
                    updatedStock.currentPrice = data.price
                    updatedStock.changePercent = data.percent
                    updatedStock.priceColor = data.color
                    updatedStock.changeColor = data.color
                    updatedStocks.append(updatedStock)
                } else {
                    // 保留原有信息
                    updatedStocks.append(stock)
                }
            }
            
            self.stockInfos = updatedStocks
//            print("更新后股票数量: \(self.stockInfos.count)")
        }
    }
    
    // 保存设置
    private func saveSettings() {
        defaults.set(stockCodes, forKey: "stockCodes")
        defaults.set(updateIntervalText, forKey: "updateInterval")
        defaults.set(menuBarDisplayOption.rawValue, forKey: "menuBarDisplayOption")
    }
    
}
