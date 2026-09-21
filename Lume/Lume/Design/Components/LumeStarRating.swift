import SwiftUI

struct LumeStarRating: View {
    @Binding var rating: Int
    var size: CGFloat = 32
    var color: Color = LumeColor.brand

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    rating = rating == star ? 0 : star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: size, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: max(44, size + 12), height: max(44, size + 12))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) estrela\(star == 1 ? "" : "s")")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Avaliação")
        .accessibilityValue(rating == 0 ? "Sem avaliação" : "\(rating) de 5 estrelas")
    }
}

struct LumeStarDisplay: View {
    var rating: Int
    var size: CGFloat = 12
    var color: Color = LumeColor.brand

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(star <= rating ? color : color.opacity(0.28))
            }
        }
        .accessibilityLabel(rating == 0 ? "Sem avaliação" : "\(rating) de 5 estrelas")
    }
}
