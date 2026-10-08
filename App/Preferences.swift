import Foundation
import ReadoutCore

enum Preferences {
    enum Key {
        static let temperatureUnit = "temperatureUnit"
        static let networkInterface = "networkInterface"

        static func enabled(_ kind: MeterKind) -> String { "item.\(kind.rawValue).enabled" }
    }

    static func registerDefaults() {
        var defaults: [String: Any] = [
            Key.temperatureUnit: TemperatureUnit.fahrenheit.rawValue,
            Key.networkInterface: "",
        ]
        for kind in MeterKind.allCases { defaults[Key.enabled(kind)] = true }
        UserDefaults.standard.register(defaults: defaults)
    }

    static func isEnabled(_ kind: MeterKind) -> Bool {
        UserDefaults.standard.bool(forKey: Key.enabled(kind))
    }

    static var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: UserDefaults.standard.string(forKey: Key.temperatureUnit) ?? "") ?? .fahrenheit
    }

    static var networkInterface: String {
        UserDefaults.standard.string(forKey: Key.networkInterface) ?? ""
    }
}
