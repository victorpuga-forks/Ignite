//
// LocalizedStringResource.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for rendering `LocalizedStringResource` values.
@Suite("LocalizedStringResource Tests")
class LocalizedStringResourceTests: IgniteTestSuite {
    /// Creates a bundle containing Spanish translations for the keys used in these tests.
    private func makeBundle() throws -> Bundle {
        let root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "Strings.bundle")
        let lproj = root.appending(path: "es.lproj")
        try FileManager.default.createDirectory(at: lproj, withIntermediateDirectories: true)

        let strings = "\"Welcome\" = \"Bienvenido\";\n\"Hello %@\" = \"Hola %@\";\n"
        try strings.write(to: lproj.appending(path: "Localizable.strings"), atomically: true, encoding: .utf8)

        return try #require(Bundle(url: root))
    }

    /// Switches the current publishing context to a Spanish site using the given bundle.
    private func useSpanishSite(bundle: Bundle) {
        var site = LocalizedTestSite()
        site.localizationBundle = bundle

        let context = PublishingContext.shared
        context.site = site
        context.environment = EnvironmentValues(
            sourceDirectory: URL(filePath: ""),
            site: site,
            allContent: []
        )
    }

    @Test("Literal without a catalog entry renders unchanged", .publishingContext())
    func literalWithoutEntry() async throws {
        let element = Text("Hello")
        let output = element.markupString()

        #expect(output == "<p>Hello</p>")
    }

    @Test("Literal resolves using the site language and bundle", .publishingContext())
    func literalResolvesInSiteLanguage() async throws {
        useSpanishSite(bundle: try makeBundle())

        let element = Text("Welcome")
        let output = element.markupString()

        #expect(output == "<p>Bienvenido</p>")
    }

    @Test("Interpolated literal resolves using the site language", .publishingContext())
    func interpolatedLiteral() async throws {
        useSpanishSite(bundle: try makeBundle())

        let name = "Ana"
        let element = Text("Hello \(name)")
        let output = element.markupString()

        #expect(output == "<p>Hola Ana</p>")
    }

    @Test("Explicit resource bundle is ignored in favor of the site bundle", .publishingContext())
    func explicitBundleIsIgnored() async throws {
        useSpanishSite(bundle: try makeBundle())

        let resource = LocalizedStringResource("Welcome", bundle: .atURL(Bundle.main.bundleURL))
        let output = Text(resource).markupString()

        #expect(output == "<p>Bienvenido</p>")
    }

    @Test("Resource works anywhere an inline element is accepted", .publishingContext())
    func resourceInInlineElement() async throws {
        useSpanishSite(bundle: try makeBundle())

        let output = Span(LocalizedStringResource("Welcome")).markupString()

        #expect(output == "<span>Bienvenido</span>")
    }

    @Test("String variables are not localized", .publishingContext())
    func stringVariableIsVerbatim() async throws {
        useSpanishSite(bundle: try makeBundle())

        let value = "Welcome"
        let output = Text(value).markupString()

        #expect(output == "<p>Welcome</p>")
    }
}

private struct LocalizedTestSite: Site {
    var name = "My Localized Site"
    var url = URL(static: "https://www.example.com")
    var language: Language = .spanish
    var localizationBundle: Bundle = .main

    var homePage = TestPage()
    var layout = EmptyLayout()
}
