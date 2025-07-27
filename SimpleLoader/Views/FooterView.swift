//
//  FooterView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack(spacing: 4) {
            Divider()
            HStack {
                Text("© 2025 laobamac. 保留所有权利。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("版本 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("GitHub", destination: URL(string: "https://github.com/laobamac/SimpleLoader")!)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
