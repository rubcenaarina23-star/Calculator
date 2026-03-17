import SwiftUI
import Combine

// MARK: - Calculator Logic (OOP Principles)
class CalculatorViewModel: ObservableObject {
    @Published var currentEntry: String = "0"
    @Published var previousEntry: Double?
    @Published var operation: String?
    @Published var history: [String] = []
    
    func inputNumber(_ number: String) {
        if currentEntry == "0" {
            currentEntry = number
        } else {
            currentEntry += number
        }
    }
    
    func inputDecimal() {
        if !currentEntry.contains(".") {
            currentEntry += "."
        }
    }
    
    func setOperation(_ op: String) {
        previousEntry = Double(currentEntry)
        operation = op
        currentEntry = "0"
    }
    
    func calculate() {
        guard let prev = previousEntry, let op = operation else { return }
        let current = Double(currentEntry) ?? 0
        var result: Double = 0
        
        switch op {
        case "+": result = prev + current
        case "-": result = prev - current
        case "*": result = prev * current
        case "/":
            guard current != 0 else {
                currentEntry = "Error"
                addToHistory("\(prev) / \(current) = Error")
                return
            }
            result = prev / current
        default: return
        }
        
        if result.truncatingRemainder(dividingBy: 1) == 0 {
            currentEntry = String(format: "%.0f", result)
        } else {
            currentEntry = String(result)
        }
        
        addToHistory("\(prev) \(op) \(current) = \(currentEntry)")
        previousEntry = nil
        operation = nil
    }
    
    func clear() {
        currentEntry = "0"
        previousEntry = nil
        operation = nil
    }
    
    func toggleSign() {
        if var value = Double(currentEntry) {
            value = -value
            currentEntry = String(value)
        }
    }
    
    func percentage() {
        if var value = Double(currentEntry) {
            value = value / 100
            currentEntry = String(value)
        }
    }
    
    private func addToHistory(_ entry: String) {
        history.insert(entry, at: 0)
        if history.count > 10 {
            history.removeLast()
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            CalculatorPad(viewModel: viewModel)
            HistoryPanel(history: viewModel.history)
                .frame(width: 220)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(minWidth: 600, minHeight: 650)
    }
}

// MARK: - Calculator Pad View
struct CalculatorPad: View {
    @ObservedObject var viewModel: CalculatorViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Display
            CalculatorDisplay(entry: viewModel.currentEntry, operation: viewModel.operation)
                .frame(width: 328)
            
            // Buttons Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Row 1
                CalculatorButton(title: "C", color: .gray) { viewModel.clear() }
                CalculatorButton(title: "±", color: .gray) { viewModel.toggleSign() }
                CalculatorButton(title: "%", color: .gray) { viewModel.percentage() }
                CalculatorButton(title: "÷", color: .orange, operation: viewModel.operation == "/") {
                    viewModel.setOperation("/")
                }
                
                // Row 2
                CalculatorButton(title: "7", color: .darkGray) { viewModel.inputNumber("7") }
                CalculatorButton(title: "8", color: .darkGray) { viewModel.inputNumber("8") }
                CalculatorButton(title: "9", color: .darkGray) { viewModel.inputNumber("9") }
                CalculatorButton(title: "×", color: .orange, operation: viewModel.operation == "*") {
                    viewModel.setOperation("*")
                }
                
                // Row 3
                CalculatorButton(title: "4", color: .darkGray) { viewModel.inputNumber("4") }
                CalculatorButton(title: "5", color: .darkGray) { viewModel.inputNumber("5") }
                CalculatorButton(title: "6", color: .darkGray) { viewModel.inputNumber("6") }
                CalculatorButton(title: "−", color: .orange, operation: viewModel.operation == "-") {
                    viewModel.setOperation("-")
                }
                
                // Row 4
                CalculatorButton(title: "1", color: .darkGray) { viewModel.inputNumber("1") }
                CalculatorButton(title: "2", color: .darkGray) { viewModel.inputNumber("2") }
                CalculatorButton(title: "3", color: .darkGray) { viewModel.inputNumber("3") }
                CalculatorButton(title: "+", color: .orange, operation: viewModel.operation == "+") {
                    viewModel.setOperation("+")
                }
                
                // Row 5 - ИСПРАВЛЕНО: 0 шире, точка и равно отдельно
                Button(action: { viewModel.inputNumber("0") }) {
                    Text("0")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color(NSColor.darkGray))
                        .cornerRadius(35)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                
                CalculatorButton(title: ".", color: .darkGray) { viewModel.inputDecimal() }
                CalculatorButton(title: "=", color: .orange) { viewModel.calculate() }
            }
        }
        .padding(20)
    }
}

// MARK: - Display View - ИСПРАВЛЕНО выравнивание
struct CalculatorDisplay: View {
    let entry: String
    let operation: String?
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let op = operation {
                Text(op)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.orange)
            }
            Text(entry)
                .font(.system(size: 64, weight: .ultraLight))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing) // ИСПРАВЛЕНО: выравнивание справа
        }
        .frame(width: 328, height: 120)
        .padding(.horizontal, 24) // Увеличил padding
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Calculator Button
struct CalculatorButton: View {
    let title: String
    let color: ButtonColor
    let operation: Bool
    let action: () -> Void
    
    init(title: String, color: ButtonColor, operation: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.operation = operation
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(buttonColor)
                .cornerRadius(35)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var buttonColor: Color {
        switch color {
        case .darkGray:
            return Color(NSColor.darkGray)
        case .gray:
            return Color(NSColor.gray)
        case .orange:
            return operation ? Color.white : Color.orange
        }
    }
}

enum ButtonColor {
    case darkGray
    case gray
    case orange
}

// MARK: - History Panel
struct HistoryPanel: View {
    let history: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)
                .padding(.top, 20)
            
            Divider()
                .padding(.horizontal)
            
            if history.isEmpty {
                Spacer()
                Text("No calculations yet")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .trailing, spacing: 10) {
                        ForEach(history, id: \.self) { entry in
                            Text(entry)
                                .font(.system(size: 13))
                                .padding(10)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    ContentView()
}
