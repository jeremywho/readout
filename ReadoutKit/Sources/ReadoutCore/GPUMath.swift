public enum GPUMath {
    public static func utilizationPercent(_ raw: Int) -> Double {
        Double(min(max(raw, 0), 100))
    }
}
