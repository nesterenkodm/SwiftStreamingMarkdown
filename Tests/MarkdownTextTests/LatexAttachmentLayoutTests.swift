//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwaTexRender
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
    let view = SwaTexView()
    view.latex = latex
    view.fontSize = 17
    view.mathStyle = .text

    _ = view.intrinsicContentSize
    let descent = view.baselineFromBottom
    let offset = -descent

    return (
      descent,
      offset + descent
    )
  }
}
