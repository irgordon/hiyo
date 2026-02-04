import Foundation

extension String {
    var displayName: String {
        self.replacingOccurrences(of: "mlx-community/", with: "")
            .replacingOccurrences(of: "-Instruct", with: "")
            .replacingOccurrences(of: "-4bit", with: "")
    }
}
