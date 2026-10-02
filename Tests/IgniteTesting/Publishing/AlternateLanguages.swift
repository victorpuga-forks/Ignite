//
// AlternateLanguages.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for publishing a site in alternate languages.
@Suite("Alternate Languages Tests")
class AlternateLanguagesTests: IgniteTestSuite {
    /// Switches the current publishing context to a site with alternate languages.
    private func useAlternateLanguagesSite(
        alternateLanguages: [Language] = [.spanish, .portugueseBrazil],
        pathSegments: [Language: String] = [:]
    ) {
        var site = AlternateLanguagesTestSite()
        site.alternateLanguages = alternateLanguages
        site.languagePathSegments = pathSegments
        PublishingContext.shared.site = site
    }

    /// Renders a page as it would be published in the given language.
    /// - Parameters:
    ///   - page: The page to render.
    ///   - language: The alternate language to render in, or nil for the site's main language.
    private func render(_ page: any StaticPage, in language: Language? = nil) -> String {
        let context = PublishingContext.shared
        context.alternateLanguage = language
        defer { context.alternateLanguage = nil }

        return context.markupString(
            for: page,
            rootPath: page.path,
            pagePath: page.path,
            hasLanguageAlternates: true)
    }

    @Test("Main language keeps the site language and root URL", .publishingContext())
    func mainLanguageStaysAtRoot() {
        useAlternateLanguagesSite()

        let output = render(AlternateLanguagesAbout())

        #expect(output.contains("lang=\"en\""))
        #expect(output.contains("href=\"https://www.example.com/about\" rel=\"canonical\""))
    }

    @Test("Alternate languages render with their own language under a prefix", .publishingContext())
    func alternatesUseLanguageAndPrefix() {
        useAlternateLanguagesSite()

        let output = render(AlternateLanguagesAbout(), in: .spanish)

        #expect(output.contains("lang=\"es\""))
        #expect(output.contains("href=\"https://www.example.com/es/about\" rel=\"canonical\""))
    }

    @Test("Region-tagged languages use the base language code by default", .publishingContext())
    func regionTaggedLanguageUsesBaseCode() {
        useAlternateLanguagesSite()

        let output = render(AlternateLanguagesAbout(), in: .portugueseBrazil)

        #expect(output.contains("lang=\"pt-BR\""))
        #expect(output.contains("href=\"https://www.example.com/pt/about\" rel=\"canonical\""))
    }

    @Test("Path segment can be overridden per language", .publishingContext())
    func pathSegmentOverride() {
        useAlternateLanguagesSite(pathSegments: [.spanish: "espanol"])

        let output = render(AlternateLanguagesAbout(), in: .spanish)

        #expect(output.contains("href=\"https://www.example.com/espanol/about\" rel=\"canonical\""))
        #expect(output.contains("hreflang=\"es\" href=\"https://www.example.com/espanol/about\""))
    }

    @Test("Pages link to every language version with hreflang", .publishingContext())
    func hreflangLinks() {
        useAlternateLanguagesSite()

        for language in [nil, Language.spanish] {
            let output = render(AlternateLanguagesAbout(), in: language)

            #expect(output.contains("hreflang=\"en\" href=\"https://www.example.com/about\""))
            #expect(output.contains("hreflang=\"es\" href=\"https://www.example.com/es/about\""))
            #expect(output.contains("hreflang=\"pt-BR\" href=\"https://www.example.com/pt/about\""))
        }
    }

    @Test("Internal links in alternate languages keep the language prefix", .publishingContext())
    func linksKeepPrefix() {
        useAlternateLanguagesSite()

        #expect(render(AlternateLanguagesHome()).contains("href=\"/about/\""))
        #expect(render(AlternateLanguagesHome(), in: .spanish).contains("href=\"/es/about/\""))
    }

    @Test("Localized text resolves in the language of each page", .publishingContext())
    func localizedTextFollowsPageLanguage() {
        useAlternateLanguagesSite()

        #expect(render(AlternateLanguagesAbout()).contains("<p>Welcome</p>"))
        #expect(render(AlternateLanguagesAbout(), in: .spanish).contains("<p>Bienvenido</p>"))
    }

    @Test("Sites without alternate languages emit no hreflang", .publishingContext())
    func noAlternates() {
        useAlternateLanguagesSite(alternateLanguages: [])

        #expect(render(AlternateLanguagesAbout()).contains("hreflang") == false)
    }
}

private struct AlternateLanguagesLayout: Layout {
    var body: some Document {
        Head()
        Body()
    }
}

private struct AlternateLanguagesHome: StaticPage {
    var title = "Home"

    var body: some HTML {
        Link("About", target: AlternateLanguagesAbout())
    }

    var layout: any Layout { AlternateLanguagesLayout() }
}

private struct AlternateLanguagesAbout: StaticPage {
    var title = "About"
    var path = "/about"

    var body: some HTML {
        Text("Welcome")
    }

    var layout: any Layout { AlternateLanguagesLayout() }
}

private struct AlternateLanguagesTestSite: Site {
    var name = "My Alternate Languages Site"
    var url = URL(static: "https://www.example.com")
    var language: Language = .english
    var alternateLanguages: [Language] = [.spanish, .portugueseBrazil]
    var languagePathSegments: [Language: String] = [:]
    var localizationCatalog: URL? {
        Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings", subdirectory: "Localization")
    }

    var homePage = AlternateLanguagesHome()
    var layout = AlternateLanguagesLayout()

    var staticPages: [any StaticPage] {
        AlternateLanguagesAbout()
    }
}
