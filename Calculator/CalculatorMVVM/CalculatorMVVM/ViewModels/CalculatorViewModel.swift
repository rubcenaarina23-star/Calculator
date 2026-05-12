import SwiftUI
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var display: String = "0"
    @Published var currentExpression: String = ""
    @Published var history: [HistoryItem] = []
    
    private var firstOperand: Double = 0
    private var operation: String?
    private var isNewInput: Bool = true
    
    func inputDigit(_ digit: String) {
        if isNewInput {
            display = digit
            isNewInput = false
        } else {
            display = display == "0" ? digit : display + digit
        }
    }
    
    func setOperation(_ op: String) {
        if operation != nil, !isNewInput {
            calculate()
        }
        firstOperand = Double(display) ?? 0
        operation = op
        isNewInput = true
        currentExpression = "\(display) \(op)"
    }
    
    func calculate() {
        guard let op = operation else { return }
        let second = Double(display) ?? 0
        var result: Double = 0
        
        switch op {
        case "+":
            result = firstOperand + second
        case "-":
            result = firstOperand - second
        case "×":
            result = firstOperand * second
        case "÷":
            result = second != 0 ? firstOperand / second : 0
        default:
            break
        }
        
        let resultStr = String(result)
        currentExpression = "\(firstOperand) \(op) \(second)"
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
        currentExpression = ""
    }
    
    func toggleSign() {
        if let val = Double(display) {
            display = "\(-val)"
        }
    }
    
    func percent() {
        if let val = Double(display) {
            display = "\(val / 100)"
        }
    }
}
