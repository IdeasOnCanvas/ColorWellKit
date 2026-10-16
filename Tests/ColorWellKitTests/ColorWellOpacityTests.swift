//
//  ColorWellOpacityTests.swift
//  ColorWellKit
//

import AppKit
import SwiftUI
import Testing
@testable import ColorWellKit

@MainActor
@Suite(.serialized)
struct ColorWellOpacityTests {

    @Test(arguments: [false, true])
    func clearSelectionRespectsOptIn(allowsClear: Bool) {
        let colorWell = ColorWellRepresentable.BridgedColorWell(color: .red)
        colorWell.allowsClear = allowsClear
        colorWell.supportsOpacity = false
        var selection = NSColor.red
        let representable = ColorWellRepresentable(
            selection: Binding(get: { selection }, set: { selection = $0 }),
            supportsOpacity: false,
            allowsClear: allowsClear
        )
        let delegate = representable.makeCoordinator()
        colorWell.delegate = delegate

        // Swatches use this same entry point and delegate notification.
        colorWell.updateColor(NSColor(Color.clear), options: [.informDelegate])

        #expect(selection.alphaComponent == (allowsClear ? 0 : 1))
        #expect(colorWell.color.alphaComponent == selection.alphaComponent)
    }

    @Test(arguments: [0.0, 0.25, 0.5, 1.0])
    func otherColorsRemainOpaque(alpha: Double) {
        let colorWell = ColorWellRepresentable.BridgedColorWell(color: .blue)
        colorWell.allowsClear = true
        colorWell.supportsOpacity = false
        let input = NSColor(srgbRed: 0.8, green: 0.2, blue: 0.4, alpha: alpha)

        colorWell.updateColor(input, options: [])

        #expect(colorWell.color.resembles(input.withAlphaComponent(1), tolerance: 0))
    }

    @Test
    func disablingClearNormalizesExistingSelection() {
        let colorWell = ColorWellRepresentable.BridgedColorWell(color: .red)
        colorWell.allowsClear = true
        colorWell.supportsOpacity = false
        colorWell.color = .clear
        #expect(colorWell.color.alphaComponent == 0)

        colorWell.allowsClear = false

        #expect(colorWell.color.alphaComponent == 1)
    }

    @Test(arguments: [false, true])
    func opacitySupportPreservesPartialTransparency(allowsClear: Bool) {
        let input = NSColor(srgbRed: 0.8, green: 0.2, blue: 0.4, alpha: 0.4)
        let colorWell = ColorWellRepresentable.BridgedColorWell(color: .blue)
        colorWell.allowsClear = allowsClear
        colorWell.supportsOpacity = true

        colorWell.updateColor(input, options: [])

        #expect(colorWell.color == input)
    }

    @Test
    func clearDoesNotExposeOpacityControl() {
        let colorPanel = NSColorPanel.shared
        let originalShowsAlpha = colorPanel.showsAlpha
        let originalColor = colorPanel.color
        let colorWell = ColorWellRepresentable.BridgedColorWell(color: .red)
        colorWell.allowsMultipleSelection = false
        colorWell.allowsClear = true
        colorWell.supportsOpacity = false
        let representable = ColorWellRepresentable(selection: .constant(.red), supportsOpacity: false, allowsClear: true)
        let delegate = representable.makeCoordinator()
        colorWell.delegate = delegate
        defer {
            colorWell.isActive = false
            colorPanel.showsAlpha = originalShowsAlpha
            colorPanel.color = originalColor
            colorPanel.orderOut(nil)
        }

        colorPanel.showsAlpha = true
        colorWell.isActive = true

        #expect(colorWell.isActive)
        #expect(colorPanel.showsAlpha == false)
        colorWell.updateColor(.clear, options: [.informDelegate])
        #expect(colorWell.color.alphaComponent == 0)
        #expect(colorPanel.showsAlpha == false)
    }
}
