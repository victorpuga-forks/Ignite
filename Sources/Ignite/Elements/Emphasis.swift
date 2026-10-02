//
// Emphasis.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Renders text with emphasis, which usually means italics.
public struct Emphasis: InlineElement {
    /// The content and behavior of this HTML.
    public var body: some InlineElement { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The content you want to render with emphasis.
    private var content: any InlineElement

    /// Creates a new `Emphasis` instance using an inline element builder
    /// of content to display.
    /// - Parameter content: The content to render with emphasis.
    public init(
        @InlineElementBuilder content: () -> some InlineElement
    ) {
        self.content = content()
    }

    /// Creates a new `Emphasis` instance using a single inline element.
    /// - Parameter singleElement: The content to render with emphasis.
    @_disfavoredOverload
    public init(_ singleElement: any InlineElement) {
        self.content = singleElement
    }

    /// Creates a new `Emphasis` instance from a localized string.
    ///
    /// String literals use this initializer, so they are looked up in your site's
    /// `Localizable.xcstrings`. Strings stored in a `String` variable are not localized.
    /// - Parameter string: The localized text to render with emphasis.
    public init(_ string: LocalizedString) {
        self.content = string
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        let contentHTML = content.markupString()
        return Markup("<em\(attributes)>\(contentHTML)</em>")
    }
}
