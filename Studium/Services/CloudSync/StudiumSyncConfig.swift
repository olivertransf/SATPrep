//
//  StudiumSyncConfig.swift
//  Studium
//

import Foundation

enum StudiumSyncConfig {
    private static let plistName = "StudiumSync"

    static var supabaseURL: URL? {
        string(for: "SUPABASE_URL").flatMap(URL.init(string:))
    }

    static var anonKey: String? {
        string(for: "SUPABASE_ANON_KEY")
    }

    static var syncEmail: String? {
        string(for: "SYNC_EMAIL")?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    static var gatePassword: String? {
        string(for: "SYNC_GATE_PASSWORD")?.nilIfEmpty
    }

    static var isConfigured: Bool {
        supabaseURL != nil && anonKey != nil
    }

    static var usesEmailAuth: Bool {
        syncEmail != nil
    }

    private static func string(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = dict[key] as? String
        else { return nil }
        return value
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
