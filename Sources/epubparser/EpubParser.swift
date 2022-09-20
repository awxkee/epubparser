//
//  FREpubParser.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AEXML
import ZIPFoundation
import SwiftSoup

public class EpubParser: NSObject {

    let book = EpubBook()
    private var htmlURL: URL?
    private var resourcesBasePath = ""
    private var shouldRemoveEpub = true
    private var epubPathToRemove: String?

    private let lock = NSLock()

    private func buildHtml(path: URL) throws -> URL {
        return try lock.withLock {
            if let htmlURL = self.htmlURL {
                return htmlURL
            }
            guard book.spine.spineReferences.count > 0 else {
                throw InvalidEpubContentsError()
            }
            let firstData = try Data(contentsOf: URL(fileURLWithPath: self.book.spine.spineReferences[0].resource.fullHref),
                                     options: .mappedIfSafe)
            guard let contents = String(data: firstData, encoding: .utf8) else {
                throw InvalidEpubContentsError()
            }
            let newDoc: Document = try SwiftSoup.parse(contents)

            do {
                var index = 0
                for spine in self.book.spine.spineReferences {
                    if index == 0 {
                        index += 1
                        continue
                    }
                    let refData = try Data(contentsOf: URL(fileURLWithPath: spine.resource.fullHref), options: .mappedIfSafe)
                    let stringData = String(data: refData, encoding: .utf8)!
                    let doc: Document = try SwiftSoup.parse(stringData)
                    if let body = doc.body() {
                        let html = try body.outerHtml()
                        try newDoc.body()?.append(html)
                    }
                }
            } catch {

            }
            let outerHtml = try newDoc.outerHtml()
            guard let finalText = outerHtml.data(using: .utf8) else {
                throw EPUBFailedToBuiltHTMLError()
            }
            let builtURL = path
                .appendingPathComponent("_____book.html")
            try finalText.write(to: builtURL)
            self.htmlURL = builtURL
            return builtURL
        }
    }

    /// Parse the Cover Image from an epub file.
    ///
    /// - Parameters:
    ///   - epubPath: Epub path on the disk.
    ///   - unzipPath: Path to unzip the compressed epub.
    /// - Returns: The book cover as UIImage object
    /// - Throws: `FolioReaderError`
    func parseCoverImage(_ epubPath: String, unzipPath: String) throws -> UIImage {
        guard let book = try? readEpub(epubPath: epubPath, removeEpub: false, unzipPath: unzipPath),
              let coverImage = book.coverImage else {
            throw EPUBCoverNotAvailableError()
        }

        guard let image = UIImage(contentsOfFile: coverImage.fullHref) else {
            throw EPUBInvalidImageError(path: coverImage.fullHref)
        }

        return image
    }

    /// Parse the book title from an epub file.
    ///
    /// - Parameters:
    ///   - epubPath: Epub path on the disk.
    ///   - unzipPath: Path to unzip the compressed epub.
    /// - Returns: The book title
    /// - Throws: `FolioReaderError`
    func parseTitle(_ epubPath: String, unzipPath: String) throws -> String {
        guard let book = try? readEpub(epubPath: epubPath, removeEpub: false, unzipPath: unzipPath), let title = book.title else {
            throw EPUBTitleNotAvailableError()
        }
        return title
    }


    /// Parse the book Author name from an epub file.
    ///
    /// - Parameters:
    ///   - epubPath: Epub path on the disk.
    ///   - unzipPath: Path to unzip the compressed epub.
    /// - Returns: The author name
    /// - Throws: `FolioReaderError`
    func parseAuthorName(_ epubPath: String, unzipPath: String) throws -> String {
        guard let book = try? readEpub(epubPath: epubPath, removeEpub: false, unzipPath: unzipPath), let authorName = book.authorName else {
            throw EPUBAuthorNotAvailableError()
        }
        return authorName
    }

