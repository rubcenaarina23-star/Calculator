import SwiftUI
import Foundation
import Combine

// MARK: -  МОДЕЛЬ ИСТОРИИ
struct HistoryItem: Identifiable {
    let id = UUID()
    let equation: String
    let timestamp: Date
}

// MARK: -  SINGLETON (ДВИЖОК + ИСТОРИЯ)
@MainActor
final class CalculatorEngine: ObservableObject {
    static let shared = CalculatorEngine()
    private init() {}
    
    @Published var display: String = "0"
    @Published var history: [HistoryItem] = [] //  Новое: массив истории
    
    private var firstOperand: Double = 0
    private var operation: String?
    private var isNewInput: Bool = true
    private var currentEquation: String = "" //  Сборка строки уравнения
    
    func inputDigit(_ digit: String) {
        if isNewInput {
            display = digit
            isNewInput = false
            currentEquation = digit
        } else {
            display = display == "0" ? digit : display + digit
            currentEquation += digit
        }
    }
    
    func setOperation(_ op: String) {
        if let currentOp = operation, !isNewInput { calculate() }
        firstOperand = Double(display) ?? 0
        operation = op
        isNewInput = true
        currentEquation += " \(op) "
    }
    
    func calculate() {
        guard let op = operation else { return }
        let second = Double(display) ?? 0
        
        // Считаем результат
        var result: Double
        switch op {
        case "+": result = firstOperand + second
        case "-": result = firstOperand - second
        case "×": result = firstOperand * second
        case "÷": result = second != 0 ? firstOperand / second : .nan
        default: result = second
        }
        
        let resultStr = result.isNaN ? "Ошибка" : String(result)
        
        //  Формируем полное уравнение ПЕРЕД записью в историю
        let fullEquation = "\(String(firstOperand)) \(op) \(String(second)) = \(resultStr)"
        
        // Записываем в историю
        if !result.isNaN {
            history.insert(HistoryItem(equation: fullEquation, timestamp: Date()), at: 0)
        }
        
        display = resultStr
        firstOperand = result
        operation = nil
        isNewInput = true
        currentEquation = ""  // Сбрасываем
    }
    
    func clear() {
        display = "0"; firstOperand = 0; operation = nil
        isNewInput = true; currentEquation = ""
    }
    
    func clearEntry() {
        display = "0"; isNewInput = true
        // При CE обрезаем последний операнд из уравнения (упрощённо)
        if let lastSpace = currentEquation.lastIndex(of: " ") {
            currentEquation = String(currentEquation[..<lastSpace])
        } else {
            currentEquation = ""
        }
    }
    
    func percent() { if let val = Double(display) { display = "\(val / 100)" } }
    func toggleSign() { if let val = Double(display) { display = "\(-val)" } }
}

// MARK: -  PROTOTYPE
enum ButtonRole { case digit, operation, function }

class CalcButton {
    let title: String
    let role: ButtonRole
    let action: () -> Void
    
    init(title: String, role: ButtonRole, action: @escaping () -> Void) {
        self.title = title; self.role = role; self.action = action
    }
    func clone() -> CalcButton { CalcButton(title: title, role: role, action: action) }
}

// MARK: -  ABSTRACT FACTORY
protocol ButtonFactory {
    func create(title: String, role: ButtonRole, action: @escaping () -> Void) -> CalcButton
}

class StandardButtonFactory: ButtonFactory {
    func create(title: String, role: ButtonRole, action: @escaping () -> Void) -> CalcButton {
        CalcButton(title: title, role: role, action: action)
    }
}

// MARK: -  BUILDER
class CalculatorBuilder {
    private var rows: [[CalcButton]] = []
    private let factory: ButtonFactory
    
    init(factory: ButtonFactory) { self.factory = factory }
    
    func addRow(_ config: [(String, ButtonRole, () -> Void)]) -> CalculatorBuilder {
        rows.append(config.map { title, role, action in factory.create(title: title, role: role, action: action).clone() })
        return self
    }
    func build() -> [[CalcButton]] { rows }
}

