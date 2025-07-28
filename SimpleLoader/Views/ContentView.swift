//
//  ContentView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
import Combine
@available(macOS 26,*)
struct ContentView: View {
    @StateObject private var kdkMerger = KDKMerger()
    @State private var showAdvancedOptions = false
    @State private var forceOverwrite = false
    @State private var backupExisting = false
    @State private var alertMessage: AlertMessage? = nil
    @State private var showAbout = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .zIndex(1)
            
            ScrollView {
                VStack(spacing: 20) {
                    KDKSelectionView(kdkMerger: kdkMerger)
                    
                    KextSelectionView(kextPaths: $kdkMerger.kextPaths)
                    
                    LogView(logMessages: $kdkMerger.logMessages)
                        .frame(height: 150)
                    
                    InstallationOptionsView(
                        showAdvancedOptions: $showAdvancedOptions,
                        forceOverwrite: $forceOverwrite,
                        backupExisting: $backupExisting
                    )
                    
                    StatusView(
                        isInstalling: $kdkMerger.isInstalling,
                        isMerging: $kdkMerger.isMerging,
                        progress: $kdkMerger.installationProgress,
                        currentOperation: $kdkMerger.currentOperation
                    )
                    
                    ActionButtonsView(
                        isKDKSelected: $kdkMerger.isKDKSelected,
                        isInstalling: $kdkMerger.isInstalling,
                        isMerging: $kdkMerger.isMerging,
                        hasKextsSelected: .init(
                            get: { !kdkMerger.kextPaths.isEmpty },
                            set: { _ in }
                        ),
                        installAction: {
                            kdkMerger.installKexts(
                                forceOverwrite: forceOverwrite,
                                backupExisting: backupExisting,
                                rebuildCache: true
                            )
                        },
                        mergeAction: kdkMerger.mergeKDK,
                        cancelAction: kdkMerger.cancelOperation,
                        openKDKDirectoryAction: kdkMerger.openKDKDirectory,
                        rebuildCacheAction: {
                            kdkMerger.currentOperation = "正在重建内核缓存"
                            kdkMerger.rebuildKernelCache()
                        },
                        createSnapshotAction: {
                            kdkMerger.currentOperation = "正在创建系统快照"
                            kdkMerger.createSystemSnapshot()
                        },
                        restoreSnapshotAction: {
                            kdkMerger.currentOperation = "正在恢复快照"
                            kdkMerger.restoreLastSnapshot()
                        },
                        aboutAction: { showAbout = true }
                    )
                }
                .padding()
            }
            .background(Color(.windowBackgroundColor))
            
            FooterView()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAdvancedOptions)
        .sheet(isPresented: $showAbout) {
                    AboutView()
        }
        .alert(item: $alertMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("确定"))
                )
        }
        .onReceive(kdkMerger.alertPublisher) { message in
            alertMessage = message
        }
    }
}

struct AlertMessage: Identifiable {
    var id: String { title + message }
    let title: String
    let message: String
}
