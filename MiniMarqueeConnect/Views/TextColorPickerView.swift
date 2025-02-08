//
//  TextColorPickerView.swift
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

struct TextColorPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    var onColorSelected: ((MarqueeSettings.TextColor) -> Void)?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        VStack {
            Text("Choose a color")
                .foregroundStyle(.primary)
                .bold()
            
            LazyVGrid(columns: columns) {
                ForEach(MarqueeSettings.TextColor.allCases, id: \.self) { textColor in
                    Button {
                        onColorSelected?(textColor)
                        dismiss()
                    } label: {
                        TextColorPickerCell(textColor: textColor)
                            .frame(height: 44)

                    }
                }
            }
        }
        .padding(20)
    }
}

struct TextColorPickerCell: View {
    let textColor: MarqueeSettings.TextColor
    let padding: CGFloat
    
    init(textColor: MarqueeSettings.TextColor, padding: CGFloat = 8) {
        self.textColor = textColor
        self.padding = padding
    }
    
    var body: some View {
        backgroundView
            .clipShape(.capsule)
            .shadow(radius: 8)
            .overlay {
                Color.black.opacity(0.6)
                    .clipShape(.capsule)
                    .padding(padding)
                    .overlay {
                        Text(textColor.title)
                            .foregroundStyle(.white)
                        
                    }
            }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if textColor == .rainbow {
            LinearGradient(gradient: .init(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]),
                           startPoint: .leading,
                           endPoint: .trailing)
        } else {
            textColor.color
        }
    }
}

#Preview {
    TextColorPickerView()
}
