//
//  NavigationSelection.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation
import Observation

public enum NavigationSelection: Hashable {
    case day(Date)
    case tag(String)
}

@Observable
public final class AppRouter {
    public var selection: NavigationSelection?
    
    public init(selection: NavigationSelection? = nil) {
        self.selection = selection
    }
}