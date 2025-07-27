//
//  StatusView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

struct StatusView: View {
    @Binding var isInstalling: Bool
    @Binding var isMerging: Bool
    @Binding var progress: Double
    @Binding var currentOperation: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("状态")
                .font(.headline)
            
            if isInstalling || isMerging {
                ProgressView(value: progress, total: 1) {
                    if let operation = currentOperation {
                        Text(operation)
                    } else {
                        Text(isInstalling ? "正在安装..." : "正在合并KDK...")
                    }
                } currentValueLabel: {
                    Text("\(Int(progress * 100))%")
                        .foregroundColor(.secondary)
                }
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                
                HStack {
                    Image(systemName: "info.circle")
                    if let operation = currentOperation {
                        Text(operation)
                            .font(.caption)
                    } else {
                        Text(isInstalling ? "正在将 Kext 安装到 /System/Library/Extensions" : "正在合并 KDK 文件")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            } else {
                HStack {
                    Image(systemName: "info.circle")
                    Text("准备就绪")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
