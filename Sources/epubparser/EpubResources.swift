//
//  FRResources.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 29/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

open class EpubResources: NSObject {
    
    var resources = [String: EpubResource]()

    /**
     Adds a resource to the resources.
     */
    func add(_ resource: EpubResource) {
        self.resources[resource.href] = resource
    }

    // MARK: Find

    /**
     Gets the first resource (random order) with the give mediatype.

     Useful for looking up the table of contents as it's supposed to be the only resource with NCX mediatype.
     */
    func findByMediaType(_ mediaType: MediaType) -> EpubResource? {
        for resource in resources.values {
            if resource.mediaType != nil && resource.mediaType == mediaType {
                return resource
            }
        }
        return nil
    }

    /**
     Gets the first resource (random order) with the give extension.

     Useful for looking up the table of contents as it's supposed to be the only resource with NCX extension.
     */
    func findByExtension(_ ext: String) -> EpubResource? {
        for resource in resources.values {
            if resource.mediaType != nil && resource.mediaType.defaultExtension == ext {
                return resource
            }
        }
        return nil
    }

    /**
     Gets the first resource (random order) with the give properties.

     - parameter properties: ePub 3 properties. e.g. `cover-image`, `nav`
     - returns: The Resource.
     */
    func findByProperty(_ properties: String) -> EpubResource? {
        for resource in resources.values {
            if resource.properties == properties {
                return resource
            }
        }
        return nil
    }

    /**
     Gets the resource with the given href.
     */
    func findByHref(_ href: String) -> EpubResource? {
        guard !href.isEmpty else { return nil }

        // This clean is neede because may the toc.ncx is not located in the root directory
        let cleanHref = href.replacingOccurrences(of: "../", with: "")
        return resources[cleanHref]
    }

    /**
     Gets the resource with the given href.
     */
    func findById(_ id: String?) -> EpubResource? {
        guard let id = id else { return nil }

        for resource in resources.values {
            if let resourceID = resource.id, resourceID == id {
                return resource
            }
        }
        return nil
    }

    /**
     Whether there exists a resource with the given href.
     */
    func containsByHref(_ href: String) -> Bool {
        guard !href.isEmpty else { return false }

        return resources.keys.contains(href)
    }

    /**
     Whether there exists a resource with the given id.
     */
    func containsById(_ id: String?) -> Bool {
        guard let id = id else { return false }

        for resource in resources.values {
            if let resourceID = resource.id, resourceID == id {
                return true
            }
        }
        return false
    }
}
