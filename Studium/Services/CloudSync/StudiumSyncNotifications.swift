//
//  StudiumSyncNotifications.swift
//  Studium
//

import Foundation

extension Notification.Name {
    static let studiumLocalDataChanged = Notification.Name("studiumLocalDataChanged")
    static let studiumSyncApplied = Notification.Name("studiumSyncApplied")
}

enum StudiumLocalDataNotify {
    static func changed(fromSync: Bool = false) {
        if fromSync {
            NotificationCenter.default.post(
                name: .studiumLocalDataChanged,
                object: nil,
                userInfo: ["fromSync": true]
            )
        } else {
            NotificationCenter.default.post(name: .studiumLocalDataChanged, object: nil)
        }
    }

    static func syncApplied() {
        NotificationCenter.default.post(name: .studiumSyncApplied, object: nil)
    }
}
