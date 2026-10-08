import Testing

@testable import ReadoutCore

@Suite struct TemperatureUnitTests {
    @Test func convertsToFahrenheit() {
        #expect(TemperatureUnit.convert(celsius: 100, to: .fahrenheit) == 212)
        #expect(TemperatureUnit.convert(celsius: -40, to: .fahrenheit) == -40)
    }

    @Test func celsiusIsIdentity() {
        #expect(TemperatureUnit.convert(celsius: 52.2, to: .celsius) == 52.2)
    }

    @Test func menuBarTemperatureRoundsAndAddsDegree() {
        #expect(MenuBarText.temperature(celsius: 52.2, unit: .fahrenheit) == "126°")
        #expect(MenuBarText.temperature(celsius: 52.2, unit: .celsius) == "52°")
    }

    @Test func menuBarTemperatureMissingOrNonFiniteIsPlaceholder() {
        #expect(MenuBarText.temperature(celsius: nil, unit: .fahrenheit) == "—")
        #expect(MenuBarText.temperature(celsius: .nan, unit: .celsius) == "—")
    }
}
