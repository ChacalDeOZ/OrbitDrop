import Foundation

public enum KeyboardNavigator: Sendable {
    /// Calcula o próximo índice de setor com wrap-around cíclico seguro.
    public static func nextIndex(current: Int?, count: Int) -> Int? {
        guard count > 0 else { return nil }
        guard let curr = current else { return 0 }
        return (curr + 1) % count
    }

    /// Calcula o índice de setor anterior com wrap-around cíclico seguro.
    public static func previousIndex(current: Int?, count: Int) -> Int? {
        guard count > 0 else { return nil }
        guard let curr = current else { return count - 1 }
        return (curr - 1 + count) % count
    }
}
