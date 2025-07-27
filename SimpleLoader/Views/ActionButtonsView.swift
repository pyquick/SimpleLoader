//
//  ActionButtonsView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

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
                    Label("打开KDK目录", systemImage: "folder")
                        .frame(minWidth: 120)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                if isInstalling || isMerging {
                    Button(action: cancelAction) {
                        Label("取消", systemImage: "xmark")
                            .frame(minWidth: 100)
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(NeutralButtonStyle())
                    .transition(.scale)
                } else {
                    Button(action: mergeAction) {
                        Label("仅合并KDK", systemImage: "square.stack.3d.down.right")
                            .frame(minWidth: 120)
                    }
                    .keyboardShortcut("m", modifiers: [.command])
                    .disabled(!isKDKSelected)
                    .buttonStyle(SecondaryButtonStyle())
                    .transition(.move(edge: .trailing))
                    
                    Button(action: installAction) {
                        Label("开始安装", systemImage: "arrow.down.circle")
                            .frame(minWidth: 120)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!hasKextsSelected)
                    .buttonStyle(AccentButtonStyle())
                    .transition(.move(edge: .trailing))
                }
            }
            
            Divider()
            
            
            HStack(spacing: 12) {
                Button(action: aboutAction) {
                    Label("关于软件", systemImage: "info.square.fill")
                        .frame(minWidth: 120)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button(action: rebuildCacheAction) {
                    Label("重建缓存", systemImage: "arrow.clockwise")
                        .frame(minWidth: 120)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: createSnapshotAction) {
                    Label("创建快照", systemImage: "camera")
                        .frame(minWidth: 120)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: restoreSnapshotAction) {
                    Label("恢复快照", systemImage: "arrow.uturn.backward")
                        .frame(minWidth: 120)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .animation(.spring(), value: isInstalling || isMerging)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