// MARK: -  SWIFTUI ИНТЕРФЕЙС
struct CalculatorView: View {
    @StateObject private var engine = CalculatorEngine.shared
    @State private var buttonGrid: [[CalcButton]] = []
    @State private var showHistory = false //  Переключатель истории
    
    init() {
        let factory = StandardButtonFactory()
        let builder = CalculatorBuilder(factory: factory)
        let grid = builder
            .addRow([("C", .function, { CalculatorEngine.shared.clear() }),
                     ("±", .function, { CalculatorEngine.shared.toggleSign() }),
                     ("%", .function, { CalculatorEngine.shared.percent() }),
                     ("÷", .operation, { CalculatorEngine.shared.setOperation("÷") })])
            .addRow([("7", .digit, { CalculatorEngine.shared.inputDigit("7") }),
                     ("8", .digit, { CalculatorEngine.shared.inputDigit("8") }),
                     ("9", .digit, { CalculatorEngine.shared.inputDigit("9") }),
                     ("×", .operation, { CalculatorEngine.shared.setOperation("×") })])
            .addRow([("4", .digit, { CalculatorEngine.shared.inputDigit("4") }),
                     ("5", .digit, { CalculatorEngine.shared.inputDigit("5") }),
                     ("6", .digit, { CalculatorEngine.shared.inputDigit("6") }),
                     ("-", .operation, { CalculatorEngine.shared.setOperation("-") })])
            .addRow([("1", .digit, { CalculatorEngine.shared.inputDigit("1") }),
                     ("2", .digit, { CalculatorEngine.shared.inputDigit("2") }),
                     ("3", .digit, { CalculatorEngine.shared.inputDigit("3") }),
                     ("+", .operation, { CalculatorEngine.shared.setOperation("+") })])
            .addRow([("0", .digit, { CalculatorEngine.shared.inputDigit("0") }),
                     (".", .digit, { CalculatorEngine.shared.inputDigit(".") }),
                     ("=", .operation, { CalculatorEngine.shared.calculate() }),
                     ("", .function, {})])
            .build()
        _buttonGrid = State(initialValue: grid)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Верхняя панель с историей
            HStack {
                Spacer()
                Button(showHistory ? " Скрыть" : " История") {
                    withAnimation(.easeInOut(duration: 0.3)) { showHistory.toggle() }
                }
                .foregroundColor(.orange)
                .font(.subheadline)
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
            
            // Список истории (появляется с анимацией)
            if showHistory {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(engine.history) { item in
                            HistoryRow(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 180)
                .background(Color.gray)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Дисплей
            HStack {
                Spacer()
                Text(engine.display)
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal)
            .frame(height: 80, alignment: .trailing)
            
            // Кнопки
            VStack(spacing: 12) {
                ForEach(0..<buttonGrid.count, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<buttonGrid[row].count, id: \.self) { col in
                            let btn = buttonGrid[row][col]
                            if !btn.title.isEmpty {
                                CalcButtonView(title: btn.title, role: btn.role, action: btn.action)
                            } else {
                                Color.clear.frame(width: 70, height: 70)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

// Компонент строки истории
struct HistoryRow: View {
    let item: HistoryItem
    var body: some View {
        HStack {
            Text(item.equation)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Text(item.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Компонент кнопки
struct CalcButtonView: View {
    let title: String
    let role: ButtonRole
    let action: () -> Void
    
    var bgColor: Color {
        switch role {
        case .digit: return Color.gray
        case .operation: return Color.orange
        case .function: return Color.gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(role == .operation ? .regular : .medium)
                .foregroundColor(role == .operation ? .white : .black)
                .frame(width: 70, height: 70)
                .background(bgColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: -  Entry Point
struct CalculatorApp: App {
    var body: some Scene { WindowGroup { CalculatorView() } }
}
