//
//  MarqueeSettingsDataSource.swift
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
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import Foundation

// Allow for multiple implementations, namely one for the "live" environment and one for previews
protocol MarqueeSettingsDataSource: Sendable {
    // Fetch the most current settings
    var settings: MarqueeSettings { get async throws }
    
    // Send user-modified settings to MiniMarque. Returns updated settings from MiniMarquee.
    func update(with settings: MarqueeSettings) async throws -> MarqueeSettings
}

// Empty DataSource enum simulates a namespace to hold our concrete data source implementations.
extension MarqueeSettings {
    enum DataSource { }
}

// Convenient place to put the default MiniMarquee host URL
extension URL {
    static let defaultMiniMarqueeHostURL = URL(string: "http://192.168.4.1")!
}

// MarqueeSettings.DataSource.Remote connects to the MiniMarquee
// over local wifi connection using http to get and update the settings.
extension MarqueeSettings.DataSource {
    struct Remote: MarqueeSettingsDataSource {
        let hostURL: URL
        private let settingsPath = "settings"
        private let networkClient: NetworkClient
        
        init(hostURL: URL = .defaultMiniMarqueeHostURL) {
            self.hostURL = hostURL
            
            // Ephemeral because we don't need any caching or credential stores.
            let configuration = URLSessionConfiguration.ephemeral

            // Use low timeout values. It shouldn't take long to connect to the MiniMarquee.
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 10

            let urlSession = URLSession(configuration: configuration)
            networkClient = .init(host: hostURL, urlSession: urlSession)
        }
        
        var settings: MarqueeSettings {
            get async throws {
                return try await networkClient.json(from: settingsPath)
            }
        }
        
        func update(with settings: MarqueeSettings) async throws -> MarqueeSettings {
            return try await networkClient.post(json: settings, to: settingsPath)
        }
    }
}

// MarqueeSettings.DataSource.Preview is used in previews so that we can edit our views
// without having to actually connect to the MiniMarquee. Optional load and update
// delays can be provided to simulate communcation delays for editing loading UI.
extension MarqueeSettings.DataSource {
    @MainActor
    class Preview: MarqueeSettingsDataSource {
        private let loadDelay: Double
        private let updateDelay: Double
        private var cachedSettings = MarqueeSettings()
        
        init(loadDelay: Double = 0, updateDelay: Double = 0) {
            self.loadDelay = loadDelay
            self.updateDelay = updateDelay
        }
        
        var settings: MarqueeSettings {
            get async throws {
                if loadDelay > 0 {
                    try await Task.sleep(for: .seconds(loadDelay))
                }
                
                return cachedSettings
            }
        }
        
        func update(with settings: MarqueeSettings) async throws -> MarqueeSettings {
            if updateDelay > 0 {
                try await Task.sleep(for: .seconds(updateDelay))
            }
            
            // Mimic the logic used by the MiniMarquee:
            // if the updated message is empty, retain the previous message.
            if settings.message.isEmpty {
                let previousMessage = cachedSettings.message
                cachedSettings = settings
                cachedSettings.message = previousMessage
            } else {
                cachedSettings = settings
            }
            
            return cachedSettings
        }
    }
}
