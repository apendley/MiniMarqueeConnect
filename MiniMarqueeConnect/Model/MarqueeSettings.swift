//
//  MarqueeSettings.swift
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

struct MarqueeSettings: Codable, Equatable {
    static let messageCharacterLimit = 511
    
    var message: String = ""
    var speed: Speed = .moderate
    var brightness: Brightness = .moderate
    var rotation: Rotation = .up
    var font: Font = .adafruit
    var textColor: TextColor = .rainbow
}

extension MarqueeSettings {
    enum TextColor: Int, CaseIterable, Codable {
        case rainbow, white, red, orange, yellow, green, cyan, blue, purple, magenta
        
        var title: String {
            switch self {
            case .white:
                "White"
            case .red:
                "Red"
            case .orange:
                "Orange"
            case .yellow:
                "Yellow"
            case .green:
                "Green"
            case .cyan:
                "Cyan"
            case .blue:
                "Blue"
            case .purple:
                "Purple"
            case .magenta:
                "Magenta"
            default:
                "Rainbow"
            }
        }
        
        var uiColor: UIColor {
            switch self {
            case .white:
                .rgba8(255, 255, 255)
            case .red:
                .rgba8(255, 0, 0)
            case .orange:
                .rgba8(255, 165, 0)
            case .yellow:
                .rgba8(255, 255, 0)
            case .green:
                .rgba8(0, 255, 0)
            case .cyan:
                .rgba8(0, 255, 255)
            case .blue:
                .rgba8(0, 0, 255)
            case .purple:
                .rgba8(128, 0, 255)
            case .magenta:
                .rgba8(255, 0, 255)
            default:
                .rgba8(0, 0, 0)
            }
        }
        
        var color: Color {
            .init(uiColor)
        }
    }
    
    enum Speed: Int, CaseIterable, Codable {
        case verySlow, slow, moderate, fast, veryFast
        
        var title: String {
            switch self {
            case .verySlow:
                "Very Slow"
            case .slow:
                "Slow"
            case .moderate:
                "Moderate"
            case .fast:
                "Fast"
            default:
                "Very Fast"
            }
        }
    }
    
    enum Brightness: Int, CaseIterable, Codable {
        case veryDim, dim, moderate, bright, veryBright
        
        var title: String {
            switch self {
            case .veryDim:
                "Very Dim"
            case .dim:
                "Dim"
            case .moderate:
                "Moderate"
            case .bright:
                "Bright"
            default:
                "Very Bright"
            }
        }
    }
    
    enum Rotation: Int, CaseIterable, Codable {
        case down, left, up, right
        
        var title: String {
            switch self {
            case .down:
                "Down"
            case .left:
                "Left"
            case .up:
                "Up"
            default:
                "Right"
            }
        }
    }
    
    enum Font: Int, CaseIterable, Codable {
        case adafruit, fixed, fixedMono, ancient
        
        var title: String {
            switch self {
            case .fixed:
                "Fixed"
            case .fixedMono:
                "Fixed Mono"
            case .ancient:
                "Ancient"
            default:
                "Adafruit"
            }
        }
    }
}
