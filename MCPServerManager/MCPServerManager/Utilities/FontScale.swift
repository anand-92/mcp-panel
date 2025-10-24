import SwiftUI

// MARK: - Custom Font Extensions
// This file provides convenience extensions for using custom fonts (Poppins & Crimson Pro)
// Note: Font scaling is now handled directly in the Typography system in Constants.swift

extension Font {
    // MARK: - Poppins (Sans-Serif)

    /// Poppins Regular
    static func poppins(size: CGFloat) -> Font {
        return .custom("Poppins-Regular", size: size)
    }

    /// Poppins Medium
    static func poppinsMedium(size: CGFloat) -> Font {
        return .custom("Poppins-Medium", size: size)
    }

    /// Poppins SemiBold
    static func poppinsSemiBold(size: CGFloat) -> Font {
        return .custom("Poppins-SemiBold", size: size)
    }

    /// Poppins Bold
    static func poppinsBold(size: CGFloat) -> Font {
        return .custom("Poppins-Bold", size: size)
    }

    // MARK: - Crimson Pro (Serif)

    /// Crimson Pro Regular
    static func crimsonPro(size: CGFloat) -> Font {
        return .custom("CrimsonPro-Regular", size: size)
    }

    /// Crimson Pro Medium
    static func crimsonProMedium(size: CGFloat) -> Font {
        return .custom("CrimsonPro-Medium", size: size)
    }

    /// Crimson Pro SemiBold
    static func crimsonProSemiBold(size: CGFloat) -> Font {
        return .custom("CrimsonPro-SemiBold", size: size)
    }

    /// Crimson Pro Bold
    static func crimsonProBold(size: CGFloat) -> Font {
        return .custom("CrimsonPro-Bold", size: size)
    }
}
