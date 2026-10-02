//
// Page.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// A single flattened page from any source – static or dynamic – ready to be
/// passed through a theme.
public struct PageMetadata: Sendable {
    private(set) public var title: String
    private(set) public var description: String
    private(set) public var url: URL
    private(set) public var image: URL?

    /// The versions of this page published in each language, including this one.
    /// Empty when the site publishes in a single language.
    private(set) var alternates = [LanguageAlternate]()
}

/// A version of a page published in a specific language.
struct LanguageAlternate: Sendable {
    let language: Language
    let url: URL
}

extension PageMetadata {
    /// Creates an empty page for use as a default value
    static let empty = PageMetadata(
        title: "",
        description: "",
        url: URL(string: "about:blank")!
    )
}
