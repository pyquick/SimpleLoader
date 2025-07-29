//
//  ActionButtonsView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
@available(macOS 26.0,*)
struct ActionButtonsView: View {
    @Binding var isKDKSelected: Bool
    @Binding var isInstalling: Bool
    @Binding var isMerging: Bool
    @Binding var hasKextsSelected: Bool
    var installAction: () -> Void
    var mergeAction: () -> Void
    var cancelAction: () -> Void
    var openKDKDirectoryAction: () -> Void
    var rebuildCacheAction: () -> Void
    var createSnapshotAction: () -> Void
    var restoreSnapshotAction: () -> Void
    var aboutAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: openKDKDirectoryAction) {
                    Label("open_kdk_dir".localized, systemImage: "folder")
                        .frame(minWidth: 120)

                }
                //.glassEffect(.regular)
                .buttonStyle(AccentLiquidGlass())
                //.buttonStyle(.glass)
                
                                            
                
                Spacer()
                
                if isInstalling || isMerging {
                    Button(action: cancelAction) {
                        Label("cancel".localized, systemImage: "xmark")
                            .frame(minWidth: 100)
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(NeutralButtonStyle())
                    .transition(.scale)
                } else {
                    Button(action: mergeAction) {
                        Label("only_merge_kdk".localized, systemImage: "square.stack.3d.down.right")
                            .frame(minWidth: 120)
                    }
                    .keyboardShortcut("m", modifiers: [.command])
                    .disabled(!isKDKSelected)
                    .buttonStyle(PrimaryLiquidGlassStyle())
                    .transition(.move(edge: .trailing))
                    
                    Button(action: installAction) {
                        Label("start_install".localized, systemImage: "arrow.down.circle")
                            .frame(minWidth: 120)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!hasKextsSelected)
                    .buttonStyle(AccentLiquidGlass())
                    .transition(.move(edge: .trailing))
                }
            }
            
            Divider()
            
            
            HStack(spacing: 12) {
                Button(action: aboutAction) {
                    Label("about".localized, systemImage: "info.square.fill")
                        .frame(minWidth: 120)
                }
                .buttonStyle(PrimaryLiquidGlassStyle())
                
                Spacer()
                
                Button(action: rebuildCacheAction) {
                    Label("rebuild".localized, systemImage: "arrow.clockwise")
                        .frame(minWidth: 120)
                }
                .buttonStyle(PrimaryLiquidGlassStyle())
                
                Button(action: createSnapshotAction) {
                    Label("creat_snapshot".localized, systemImage: "camera")
                        .frame(minWidth: 120)
                }
                .buttonStyle(PrimaryLiquidGlassStyle())
                
                Button(action: restoreSnapshotAction) {
                    Label("restore_snapshot".localized, systemImage: "arrow.uturn.backward")
                        .frame(minWidth: 120)
                }
                .buttonStyle(PrimaryLiquidGlassStyle())
            }
        }
        .animation(.spring(), value: isInstalling || isMerging)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
