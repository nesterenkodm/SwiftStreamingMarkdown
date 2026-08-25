//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import Markdown
@testable import SwiftStreamingMarkdown
import UIKit
import XCTest

@MainActor
final class TypographyPropagationTests: XCTestCase {
  let parser: MarkdownParser = MarkdownParserImpl()

  func testHeaderTypographyPropagation() async throws {
    let text = "# This is a *header*"
    let document = await parser.parse(text: text)

    // Check if the document has a Heading
    guard let heading = document.child(at: 0) as? Heading else {
      XCTFail("Should have a heading")
      return
    }

    // Convert the heading to renderable
    let config = MarkdownRenderConfig.default
    // Headings use different typography based on level.
    // Level 1 maps to extraLargeTextFonts in the rendering logic.
    let headingFonts = Typography.extraLargeTextFonts

    let renderable = heading.convert(attributeContainer: .init(), config: config)

    if case .heading(_, let level, let attributedString) = renderable {
      XCTAssertEqual(level, 1)

      // The attributed string should have the .font attribute set to extraLarge normal
      // and for the italic part, it should be extraLarge italic.

      // Find the range of "header" (which is italicized)
      let string = attributedString.string
      guard let headerRange = string.range(of: "header") else {
        XCTFail("Should find 'header' in string")
        return
      }
      let nsHeaderRange = NSRange(headerRange, in: string)

      // Check attribute for "This is a "
      let regularFont = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
      XCTAssertEqual(regularFont, headingFonts.normal)

      // Check attribute for "header"
      let italicFont = attributedString.attribute(.font, at: nsHeaderRange.location, effectiveRange: nil) as? UIFont
      XCTAssertEqual(italicFont, headingFonts.italic)
    } else {
      XCTFail("Renderable should be a heading")
    }
  }

  func testStrongItalicTypographyPropagation() async throws {
    let text = "Text with ***strong italic***"
    let document = await parser.parse(text: text)

    guard let paragraph = document.child(at: 0) as? Paragraph else {
      XCTFail("Should have a paragraph")
      return
    }

    let config = MarkdownRenderConfig.default
    let renderable = paragraph.convert(attributeContainer: .init(), config: config)

    if case .paragraph(_, let attributedString) = renderable {
      let string = attributedString.string
      guard let strongItalicRange = string.range(of: "strong italic") else {
        XCTFail("Should find 'strong italic' in string")
        return
      }
      let nsRange = NSRange(strongItalicRange, in: string)

      let font = attributedString.attribute(.font, at: nsRange.location, effectiveRange: nil) as? UIFont
      XCTAssertEqual(font, Typography.baseTextFonts.boldItalic)
    } else {
      XCTFail("Renderable should be a paragraph")
    }
  }

  func testInlineMathUsesConfiguredScaleAndInheritedFont() async throws {
    let document = await parser.parse(text: "Inline \\(x^2\\)")
    let bodySize: CGFloat = 20
    let bodyFonts = TextFonts(
      normal: .systemFont(ofSize: bodySize),
      italic: .italicSystemFont(ofSize: bodySize),
      bold: .boldSystemFont(ofSize: bodySize),
      boldItalic: .boldSystemFont(ofSize: bodySize),
      preferredLetterSpacing: nil,
      preferredLineHeight: nil
    )
    let config = MarkdownRenderConfig(
      paragraphStyle: .init(textFonts: bodyFonts, textColor: .primary),
      mathStyle: .init(inlineScale: 1.08, displayScale: 1)
    )

    guard case .paragraph(_, let content) = document.convert(with: config).first,
          let attachment = content.attribute(
            NSAttributedString.Key.attachment,
            at: content.length - 1,
            effectiveRange: nil
          ) as? NSTextAttachment,
          let payload = attachment.contents,
          let attachmentData = try? JSONDecoder().decode(LatexAttachmentData.self, from: payload) else {
      XCTFail("Expected an encoded inline formula attachment")
      return
    }

    XCTAssertEqual(attachmentData.fontSize, bodySize * 1.08, accuracy: 0.001)
  }

  func testMathStyleBuilderPreservesIndependentScales() {
    let mathStyle = MarkdownRenderConfig.MarkdownMathStyle(
      inlineScale: 1.08,
      displayScale: 1.12
    )
    let config = MarkdownRenderConfig.default
      .withMathStyle(value: mathStyle)
      .withBlockSpacing(value: 12)

    XCTAssertEqual(config.mathStyle, mathStyle)
  }

  func testUnorderedListStyleBuilderPreservesMarkerLayout() {
    let listStyle = MarkdownRenderConfig.MarkdownUnorderedListStyle(
      markerColor: .red,
      markerSize: 5,
      markerColumnWidth: 12,
      markerSpacing: 4,
      itemSpacing: 6
    )
    let config = MarkdownRenderConfig.default
      .withUnorderedListStyle(value: listStyle)
      .withBlockSpacing(value: 12)

    XCTAssertEqual(config.unorderedListStyle, listStyle)
  }
}
#endif