    /// Unzip, delete and read an epub file.
    ///
    /// - Parameters:
    ///   - withEpubPath: Epub path on the disk
    ///   - removeEpub: Should remove the original file?
    ///   - unzipPath: Path to unzip the compressed epub.
    /// - Returns: `FRBook` Object
    /// - Throws: `FolioReaderError`
    func readEpub(epubPath withEpubPath: String, removeEpub: Bool = true, unzipPath: String) throws -> EpubBook {
        epubPathToRemove = withEpubPath
        shouldRemoveEpub = removeEpub

        var isDir: ObjCBool = false
        let fileManager = FileManager.default
        let bookName = withEpubPath.lastPathComponent
        var bookBasePath = ""

        if fileManager.fileExists(atPath: unzipPath) {
            bookBasePath = unzipPath
        }
        bookBasePath = bookBasePath.appendingPathComponent(bookName)

        guard fileManager.fileExists(atPath: withEpubPath) else {
            throw EPUBBookNotAvailableError()
        }

        // Unzip if necessary
        let needsUnzip = !fileManager.fileExists(atPath: bookBasePath, isDirectory: &isDir) || !isDir.boolValue

        if needsUnzip {
            try FileManager.default.unzipItem(at: URL(fileURLWithPath: withEpubPath),
                                              to: URL(fileURLWithPath: bookBasePath))
        }

        // Skip from backup this folder
        try addSkipBackupAttributeToItemAtURL(URL(fileURLWithPath: bookBasePath, isDirectory: true))

        book.name = bookName
        try readContainer(with: bookBasePath)
        try readOpf(with: bookBasePath)
        let url = try buildHtml(path: URL(fileURLWithPath: bookBasePath))
        self.book.htmlURL = url
        return self.book
    }

    /// Read and parse container.xml file.
    ///
    /// - Parameter bookBasePath: The base book path
    /// - Throws: `FolioReaderError`
    private func readContainer(with bookBasePath: String) throws {
        let containerPath = "META-INF/container.xml"
        let containerData = try Data(contentsOf: URL(fileURLWithPath: bookBasePath.appendingPathComponent(containerPath)), options: .alwaysMapped)
        let xmlDoc = try AEXMLDocument(xml: containerData)
        let opfResource = EpubResource()
        opfResource.href = xmlDoc.root["rootfiles"]["rootfile"].attributes["full-path"]
        guard let fullPath = xmlDoc.root["rootfiles"]["rootfile"].attributes["full-path"] else {
            throw EPUBPathEmptyError()
        }
        opfResource.mediaType = MediaType.by(fileName: fullPath)
        book.opfResource = opfResource
        resourcesBasePath = bookBasePath.appendingPathComponent(book.opfResource.href.deletingLastPathComponent)
    }

    /// Read and parse .opf file.
    ///
    /// - Parameter bookBasePath: The base book path
    /// - Throws: `FolioReaderError`
    private func readOpf(with bookBasePath: String) throws {
        let opfPath = bookBasePath.appendingPathComponent(book.opfResource.href)
        var identifier: String?

        let opfData = try Data(contentsOf: URL(fileURLWithPath: opfPath), options: .alwaysMapped)
        let xmlDoc = try AEXMLDocument(xml: opfData)

        // Base OPF info
        if let package = xmlDoc.children.first {
            identifier = package.attributes["unique-identifier"]

            if let version = package.attributes["version"] {
                book.version = Double(version)
            }
        }

        // Parse and save each "manifest item"
        xmlDoc.root["manifest"]["item"].all?.forEach {
            let resource = EpubResource()
            resource.id = $0.attributes["id"]
            resource.properties = $0.attributes["properties"]
            resource.href = $0.attributes["href"]
            resource.fullHref = resourcesBasePath.appendingPathComponent(resource.href).removingPercentEncoding
            resource.mediaType = MediaType.by(name: $0.attributes["media-type"] ?? "", fileName: resource.href)
            resource.mediaOverlay = $0.attributes["media-overlay"]

            // if a .smil file is listed in resources, go parse that file now and save it on book model
            if (resource.mediaType != nil && resource.mediaType == .smil) {
                readSmilFile(resource)
            }

            book.resources.add(resource)
        }

        book.smils.basePath = resourcesBasePath

        // Read metadata
        book.metadata = readMetadata(xmlDoc.root["metadata"].children)

        // Read the book unique identifier
        if let identifier = identifier, let uniqueIdentifier = book.metadata.find(identifierById: identifier) {
            book.uniqueIdentifier = uniqueIdentifier.value
        }

        // Read the cover image
        let coverImageId = book.metadata.find(byName: "cover")?.content
        if let coverImageId = coverImageId, let coverResource = book.resources.findById(coverImageId) {
            book.coverImage = coverResource
        } else if let coverResource = book.resources.findByProperty("cover-image") {
            book.coverImage = coverResource
        }

        // Specific TOC for ePub 2 and 3
        // Get the first resource with the NCX mediatype
        if let tocResource = book.resources.findByMediaType(MediaType.ncx) {
            book.tocResource = tocResource
        } else if let tocResource = book.resources.findByExtension(MediaType.ncx.defaultExtension) {
            // Non-standard books may use wrong mediatype, fallback with extension
            book.tocResource = tocResource
        } else if let tocResource = book.resources.findByProperty("nav") {
            book.tocResource = tocResource
        }

        precondition(book.tocResource != nil, "ERROR: Could not find table of contents resource. The book don't have a TOC resource.")

        // The book TOC
        book.tableOfContents = findTableOfContents()
        book.flatTableOfContents = flatTOC

        // Read Spine
        let spine = xmlDoc.root["spine"]
        book.spine = readSpine(spine.children)

        // Page progress direction `ltr` or `rtl`
        if let pageProgressionDirection = spine.attributes["page-progression-direction"] {
            book.spine.pageProgressionDirection = pageProgressionDirection
        }
    }

