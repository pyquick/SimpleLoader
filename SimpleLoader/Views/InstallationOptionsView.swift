//
//  InstallationOptionsView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

struct InstallationOptionsView: View {
    @Binding var showAdvancedOptions: Bool
    @Binding var forceOverwrite: Bool
    @Binding var backupExisting: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("安装选项")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        showAdvancedOptions.toggle()
                    }
                }) {
                    Text(showAdvancedOptions ? "隐藏高级选项" : "显示高级选项")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Toggle("强行覆盖重名文件", isOn: $forceOverwrite)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: forceOverwrite) { newValue in
                    if !newValue {
                        backupExisting = false
                    }
                }
            
            Toggle("备份现有 Kext", isOn: $backupExisting)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .disabled(!forceOverwrite)
            
            if showAdvancedOptions {
                Divider()
                    .transition(.opacity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("高级选项（未来功能扩展，暂未用到）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("1", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("2", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    Toggle("3", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
