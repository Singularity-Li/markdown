import Foundation
import Observation

/// 只保存背景透明度；弹出面板的开关是临时界面状态。
@Observable
final class AppearanceSettings {
    static let shared = AppearanceSettings()
    static let defaultTransparency = 0.35
    private static let key = "windowGlassTransparency"
    private let defaults: UserDefaults
    private var storedTransparency: Double
    var onChange: ((Double) -> Void)?

    var transparency: Double {
        get { storedTransparency }
        set {
            let value = Self.normalized(newValue)
            storedTransparency = value
            defaults.set(value, forKey: Self.key)
            onChange?(value)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storedTransparency = Self.normalized(defaults.object(forKey: Self.key) as? Double ?? Self.defaultTransparency)
    }

    private static func normalized(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : defaultTransparency
    }
}
