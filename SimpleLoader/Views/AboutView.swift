//
//  AboutView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.Mod
//

import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isExpanded: Bool = false
    @Namespace private var namespace
        
    var body: some View {
        GlassEffectContainer(spacing: 40.0) {
            HStack(spacing: 40.0) {
                Image(systemName: "scribble.variable")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect()
                    .glassEffectID("pencil", in: namespace)
                if isExpanded {
                    Image(systemName: "eraser.fill")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect()
                        .glassEffectID("eraser", in: namespace)
                }
            }
        }
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text("SimpleLoader")
                        .font(.title)
                        .bold()
                    Text("系统扩展安装工具")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "number", title: "版本", value: "1.0.0")
                InfoRow(icon: "person", title: "作者", value: "laobamac")
                InfoRow(icon: "c", title: "版权", value: "© 2025 保留所有权利")
            }
            
            Divider()
            
            Link(destination: URL(string: "https://github.com/pyquick/SimpleLoader")!) {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("访问GitHub仓库")
                }
                .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 120)
        }
        .padding()
        .frame(width: 320, height: 280)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            Text(title)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .bold()
            Spacer()
        }
    }
}
