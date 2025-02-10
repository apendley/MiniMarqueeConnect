//
//  MarqueeSettingsView.swift
//
//  ISC Licence
//
//  Copyright (c) 2025 Aaron Pendley
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or
//  without fee is hereby granted, provided that the above copyright notice and this permission
//  notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
//  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import SwiftUI

struct MarqueeSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    @State private var viewState = ViewState.initial

    @State private var currentSettings: MarqueeSettings?
    @State private var editedSettings = MarqueeSettings()
    
    @FocusState private var isMessageFocused: Bool
    
    @State private var isShowingColorPicker = false
    
    @State private var errorAlertConfig: AlertConfig?
    @State private var isShowingError = false
    
    // True if current settings don't match edited settings
    private var shouldSendUpdate: Bool {
        // Nothing to send if we've not even been able to connect yet.
        guard let currentSettings else {
            return false
        }
        
        // Modified settings match current settings, nothing to update.
        if editedSettings == currentSettings {
            return false
        }
        
        // If we send an empty message to the MiniMarquee, it will ignore it.
        // So, if the message field is empty, we only need to send an update
        // if any of the other settings have changed.
        if editedSettings.message == "",
           currentSettings.message.isEmpty == false,
           editedSettings.speed == currentSettings.speed,
           editedSettings.brightness == currentSettings.brightness,
           editedSettings.rotation == currentSettings.rotation,
           editedSettings.font == currentSettings.font,
           editedSettings.textColor == currentSettings.textColor
        {
            return false
        }
        
        // Something's changed, we need to update!
        return true
    }
    
    private var isUpdateButtonDisabled: Bool {
        if viewState.isInitial || viewState.isBusy {
            return true
        }
        
        return shouldSendUpdate == false
    }
    
    // Shorthand for dimmed opacity of child views when busy
    private var childOpacity: CGFloat {
        viewState.isBusy ? 0.5 : 1.0
    }
    
    // If nil, the permission check is skipped (useful for previews).
    // Otherwise, this method is used to request the local network
    // permission state, possibly initiating a system prompt.
    private let requestLocalNetworkPermission: (() async throws -> Void)?
    
    private let dataSource: any MarqueeSettingsDataSource
    
    // By default, request local network authorization, and use the remote data source.
    init(requestLocalNetworkPermission: (() async throws -> Void)? = requestLocalNetworkAuthorization,
         dataSource: any MarqueeSettingsDataSource = MarqueeSettings.DataSource.Remote())
    {
        self.requestLocalNetworkPermission = requestLocalNetworkPermission
        self.dataSource = dataSource
    }
    
    var body: some View {
        List {
            messageSection
            settingsSection
            updateSection
        }
        .navigationTitle("MiniMarquee")
        .toolbarTitleDisplayMode(.inline)
        .listStyle(.grouped)
        .disabled(viewState.isBusy)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewState.isBusy {
                    ProgressView()
                } else {
                    Button {
                        load()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear() {
            load()
        }
        .sheet(isPresented: $isShowingColorPicker) {
            TextColorPickerView { color in
                editedSettings.textColor = color
            }
            // This provides just enough space to show the whole color picker
            .presentationDetents([.height(324)])
        }
        .alert(errorAlertConfig?.title ?? "Error", isPresented: $isShowingError, actions: {
            if let errorAlertConfig {
                if let retry = errorAlertConfig.onRetryAfterError {
                    Button("Retry") {
                        retry()
                    }
                }
                
                if let onReturnFromSettings = errorAlertConfig.onReturnFromSettings {
                    Button("Go to Settings") {
                        viewState = .waitingForReturnFromSettings(retry: onReturnFromSettings)
                        
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                // Dismiss this view since we cannot proceed.
                dismiss()
            }
        }, message: {
            if let message =  errorAlertConfig?.message {
                Text(message)
            }
        })
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, case .waitingForReturnFromSettings(let retry) = viewState {
                retry()
            }
        }
    }
    
    @ViewBuilder
    private var messageSection: some View {
        Section("Message (\(editedSettings.message.count)/\(MarqueeSettings.messageCharacterLimit))") {
            HStack {
                TextField("Enter message", text: $editedSettings.message, axis: .vertical)
                    .keyboardType(.asciiCapable)
                    .focused($isMessageFocused)
                    .onChange(of: isMessageFocused) { oldValue, newValue in
                        if newValue == false, oldValue == true {
                            editedSettings.message = sanitize(message: editedSettings.message)
                        }
                    }
                    .onChange(of: editedSettings.message) { _, newValue in
                        if newValue.contains(where: { $0 == "\n" }) {
                            isMessageFocused = false
                        } else {
                            editedSettings.message = String(newValue.prefix(MarqueeSettings.messageCharacterLimit));
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("Dismiss Keyboard", systemImage: "keyboard.chevron.compact.down.fill") {
                                isMessageFocused = false
                            }
                        }
                    }
                
                Image(systemName: editedSettings.message.isEmpty ? "trash.circle" : "trash.circle.fill")
                    .resizable()
                    .foregroundColor(editedSettings.message.isEmpty ? .gray : .red)
                    .background(editedSettings.message.isEmpty ? .clear : .white)
                    .frame(width: 30, height: 30)
                    .clipShape(.circle)
                    .frame(width: 44, height: 44)
                    .onTapGesture {
                        editedSettings.message = ""
                    }
                    .disabled(editedSettings.message.isEmpty)
            }
            .opacity(childOpacity)
        }
    }
    
    @ViewBuilder
    private var settingsSection: some View {
        Section("Settings") {
            HStack {
                Text("Text color")
                
                Spacer()
                
                Button {
                    isShowingColorPicker = true
                } label: {
                    TextColorPickerCell(textColor: editedSettings.textColor, padding: 6)
                        .frame(width: 120, height: 44)
                        // For some reason on device the opacity applied
                        // to the parent HStack isn't getting applied here...
                        .opacity(childOpacity)
                }
            }
            .opacity(childOpacity)
            
            VStack(alignment: .leading) {
                enumPicker("Brightness", selection: $editedSettings.brightness) {
                    Text($0.title)
                }
                
                if editedSettings.brightness == .veryDim {
                    Text("On '\(editedSettings.brightness.title)' brightness, colors will lose resolution and may not appear as expected.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .opacity(childOpacity)
            
            enumPicker("Speed", selection: $editedSettings.speed) {
                Text($0.title)
            }
            .opacity(childOpacity)
            
            enumPicker("Font", selection: $editedSettings.font) {
                Text($0.title)
            }
            .opacity(childOpacity)
            
            enumPicker("Rotation", selection: $editedSettings.rotation) {
                Text($0.title)
            }
            .opacity(childOpacity)
        }
    }
    
    @ViewBuilder
    private var updateSection: some View {
        if shouldSendUpdate {
            Section("Press update to send modified settings to MiniMarquee") {
                HStack {
                    Spacer()
                    
                    updateButton
                        .buttonStyle(.borderedProminent)
                        .clipShape(.capsule)
                        .frame(height: 44)
                    
                    Spacer()
                }
            }
        } else {
            Section("MiniMarquee is up to date!") { }
        }
    }
    
    @ViewBuilder
    private var updateButton: some View {
        if viewState.isBusy {
            Button {
                // Do nothing, disabled anyway
            } label: {
                HStack {
                    Image(systemName: "tv.badge.wifi.fill")
                    Text("Updating...")
                }
            }
            .disabled(true)
        } else {
            Button {
                isMessageFocused = false
                postUpdate()
            } label: {
                HStack {
                    Image(systemName: "tv.badge.wifi.fill")
                    Text("Update")
                }
            }
            .disabled(isUpdateButtonDisabled)
        }
    }
    
    private func load() {
        checkLocalNetworkPermissionThen {
            viewState = .loading
            
            do {
                let updatedSettings = try await dataSource.settings
                settingsUpdated(updatedSettings)
            } catch {
                print("Failed to load settings: \(error.localizedDescription)")
                viewState = .error
                showAlert(config: .init(title: "Connection Error",
                                        message: "Unable to connect to MiniMarquee. Make sure you are connected to the 'MiniMarquee' Wi-Fi hotspot and try again",
                                        onRetryAfterError: load))
            }
        }
    }
    
    private func postUpdate() {
        checkLocalNetworkPermissionThen {
            do {
                editedSettings.message = sanitize(message: editedSettings.message)
                let updatedSettings = try await dataSource.update(with: editedSettings)
                settingsUpdated(updatedSettings)
            } catch {
                print("Failed to post update: \(error.localizedDescription)")
                viewState = .error
                showAlert(config: .init(title: "Connection Error",
                                        message: "Unable to connect to MiniMarquee. Make sure you are connected to the 'MiniMarquee' Wi-Fi hotspot and try again",
                                        onRetryAfterError: postUpdate))
            }
        }
    }
    
    private func checkLocalNetworkPermissionThen(perform: @escaping () async -> Void) {
        if viewState.isBusy, viewState.isWaitingForReturnFromSettings == false {
            return
        }
  
        viewState = .checkingLocalNetworkPermission
        
        Task {
            do {
                if let requestLocalNetworkPermission {
                    try await requestLocalNetworkPermission()
                }
            } catch is LocalNetworkAuthorizationDenied {
                showAlert(config: .init(title: "Permissions Error",
                                        message: "Please enable the 'Local Network' permission in the Settings app so MiniMarqueeConnect can connect to the device",
                                        onReturnFromSettings: { checkLocalNetworkPermissionThen { await perform() } }))
                
                return
            } catch {
                showAlert(config: .init(title: "Unexpected Error",
                                        message: "Failed to retrieve local network access permission",
                                        onRetryAfterError: { checkLocalNetworkPermissionThen { await perform() } }))
                
                return
            }
            
            await perform()
        }
    }
    
    
    private func settingsUpdated(_ newSettings: MarqueeSettings) {
        editedSettings = newSettings
        currentSettings = newSettings
        viewState = .loaded
    }
    
    private func showAlert(config: AlertConfig? = nil) {
        errorAlertConfig = config
        isShowingError = true
    }
    
    private func sanitize(message: String) -> String {
        let trimmed = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
        
        return String(trimmed.prefix(MarqueeSettings.messageCharacterLimit))
    }
}

// Internal types
private extension MarqueeSettingsView {
    enum ViewState {
        // Just initialized
        case initial
        
        // Checking for local network access
        case checkingLocalNetworkPermission
        
        // When checking permission, if denied, we prompt the user with an option
        // to go to the settings screen and change the 'local network' permission.
        // Then, we wait in this state until returning from the background,
        // at which point we retry the permission check again to make sure they enabled it.
        case waitingForReturnFromSettings(retry: () -> Void)
        
        // Currently retrieving current settings from device
        case loading
        
        // Settings have been retrieved from device and user can edit them.
        case loaded
        
        // Currently sending updated settings to device.
        case updating
        
        // There was some sort of error.
        case error
        
        // Shorthand to check for initial state
        var isInitial: Bool {
            if case .initial = self {
                return true
            }
            
            return false
        }
        
        // Shorthand to check for waiting state
        var isWaitingForReturnFromSettings: Bool {
            if case .waitingForReturnFromSettings = self {
                return true
            }
            
            return false
        }
        
        // Shorthand to check for states that perform some async activity
        var isBusy: Bool {
            switch self {
            case .checkingLocalNetworkPermission,
                    .waitingForReturnFromSettings,
                    .loading,
                    .updating:
                return true
                
            default:
                return false
            }
        }
    }
    
    struct AlertConfig {
        var title: String
        var message: String? = nil
        var onReturnFromSettings: (() -> Void)? = nil
        var onRetryAfterError: (() -> Void)? = nil
    }
}

// This may be overkill but it was fun to write.
// Besides, I have 4 pickers with basically identical code.
private func enumPicker<T>(_ title: String,
                           selection: Binding<T>,
                           content: @escaping (T) -> some View)
-> some View
where T: Hashable & CaseIterable & RawRepresentable,
      T.AllCases: RandomAccessCollection
{
    Picker(title, selection: selection) {
        ForEach(T.self.allCases, id: \.self) {
            content($0)
        }
    }
}

#Preview {
    // Use this data source to edit UI with a fake (i.e. not connected) data source.
    let dataSource = MarqueeSettings.DataSource.Preview(loadDelay: 0, updateDelay: 3)
    
    // Or you can use the actual data source if you've connected your computer's Wi-Fi to the MiniMarquee
    //let dataSource = MarqueeSettings.DataSource.Remote()
    
    // Present in a navigation stack so we can see the title and toolbar in the preview
    NavigationStack {
        MarqueeSettingsView(requestLocalNetworkPermission: nil, dataSource: dataSource)
    }
}
