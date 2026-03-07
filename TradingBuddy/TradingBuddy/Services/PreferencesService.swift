//
//  PreferencesService.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation

public protocol PreferencesService {
    var showHistoryJumpWarning: Bool { get set }
    var rolloverPromptDelayHours: Int { get set }
    var snoozedUntil: Date? { get set }
}

public class AppPreferencesService: PreferencesService {
    private let defaults = UserDefaults.standard
    
    public init() {}
    
    public var showHistoryJumpWarning: Bool {
        get { defaults.object(forKey: "showHistoryJumpWarning") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showHistoryJumpWarning") }
    }
    
    public var rolloverPromptDelayHours: Int {
        get { defaults.object(forKey: "rolloverPromptDelayHours") as? Int ?? 2 }
        set { defaults.set(newValue, forKey: "rolloverPromptDelayHours") }
    }
    
    public var snoozedUntil: Date? {
        get { defaults.object(forKey: "snoozedUntil") as? Date }
        set { defaults.set(newValue, forKey: "snoozedUntil") }
    }
}