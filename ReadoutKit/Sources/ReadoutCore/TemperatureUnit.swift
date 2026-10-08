public enum TemperatureUnit: String, Sendable, CaseIterable {
    case fahrenheit
    case celsius

    public static func convert(celsius: Double, to unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius: celsius
        case .fahrenheit: celsius * 9 / 5 + 32
        }
    }
}
