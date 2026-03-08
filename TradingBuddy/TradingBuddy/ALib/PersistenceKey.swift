//
//  PersistenceKey.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/8/26.
//


//
//  PersistenceKey.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation
/// A type-safe key for persistence.
/// The `Value` generic parameter links the key to the type of data it stores,
/// preventing type-mismatch errors at compile time.
struct PersistenceKey<Value> {
    let name: String
}
extension PersistenceKey {
    // QOL Settings
    static var chatFontSize: PersistenceKey<Double> { .init(name: AppConstants.Storage.chatFontSizeKey) }
    
    // Preferences
    static var showHistoryJumpWarning: PersistenceKey<Bool> { .init(name: AppConstants.Storage.showHistoryJumpWarningKey) }
    static var rolloverPromptDelayHours: PersistenceKey<Int> { .init(name: AppConstants.Storage.rolloverPromptDelayHoursKey) }
    static var snoozedUntil: PersistenceKey<Date> { .init(name: AppConstants.Storage.snoozedUntilKey) }
    
    // Window State
    static func windowState(name: String) -> PersistenceKey<WindowState> {
        .init(name: "\(AppConstants.Storage.windowStatekey)_\(name)")
    }
}
