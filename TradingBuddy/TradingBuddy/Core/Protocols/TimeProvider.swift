//
//  TimeProvider.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation

public protocol TimeProvider {
    var now: Date { get }
}

// The concrete implementation the real app will use
public struct SystemTimeProvider: TimeProvider {
    public init() {}
    public var now: Date { Date() }
}

// A mock implementation we can use later in ViewModels to simulate time
public struct MockTimeProvider: TimeProvider {
    public var now: Date
    public init(now: Date) {
        self.now = now
    }
}