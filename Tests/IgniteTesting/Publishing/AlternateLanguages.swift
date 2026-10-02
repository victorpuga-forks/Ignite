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

    @Test(
        "Link text follows the language of the page",
        .publishingContext(),
        arguments: [
            (nil, "About"),
            (Language.spanish, "Acerca de"),
            (Language.portugueseBrazil, "About")
        ] as [(Language?, String)]
    )
    func linkTextFollowsPageLanguage(language: Language?, expectedTitle: String) {
        useAlternateLanguagesSite()

        let output = render(AlternateLanguagesHome(), in: language)

        #expect(output.contains(">\(expectedTitle)</a>"))
    }

    @Test("Link titles stored in String variables are not localized", .publishingContext())
    func linkStringVariableIsVerbatim() {
        useAlternateLanguagesSite()

        let title = "About"
        let page = AlternateLanguagesLinks(links: [Link(title, target: "/about")])

        #expect(render(page, in: .spanish).contains(">About</a>"))
    }

    @Test(
        "Links to the homepage and static pages keep the page language",
        .publishingContext(),
        arguments: [
            (nil, "/", "/about/"),
            (Language.spanish, "/es/", "/es/about/"),
            (Language.portugueseBrazil, "/pt/", "/pt/about/")
        ] as [(Language?, String, String)]
    )
    func homeAndStaticPageLinksKeepPrefix(language: Language?, homeHref: String, aboutHref: String) {
        useAlternateLanguagesSite()
        let page = AlternateLanguagesLinks(links: [
            Link("Home", target: "/"),
            Link("About", target: AlternateLanguagesAbout())
        ])

        let output = render(page, in: language)

        #expect(output.contains("href=\"\(homeHref)\""))
        #expect(output.contains("href=\"\(aboutHref)\""))
    }

    @Test(
        "Language switcher links point to the requested language",
        .publishingContext(),
        arguments: [nil, Language.spanish, Language.portugueseBrazil] as [Language?],
        [
            (Language.english, "/", "/about/"),
            (Language.spanish, "/es/", "/es/about/"),
            (Language.portugueseBrazil, "/br/", "/br/about/")
        ]
    )
    func languageSwitcherLinks(pageLanguage: Language?, target: (Language, String, String)) {
        useAlternateLanguagesSite(pathSegments: [.portugueseBrazil: "br"])
        let (language, homeHref, aboutHref) = target
        let page = AlternateLanguagesLinks(links: [
            Link("Home", target: "/").language(language),
            Link("About", target: "/about").language(language)
        ])

        let output = render(page, in: pageLanguage)

        #expect(output.contains("href=\"\(homeHref)\""))
        #expect(output.contains("href=\"\(aboutHref)\""))
    }

    @Test(
        "External links, anchors and assets are never prefixed",
        .publishingContext(),
        arguments: [
            "https://www.example.org/about",
            "#contact",
            "/files/guide.pdf",
            "mailto:hello@example.com"
        ]
    )
    func nonPageLinksAreUnchanged(target: String) {
        useAlternateLanguagesSite()
        let page = AlternateLanguagesLinks(links: [Link("Link", target: target)])

        for language in [nil, Language.spanish] {
            #expect(render(page, in: language).contains("href=\"\(target)\""))
        }
    }

    @Test("Language links to languages outside the site fall back to the current language", .publishingContext())
    func unknownLanguageLinkFallsBack() {
        useAlternateLanguagesSite()
        let page = AlternateLanguagesLinks(links: [Link("Français", target: "/about").language(.french)])

        let output = render(page, in: .spanish)

        #expect(output.contains("href=\"/es/about/\""))
        #expect(PublishingContext.shared.warnings.contains { $0.contains("fr") })
    }

    @Test("Localized text works in other inline elements", .publishingContext())
    func localizedInlineElements() {
        useAlternateLanguagesSite()
        let elements: [any InlineElement] = [
            Span("About"),
            Strong("About"),
            Emphasis("About"),
            Underline("About"),
            Strikethrough("About"),
            Badge("About"),
            Button("About")
        ]

        for element in elements {
            let page = AlternateLanguagesInlineElement(element: element)

            #expect(render(page).contains("Acerca de") == false, "\(type(of: element))")
            #expect(render(page, in: .spanish).contains("Acerca de"), "\(type(of: element))")
        }
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

private struct AlternateLanguagesLinks: StaticPage {
    var title = "Links"
    var path = "/links"
    var links: [Link]

    var body: some HTML {
        ForEach(links) { link in
            link
        }
    }

    var layout: any Layout { AlternateLanguagesLayout() }
}

private struct AlternateLanguagesInlineElement: StaticPage {
    var title = "Inline"
    var path = "/inline"
    var element: any InlineElement

    var body: some HTML {
        Text { element }
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
