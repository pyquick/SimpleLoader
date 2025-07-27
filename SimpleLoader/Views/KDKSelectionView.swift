//
//  KDKSelectionView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct KDKSelectionView: View {
    @ObservedObject var kdkMerger: KDKMerger
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择 KDK")
                .font(.headline)
            
            HStack {
                Picker("选择已安装的KDK", selection: $kdkMerger.selectedKDK) {
                    Text("未选择").tag(nil as String?)
                    ForEach(kdkMerger.kdkItems, id: \.self) { kdk in
                        Text(URL(fileURLWithPath: kdk).lastPathComponent).tag(kdk as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .onChange(of: kdkMerger.selectedKDK) { newValue in
                    if let newValue = newValue {
                        kdkMerger.kdkPath = newValue
                        kdkMerger.isKDKSelected = true
                        kdkMerger.logPublisher.send("已选择KDK: \(newValue)")
                    } else {
                        kdkMerger.kdkPath = ""
                        kdkMerger.isKDKSelected = false
                    }
                }
                
                Button("刷新") {
                    kdkMerger.refreshKDKList()
                }
                .buttonStyle(BorderedButtonStyle())
            }
            
            if kdkMerger.isKDKSelected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("有效的 KDK 已选择")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale))
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

