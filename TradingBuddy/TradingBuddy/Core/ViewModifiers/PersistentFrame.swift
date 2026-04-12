//
//  PersistentFrame.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/8/26.

import SwiftUI
extension View {
    /// A modifier to automatically save and load a window's frame to persistence.
    /// - Parameters:
    ///   - key: A unique string identifying this window (e.g., "mainWindow").
    ///   - onLoad: A closure to load the saved frame.
    ///   - onSave: A closure to save the frame.
    func persistentFrame(
        forKey key: String,
        onLoad: @escaping (String) -> WindowState?,
        onSave: @escaping (String, WindowState) -> Void
    ) -> some View {
        self.modifier(PersistentWindow(key: key, onLoad: onLoad, onSave: onSave))
    }
}
