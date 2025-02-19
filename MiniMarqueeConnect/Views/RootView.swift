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
    @State private var backgroundHue: Double = 0
    @State private var isShowingSettings = false
    
    private let colorCycleDuration: Double = 30
    
    // Offset so we start at blue instead of red
    private let colorCycleOffset: Double = 234
    
    private var shouldShowSettingsButton: Bool {
        ProcessInfo.processInfo.isiOSAppOnMac == false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor(hue: backgroundHue,
                                        saturation: 0.7,
                                        brightness: 0.5,
                                        alpha: 1.0)))
                    .hueRotation(Angle(degrees: backgroundHue + colorCycleOffset))
                    .onAppear {
                        withAnimation(
                            .linear(duration: colorCycleDuration)
                            .repeatForever(autoreverses: false)
                        ) {
                            backgroundHue = 360
                        }
                    }
                
                actionButton
            }
            .ignoresSafeArea()
            .safeAreaInset(edge: .bottom) {
                if shouldShowSettingsButton {
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
            }
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
}

#Preview {
    RootView()
}
