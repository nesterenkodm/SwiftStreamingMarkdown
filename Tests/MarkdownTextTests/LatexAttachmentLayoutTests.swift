//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import iosMath
@testable import SwiftStreamingMarkdown
import XCTest

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class LatexAttachmentLayoutTests: XCTestCase {
  func testInlineFormulasShareTheirMathematicalBaseline() throws {
    let plain = try metrics(for: "x")
    let superscript = try metrics(for: "x^2")
    let withSubscript = try metrics(for: "x_2")

    XCTAssertGreaterThan(withSubscript.descent, plain.descent)
    XCTAssertEqual(plain.baselinePosition, 0, accuracy: 0.001)
    XCTAssertEqual(superscript.baselinePosition, 0, accuracy: 0.001)
    XCTAssertEqual(withSubscript.baselinePosition, 0, accuracy: 0.001)
  }

  private func metrics(for latex: String) throws -> (descent: CGFloat, baselinePosition: CGFloat) {
    let label = MTMathUILabel()
    label.latex = latex
    label.displayErrorInline = false
    label.fontSize = 17

    #if canImport(UIKit)
    label.sizeToFit()
    label.layoutIfNeeded()
    let size = label.bounds.size
    #elseif canImport(AppKit)
    let size = label.intrinsicContentSize
    label.frame.size = size
    label.layoutSubtreeIfNeeded()
    #endif

    let displayList = try XCTUnwrap(label.displayList)
    let attachmentHeight = size.height.rounded(.up) + 1
    let bottomPadding = max(
      0,
      attachmentHeight - displayList.ascent - displayList.descent
    ) / 2
    let offset = LatexAttachmentLayout.baselineOffset(
      displayAscent: displayList.ascent,
      displayDescent: displayList.descent,
      attachmentHeight: attachmentHeight
    )

    return (
      displayList.descent,
      offset + displayList.descent + bottomPadding
    )
  }
}
