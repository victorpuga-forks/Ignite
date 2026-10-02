//
// Underline.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Renders text with an underline.
public struct Underline: InlineElement {
    /// The content and behavior of this HTML.
    public var body: some InlineElement { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The content that should be underlined.
    var content: any InlineElement

    /// Creates a new `Underline` instance using an inline element builder
    /// that returns an array of content to place inside.
    public init(@InlineElementBuilder content: @escaping () -> some InlineElement) {
        self.content = content()
    }

    /// Creates a new `Underline` instance using one `InlineElement`
    /// that should be rendered with a strikethrough effect.
    /// - Parameter singleElement: The element to strike.
    @_disfavoredOverload
    public init(_ singleElement: some InlineElement) {
        self.content = singleElement
    }

    /// Creates a new `Underline` instance from a localized string.
    ///
    /// String literals use this initializer, so they are looked up in your site's
    /// `Localizable.xcstrings`. Strings stored in a `String` variable are not localized.
    /// - Parameter string: The localized text to underline.
    public init(_ string: LocalizedString) {
        self.content = string
    }

    /// Renders this element.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        let contentHTML = content.markupString()
        return Markup("<u\(attributes)>\(contentHTML)</u>")
    }
}