    /// Reads and parses a .smil file.
    ///
    /// - Parameter resource: A `FRResource` to read the smill
    private func readSmilFile(_ resource: EpubResource) {
        do {
            let smilData = try Data(contentsOf: URL(fileURLWithPath: resource.fullHref), options: .alwaysMapped)
            var smilFile = EpubSmilFile(resource: resource)
            let xmlDoc = try AEXMLDocument(xml: smilData)

            let children = xmlDoc.root["body"].children

            if children.count > 0 {
                smilFile.data.append(contentsOf: readSmilFileElements(children))
            }

            book.smils.add(smilFile)
        } catch {
            print("Cannot read .smil file: "+resource.href)
        }
    }

    private func readSmilFileElements(_ children: [AEXMLElement]) -> [EpubSmilElement] {
        var data = [EpubSmilElement]()

        // convert each smil element to a FRSmil object
        children.forEach{
            let smil = EpubSmilElement(name: $0.name, attributes: $0.attributes)

            // if this element has children, convert them to objects too
            if $0.children.count > 0 {
                smil.children.append(contentsOf: readSmilFileElements($0.children))
            }

            data.append(smil)
        }

        return data
    }

    /// Read and parse the Table of Contents.
    ///
    /// - Returns: A list of toc references
    private func findTableOfContents() -> [EpubTocReference] {
        var tableOfContent = [EpubTocReference]()
        var tocItems: [AEXMLElement]?
        guard let tocResource = book.tocResource else { return tableOfContent }
        let tocPath = resourcesBasePath.appendingPathComponent(tocResource.href)

        do {
            if tocResource.mediaType == MediaType.ncx {
                let ncxData = try Data(contentsOf: URL(fileURLWithPath: tocPath), options: .alwaysMapped)
                let xmlDoc = try AEXMLDocument(xml: ncxData)
                if let itemsList = xmlDoc.root["navMap"]["navPoint"].all {
                    tocItems = itemsList
                }
            } else {
                let tocData = try Data(contentsOf: URL(fileURLWithPath: tocPath), options: .alwaysMapped)
                let xmlDoc = try AEXMLDocument(xml: tocData)

                if let nav = xmlDoc.root["body"]["nav"].first, let itemsList = nav["ol"]["li"].all {
                    tocItems = itemsList
                } else if let nav = findNavTag(xmlDoc.root["body"]), let itemsList = nav["ol"]["li"].all {
                    tocItems = itemsList
                }
            }
        } catch {
            print("Cannot find Table of Contents.")
        }

        guard let items = tocItems else { return tableOfContent }

        for item in items {
            guard let ref = readTOCReference(item) else { continue }
            tableOfContent.append(ref)
        }

        return tableOfContent
    }

    /// Recursively finds a `<nav>` tag on html.
    ///
    /// - Parameter element: An `AEXMLElement`, usually the `<body>`
    /// - Returns: If found the `<nav>` `AEXMLElement`
    @discardableResult func findNavTag(_ element: AEXMLElement) -> AEXMLElement? {
        for element in element.children {
            if let nav = element["nav"].first {
                return nav
            } else {
                findNavTag(element)
            }
        }
        return nil
    }

    fileprivate func readTOCReference(_ navpointElement: AEXMLElement) -> EpubTocReference? {
        var label = ""

        if book.tocResource?.mediaType == MediaType.ncx {
            if let labelText = navpointElement["navLabel"]["text"].value {
                label = labelText
            }

            guard let reference = navpointElement["content"].attributes["src"] else { return nil }
            let hrefSplit = reference.split {$0 == "#"}.map { String($0) }
            let fragmentID = hrefSplit.count > 1 ? hrefSplit[1] : ""
            let href = hrefSplit[0]

            let resource = book.resources.findByHref(href)
            let toc = EpubTocReference(title: label, resource: resource, fragmentID: fragmentID)

            // Recursively find child
            if let navPoints = navpointElement["navPoint"].all {
                for navPoint in navPoints {
                    guard let item = readTOCReference(navPoint) else { continue }
                    toc.children.append(item)
                }
            }
            return toc
        } else {
            if let labelText = navpointElement["a"].value {
                label = labelText
            }

            guard let reference = navpointElement["a"].attributes["href"] else { return nil }
            let hrefSplit = reference.split {$0 == "#"}.map { String($0) }
            let fragmentID = hrefSplit.count > 1 ? hrefSplit[1] : ""
            let href = hrefSplit[0]

            let resource = book.resources.findByHref(href)
            let toc = EpubTocReference(title: label, resource: resource, fragmentID: fragmentID)

            // Recursively find child
            if let navPoints = navpointElement["ol"]["li"].all {
                for navPoint in navPoints {
                    guard let item = readTOCReference(navPoint) else { continue }
                    toc.children.append(item)
                }
            }
            return toc
        }
    }

