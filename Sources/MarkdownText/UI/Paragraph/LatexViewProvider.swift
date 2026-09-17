//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwaTexRender
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - LatexAttachmentData Color Resolution

extension LatexAttachmentData {
  var resolvedTextColor: MDColor {
    let fallback = MDColor(Color.Theme.Foreground.Primary.Primary750)
    #if canImport(UIKit)
    guard let lightColor = UIColor(hex: lightTextColor),
          let darkColor = UIColor(hex: darkTextColor) else {
      return fallback
    }
    return UIColor { trait in
      trait.userInterfaceStyle == .dark ? darkColor : lightColor
    }
    #elseif canImport(AppKit)
    guard let lightColor = NSColor(hex: lightTextColor),
          let darkColor = NSColor(hex: darkTextColor) else {
      return fallback
    }
    return NSColor(name: nil) { appearance in
      let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
      return isDark ? darkColor : lightColor
    }
    #endif
  }
}

// MARK: - Latex View Provider

enum LatexAttachmentLayout {
  static func baselineOffset(
    displayAscent: CGFloat,
    displayDescent: CGFloat,
    attachmentHeight: CGFloat
  ) -> CGFloat {
    let displayHeight = displayAscent + displayDescent
    let bottomPadding = max(0, attachmentHeight - displayHeight) / 2
    return -(displayDescent + bottomPadding)
  }
}

final class LatexViewProvider: NSTextAttachmentViewProvider {
  private let latex: String
  private let fontSize: CGFloat
  private let textColor: MDColor
  private static let jsonDecoder = JSONDecoder()

  private struct DecodedAttachment {
    var latex: String = ""
    var fontSize: CGFloat = Typography.base.mdFont.pointSize
    var textColor: MDColor = MDColor(Color.Theme.Foreground.Primary.Primary750)
  }

  #if canImport(UIKit)
  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: UIView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {
    let decoded = Self.decode(attachment: attachment)
    (latex, fontSize, textColor) = (decoded.latex, decoded.fontSize, decoded.textColor)
    super.init(textAttachment: attachment, parentView: parentView,
               textLayoutManager: textLayoutManager, location: location)
    tracksTextAttachmentViewBounds = true
  }
  #elseif canImport(AppKit)
  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: NSView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {
    let decoded = Self.decode(attachment: attachment)
    (latex, fontSize, textColor) = (decoded.latex, decoded.fontSize, decoded.textColor)
    super.init(textAttachment: attachment, parentView: parentView,
               textLayoutManager: textLayoutManager, location: location)
    tracksTextAttachmentViewBounds = true
  }
  #endif

  private static func decode(attachment: NSTextAttachment) -> DecodedAttachment {
    var result = DecodedAttachment()
    if let data = attachment.contents,
       let attachmentData = try? jsonDecoder.decode(LatexAttachmentData.self, from: data) {
      result.latex = attachmentData.latex
      result.fontSize = attachmentData.fontSize
      result.textColor = attachmentData.resolvedTextColor
    }
    return result
  }

  override func loadView() {
    let mathView = SwaTexView()
    mathView.latex = latex
    mathView.color = textColor
    mathView.fontSize = fontSize
    mathView.mathStyle = .text
    mathView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    self.view = mathView
  }

  override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                 location: any NSTextLocation,
                                 textContainer: NSTextContainer?,
                                 proposedLineFragment: CGRect,
                                 position: CGPoint) -> CGRect {
    guard let mathView = view as? SwaTexView else {
      return .zero
    }
    let size = mathView.intrinsicContentSize
    let height = size.height.rounded(.up)
    let yOffset = -mathView.baselineFromBottom
    return CGRect(x: 0, y: yOffset, width: size.width.rounded(.up), height: height)
  }
}
