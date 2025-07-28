//
//  LogView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
@available(macOS 26.0,*)
struct LogView: View {
    @Binding var logMessages: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("操作日志")
                .font(.headline)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logMessages.indices, id: \.self) { index in
                            Text(logMessages[index])
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(2)
                                .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.1))
                                .id(index)
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: .infinity)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .onChange(of: logMessages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(logMessages.count - 1, anchor: .bottom)
                    }
                }
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