    // MARK: - Recursive add items to a list

    var flatTOC: [EpubTocReference] {
        var tocItems = [EpubTocReference]()

        for item in book.tableOfContents {
            tocItems.append(item)
            tocItems.append(contentsOf: countTocChild(item))
        }
        return tocItems
    }

    func countTocChild(_ item: EpubTocReference) -> [EpubTocReference] {
        var tocItems = [EpubTocReference]()

        item.children.forEach {
            tocItems.append($0)
        }
        return tocItems
    }

    /// Read and parse <metadata>.
    ///
    /// - Parameter tags: XHTML tags
    /// - Returns: Metadata object
    fileprivate func readMetadata(_ tags: [AEXMLElement]) -> EpubMetadata {
        let metadata = EpubMetadata()

        for tag in tags {
            if tag.name == "dc:title" {
                metadata.titles.append(tag.value ?? "")
            }

            if tag.name == "dc:identifier" {
                let identifier = Identifier(id: tag.attributes["id"], scheme: tag.attributes["opf:scheme"], value: tag.value)
                metadata.identifiers.append(identifier)
            }

            if tag.name == "dc:language" {
                let language = tag.value ?? metadata.language
                metadata.language = language != "en" ? language : metadata.language
            }

            if tag.name == "dc:creator" {
                metadata.creators.append(Author(name: tag.value ?? "", role: tag.attributes["opf:role"] ?? "", fileAs: tag.attributes["opf:file-as"] ?? ""))
            }

            if tag.name == "dc:contributor" {
                metadata.creators.append(Author(name: tag.value ?? "", role: tag.attributes["opf:role"] ?? "", fileAs: tag.attributes["opf:file-as"] ?? ""))
            }

            if tag.name == "dc:publisher" {
                metadata.publishers.append(tag.value ?? "")
            }

            if tag.name == "dc:description" {
                metadata.descriptions.append(tag.value ?? "")
            }

            if tag.name == "dc:subject" {
                metadata.subjects.append(tag.value ?? "")
            }

            if tag.name == "dc:rights" {
                metadata.rights.append(tag.value ?? "")
            }

            if tag.name == "dc:date" {
                metadata.dates.append(EventDate(date: tag.value ?? "", event: tag.attributes["opf:event"] ?? ""))
            }

            if tag.name == "meta" {
                if tag.attributes["name"] != nil {
                    metadata.metaAttributes.append(Meta(name: tag.attributes["name"], content: tag.attributes["content"]))
                }

                if tag.attributes["property"] != nil && tag.attributes["id"] != nil {
                    metadata.metaAttributes.append(Meta(id: tag.attributes["id"], property: tag.attributes["property"], value: tag.value))
                }

                if tag.attributes["property"] != nil {
                    metadata.metaAttributes.append(Meta(property: tag.attributes["property"], value: tag.value, refines: tag.attributes["refines"]))
                }
            }
        }
        return metadata
    }

    /// Read and parse <spine>.
    ///
    /// - Parameter tags: XHTML tags
    /// - Returns: Spine object
    fileprivate func readSpine(_ tags: [AEXMLElement]) -> EpubSpine {
        let spine = EpubSpine()

        for tag in tags {
            guard let idref = tag.attributes["idref"] else { continue }
            var linear = true

            if tag.attributes["linear"] != nil {
                linear = tag.attributes["linear"] == "yes" ? true : false
            }

            if book.resources.containsById(idref) {
                guard let resource = book.resources.findById(idref) else { continue }
                spine.spineReferences.append(Spine(resource: resource, linear: linear))
            }
        }
        return spine
    }

    /// Skip a file from iCloud backup.
    ///
    /// - Parameter url: File URL
    /// - Throws: Error if not possible
    fileprivate func addSkipBackupAttributeToItemAtURL(_ url: URL) throws {
        assert(FileManager.default.fileExists(atPath: url.path))

        var urlToExclude = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try urlToExclude.setResourceValues(resourceValues)
    }

}
