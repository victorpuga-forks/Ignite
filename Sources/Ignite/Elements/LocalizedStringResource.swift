//
// LocalizedStringResource.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Allows localized string resources to be used directly inside HTML.
///
/// Resources are resolved using the language of the page being rendered
/// and `Site.localizationBundle`. Any bundle set on the resource itself is ignored.
extension LocalizedStringResource: InlineElement {
    /// The content and behavior of this HTML.
    public var body: some InlineElement { self }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        guard let context = PublishingContext.current else {
            return Markup(verbatim: String(localized: self))
        }

        let resource = LocalizedStringResource(
            defaultValue,
            table: table,
            locale: context.environment.language.locale,
            bundle: .atURL(context.site.localizationBundle.bundleURL)
        )

        return Markup(verbatim: String(localized: resource))
    }
}
