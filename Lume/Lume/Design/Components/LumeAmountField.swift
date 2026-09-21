import SwiftUI

/// A big serif currency display driven by a real (invisibly-styled) TextField,
/// so the system decimal keypad handles input. The mockup hand-draws a custom
/// keypad grid to communicate intent; the correct native equivalent is the
/// real system numeric keyboard, styled around with our own display.
struct LumeAmountField: View {
    /// Raw typed digits, cents-based ("4890" → R$ 48,90).
    @Binding var digits: String
    var fontSize: CGFloat = 66
    var color: Color = LumeColor.ink
    var autofocus: Bool = true
    @FocusState private var isFocused: Bool

    var amount: Double { LumeCurrency.amount(fromDigits: digits) }

    var body: some View {
        ZStack {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("R$")
                    .font(LumeType.serif(fontSize * 0.46))
                    .foregroundStyle(LumeColor.textFainter)
                Text(LumeCurrency.number(amount))
                    .font(LumeType.serif(fontSize))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .animation(.default, value: digits)
                LumeBlinkingCursor(color: LumeColor.brand, width: max(2, fontSize * 0.045), height: fontSize * 0.82)
            }
            .frame(maxWidth: .infinity)

            TextField("", text: $digits)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .opacity(0.01)
                .onChange(of: digits) { _, newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(9))
                    if filtered != newValue { digits = filtered }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear {
            guard autofocus else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isFocused = true }
        }
    }
}
