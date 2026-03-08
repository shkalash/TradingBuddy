import SwiftUI

/// A settings tab for managing clipboard monitoring and intake behavior.
///
/// **Responsibilities:**
/// - Toggling automated clipboard polling.
/// - Configuring focus behavior during image intake.
struct ClipboardSettingsTab: View {
    // MARK: - Properties
    
    let dependencies: any AppDependencies
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("settings.clipboard.header")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { dependencies.preferencesService.isClipboardMonitoringEnabled },
                    set: { isEnabled in
                        dependencies.preferencesService.isClipboardMonitoringEnabled = isEnabled
                        if isEnabled {
                            dependencies.pasteboardMonitor.startMonitoring()
                        } else {
                            dependencies.pasteboardMonitor.stopMonitoring()
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.clipboard.enable.label")
                        Text("settings.clipboard.enable.help")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                Toggle(isOn: Binding(
                    get: { dependencies.preferencesService.forceFocusChatOnImageIntake },
                    set: { dependencies.preferencesService.forceFocusChatOnImageIntake = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.clipboard.focus.label")
                        Text("settings.clipboard.focus.help")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!dependencies.preferencesService.isClipboardMonitoringEnabled)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            Spacer()
        }
        .padding(20)
    }
}
