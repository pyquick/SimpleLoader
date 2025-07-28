//
//  HeaderView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
@available(macOS 26.0,*)
struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                Text("SimpleLoader 系统扩展安装工具")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
            }
            
            Text("自动合并 KDK 并安装 Kext/Bundle 到 /System/Library/Extensions")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}
