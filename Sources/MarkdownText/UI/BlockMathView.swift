//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI
import SwaTexRender

#if canImport(UIKit)

struct BlockMathView: UIViewRepresentable {
  let latex: String
  let color: Color
  let pointSize: CGFloat

  init(latex: String, color: Color = Color.Theme.Foreground.Primary.Primary750, pointSize: CGFloat = Typography.base.mdFont.pointSize) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
  }

  func makeUIView(context: Context) -> SwaTexView {
    let view = SwaTexView()
    configure(view)
    view.setContentHuggingPriority(.defaultHigh, for: .vertical)
    return view
  }

  func updateUIView(_ uiView: SwaTexView, context: Context) {
    configure(uiView)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: SwaTexView, context: Context) -> CGSize? {
    let size = uiView.intrinsicContentSize
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up))
  }

  private func configure(_ view: SwaTexView) {
    view.latex = latex
    view.color = UIColor(color)
    view.fontSize = pointSize
    view.mathStyle = .display
    view.isAccessibilityElement = true
    view.accessibilityLabel = latex
  }
}

#elseif canImport(AppKit)

struct BlockMathView: NSViewRepresentable {
  let latex: String
  let color: Color
  let pointSize: CGFloat

  init(latex: String, color: Color = Color.Theme.Foreground.Primary.Primary750, pointSize: CGFloat = Typography.base.mdFont.pointSize) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
  }

  func makeNSView(context: Context) -> SwaTexView {
    let view = SwaTexView()
    configure(view)
    view.setContentHuggingPriority(.defaultHigh, for: .vertical)
    return view
  }

  func updateNSView(_ nsView: SwaTexView, context: Context) {
    configure(nsView)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, nsView: SwaTexView, context: Context) -> CGSize? {
    let size = nsView.intrinsicContentSize
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up))
  }

  private func configure(_ view: SwaTexView) {
    view.latex = latex
    view.color = NSColor(color)
    view.fontSize = pointSize
    view.mathStyle = .display
    view.setAccessibilityElement(true)
    view.setAccessibilityLabel(latex)
  }
}

#endif
