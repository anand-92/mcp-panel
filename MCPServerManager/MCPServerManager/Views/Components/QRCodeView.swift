import SwiftUI

/// SwiftUI view that displays a QR code
struct QRCodeView: View {
    let url: String
    let size: CGFloat

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(spacing: 16) {
            if let qrImage = QRCodeGenerator.generateStyled(
                from: url,
                size: CGSize(width: size, height: size),
                foregroundColor: .black,
                backgroundColor: .white
            ) {
                Image(nsImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .cornerRadius(12)
                    .overlay(
                        Text("Failed to generate QR code")
                            .foregroundColor(.secondary)
                            .font(DesignTokens.Typography.bodySmall)
                    )
            }

            Text("Scan with your phone")
                .font(DesignTokens.Typography.label)
                .foregroundColor(themeColors.primaryText)

            Text(extractDomain(from: url))
                .font(DesignTokens.Typography.bodySmall)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
        }
    }

    private func extractDomain(from url: String) -> String {
        if let range = url.range(of: "://") {
            let afterProtocol = url[range.upperBound...]
            if let endRange = afterProtocol.range(of: "?") {
                return String(afterProtocol[..<endRange.lowerBound])
            }
            return String(afterProtocol)
        }
        return url
    }
}

#Preview {
    QRCodeView(
        url: "http://192.168.1.100:8765?token=abc123",
        size: 200
    )
    .padding()
    .background(Color.black)
}
