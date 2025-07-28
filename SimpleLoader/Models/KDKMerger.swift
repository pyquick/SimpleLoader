//
//  KDKMerger.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import Foundation
import Combine
import AppKit

class KDKMerger: ObservableObject {
    @Published var isKDKSelected = false
    @Published var kdkPath = ""
    @Published var kextPaths: [String] = []
    @Published var isInstalling = false
    @Published var isMerging = false
    @Published var installationProgress: Double = 0
    @Published var logMessages: [String] = ["等待操作..."]
    @Published var selectedKDK: String?
    @Published var kdkItems: [String] = []
    @Published var logPublisher = PassthroughSubject<String, Never>()
    @Published var currentOperation: String? = nil
    
    private let fileManager = FileManager.default
    private let kdkDirectory = "/Library/Developer/KDKs"
    private var cancellables = Set<AnyCancellable>()
    private var progressTimer: Timer?
    
    var alertPublisher = PassthroughSubject<AlertMessage, Never>()

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertPublisher.send(AlertMessage(title: title, message: message))
        }
    }
    
    init() {
        setupLogging()
        checkKDKDirectory()
    }
    
    private func setupLogging() {
        logPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.logMessages.append(message)
                if self?.logMessages.count ?? 0 > 100 {
                    self?.logMessages.removeFirst()
                }
            }
            .store(in: &cancellables)
    }
    
    func refreshKDKList() {
        let url = URL(fileURLWithPath: kdkDirectory)
        do {
            let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            let kdks = items.filter { $0.pathExtension == "kdk" || $0.lastPathComponent.contains("KDK") }
                .map { $0.path }
                .sorted()
            
            DispatchQueue.main.async {
                self.kdkItems = kdks
                if kdks.isEmpty {
                    self.logPublisher.send("警告: 未找到KDK，请先安装KDK")
                    self.showAlert(title: "警告", message: "未找到KDK，请先安装KDK")
                } else {
                    self.logPublisher.send("找到 \(kdks.count) 个KDK")
                }
            }
        } catch {
            logPublisher.send("错误: 无法读取KDK目录 - \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.kdkItems = []
            }
        }
    }
    
    func mergeKDK() {
        guard let selectedKDK = selectedKDK else {
            logPublisher.send("错误: 未选择KDK")
            self.showAlert(title: "错误", message: "未选择KDK")
            return
        }
        
        isMerging = true
        installationProgress = 0
        logPublisher.send("开始合并KDK: \(selectedKDK)")
        
        startProgressUpdates()
        
        let shellScript = """
        umount "$MOUNT_PATH"; \
        echo '开始合并KDK进程...' && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "原始标识符: $ROOT_VOLUME_ORIGIN" && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        rsync -r -i -a '\(selectedKDK)/System/Library/Extensions/' "$MOUNT_PATH/System/Library/Extensions" && \
        kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
        bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
        if [ -f "$MOUNT_PATH/System/Library/Extensions/System.kext/PlugIns/Libkern.kext/Libkern" ]; then \
            echo 'KDK合并成功' && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                umount "$MOUNT_PATH"; \
            fi && \
            echo '卸载根卷，操作完成'; \
        else \
            echo '错误: KDK合并失败' && \
            exit 1; \
        fi
        """
        
        let appleScript = """
        do shell script "\(shellScript.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        logPublisher.send("定位根目录...")
        logPublisher.send("开始合并KDK到根目录")
        logPublisher.send("此步骤很慢，不要强制停止！")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.executeAppleScript(script: appleScript) { success, output in
                DispatchQueue.main.async {
                    self.stopProgressUpdates()
                    
                    if success {
                        self.installationProgress = 1.0
                        self.logPublisher.send("合并完成，已卸载根目录")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.isMerging = false
                            self.installationProgress = 0
                        }
                        self.showAlert(title: "合并成功", message: "KDK已成功合并")
                    } else {
                        self.logPublisher.send("错误: 合并KDK失败 - \(output ?? "无输出")")
                        self.isMerging = false
                        self.installationProgress = 0
                        self.showAlert(title: "合并失败", message: output ?? "未知错误")
                        self.errorOperation()
                    }
                }
            }
        }
    }
    
    func installKexts(forceOverwrite: Bool, backupExisting: Bool, rebuildCache: Bool) {
        guard !kextPaths.isEmpty else {
            logPublisher.send("错误: 未选择任何Kext文件")
            return
        }
        
        let selectedKDKpath: String
        if let selectedKDKvalue = selectedKDK {
            logPublisher.send("是否选择KDK：\(isKDKSelected)")
            selectedKDKpath = selectedKDKvalue
        } else {
            logPublisher.send("信息: 未选择任何KDK")
            selectedKDKpath = ""
        }
        
        isInstalling = true
        installationProgress = 0
        logPublisher.send("开始安装Kext文件...")
        logPublisher.send("选项: 强制覆盖=\(forceOverwrite), 备份=\(backupExisting), 重建缓存=\(rebuildCache)")
        
        startProgressUpdates()
        
        let shellScript: String
        if isKDKSelected {
            logPublisher.send("开始合并KDK并安装Kext...")
            shellScript = """
            echo '开始合并KDK并安装Kext...' && \
            echo '开始合并KDK进程...' && \
            ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
            if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
                echo '处理快照' && \
                ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
            else \
                ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
            fi && \
            echo "原始标识符: $ROOT_VOLUME_ORIGIN" && \
            echo "根卷标识符: $ROOT_VOLUME" && \
            if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
                umount /System/Volumes/Update/mnt1; \
            else \
                echo '没有挂载'; \
            fi && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                echo '检测到macOS Big Sur或更高版本' && \
                mkdir -p /System/Volumes/Update/mnt1 && \
                mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
                MOUNT_PATH='/System/Volumes/Update/mnt1'; \
            else \
                echo '检测到macOS Catalina或更早版本' && \
                mount -uw / && \
                MOUNT_PATH='/'; \
            fi && \
            echo "挂载路径: $MOUNT_PATH" && \
            rsync -r -i -a "\(selectedKDKpath)/System/Library/Extensions/" "$MOUNT_PATH/System/Library/Extensions" && \
            \(kextInstallationCommands(mountPath: "$MOUNT_PATH", forceOverwrite: forceOverwrite, backupExisting: backupExisting)) && \
            \(rebuildCache ? "kmutil create --volume-root \"$MOUNT_PATH\" --update-all --allow-missing-kdk &&" : "") \
            kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
            bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                umount "$MOUNT_PATH"; \
            fi && \
            echo '操作完成'
            """
        } else {
            logPublisher.send("开始安装Kext...")
            shellScript = """
            echo '开始安装Kext...' && \
            ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
            if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
                echo '处理快照' && \
                ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
            else \
                ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
            fi && \
            echo "根卷标识符: $ROOT_VOLUME" && \
            if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
                umount /System/Volumes/Update/mnt1; \
            else \
                echo '没有挂载'; \
            fi && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                echo '检测到macOS Big Sur或更高版本' && \
                mkdir -p /System/Volumes/Update/mnt1 && \
                mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
                MOUNT_PATH='/System/Volumes/Update/mnt1'; \
            else \
                echo '检测到macOS Catalina或更早版本' && \
                mount -uw / && \
                MOUNT_PATH='/'; \
            fi && \
            echo "挂载路径: $MOUNT_PATH" && \
            \(kextInstallationCommands(mountPath: "$MOUNT_PATH", forceOverwrite: forceOverwrite, backupExisting: backupExisting)) && \
            \(rebuildCache ? "kmutil create --volume-root \"$MOUNT_PATH\" --update-all --allow-missing-kdk &&" : "") \
            kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
            bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                umount "$MOUNT_PATH"; \
            fi && \
            echo '操作完成'
            """
        }
        
        let appleScript = """
        do shell script "\(shellScript.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.executeAppleScript(script: appleScript) { success, output in
                DispatchQueue.main.async {
                    self.stopProgressUpdates()
                    
                    if success {
                        self.installationProgress = 1.0
                        self.logPublisher.send("安装完成")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.isInstalling = false
                            self.installationProgress = 0
                        }
                        self.showAlert(title: "操作成功", message: "指定的内核扩展已安装")
                    } else {
                        self.logPublisher.send("错误: 安装失败 - \(output ?? "无输出")")
                        self.isInstalling = false
                        self.installationProgress = 0
                        self.showAlert(title: "操作失败", message: output ?? "未知错误")
                        self.errorOperation()
                    }
                }
            }
        }
    }
    
    private func kextInstallationCommands(mountPath: String, forceOverwrite: Bool, backupExisting: Bool) -> String {
        var commands = [String]()
        let backupDir = "\(NSHomeDirectory())/Desktop/SimpleLoaderBak"
        
        // 创建备份目录（如果需要）
        if backupExisting {
            commands.append("mkdir -p '\(backupDir)'")
        }
        
        for path in kextPaths {
            let kextName = URL(fileURLWithPath: path).lastPathComponent
            let destPath = "\(mountPath)/System/Library/Extensions/\(kextName)"
            
            commands.append("echo '正在处理 \(kextName)'")
            
            // 备份现有文件（如果需要）
            if backupExisting {
                commands.append("""
                if [ -d "\(destPath)" ]; then \
                    rsync -a "\(destPath)" "\(backupDir)/\(kextName)" && \
                    echo "已备份原有 \(kextName)"; \
                fi
                """)
            }
            
            // 安装新文件
            if forceOverwrite {
                commands.append("""
                rsync -r -i -a --delete "\(path)" "\(mountPath)/System/Library/Extensions/ \"
                """)
            } else {
                commands.append("""
                if [ ! -d "\(destPath)" ]; then \
                    rsync -r -i -a "\(path)" "\(mountPath)/System/Library/Extensions/"; \
                else \
                    echo "跳过已存在的 \(kextName)"; \
                fi
                """)
            }
            
            commands.append("""
                            echo "已处理 \(kextName)"
            """)
        }
        return commands.joined(separator: " && \\\n")
    }
    
    private func startProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isInstalling || self.isMerging else { return }
            
            DispatchQueue.main.async {
                if self.installationProgress < 0.95 {
                    self.installationProgress += 0.05
                }
            }
        }
    }
    
    private func stopProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func cancelOperation() {
        isInstalling = false
        isMerging = false
        installationProgress = 0
        currentOperation = nil
        stopProgressUpdates()
        logPublisher.send("操作已取消")
    }
    func errorOperation() {
        isInstalling = false
        isMerging = false
        installationProgress = 0
        currentOperation = nil
        stopProgressUpdates()
        logPublisher.send("操作失败")
    }
    
    func openKDKDirectory() {
        let url = URL(fileURLWithPath: kdkDirectory)
        NSWorkspace.shared.open(url)
        logPublisher.send("已打开KDK目录: \(kdkDirectory)")
    }
    
    private func checkKDKDirectory() {
        let url = URL(fileURLWithPath: kdkDirectory)
        if fileManager.fileExists(atPath: url.path) {
            logPublisher.send("KDK目录存在: \(kdkDirectory)")
            refreshKDKList()
        } else {
            logPublisher.send("警告: KDK目录不存在")
        }
    }
    
    private func executeAppleScript(script: String, completion: @escaping (Bool, String?) -> Void) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if let error = error {
                completion(false, error.description)
            } else {
                completion(true, output.stringValue)
            }
        } else {
            completion(false, "无法创建 AppleScript 对象")
        }
    }
    
    func rebuildKernelCache() {
        isInstalling = true
        installationProgress = 0
        logPublisher.send("开始重建内核缓存...")
        
        startProgressUpdates()
        
        let shellScript = """
        echo '开始重建内核缓存...' && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            umount "$MOUNT_PATH"; \
        fi && \
        echo '内核缓存重建完成'
        """
        
        executeScriptWithProgress(shellScript: shellScript, successMessage: "内核缓存重建成功", failureMessage: "内核缓存重建失败")
    }
    
    func createSystemSnapshot() {
        isInstalling = true
        installationProgress = 0
        logPublisher.send("开始创建系统快照...")
        
        startProgressUpdates()
        
        let shellScript = """
        echo '开始创建系统快照...' && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            umount "$MOUNT_PATH"; \
        fi && \
        echo '系统快照创建完成'
        """
        
        executeScriptWithProgress(shellScript: shellScript, successMessage: "系统快照创建成功", failureMessage: "系统快照创建失败")
    }
    
    func restoreLastSnapshot() {
        isInstalling = true
        installationProgress = 0
        logPublisher.send("开始恢复最后一个快照...")
        
        startProgressUpdates()
        
        let shellScript = """
        echo '开始恢复最后一个快照...' && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        bless --mount "$MOUNT_PATH" --bootefi --last-sealed-snapshot && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            umount "$MOUNT_PATH"; \
        fi && \
        echo '快照恢复完成'
        """
        
        executeScriptWithProgress(shellScript: shellScript, successMessage: "快照恢复成功", failureMessage: "快照恢复失败")
    }
    
    private func executeScriptWithProgress(shellScript: String, successMessage: String, failureMessage: String) {
        let appleScript = """
        do shell script "\(shellScript.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.executeAppleScript(script: appleScript) { success, output in
                DispatchQueue.main.async {
                    self.stopProgressUpdates()
                    
                    if success {
                        self.installationProgress = 1.0
                        self.logPublisher.send(successMessage)
                        self.showAlert(title: "操作成功", message: successMessage)
                    } else {
                        self.logPublisher.send("错误: \(failureMessage) - \(output ?? "无输出")")
                        self.showAlert(title: "操作失败", message: output ?? failureMessage)
                        self.errorOperation()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.isInstalling = false
                        self.installationProgress = 0
                    }
                }
            }
        }
    }
}
