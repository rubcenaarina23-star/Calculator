import SwiftUI
import Combine

struct HistoryItem: Identifiable {
    let id = UUID()
    let equation: String
}

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var display: String = "0"
    @Published var currentExpression: String = ""  // ← Новое: текущая операция
    @Published var history: [HistoryItem] = []
    
    private var firstOperand: Double = 0
    private var operation: String?
    private var isNewInput: Bool = true
    
    func inputDigit(_ digit: String) {
        if isNewInput { display = digit; isNewInput = false }
        else { display = display == "0" ? digit : display + digit }
    }
    
    func setOperation(_ op: String) {
        if let currentOp = operation, !isNewInput { calculate() }
        firstOperand = Double(display) ?? 0
        operation = op
        isNewInput = true
        currentExpression = "\(display) \(op)"  // ← Показываем операцию
    }
    
    func calculate() {
        guard let op = operation else { return }
        let second = Double(display) ?? 0
        var result: Double = 0
        
        switch op {
        case "+": result = firstOperand + second
        case "-": result = firstOperand - second
        case "×": result = firstOperand * second
        case "÷": result = second != 0 ? firstOperand / second : 0
        default: break
        }
        
        let resultStr = String(result)
        currentExpression = "\(firstOperand) \(op) \(second)"  // ← Показываем полное выражение
        history.insert(HistoryItem(equation: "\(currentExpression) = \(resultStr)"), at: 0)
        display = resultStr
        firstOperand = result
        operation = nil
        isNewInput = true
    }
    
    func clear() {
        display = "0"
        firstOperand = 0
        operation = nil
        isNewInput = true
        currentExpression = ""  // ← Очищаем выражение
    }
    func toggleSign() { if let val = Double(display) { display = "\(-val)" } }
    func percent() { if let val = Double(display) { display = "\(val / 100)" } }
}

enum ButtonRole { case digit, operation, function }

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @State private var showHistory = false
    
    let buttons: [[(String, ButtonRole)]] = [
        [("C", .function), ("±", .function), ("%", .function), ("÷", .operation)],
        [("7", .digit), ("8", .digit), ("9", .digit), ("×", .operation)],
        [("4", .digit), ("5", .digit), ("6", .digit), ("-", .operation)],
        [("1", .digit), ("2", .digit), ("3", .digit), ("+", .operation)],
        [("0", .digit), (".", .digit), ("=", .operation)]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // History button
            HStack { Spacer()
                Button(showHistory ? "Скрыть" : "История") {
                    withAnimation { showHistory.toggle() }
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            
            // History with nice dark gray background
            if showHistory {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.history) { item in
                            Text(item.equation)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.4))
                                .cornerRadius(8)
                        }
                        if viewModel.history.isEmpty {
                            Text("История пуста")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 150)
                .background(Color.gray.opacity(0.2))  // ← Приятный тёмно-серый
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Current expression (what you're typing)
            Text(viewModel.currentExpression.isEmpty ? " " : viewModel.currentExpression)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
            
            // Display (result)
            Text(viewModel.display)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            
            // Buttons
            ForEach(0..<buttons.count, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<buttons[row].count, id: \.self) { col in
                        let (title, role) = buttons[row][col]
                        
                        Button(action: {
                            handleButton(title, role)
                        }) {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(buttonColor(role))
                                .clipShape(Circle())
                                .contentShape(Circle())  // ← ПОСЛЕ clipShape!
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
    
    private func buttonColor(_ role: ButtonRole) -> Color {
        switch role {
        case .digit: return Color.gray.opacity(0.6)
        case .operation: return .orange
        case .function: return Color.gray.opacity(0.4)
        }
    }
    
    private func handleButton(_ title: String, _ role: ButtonRole) {
        switch title {
        case "C": viewModel.clear()
        case "±": viewModel.toggleSign()
        case "%": viewModel.percent()
        case "+", "-", "×", "÷": viewModel.setOperation(title)
        case "=": viewModel.calculate()
        case ".": viewModel.inputDigit(".")
        default: viewModel.inputDigit(title)
        }
    }
}
