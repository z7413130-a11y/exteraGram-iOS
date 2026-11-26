import Foundation
import SwiftSignalKit

public enum ExteraSettingsCategory: Int32, CaseIterable {
    case general
    case appearance
    case chats
    case plugins
    case other
}

public struct ExteraSettingDefinition {
    public let key: String
    public let category: ExteraSettingsCategory
}

public struct ExteraPreference<Value: Codable> {
    public let definition: ExteraSettingDefinition
    public let defaultValue: Value

    init(_ key: String, _ category: ExteraSettingsCategory, _ defaultValue: Value) {
        self.definition = ExteraSettingDefinition(key: key, category: category)
        self.defaultValue = defaultValue
    }
}

/// Device-local preferences. Keeping each value under a separate key allows
/// adding settings without rewriting or migrating unrelated values.
public final class ExteraSettingsStore {
    public static let shared = ExteraSettingsStore(defaults: .standard)

    private let defaults: UserDefaults
    private let changePipe = ValuePipe<Void>()

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public var changes: Signal<Void, NoError> {
        return .single(()) |> then(self.changePipe.signal())
    }

    public func value<Value>(for preference: ExteraPreference<Value>) -> Value {
        guard let data = self.defaults.data(forKey: self.storageKey(preference.definition)),
              let value = try? JSONDecoder().decode(Value.self, from: data) else {
            return preference.defaultValue
        }
        return value
    }

    public func set<Value>(_ value: Value, for preference: ExteraPreference<Value>) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        self.defaults.set(data, forKey: self.storageKey(preference.definition))
        self.changePipe.putNext(())
    }

    public func reset() {
        for definition in ExteraPreferences.androidDefinitions + ExteraPreferences.iOSDefinitions {
            self.defaults.removeObject(forKey: self.storageKey(definition))
        }
        self.changePipe.putNext(())
    }

    private func storageKey(_ definition: ExteraSettingDefinition) -> String {
        return "org.exteragram.iosport.preferences." + definition.key
    }
}
