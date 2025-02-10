//
//  RootView.swift
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

struct RootView: View {
    @State private var colorCycleTask: Task<Void, Never>?
    @State private var colorCycleHue: Double
    @State private var backgroundColor: Color
    
    @State private var isShowingSettings = false
    
    init() {
        let startingHue = 0.65
        colorCycleHue = startingHue
        backgroundColor = .connectBackgroundColor(hue: startingHue)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                actionButton
            }
            .ignoresSafeArea()
            .safeAreaInset(edge: .bottom) {
                Button {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                } label: {
                    Image(systemName: "gear")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.white)
                }
                .padding()
            }
            .onAppear(perform: startColorCycle)
            .onDisappear(perform: stopColorCycle)
            .navigationDestination(isPresented: $isShowingSettings) {
                MarqueeSettingsView()
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Image(systemName: "tv.badge.wifi")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 350)
                .padding([.leading], 50)
                .padding([.trailing], 25)
                .overlay {
                    Text("Tap to connect to MiniMarquee")
                        .multilineTextAlignment(.center)
                        .frame(width: 242, height: 144)
                        .offset(CGSize(width: -26, height: -30))
                        .font(.title)
                }
        }
        .foregroundStyle(.white)
        .shadow(radius: 8)
    }
    
    private func startColorCycle() {
        if colorCycleTask != nil {
            return
        }
        
        colorCycleTask = Task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(0.2))
                
                // Slowly and continuously increase while wrapping back to zero at 1.0
                colorCycleHue = (colorCycleHue + 0.005).truncatingRemainder(dividingBy: 1.0)
                backgroundColor = .connectBackgroundColor(hue: colorCycleHue)
            }
        }
    }
    
    private func stopColorCycle() {
        colorCycleTask?.cancel()
        colorCycleTask = nil
    }
}

private extension Color {
    static func connectBackgroundColor(hue: Double) -> Self {
        .init(hue: hue, saturation: 0.7, brightness: 0.5)
    }
}

#Preview {
    RootView()
}
