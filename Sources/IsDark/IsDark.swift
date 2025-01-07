import Cocoa

public func isDark() -> Bool {
    if #available(macOS 10.14, *) {
        if #available(macOS 11, *) {
            return NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        } else {
            return NSAppearance.current.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        }
    } else {
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }
}
