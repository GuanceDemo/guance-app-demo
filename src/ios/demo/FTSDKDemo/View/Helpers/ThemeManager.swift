import UIKit

/// Global theme color constant
struct ThemeManager {
    
    /// Primary theme color
    static let primaryColor: UIColor = .orange
}

/// UIColor extension for theme color
extension UIColor {
    
    /// Theme color
    static var theme: UIColor {
        return ThemeManager.primaryColor
    }
}
