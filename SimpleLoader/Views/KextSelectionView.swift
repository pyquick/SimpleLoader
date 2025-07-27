//
//  KextSelectionView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct KextSelectionView: View {
    @Binding var kextPaths: [String]
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择 Kext 文件")
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isTargeted ? Color.accentColor.opacity(0.2) : Color(.controlBackgroundColor))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                    .animation(.easeInOut, value: isTargeted)
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                
                if kextPaths.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.square.dashed")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("拖放 Kext 文件到这里")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("或")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button(action: selectFiles) {
                            Text("点击选择文件...")
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(kextPaths, id: \.self) { path in
                                HStack {
                                    Image(systemName: "doc")
                                    Text(URL(fileURLWithPath: path).lastPathComponent)
                                        .font(.caption)
                                    Spacer()
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            kextPaths.removeAll { $0 == path }
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                                .transition(.move(edge: .leading))
                            }
                        }
                        .padding()
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
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                if let urlData = urlData as? Data {
                    let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                    DispatchQueue.main.async {
                        addKext(at: url.path)
                    }
                }
            }
        }
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.bundle]
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                addKext(at: url.path)
            }
        }
    }
    
    private func addKext(at path: String) {
        guard !kextPaths.contains(path) else { return }
        withAnimation {
            kextPaths.append(path)
        }
    }
}
