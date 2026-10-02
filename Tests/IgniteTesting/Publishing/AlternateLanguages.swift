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
    /// Switches the current publishing context to a site with alternate languages
    /// and points its build directory at a fresh temporary folder.
    private func useAlternateLanguagesSite(
        pathSegments: [Language: String] = [:]
    ) throws -> URL {
        let buildDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: buildDirectory, withIntermediateDirectories: true)

        var site = AlternateLanguagesTestSite()
        site.languagePathSegments = pathSegments

        let context = PublishingContext.shared
        context.site = site
        context.buildDirectory = buildDirectory
        return buildDirectory
    }

    private func publish(at buildDirectory: URL) {
        let context = PublishingContext.shared
        context.render(homePage: context.site.homePage)

        for page in context.site.staticPages {
            context.render(page)
        }

        context.renderAlternateLanguages()
    }

    private func read(_ path: String, in buildDirectory: URL) throws -> String {
        try String(contentsOf: buildDirectory.appending(path: path), encoding: .utf8)
    }

    @Test("Main language stays at the root while alternates get a prefix", .publishingContext())
    func alternatesArePublishedUnderPrefix() throws {
        let buildDirectory = try useAlternateLanguagesSite()
        publish(at: buildDirectory)

        #expect(try read("index.html", in: buildDirectory).contains("lang=\"en\""))
        #expect(try read("about/index.html", in: buildDirectory).contains("lang=\"en\""))
        #expect(try read("es/index.html", in: buildDirectory).contains("lang=\"es\""))
        #expect(try read("es/about/index.html", in: buildDirectory).contains("lang=\"es\""))
    }

    @Test("Region-tagged languages use the base language code by default", .publishingContext())
    func regionTaggedLanguageUsesBaseCode() throws {
        let buildDirectory = try useAlternateLanguagesSite()
        publish(at: buildDirectory)

        let output = try read("pt/about/index.html", in: buildDirectory)
        #expect(output.contains("lang=\"pt-BR\""))
    }

    @Test("Path segment can be overridden per language", .publishingContext())
    func pathSegmentOverride() throws {
        let buildDirectory = try useAlternateLanguagesSite(pathSegments: [.spanish: "espanol"])
        publish(at: buildDirectory)

        #expect(try read("espanol/about/index.html", in: buildDirectory).contains("lang=\"es\""))
        #expect(FileManager.default.fileExists(atPath: buildDirectory.appending(path: "es").path) == false)
    }

    @Test("Pages link to every language version with hreflang", .publishingContext())
    func hreflangLinks() throws {
        let buildDirectory = try useAlternateLanguagesSite()
        publish(at: buildDirectory)

        for path in ["about/index.html", "es/about/index.html"] {
            let output = try read(path, in: buildDirectory)
            #expect(output.contains("hreflang=\"en\""))
            #expect(output.contains("hreflang=\"es\""))
            #expect(output.contains("hreflang=\"pt-BR\""))
            #expect(output.contains("https://www.example.com/about"))
            #expect(output.contains("https://www.example.com/es/about"))
            #expect(output.contains("https://www.example.com/pt/about"))
        }
    }

    @Test("Internal links in alternate languages keep the language prefix", .publishingContext())
    func linksKeepPrefix() throws {
        let buildDirectory = try useAlternateLanguagesSite()
        publish(at: buildDirectory)

        #expect(try read("index.html", in: buildDirectory).contains("href=\"/about/\""))
        #expect(try read("es/index.html", in: buildDirectory).contains("href=\"/es/about/\""))
    }

    @Test("Sites without alternate languages emit no hreflang", .publishingContext())
    func noAlternates() throws {
        let buildDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: buildDirectory, withIntermediateDirectories: true)

        var site = AlternateLanguagesTestSite()
        site.alternateLanguages = []

        let context = PublishingContext.shared
        context.site = site
        context.buildDirectory = buildDirectory
        publish(at: buildDirectory)

        #expect(try read("about/index.html", in: buildDirectory).contains("hreflang") == false)
        #expect(FileManager.default.fileExists(atPath: buildDirectory.appending(path: "es").path) == false)
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
        Text("About")
    }

    var layout: any Layout { AlternateLanguagesLayout() }
}

private struct AlternateLanguagesTestSite: Site {
    var name = "My Alternate Languages Site"
    var url = URL(static: "https://www.example.com")
    var language: Language = .english
    var alternateLanguages: [Language] = [.spanish, .portugueseBrazil]
    var languagePathSegments: [Language: String] = [:]

    var homePage = AlternateLanguagesHome()
    var layout = AlternateLanguagesLayout()

    var staticPages: [any StaticPage] {
        AlternateLanguagesAbout()
    }
}
